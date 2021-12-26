Methodology
===========

The spam loop consists of an unrolled loop at 18 dots per write plus
15 dots of rest between iterations.  The self-modifying code in RAM
occupies 3 bytes per iteration plus 4 bytes for loop and return.
It takes the following form:

    @loop:
      .repeat SPAMINC_WRITES_PER_ITERATION
        inc $8001  ; 3
      .endrepeat
      dex          ; 6
      bne @loop    ; 9
      rts

A loop on 6502 cannot exceed 128 bytes, limiting us to a maximum of
`(128 - 3) // 3` or 41 writes per iteration.

How many iterations do we actually need?  To prevent the rest between
iterations from lining up over sprite 0, we don't want the length
of an iteration to be close to multiple of a scanline (341 dots).
I'll aim for the square root of 2 times the length of a scanline, or
482 dots.  Using 26 iterations gives `26 * 18 + 15` or 483 dots.

We spam three different writes, each intended to bring opaque
graphics data into the PPU's view for one CPU cycle.

- `inc $8001`  
  Puts CHR pages with opaque then transparent tile 0 in window 0 at
  PPU $0000.
- `asl $8000`  
  Swaps then unswaps $0000-$0FFF and $1000-$1FFF.  This puts CHR
  page 2 with opaque tile 0 then page 0 with transparent tile 0 at
  PPU $0000.
- `lsr $A000`  
  Points $2800-$2BFF at nametable 1 (filled with opaque tile $80)
  then nametable 0 (filled with transparent tile $00).

To make it less likely that an emulator or clone hardware passes for
the wrong reason, the test occurs in three phases: control group,
short spam, and long spam.  Control group writes the ending value
once, using an ordinary non-RMW store, and ensures that the result is
as expected.  Short spam does a set of RMWs that finishes long before
sprite 0 is drawn.  If sprite 0 is hit, the first write of the old
value took effect; if it is missed, the second write of the new value
took effect.  Long spam performs RMWs that cover most of the frame,
ideally causing the PPU to briefly see the old value if MMC3 honors
both writes.

Control group tests:

* Vertical mirroring, CHR page 0-1 in window 0, window 0 at $0000:  
  No sprite 0 hit
* Vertical mirroring, CHR page 4-5 in window 0, window 0 at $0000:  
  No sprite 0 hit
* Horizontal mirroring, CHR page 0-1 in window 0, window 0 at $0000:  
  Sprite 0 hit
* Vertical mirroring, CHR page 2-3 in window 0, window 0 at $0000:  
  Sprite 0 hit
* Vertical mirroring, CHR page 0-1 in window 0, window 2 at $0000:  
  Sprite 0 hit
