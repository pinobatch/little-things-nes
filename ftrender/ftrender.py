#!/usr/bin/env python3
import sys
from contextlib import closing
import subprocess
import wave
import time
from PIL import Image, ImageDraw

# FamiTracker data model ############################################

semitonenames = [
    'C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-'
]

class FTEModule(object):
    def __init__(self):
        self.title = self.author = self.copyright = ""
        self.commentlines = []
        self.songs = []
        self.songs_using_speedseq = []
        self.speedseqs = []

    def add_song(self, song):
        self.songs.append(song)

class FTESong(object):
    def __init__(self):
        self.effect_columns = None
        self.orders = []
        self.patterns = []
        self.pattern_length = 64
        self.initial_speed = 6
        self.using_speedseq = False
        self.initial_tempo = 150
        self.beat_length = 4
        self.measure_length = 16
        self.title = "New song"
        self.speedseqs = None

    def set_effect_columns(self, columns):
        self.effect_columns = [
            int_with_default_base(x, 16) for x in columns
        ]
        if len(columns) > len(self.patterns):
            self.patterns.extend(
                []
                for i in range(len(self.patterns), len(columns))
            )

    def set_order(self, i, pattern_numbers):
        num_channels = len(self.effect_columns)
        if i + 1 > len(self.orders):
            self.orders.extend(
                [0] * num_channels
                for i in range(len(self.orders), i + 1)
            )
        self.orders[i] = [
            int_with_default_base(x, 16) for x in pattern_numbers
        ]

    def set_patterns(self, i, patterns):
        num_channels = len(self.effect_columns)
        for chpats, pattern in zip(self.patterns, patterns):
            if i + 1 > len(chpats):
                chpats.extend(
                    [None] * num_channels
                    for i in range(len(chpats), i + 1)
                )
            chpats[i] = pattern

    def count_max_effects(self, ch):
        return max(pattern.count_max_effects()
                   for pattern in self.patterns[ch])

    def compact_effects(self, ch, new_width=None):
        curfx = self.effect_columns[ch]
        if new_width is None:
            new_width = self.count_max_effects(ch)
        for pattern in self.patterns[ch]:
            pattern.compact_effects(new_width)
        self.effect_columns[ch] = new_width

    def update_used_columns(self):
        out = []
        for chpats in self.patterns:
            used_columns = 0
            for pattern in chpats:
                used_columns |= pattern.get_used_columns()
            out.append(used_columns)
        self.used_columns = out

class FTEPattern(object):
    def __init__(self, length):
        self.rows = [FTEPatternRow() for x in range(length)]

    def count_max_effects(self):
        return max(len([x for x in row.effects if x is not None])
                   for row in self.rows)

    def compact_effects(self, maxwidth):
        for row in self.rows:
            realfx = [x for x in row.effects if x is not None]
            realfx.extend([None] * (maxwidth - len(realfx)))
            row.effects[:] = realfx

    def get_used_columns(self):
        used_columns = 0
        for row in self.rows:
            if row.note is not None:
                used_columns |= 1
            if row.instrument is not None:
                used_columns |= 2
            if row.volume is not None:
                used_columns |= 4
        return used_columns

class FTEPatternRow(object):
    def __init__(self):
        self.note = self.instrument = self.volume = None
        self.effects = []
        self.is_noise = False

    def tostrings(self):
        parts = []
        if self.note is None:
            note = '...'
        elif self.note == '=':  # slow noteoff
            note = '==='
        elif self.note == '-':  # fast noteoff
            note = '---'
        elif self.is_noise:
            assert self.note < 16
            note = '%X-#' % self.note
        else:
            pitchclass, octave = self.note % 12, self.note // 12
            note = "%s%d" % (semitonenames[pitchclass], octave)
        parts.append(note)
        parts.append("%02X" % self.instrument
                     if self.instrument is not None
                     else '..')
        parts.append("%X" % self.volume
                     if self.volume is not None
                     else '.')
        parts.extend("%s%02X" % (fx[0], fx[1])
                     if fx is not None
                     else '...'
                     for fx in self.effects)
        return parts

    def __str__(self):
        return " ".join(self.tostrings())

def fte_trial_playback(song, frame_id=0):
    """Interpret speed commands in a module played from start.

Return a generator of (frame ID, row ID, start time in ticks) tuples.
"""
    cumul_time = 0
    frac_time = 0
    row_id = 0
    tempo = song.initial_tempo
    speed = song.initial_speed
    speedseq = speed if song.using_speedseq else None
    speedseqpos = 0
    while True:
        yield (frame_id, row_id, cumul_time)

        # Scan for relevant effects (B, C, D, F)
        # B: set jump frame
        # C: stop
        # D: set jump row
        orders = song.orders[frame_id]
        rows = [song.patterns[ch][patid].rows[row_id]
                for ch, patid in enumerate(orders)]
        jump_frame = jump_row = None
        all_effects = [fx for row in rows for fx in row.effects if fx]
        for fxtype, fxvalue in all_effects:
            if fxtype == 'C':
                return
            elif fxtype == 'F':
                if fxvalue < 32:
                    speed = fxvalue
                    speedseq = None
                    using_speedseq = False
                else:
                    tempo = fxvalue
            elif fxtype == 'B':
                jump_frame = fxvalue
            elif fxtype == 'D':
                jump_row = fxvalue

        # Add tempo and speed
        if tempo == 0: return
        if speedseq is not None:
            # Speed sequences, also called "grooves"
            speed = song.speedseqs[speedseq][speedseqpos]
            speedseqpos += 1
            if speedseqpos >= len(song.speedseqs[speedseq]):
                speedseqpos = 0
        frac_time += 150 * speed
        row_time, frac_time = frac_time // tempo, frac_time % tempo
        cumul_time += row_time

        # If no jump, but we're on the pattern's last row,
        # jump to the next frame
        if (jump_row is None and jump_frame is None
            and row_id + 1 >= song.pattern_length):
            jump_row = 0

        # If a jump row is specified, default to the next frame.
        if jump_row is not None and jump_frame is None:
            jump_frame = frame_id + 1
            if jump_frame >= len(song.orders):
                jump_frame = 0

        # If a jump frame is specified, default to the first row.
        if jump_frame is not None:
            if jump_row is None:
                jump_row = 0
            frame_id, row_id = jump_frame, jump_row
        else:
            row_id += 1

# FamiTracker text export loading ###################################

def int_with_default_base(x, base=10):
    """Convert x to an integer, using the chosen base if x is a string.

Unfortunately, instead of ignoring an explicit base when converting a
non-string, Python's int(x, base) constructor raises the following
exception:

    TypeError: int() can't convert non-string with explicit base

This constructor instead ignores the base in this case.
"""
    return int(x, base) if isinstance(x, str) else int(x)

def csv_unquote(x):
    """If x starts and ends with double quotes ("), replace "" with "."""
    if x.startswith('"') and x.endswith('"'):
        x = x[1:-1].replace('""', '"')
    return x

isemitonenames = {v: k for k, v in enumerate(semitonenames)}

def parse_patnote(notestr, is_noise=False):
    if notestr == '...':
        return None
    if notestr == '---':
        return '-'
    if notestr == '===':
        return '='
    if is_noise:
        if notestr[1:] != '-#':
            raise ValueError("invalid noise note: " + notestr)
        return int(notestr[0], 16)
    return isemitonenames[notestr[:2]] + 12 * int(notestr[2])

def parse_patrowch(rowstr, is_noise=False):
    row = rowstr.split()
    note = parse_patnote(row[0], is_noise=is_noise)
    instrument = int(row[1], 16) if row[1] != '..' else None
    volume = int(row[2], 16) if row[2] != '.' else None
    effects = [
        (fx[0], int(fx[1:3], 16)) if fx != '...' else None
        for fx in row[3:]
    ]
    return note, instrument, volume, effects

class FTELoader(object):
    def __init__(self):
        self.num_lines = 0
        self.module = FTEModule()
        self.cur_song = None
        self.cur_patterns = None
        self.unknown_words = set()

    def append(self, line):
        self.num_lines += 1
        line = line.strip()
        if line == '' or line.startswith("#"):  # Blank or comment
            return
        word_remainder = line.split(None, 1)
        if len(word_remainder) < 2:
            raise ValueError("no arguments to " + line)
        word, remainder = word_remainder
        word_handler = self.word_handlers.get(word.upper(), FTELoader.unknown_word_handler)
        word_handler(self, word, remainder)

    def extend(self, lines):
        for line in lines:
            self.append(line)

    def unknown_word_handler(self, word, remainder):
        word = word.upper()
        if word not in self.unknown_words:
            self.unknown_words.add(word)
            print("Unknown word %s args %s"
                  % (word, remainder), file=sys.stderr)

    def handle_TITLE(self, word, remainder):
        self.module.title = csv_unquote(remainder)

    def handle_AUTHOR(self, word, remainder):
        self.module.author = csv_unquote(remainder)

    def handle_COPYRIGHT(self, word, remainder):
        self.module.copyright = csv_unquote(remainder)

    def handle_COMMENT(self, word, remainder):
        self.module.commentlines.append(csv_unquote(remainder))

    def handle_TRACK(self, word, remainder):
        lstn = remainder.split(None, 3)
        if len(lstn) < 4:
            raise ValueError("TRACK too short: " + remainder)
        length, speed, tempo, title = lstn
        self.cur_song = song = FTESong()
        song_id = len(self.module.songs)
        self.module.songs.append(song)
        song.pattern_length = int(length)
        song.initial_speed = int(speed)
        song.initial_tempo = int(tempo)
        song.title = csv_unquote(title)
        song.speedseqs = self.module.speedseqs
        if self.module.songs_using_speedseq:
            print("songs_using_speedseq is", self.module.songs_using_speedseq)
            song.using_speedseq = self.module.songs_using_speedseq[song_id]

    def handle_COLUMNS(self, word, remainder):
        r = remainder.split()
        if r[0] != ":":
            raise ValueError("COLUMNS must start with a colon: " + remainder)
        self.cur_song.set_effect_columns(r[1:])

    def handle_ORDER(self, word, remainder):
        frame_cols = remainder.split(":", 1)
        if len(frame_cols) < 2:
            raise ValueError("ORDER missing colon: " + remainder)
        frame, cols = (x.strip() for x in frame_cols)
        self.cur_song.set_order(int(frame, 16), cols.split())

    def handle_PATTERN(self, word, remainder):
        pattern_id = int(remainder, 16)
        pl = self.cur_song.pattern_length
        pats = [FTEPattern(pl) for p in self.cur_song.effect_columns]
        self.cur_patterns = pats
        self.cur_song.set_patterns(pattern_id, pats)

    def handle_ROW(self, word, remainder):
        row_pats = [x.strip() for x in remainder.split(":")]
        row_id = int(row_pats.pop(0), 16)
        for ch, s in enumerate(row_pats):
            is_noise = ch == 3
            row = parse_patrowch(s, is_noise)
            pr = self.cur_patterns[ch].rows[row_id]
            pr.note, pr.instrument, pr.volume, pr.effects = row
            pr.is_noise = is_noise

    def handle_GROOVE(self, word, remainder):
        args_frames = remainder.split(":", 1)
        if len(args_frames) != 2:
            raise ValueError("GROOVE missing colon: " + remainder)
        args = [int(x) for x in args_frames[0].split()]
        if len(args) != 2:
            raise ValueError("GROOVE missing initial args: " + remainder)
        # These are guesses, as 0CC-exclusive parts of text export
        # are largely undocumented
        groove_id, secondparam = args
        frames = [int(x) for x in args_frames[1].split()]

        grooves_to_add = groove_id + 1 - len(self.module.speedseqs)
        if grooves_to_add > 0:
            self.module.speedseqs.extend([None] * grooves_to_add)
        self.module.speedseqs[groove_id] = frames

    def handle_USEGROOVE(self, word, remainder):
        r = remainder.split()
        if r[0] != ":":
            raise ValueError("USEGROOVE must start with a colon: " + remainder)
        self.module.songs_using_speedseq = [bool(int(x)) for x in r[1:]]
        print("songs_using_speedseq set to", self.module.songs_using_speedseq)

    word_handlers = {
        "TITLE": handle_TITLE,
        "AUTHOR": handle_AUTHOR,
        "COPYRIGHT": handle_COPYRIGHT,
        "COMMENT": handle_COMMENT,
        "TRACK": handle_TRACK,
        "COLUMNS": handle_COLUMNS,
        "ORDER": handle_ORDER,
        "PATTERN": handle_PATTERN,
        "ROW": handle_ROW,
        "GROOVE": handle_GROOVE,
        "USEGROOVE": handle_USEGROOVE,
    }

# Drawing rows ######################################################

class BMFont(object):
    def __init__(self, im, glyphsize=(8, 8), numlevels=2):
        """
im -- an indexed (type P) image with colors 0 through numlevels-1
    representing 0 through full coverage

"""
        self.im = im
        self.glyphsize = glyphsize
        self.numlevels = numlevels

    def setcolors(self, fgcolor, bgcolor):
        nl = self.numlevels
        palettedata = []
        for i in range(nl):
            proportion = i / (nl - 1)
            r = bgcolor[0] + (fgcolor[0] - bgcolor[0]) * proportion
            g = bgcolor[1] + (fgcolor[1] - bgcolor[1]) * proportion
            b = bgcolor[2] + (fgcolor[2] - bgcolor[2]) * proportion
            palettedata.extend(int(round(x)) for x in (r, g, b))
        self.im.putpalette(palettedata)

    def draw(self, im, xy, txt):
        x, y = xy
        gw, gh = self.glyphsize
        glyphs_per_row = self.im.size[0] // gw
        for c in txt:
            c = ord(c) - 32
            srcx, srcy = c % glyphs_per_row * gw, c // glyphs_per_row * gh
            glyph = self.im.crop((srcx, srcy, srcx + gw, srcy + gh))
            im.paste(glyph, (x, y))
            x += gw

class DrawStyle(object):
    bgcolors = [(0, 0, 0), (0, 0, 0), (32, 32, 0), (0, 0, 128)]
    fgcolors = [(0, 255, 0), (240, 240, 0), (255, 255, 96), (255, 255, 255)]
    uilightcolor = (192, 192, 192)
    uidarkcolor = (0, 0, 32)
    font = BMFont(Image.open("font.png"), (16, 24), 3)

def pattern_row_size(style, num_effects, used_columns=None):
    if used_columns == None:
        used_columns = 7
    char_width, ht = style.font.glyphsize
    halfspace_width = -(-char_width // 2)

    num_chars = 3 * num_effects
    num_halfspaces = num_effects - 1
    if used_columns & 1:  # Note column
        num_chars += 3
        num_halfspaces += 1
    if used_columns & 2:  # Instrument column
        num_chars += 2
        num_halfspaces += 1
    if used_columns & 4:  # Volume column
        num_chars += 1
        num_halfspaces += 1
    return (num_chars * char_width + num_halfspaces * halfspace_width, ht)

def get_row_colors(style, hllevel=0, faded=False):
    """Get colors for a pattern row.

hllevel -- 0 for most rows, 1 for beat highlight, 2 for measure highlight,
    3 for playback cursor
faded -- True to mix style colors equally with hllevel 0 background

Return a (fgrgb, bgrgb) tuple
"""
    bgr, bgg, bgb = style.bgcolors[hllevel]
    fgr, fgg, fgb = style.fgcolors[hllevel]
    if faded:
        bg0r, bg0g, bg0b = style.bgcolors[0]
        bgr = (bgr + bg0r) // 2
        bgg = (bgg + bg0g) // 2
        bgb = (bgb + bg0b) // 2
        fgr = (fgr + bg0r) // 2
        fgg = (fgg + bg0g) // 2
        fgb = (fgb + bg0b) // 2
    return ((fgr, fgg, fgb), (bgr, bgg, bgb))

def render_pattern_row(im, row, xy, style,
                       hllevel=0, faded=False, used_columns=7):
    """Render an FTEPatternRow to a Pillow image.

im -- destination image
row -- an FTEPatternRow instance
xy -- (x, y) coordinate
style -- DrawStyle instance
hllevel, faded -- as for get_row_colors()
"""
    colors = get_row_colors(style, hllevel, faded)
    style.font.setcolors(*colors)

    x, y = xy
    char_width = style.font.glyphsize[0]
    halfspace_width = -(-char_width // 2)
    for i, word in enumerate(row.tostrings()):
        if i < 3 and ((1 << i) & used_columns) == 0:
            continue
        style.font.draw(im, (x, y), word)
        x += len(word) * char_width + halfspace_width

def frame_row_size(style, effect_columns, used_columns=None):
    char_width, ht = style.font.glyphsize
    if used_columns is None:
        used_columns = [7] * len(effect_columns)
    widths = [pattern_row_size(style, ec, uc)[0]
              for ec, uc in zip(effect_columns, used_columns)]
    xs = []
    cumul_width = 2 * char_width
    for w in widths:
        if w < 16:
            xs.append(None)
            continue
        cumul_width += char_width  # Border to left of each track
        xs.append(cumul_width)
        cumul_width += w
    return ((cumul_width, ht), xs)

def render_frame_row(im, dc, xy, song, frame_id, row_id, style,
                     is_cursor=False, faded=False, frs=None):
    # Determine highlight
    pos_in_measure = row_id % song.measure_length
    pos_in_beat = pos_in_measure % song.beat_length
    hllevel = (
        3 if is_cursor
        else 2 if pos_in_measure == 0
        else 1 if pos_in_beat == 0
        else 0
    )

    fgcolor, bgcolor = get_row_colors(style, hllevel, faded)
    if frs is None:
        frs = frame_row_size(style, song.effect_columns, song.used_columns)
    (width, ht), xs = frs
    x, y = xy
    dc.rectangle((x, y, x + width - 1, y + ht - 1), bgcolor)

    # Draw row number
    style.font.setcolors(fgcolor, bgcolor)
    style.font.draw(im, (x, y), "%02X" % row_id)

    # Draw contents of this pattern row
    cw = style.font.glyphsize[0]
    vbarwidth = (cw + 2) // 4
    vbarxoffset = (vbarwidth + cw) // 2
    vbarcolor = style.fgcolors[3]
    orders = song.orders[frame_id]
    rows = [song.patterns[ch][patid].rows[row_id]
            for ch, patid in enumerate(orders)]
    for rel_x, row, uc in zip(xs, rows, song.used_columns):
        if rel_x is None:
            continue
        vbarx = x + rel_x - vbarxoffset
        dc.rectangle((vbarx, y, vbarx + vbarwidth - 1, y + ht - 1), vbarcolor)
        render_pattern_row(im, row, (x + rel_x, y), style,
                           hllevel, faded, uc)

def render_song_rows(canvas, style, song, frametimes, first_row,
                     cursor_row=None, moduletitle=None):
    frs = frame_row_size(style, song.effect_columns, song.used_columns)
    (roww, rowht), xs = frs
    imw, imht = canvas.size
    cw = style.font.glyphsize[0]

    # Center the overall display, offset a bit right to fit frame_id marks
    patleft = (imw + 3 * cw - roww) // 2

    # BBC 16:9 title safe area begins 5% from the top (720p: 36 down)
    title_y = imht // 20
    chnames_y = title_y + rowht
    notegrid_top = chnames_y + rowht
    visrows = -(-(imht - notegrid_top) // rowht)

    # Clear previous frame if any
    dc = ImageDraw.Draw(canvas)
    dc.rectangle((0, 0, imw - 1, imht - 1), fill=style.uidarkcolor)

    # Draw module and song titles
    dc.rectangle((patleft, title_y, patleft+roww-1, title_y+rowht*2-1),
                 style.uilightcolor)
    style.font.setcolors(style.uidarkcolor, style.uilightcolor)

    # Draw channel names, abbreviating for lack of space
    chnames = [
        ("PULSE 1", "SQ1"),
        ("PULSE 2", "SQ2"),
        ("TRIANGLE", "TRI"),
        ("NOISE", "NOI"),
        ("DPCM", "DMC")
    ]
    chnames.extend(
        ("EXPANSION %d" % i, "EXP%d" % i)
        for i in range(1, len(xs) - len(chnames) + 1)
    )
    chxs = [(x, nm) for x, nm in zip(xs, chnames) if x is not None]
    chxs.append((roww, ("", "")))
    chxs = [(x, x2 - x, nm) for (x, nm), (x2, _) in zip(chxs, chxs[1:])]
    for x, w, (chname, chnamealt) in chxs:
        if cw * len(chname) >= w:
            chname = chnamealt
        style.font.draw(canvas, (patleft + x, chnames_y), chname)

    songtitle = song.title
    if moduletitle:
        songtitle = ": ".join((moduletitle, songtitle))
    style.font.draw(canvas, (patleft, title_y), songtitle.upper())

    cursor_frame = (frametimes[cursor_row][0]
                    if cursor_row is not None
                    else None)
    drawn_frame_id = None
    for row_y, (frame_id, rowid, t) \
        in enumerate(frametimes[first_row:first_row + visrows]):
        y = row_y * rowht + notegrid_top
        is_cursor = cursor_row == first_row + row_y
        faded = cursor_frame is not None and cursor_frame != frame_id
        render_frame_row(canvas, dc, (patleft, y), song,
                         frame_id, rowid, style,
                         is_cursor=is_cursor, faded=faded, frs=frs)
        if drawn_frame_id != frame_id:
            drawn_frame_id = frame_id
            style.font.setcolors(style.uilightcolor, style.uidarkcolor)
            style.font.draw(canvas, (patleft - cw * 3, y), "%02X" % frame_id)

# Now we do something with this #####################################

def main():
    module_path = "boy2.txt"
    song_id = 0
    audio_path = "boy2.wav"
    output_path = "boy2.mp4"
    beat_length = 4
    measure_length = 16

    # normally 1280, but if expansions make it too wide, use
    # 1440 to 1920 to horizontally compress the output
    prescale_width = 960
    video_quality = 0  # 0 to 10
    use_flipscreen = False

    # Get the wave's runtime
    with closing(wave.open(audio_path)) as w:
        runtime = w.getnframes() / w.getframerate()
    maxframes = int((60 * runtime) // 1)

    # Load the module
    loader = FTELoader()
    with open(module_path, "r") as infp:
        loader.extend(infp)
    m = loader.module
    song = m.songs[song_id]
    song.beat_length = beat_length
    song.measure_length = measure_length
    for ch in range(len(song.patterns)):
        song.compact_effects(ch)
    song.update_used_columns()

    # Collect time to display each frame
    frametimes = []
    for row in fte_trial_playback(song):
        frametimes.append(row)
        if row[2] >= maxframes:
            break
##    print("\n".join(repr(row) for row in frametimes))

    style = DrawStyle()
    fps = 30
    canvas_sz = prescale_width, 720
    enc_sz = canvas_sz[0]//2, canvas_sz[1]//2

    cmd_out = [
        'ffmpeg', '-y',  # overwrite

        # Input from a raw RGB24 pixel filmstrip stream
        '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', "%dx%d" % canvas_sz,
        '-r', "%f" % fps, '-i', '-',

        # Input from FT audio export
        "-i", audio_path,

        # Video transformation options
        '-pix_fmt', 'yuv420p',
        '-vf', 'scale=%d:%d' % enc_sz,
        '-t', "%.2f" % (maxframes/60),

        # Encoding options
        # Constant rate factor varies from 28 (low quality) to 18 (high
        # quality) per http://slhck.info/video/2017/02/24/crf-guide.html
        '-c:v', 'libx264',
        '-crf', "%d" % (28 - video_quality),
        '-c:a', 'aac',
        "-b:a", "80k",
        "-movflags", "+faststart",
        output_path
    ]
    encoder = subprocess.Popen(cmd_out, stdin=subprocess.PIPE)

    canvas = Image.new("RGB", canvas_sz)
    top_i = 0
    timestamp = 0
    frame_data = None
    time_i0 = time.time()

    for i, (frame_id, row_id, rowstarttime) in enumerate(frametimes):
        # Push out the rendered scene
        while frame_data is not None and timestamp < rowstarttime:
            encoder.stdin.write(frame_data)
            timestamp += 60 // fps
        frame_data = None

        if use_flipscreen:
            # Flip scrolling on each new measure
            old_frame_id, old_row_id, _ = frametimes[top_i]
            old_measure = old_row_id // song.measure_length
            measure = row_id // song.measure_length
            if old_frame_id != frame_id or old_measure != measure:
                top_i = i
        else:
            top_i = max(0, i - 8)

        # Render scene
        if row_id % song.measure_length == 0:
            progress = [
                "%4d/%4d %02X:%02X %d:%02d.%d"
                % (i, len(frametimes), frame_id, row_id,
                   timestamp // 3600, (timestamp // 60) % 60,
                   (timestamp % 60) // 6)
            ]

            # If enough of the video has been rendered,
            # estimate time left
            if i >= 64:
                elapsed = time.time() - time_i0
                est_totaltime = elapsed * len(frametimes) / i
                remaining = int(round(est_totaltime - elapsed))
                if remaining > 3:
                    progress.append(
                        "; %d:%02d left" % (remaining // 60, remaining % 60)
                    )

            print("".join(progress))

        render_song_rows(canvas, style, song, frametimes, top_i,
                         cursor_row=i, moduletitle=m.title)
        frame_data = canvas.tobytes()

    while frame_data is not None and timestamp < maxframes:
        encoder.stdin.write(frame_data)
        timestamp += 60 // fps

    encoder.communicate()

if __name__=='__main__':
    main()
