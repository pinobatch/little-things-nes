#!/usr/bin/env python3
import sim
import re
import sys
import math

exportsRE = re.compile(r"([a-zA-Z_][a-zA-Z0-9_]+)\s+00([0-9A-F]{4})")
def load_exports():
    from itertools import chain

    with open('../map.txt', 'rU') as infp:
        map_txt = [line.rstrip() for line in infp]
    firstLine = map_txt.index('Exports list by value:') + 2
    lastLine = map_txt.index('Imports list:')
    map_txt = [exportsRE.findall(line) for line in map_txt[firstLine:lastLine]]
    return dict((name, int(address, 16))
                for (name, address) in chain.from_iterable(map_txt))

def jsr(pc, a=0, x=0, y=0, p=0):
    regs = {'pc': pc, 'a': a, 'x': x, 'y': y, 'p': 0, 's': 0xFD}
    cycles = 0
    while regs['s'] <= 0xFD:
        rts = regs['pc']
        try:
            cycles += sim.run_instruction(regs)
        except KeyError:
            print("Unknown instruction at $%04x" % regs['p'], file=sys.stderr)
            return None
    return (rts, regs['a'], regs['x'], regs['y'], regs['p'], cycles)

def exhaustive_test_mul8(mul8):
    failures = 0
    maxcyc = 0
    print("Testing mul8")
    for factor0 in range(256):
        for factor1 in range(256):
            (rts, a, x, y, p, cycles) = jsr(mul8, a=factor0, y=factor1)
            maxcyc = max(cycles, maxcyc)
            mulresult = a << 8 | sim.ram[0]
            if mulresult != factor0 * factor1:
                print("%d * %d != %d" % (factor0, factor1, mulresult))
                failures += 1
        sys.stdout.write('.')
    sys.stdout.write('\n')
    print("failed cases: %d; max cycles: %d" % (failures, maxcyc))
    return failures == 0

def exhaustive_test_getSlope1(getSlope1):
    failures = 0
    maxcyc = 0
    print("Testing getSlope1")
    for run in range(1, 256):
        for rise in range(run):
            (rts, a, x, y, p, cycles) = jsr(getSlope1, a=rise, y=run)
            maxcyc = max(cycles, maxcyc)
            if a != 256 * rise // run:
                print("256 * %d // %d != %d" % (rise, run, a))
                failures += 1
        sys.stdout.write('.')
    sys.stdout.write('\n')
    print("failed cases: %d; max cycles: %d" % (failures, maxcyc))
    return failures == 0

def exhaustive_test_bcd8bit(bcd8bit):
    failures = 0
    maxcyc = 0
    print("Testing bcd8bit")
    for n in range(256):
        (rts, a, x, y, p, cycles) = jsr(bcd8bit, n)
        maxcyc = max(cycles, maxcyc)
        result = '%02x%x' % (sim.ram[0], a)
        if result != "%03d" % n:
            print("%s != %03d" % (result, n))
            failures += 1
    print("failed cases: %d; max cycles: %d" % (failures, maxcyc))
    return failures == 0

def exhaustive_test_bcdConvert(bcdConvert):
    failures = 0
    maxcyc = 0
    print("Testing bcdConvert")
    for n in range(65536):
        sim.ram[0] = n & 0xFF
        sim.ram[1] = n >> 8
        (rts, a, x, y, p, cycles) = jsr(bcdConvert)
        maxcyc = max(cycles, maxcyc)
        result = ''.join('%x' % d for d in reversed(sim.ram[2:7]))
        if result != "%05d" % n:
            print("%s != %05d" % (result, n))
            failures += 1
        if n % 256 == 0:
            sys.stdout.write('.')
    sys.stdout.write('\n')
    print("failed cases: %d; max cycles: %d" % (failures, maxcyc))
    return failures == 0

# Because getAngle has four arguments, X1, Y1, X2, and Y2, an
# exhaustive test is not practical (4.2 billion calls).  Instead,
# we'll do several exhaustive subsets, letting two arguments go free
# while fixing the other two, followed by a pseudorandom test.
# The first 18 subsets fix either X1,Y1 or X2,Y2 at the
# left, center, or right and top, center, or bottom, and lets the
# other go free.  Others are as follows:
# X2,Y2 = X1,255-Y1
# X2,Y2 = 255-X1,Y1
# X2,Y2 = 255-X1,255-Y1
# X2,Y2 = Y1,X1

def getAngle_iteration(getAngle, x1, y1, x2, y2):
    sim.ram[0] = x1
    sim.ram[1] = y1
    sim.ram[2] = x2
    sim.ram[3] = y2
    (rts, got_theta, x, y, p, cycles) = jsr(getAngle)
    expected_theta = math.atan2(y2-y1, x2-x1) * 16.0 / math.pi
    theta_error = (got_theta + 16 - expected_theta) % 32 - 16
    if abs(theta_error) > 0.51:
        print("Error: (%d,%d)-(%d,%d) expected %.2f but got %d"
              % (x1, y1, x2, y2, expected_theta, got_theta),
              file=sys.stderr)
    return got_theta, theta_error, cycles

def test_getAngle_anchor(getAngle, xfixed, yfixed):
    print("Testing getAngle, one end fixed at (%d, %d)" % (xfixed, yfixed))
    maxcyc = 0
    maxerr = 0
    for yfloat in range(256):
        for xfloat in range(256):
            (theta1, err1, cyc1) = getAngle_iteration(getAngle, xfloat, yfloat, xfixed, yfixed)
            (theta2, err2, cyc2) = getAngle_iteration(getAngle, xfixed, yfixed, xfloat, yfloat)
            maxcyc = max(cyc1, cyc2, maxcyc)
            maxerr = max(err1, err2, maxerr)
        sys.stdout.write('.')
    sys.stdout.write("\n")
    return maxcyc, maxerr

def test_getAngle_quadrants(getAngle):
    maxcyc = 0
    maxerr = 0
    for yfixed in (0, 128, 255):
        for xfixed in (0, 128, 255):
            cyc, err = test_getAngle_anchor(getAngle, xfixed, yfixed)
            print("cyc", cyc, "err", err)
            maxcyc = max(cyc, maxcyc)
            maxerr = max(err, maxerr)
    return maxcyc, maxerr

def test_getAngle_reflect(getAngle, xflip, yflip):
    print("Testing getAngle, %s X, %s Y"
          % ("flipping" if xflip else "not flipping",
             "flipping" if yflip else "not flipping"))
    xflip = 255 if xflip else 0
    yflip = 255 if yflip else 0
    maxcyc = 0
    maxerr = 0
    for y in range(256):
        for x in range(256):
            (theta1, err1, cyc1) = getAngle_iteration(getAngle, x, y, x^xflip, y^yflip)
            (theta2, err2, cyc2) = getAngle_iteration(getAngle, x, y, y^yflip, x^xflip)
            maxcyc = max(cyc1, cyc2, maxcyc)
            maxerr = max(err1, err2, maxerr)
        sys.stdout.write('.')
    return maxcyc, maxerr

def test_getAngle_reflects(getAngle):
    maxcyc = 0
    maxerr = 0
    for yflip in (False, True):
        for xflip in (False, True):
            cyc, err = test_getAngle_reflect(getAngle, xflip, yflip)
            print("cyc", cyc, "err", err)
            maxcyc = max(cyc, maxcyc)
            maxerr = max(err, maxerr)
    return maxcyc, maxerr

def randomized_test_diva2by1(diva2by1):
    seed = 69
    failures = 0
    maxcyc = 0
    print("Testing diva2by1")
    for run in range(1, 256):
        sim.ram[1] = run  # divisor; the subroutine doesn't change it
        if run >= 4:
            rises = range(run * 4)
            for i in range(run * 4, run * 256, run // 2):

                # The linear congruential generator used by the standard
                # library of the BCPL language. "Excellent spectral test"
                # per http://random.mat.sbg.ac.at/results/karl/server/node4.html
                seed = (seed * 2147001325 + 715136305) & 0xFFFFFFFF
                rise = min(run * 256 - 1, ((run // 2 * seed) >> 32) + i)
                rises.append(rise)
        else:
            rises = range(256 * run)
        for rise in rises:
            sim.ram[2] = rise & 0xFF
            (rts, a, x, y, p, cycles) = jsr(diva2by1, a=rise >> 8, y=run)
            maxcyc = max(cycles, maxcyc)
            if a != rise % run:
                print("%d %% %d != %d" % (rise, run, a))
                failures += 1
            if sim.ram[0] != rise // run:
                print("%d // %d != %d" % (rise, run, sim.ram[0]))
                failures += 1
        sys.stdout.write('.')
    sys.stdout.write('\n')
    print("failed cases: %d; max cycles: %d" % (failures, maxcyc))
    return failures == 0

def pi_test_pctageDigit(pctageDigit):

    # 71/226 is very close to pi/10
    # so try with all multiples of Pi
    failures = 0
    for factor in range(1, 65535//226 + 1):
        num = 71 * factor
        den = 226 * factor
        sim.ram[0] = num & 0xFF
        sim.ram[1] = num >> 8
        sim.ram[2] = den & 0xFF
        sim.ram[3] = den >> 8
        piDigits = []
        totalcyc = 0
        for i in range(8):
            (rts, a, x, y, p, cycles) = jsr(pctageDigit)
            totalcyc += cycles
            if a >= 10:
                print("failure at factor %d: digit should never be over 10"
                      % factor, file=sys.stderr)
                failures += 1
            piDigits.append("%x" % a)
        piDigits = ''.join(piDigits)

        # Factor 1 will take the longest because it has the most trial subs;
        # bigger factors start skipping more trial subs with alreadyGreater.
        if factor == 1:
            print("Eight digits converted in %d cycles" % totalcyc)
        if piDigits != '31415929':
            print("Bad pi at factor %d: %d/%d = .%s"
                  % (factor, num, den, piDigits), file=sys.stderr)
            failures += 1
    if failures == 0:
        print("Mmm... pi.  (No error)")

def exhaustive_test_sqrt16(sqrt16):
    failures = 0
    maxcyc = 0
    for i in range(65536):
        expected_root = int(math.floor(math.sqrt(i)))
        expected_remainder = i - expected_root * expected_root
        sim.ram[0] = i & 0xFF
        sim.ram[1] = i >> 8
        (rts, a, x, y, p, cycles) = jsr(sqrt16)
        maxcyc = max(maxcyc, cycles)
        remainder = sim.ram[3] | ((p & 0x01) << 8)
        root = sim.ram[2]
        if root != expected_root or remainder != expected_remainder:
            print("sqrt(%d) was %d rem %d; expected %d rem %d"
                  % (i, root, remainder, expected_root, expected_remainder),
                  file=sys.stderr)
            failures += 1
        if i % 256 == 0:
            sys.stdout.write('.')
    sys.stdout.write('\n')
    print("max cycles:", maxcyc)
    return failures == 0

def exploratory_test_bpm(gcbf):
    tvSystem = 0
    rpb = 3
    sim.ram[10] = tvSystem
    sim.ram[11] = rpb

    for tempoCounter in range(0, 3606, 50):
        negTempoCounter = tempoCounter - 3606
        sim.ram[8] = negTempoCounter & 0xFF
        sim.ram[9] = (negTempoCounter >> 8) & 0xFF
        (rts, a, x, y, p, cycles) = jsr(gcbf)
        print("%4d =>%3d in %4d" % (tempoCounter, a, cycles))

def count_ones_reference(n):
    count = 0
    while n > 0:
        n &= n - 1
        count += 1
    return count

def exhaustive_test_parity(versions):
    failures = 0
    for i in range(256):
        parity_ref = count_ones_reference(i) & 1
        for name, addr in versions:
            sim.ram[0] = i
            (rts, a, x, y, p, cycles) = jsr(addr)
            parity = p & 1
            print ("%d bytes %d cycles"% (rts-addr, cycles))
            if parity != parity_ref:
                print ("%s has a failure with i = $%x, %d != expected %d"
                       % (name, i, parity, parity_ref))
                failures += 1

def main():
    with open('../mathlib.prg', 'rb') as infp:
        sim.rom.extend(infp.read(16384))
    exports = load_exports()
    print("Exported symbols:", sorted(exports.keys()))
##    exploratory_test_bpm(exports['getCurBeatFraction'])
    exhaustive_test_parity([
        ('parity_by_shifting', exports['parity_by_shifting']),
        ('parity_by_adding', exports['parity_by_adding'])
    ])
    

if __name__=='__main__':
    main()
