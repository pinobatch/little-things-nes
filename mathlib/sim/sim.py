#!/usr/bin/env python3
"""

This is part of a tool to run individual 6502 subroutines in
isolation for debugging and automated test cases.

Decimal mode ADC/SBC is not supported because the NES doesn't
use it.

"""

# 0: (dd,x)
# 1: dd
# 2: #ii
# 3: abs
# 4: (dd),y
# 5: d,x
# 6: a,y
# 7: a,x
# 8: 1 byte instructions, mostly 2 cycles
# 9: dd,y
# 10: rel
# 11: (aaaa)

# Each microop takes 1 cycle, except indirect takes two, and
# X16 and Y16 on reads with no page crossing take none
AMODE_LOBYTE_X = 0x01
AMODE_LOBYTE_Y = 0x02
AMODE_INDIRECT = 0x04
AMODE_ABSOLUTE = 0x08
AMODE_X16 = 0x10
AMODE_Y16 = 0x20
AMODE_FETCHINC = 0x40
AMODE_FETCH = 0x80
amode_bytes = [2, 2, 2, 3, 2, 2, 3, 3, 1, 2, 2, 3]
amode_microops = [
    AMODE_LOBYTE_X|AMODE_INDIRECT|AMODE_FETCH,
    AMODE_FETCH,
    0,
    AMODE_ABSOLUTE|AMODE_FETCH,

    AMODE_INDIRECT|AMODE_Y16|AMODE_FETCH,
    AMODE_LOBYTE_X|AMODE_FETCH,
    AMODE_ABSOLUTE|AMODE_Y16|AMODE_FETCH,
    AMODE_ABSOLUTE|AMODE_X16|AMODE_FETCH,

    0,
    AMODE_LOBYTE_Y|AMODE_FETCH,
    0,
    AMODE_ABSOLUTE|AMODE_FETCHINC|AMODE_FETCH
]

opcodes = "BRK,ORA,KIL,SLO,NOP,ORA,ASL,SLO,PHP,ORA,ASL,ANC,NOP,ORA,ASL,SLO,BPL,ORA,KIL,SLO,NOP,ORA,ASL,SLO,CLC,ORA,NOP,SLO,NOP,ORA,ASL,SLO,JSR,AND,KIL,RLA,BIT,AND,ROL,RLA,PLP,AND,ROL,ANC,BIT,AND,ROL,RLA,BMI,AND,KIL,RLA,NOP,AND,ROL,RLA,SEC,AND,NOP,RLA,NOP,AND,ROL,RLA,RTI,EOR,KIL,SRE,NOP,EOR,LSR,SRE,PHA,EOR,LSR,ALR,JMP,EOR,LSR,SRE,BVC,EOR,KIL,SRE,NOP,EOR,LSR,SRE,CLI,EOR,NOP,SRE,NOP,EOR,LSR,SRE,RTS,ADC,KIL,RRA,NOP,ADC,ROR,RRA,PLA,ADC,ROR,ARR,JMP,ADC,ROR,RRA,BVS,ADC,KIL,RRA,NOP,ADC,ROR,RRA,SEI,ADC,NOP,RRA,NOP,ADC,ROR,RRA,NOP,STA,NOP,SAX,STY,STA,STX,SAX,DEY,NOP,TXA,XAA,STY,STA,STX,SAX,BCC,STA,KIL,AHX,STY,STA,STX,SAX,TYA,STA,TXS,TAS,SHY,STA,SHX,AHX,LDY,LDA,LDX,LAX,LDY,LDA,LDX,LAX,TAY,LDA,TAX,LAX,LDY,LDA,LDX,LAX,BCS,LDA,KIL,LAX,LDY,LDA,LDX,LAX,CLV,LDA,TSX,LAS,LDY,LDA,LDX,LAX,CPY,CMP,NOP,DCP,CPY,CMP,DEC,DCP,INY,CMP,DEX,AXS,CPY,CMP,DEC,DCP,BNE,CMP,KIL,DCP,NOP,CMP,DEC,DCP,CLD,CMP,NOP,DCP,NOP,CMP,DEC,DCP,CPX,SBC,NOP,ISC,CPX,SBC,INC,ISC,INX,SBC,NOP,SBC,CPX,SBC,INC,ISC,BEQ,SBC,KIL,ISC,NOP,SBC,INC,ISC,SED,SBC,NOP,ISC,NOP,SBC,INC,ISC".split(',')
opamodes = [2,0,2,0,1,1,1,1,8,2,8,2,3,3,3,3,10,4,2,4,5,5,9,9,8,6,8,6,7,7,6,6,2,0,2,0,1,1,1,1,8,2,8,2,3,3,3,3,10,4,2,4,5,5,5,5,8,6,8,6,7,7,7,7]
ram = bytearray([0xFF]) * 2048
rom = bytearray()
loglines = None

def mem_read(addr):
    if addr < 0x2000:
        addr &= 0x7FF
        value = ram[addr]
        if loglines is not None:
            loglines.append("peek($%03x) = $%02x" % (addr, value))
        return value
    if addr >= 0x8000:
        addr = addr & 0x3FFF
        return rom[addr] if addr < len(rom) else 0xFF
    return 0xFF

def mem_write(addr, value):
    if addr < 0x2000:
        value &= 0xFF
        addr &= 0x7FF
        ram[addr] = value
        if loglines is not None:
            loglines.append("poke $%03x,$%02x" % (addr, value))

def mem_push(value, regs):
    mem_write(regs['s'] | 0x100, value)
    regs['s'] = (regs['s'] - 1) & 0xFF

def mem_pull(regs):
    regs['s'] = (regs['s'] + 1) & 0xFF
    value = mem_read(regs['s'] | 0x100)
    return value

# BPL/BMI, BVC/BVS, BCC/BCS, BNE/BEQ
branch_masks = [0x80, 0x40, 0x01, 0x02]
def run_branch(opcode, operand, regs):
    p = regs['p']
    if opcode & 0x20:
        p = ~p
    p &= branch_masks[opcode >> 6]
    if p:
        if loglines is not None:
            loglines.append("Untaken!")
        return 2
    if loglines is not None:
        loglines.append("Taken!")
    if operand & 0x80:
        operand -= 256
    pc = regs['pc']
    mem_read(pc)
    tmp = (pc & 0xFF) + operand
    cycles = 3
    if tmp < 0 or tmp >= 0x100:
        mem_read((pc & 0xFF00) | (tmp & 0xFF))
        cycles = 4
    regs['pc'] = (pc & 0xFF00) + tmp
    return cycles

def set_nz(operand, regs):
    nzflags = (operand & 0x80) if operand & 0xFF else 0x02
    regs['p'] = regs['p'] & 0x4D | nzflags

def run_LDY(operand, regs):
    regs['y'] = operand
    set_nz(operand, regs)
    return 0

def run_LDX(operand, regs):
    regs['x'] = operand
    set_nz(operand, regs)
    return 0

def run_LDA(operand, regs):
    regs['a'] = operand
    set_nz(operand, regs)
    return 0

def run_LAX(operand, regs):
    regs['x'] = operand
    return run_LDA(operand, regs)

def run_STY(operand, regs):
    mem_write(operand, regs['y'])
    return 1

def run_STX(operand, regs):
    mem_write(operand, regs['x'])
    return 1

def run_STA(operand, regs):
    mem_write(operand, regs['a'])
    return 1

def run_SAX(operand, regs):
    mem_write(operand, regs['a'] & regs['x'])
    return 1

def run_TXS(operand, regs):
    regs['s'] = regs['x']
    return 0

def run_SEP(operand, regs):
    regs['p'] |= operand
    return 0

def run_REP(operand, regs):
    regs['p'] &= ~operand
    return 0

def run_ADC(operand, regs):
    tmp = (regs['p'] & 1) + operand + regs['a']

    if (operand ^ regs['a']) & 0x80:
        vflag = 0  # Different input signs: no overflow
    else:
        vflag = ((tmp ^ regs['a']) & 0x80) >> 1
    regs['p'] = (regs['p'] & 0x0C) | (tmp >> 8) | vflag
    regs['a'] = tmp & 0xFF
    set_nz(regs['a'], regs)
    return 0

def run_SBC(operand, regs):
    return run_ADC(operand ^ 0xFF, regs)

def run_ROL(operand, regs):
    tmp = (regs['p'] & 1) + operand + regs['a']
    regs['p'] = (regs['p'] & 0x4C) | (tmp >> 8)
    regs['a'] = tmp & 0xFF
    set_nz(regs['a'], regs)
    return 0

def run_ASL(operand, regs):
    regs['p'] &= ~0x01
    return run_ROL(operand, regs)

def run_LSR(operand, regs):
    regs['p'] = (regs['p'] & 0x4C) | (operand & 1)
    regs['a'] = operand >> 1
    set_nz(regs['a'], regs)
    return 0

def run_BIT(operand, regs):
    nvzflag = operand & 0xC0
    if (operand & regs['a']) == 0:
        nvzflag |= 0x02
    regs['p'] = (regs['p'] & 0x0D) | nvzflag
    return 0

def run_CPR(regvalue, operand, regs):
    tmp = regvalue + 0x100 - operand
    regs['p'] = (regs['p'] & 0x4C) | (tmp >> 8)
    set_nz(tmp, regs)
    return 0

def run_CMP(operand, regs):
    return run_CPR(regs['a'], operand, regs)
    
def run_PHA(operand, regs):
    mem_push(operand, regs)
    return 1

def run_PLA(operand, regs):
    regs['a'] = mem_pull(regs)
    set_nz(regs['a'], regs)
    return 2

def run_PLP(operand, regs):
    regs['p'] = mem_pull(regs) & 0xCF
    return 2

def run_ADQ(reg, operand, regs):
    regs[reg] = (regs[reg] + operand) & 0xFF
    set_nz(regs[reg], regs)
    return 0

def run_ORA(operand, regs):
    return run_LDA(regs['a'] | operand, regs)

def run_AND(operand, regs):
    return run_LDA(regs['a'] & operand, regs)

def run_EOR(operand, regs):
    return run_LDA(regs['a'] ^ operand, regs)

instable = {
    'ADC': run_ADC,
    'AND': run_AND,
    'ASL': run_ASL,
    'BIT': run_BIT,
    'CLC': lambda o, r: run_REP(0x01, r),
    'CLD': lambda o, r: run_REP(0x08, r),
    'CLI': lambda o, r: run_REP(0x04, r),
    'CLV': lambda o, r: run_REP(0x40, r),
    'CMP': run_CMP,
    'CPX': lambda o, r: run_CPR(r['x'], o, r),
    'CPY': lambda o, r: run_CPR(r['y'], o, r),
    'EOR': run_EOR,
    'LAX': run_LAX,
    'LDA': run_LDA,
    'LDX': run_LDX,
    'LDY': run_LDY,
    'LSR': run_LSR,
    'NOP': lambda o, r: 0,
    'ORA': run_ORA,
    'PHA': run_PHA,
    'PHP': lambda o, r: run_PHA(r['p'] | 0x30, r),
    'PLA': lambda o, r: run_PLA(o, r),
    'PLP': lambda o, r: run_PLP(o, r),
    'ROL': run_ROL,
    'ROR': lambda o, r: run_LSR(o | ((r['p'] & 0x1) << 8), r),
    'SBC': run_SBC,
    'SEC': lambda o, r: run_SEP(0x01, r),
    'SED': lambda o, r: run_SEP(0x08, r),
    'SEI': lambda o, r: run_SEP(0x04, r),
    'SAX': run_SAX,
    'STA': run_STA,
    'STX': run_STX,
    'STY': run_STY,
    'INX': lambda o, r: run_ADQ('x', 1, r),
    'INY': lambda o, r: run_ADQ('y', 1, r),
    'DEX': lambda o, r: run_ADQ('x', 255, r),
    'DEY': lambda o, r: run_ADQ('y', 255, r),
    'TAX': lambda o, r: run_LDX(r['a'], r),
    'TXA': lambda o, r: run_LDA(r['x'], r),
    'TAY': lambda o, r: run_LDY(r['a'], r),
    'TYA': lambda o, r: run_LDA(r['y'], r),
    'TSX': lambda o, r: run_LDX(r['s'], r),
    'TXS': run_TXS,
}

# RMW instructions return the output of the modify stage instead of
# the number of extra cycles they took.

def mod_ROL(operand, regs):
    tmp = (regs['p'] & 1) + (operand << 1)
    regs['p'] = (regs['p'] & 0x4C) | (tmp >> 8)
    return tmp & 0xFF

def mod_ASL(operand, regs):
    regs['p'] &= ~0x01
    return mod_ROL(operand, regs)

def mod_LSR(operand, regs):
    regs['p'] = (regs['p'] & 0x4C) | (operand & 1)
    return operand >> 1

def mod_ROR(operand, regs):
    operand |= (regs['p'] & 0x01) << 8
    regs['p'] = (regs['p'] & 0x4C) | (operand & 1)
    return operand >> 1

# modify and post-modify steps for read-modify-write instruction
modtable = {
    'ASL': (mod_ASL, None),
    'LSR': (mod_LSR, None),
    'ROL': (mod_ROL, None),
    'ROR': (mod_ROR, None),
    'DEC': (lambda o, r: (o + 255) & 0xFF, None),
    'INC': (lambda o, r: (o + 1) & 0xFF, None),
    'DCP': (lambda o, r: (o + 255) & 0xFF, run_CMP),
    'ISC': (lambda o, r: (o + 1) & 0xFF, run_SBC),
    'SLO': (mod_ASL, run_ORA),
    'SRE': (mod_LSR, run_EOR),
    'RLA': (mod_ROL, run_AND),
    'RRA': (mod_ROR, run_ADC),
}

def disasm_operand(mn, amode, operandaddr, regs):
    if amode == 8 or mn in ('RTI', 'BRK'):
        operandlen = 0
    elif amode_microops[amode] & AMODE_ABSOLUTE or mn in ('JMP', 'JSR'):
        operandlen = 2
    else:
        operandlen = 1

def run_instruction(regs):
    pc = regs['pc']
    opcode = mem_read(pc)
    pc = (pc + 1) & 0xFFFF
    operand = mem_read(pc)
    cycles = 2
    amodeidx = (opcode ^ 0x80) & 0xDF
    if amodeidx >= 0x40:
        amodeidx = (amodeidx & 0x1F) | 0x20
    amode = opamodes[amodeidx]
    is_rmw = (amodeidx >= 0x20 and amode != 2
              and (opcode & 0x02) and (opcode & 0x05))
    if amode == 8:
        operand = regs['a']
    else:
        pc = (pc + 1) & 0xFFFF

    if loglines is not None:
        loglines.append(("%04x %02x %02x %s m%2d"
                      % (regs['pc'], opcode, operand,
                         opcodes[opcode], amode)))
    if amode == 10:
        regs['pc'] = pc
        return run_branch(opcode, operand, regs)

    if opcode == 0x4C:  # JMP aaaa
        regs['pc'] = (mem_read(pc) << 8) | operand
        return 3
    if opcode == 0x6C:  # JMP (aaaa)
        operand |= (mem_read(pc) << 8)
        pc = mem_read(operand)
        operand = (operand & 0xFF00) | ((operand + 1) & 0xFF)
        regs['pc'] = pc | mem_read(operand) << 8
        return 5
    if opcode == 0x20:  # JSR aaaa
        operand |= (mem_read(pc) << 8)
        regs['pc'] = operand
        mem_push(pc >> 8, regs)
        mem_push(pc, regs)
        mem_read(operand)
        return 6
    if opcode == 0x40:  # RTI
        mem_read(pc)
        regs['p'] = mem_pull(regs) & 0xCF
        operand = mem_pull(regs)
        operand |= mem_pull(regs) << 8
        regs['pc'] = operand
        mem_read(operand)
        return 6
    if opcode == 0x60:  # RTS
        mem_read(pc)
        operand = mem_pull(regs)
        operand |= mem_pull(regs) << 8
        regs['pc'] = (operand + 1) & 0xFFFF
        mem_read(operand)
        return 6

    pageuncrossed = False
    is_write_inst = (opcode & 0xE0) == 0x80

    # Handle normal opcodes
    microops = amode_microops[amode]
    if microops & AMODE_LOBYTE_X:
        operand = (operand + regs['x']) & 0xFF
        cycles += 1
    if microops & AMODE_LOBYTE_Y:
        operand = (operand + regs['y']) & 0xFF
        cycles += 1
    if microops & AMODE_INDIRECT:
        lo = mem_read(operand)
        operand = (mem_read((operand + 1) & 0xFF) << 8) | lo
        cycles += 2
    if microops & AMODE_ABSOLUTE:
        operand |= (mem_read(pc) << 8)
        pc = (pc + 1) & 0xFFFF
        cycles += 1
    if microops & AMODE_X16:
        tmp = (operand & 0xFF) + regs['x']
        readdata = mem_read((operand & 0xFF00) | (tmp & 0xFF))
        operand = ((operand & 0xFF00) + tmp) & 0xFFFF
        cycles += 1
        if tmp < 0x100 and not is_write_inst and not is_rmw:
            pageuncrossed = True
            operand = readdata
    if microops & AMODE_Y16:
        tmp = (operand & 0xFF) + regs['y']
        readdata = mem_read((operand & 0xFF00) | (tmp & 0xFF))
        operand = ((operand & 0xFF00) + tmp) & 0xFFFF
        cycles += 1
        if tmp < 0x100 and not is_write_inst and not is_rmw:
            pageuncrossed = True
            operand = readdata
    if is_rmw:
        tmp = mem_read(operand)
        mem_write(operand, tmp)
        if opcodes[opcode] not in modtable:
            print("%s ($%02x) not in %s"
                  % (opcodes[opcode], opcode, sorted(modtable)))
        (func1, func2) = modtable[opcodes[opcode]]
        tmp = func1(tmp, regs)
        set_nz(tmp, regs)
        mem_write(operand, tmp)
        func2 and func2(tmp, regs)
        cycles += 3
    else:
        if (microops & AMODE_FETCH) and not pageuncrossed and not is_write_inst:
            operand = mem_read(operand)
            cycles += 1
        cycles += instable[opcodes[opcode]](operand, regs)
    regs['pc'] = pc
    if loglines is not None:
        loglines.append("ea=%04x A=%02x X=%02x Y=%02x P=%02x S=%02x C=%d"
                        % (operand, regs['a'], regs['x'], regs['y'], regs['p'], regs['s'], cycles))
    return cycles

def find(s):
    print("\n----\n".join("\n".join(loglines[i-10:i + 1]))
                          for i, line in enumerate(loglines)
                          if s in line)

def run_nestest():
    global loglines

    print("loading nestest")
    with open("../nested/nestest.nes", "rb") as infp:
        infp.read(16)
        rom.extend(infp.read(16384))
    with open("../nested/nestest.log", "rU") as infp:
        pc_log = [(int(row[0:4], 16), len(row[6:14].split()),
                   int(row[50:52], 16), int(row[55:57], 16), int(row[60:62], 16),
                   int(row[65:67], 16) & 0xCF, int(row[71:73], 16),
                   int(row[78:81].lstrip()))
                  for row in infp]
    loglines = None
    print("running %d instructions" % len(pc_log))
    regs = {'a': 0, 'x': 0, 'y': 0, 'p': 0x04, 's': 0xFD, 'pc': 0xC000}
    cycles = 0
    for (i, (expected_pc, ilen,
             a, x, y, p, s, expected_cyc)) in enumerate(pc_log):
        if expected_pc != regs['pc']:
            print("PC fail! %04x != expected %04x" % (regs['pc'], expected_pc))
            break
        if (a != regs['a'] or x != regs['x'] or y != regs['y']
            or p != regs['p'] or s != regs['s']):
            print("AXYPS fail before %04x! %02x%02x%02x %02x%02x != expected %02x%02x%02x %02x%02x"
                  % (expected_pc,
                     regs['a'], regs['x'], regs['y'], regs['p'], regs['s'],
                     a, x, y, p, s))
            break
        if cycles != expected_cyc:
            print("Cycle count fail before %04x!! %d != expected %d"
                  % (expected_pc, cycles, expected_cyc))
            break
        try:
            cycles += 3 * run_instruction(regs)
        except (KeyError, NameError) as e:
            from traceback import print_exc
            print_exc()
            break
        cycles = cycles % 341
    i += 1
    if i < len(pc_log):
        print('\n'.join(loglines[-50:]))
        permil = (1000 * i) // len(pc_log)
        print("Got to %d.%d%%" % (permil // 10, permil % 10))
    else:
        print("Behaviors match, and cycles match.")

if __name__=='__main__':
    run_nestest()
