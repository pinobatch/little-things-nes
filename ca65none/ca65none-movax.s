;
; Reimplementation of 6502 ISA in ca65 macros
; Copyright 2013 Damian Yerrick
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

; Assembles with ca65 2.14.0:
; ca65 ca65none.s -l ca65none.txt && exo-open ca65none.txt

.feature ubiquitous_idents

; Control opcode block ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.macro brk arg
  .byte $00, arg
.endmacro

.macro jsr arg
  .byte $20
  .word arg
.endmacro

.macro rti
  .byte $40
.endmacro

.macro rts
  .byte $60
.endmacro

.macro php
  .byte $08
.endmacro

.macro clc
  .byte $18
.endmacro

.macro plp
  .byte $28
.endmacro

.macro sec
  .byte $38
.endmacro

.macro pha
  .byte $48
.endmacro

.macro cli
  .byte $58
.endmacro

.macro pla
  .byte $68
.endmacro

.macro sei
  .byte $78
.endmacro

.macro dey
  .byte $88
.endmacro

.macro tya
  .byte $98
.endmacro

.macro tay
  .byte $A8
.endmacro

.macro clv
  .byte $B8
.endmacro

.macro iny
  .byte $C8
.endmacro

.macro cld
  .byte $D8
.endmacro

.macro inx
  .byte $E8
.endmacro

.macro sed
  .byte $F8
.endmacro

.macro bit arg
  NONE02_rmwamodes $24, {arg}, {arg2}
.endmacro

.macro NONE02_branch inst, target
  .local @distance
  @distance = (target) - (* + 2)
  .assert @distance >= -128 && @distance <= 127, error, "branch out of range"
  .byte inst, <@distance
.endmacro

.macro bpl target
  NONE02_branch $10, {target}
.endmacro

.macro bmi target
  NONE02_branch $30, {target}
.endmacro

.macro bvc target
  NONE02_branch $50, {target}
.endmacro

.macro bvs target
  NONE02_branch $70, {target}
.endmacro

.macro bcc target
  NONE02_branch $90, {target}
.endmacro

.macro bcs target
  NONE02_branch $b0, {target}
.endmacro

.macro bne target
  NONE02_branch $d0, {target}
.endmacro

.macro beq target
  NONE02_branch $f0, {target}
.endmacro

.macro jmp arg
  .local @argvalue, @lpar, @rpar
  @argvalue = arg
  @lpar = .match (.left (1, {arg}), {(})
  @rpar = .match (.right (1, {arg}), {)})
  .if @rpar && @lpar
    .assert .lobyte(@argvalue) <> $FF, warning, "Indirect JMP() across page border"
    .byte $6C
    .word @argvalue
  .else
    .byte $4C
    .word @argvalue
  .endif
.endmacro

.macro sty arg, arg2
  .assert .paramcount < 2 || .xmatch ({arg2}, x), error, "bad STY addressing mode"
  .local @argvalue
  @argvalue = arg
  .if .paramcount < 2
    NONE02_rmwamodes $84, @argvalue
  .else
    .byte $94, @argvalue
  .endif
.endmacro

.macro ldy arg, arg2
  .assert .paramcount < 2 || .xmatch ({arg2}, x), error, "bad LDY addressing mode"
  .local @argvalue
  .if (.match (.left (1, {arg}), #)) && .paramcount < 2
    @argvalue = .right(.tcount({arg})-1, {arg})
    .byte $A0, @argvalue
  .else
    @argvalue = arg
    .if .paramcount < 2
      NONE02_rmwamodes $A4, @argvalue
    .else
      NONE02_rmwamodes $B4, @argvalue
    .endif
  .endif
.endmacro

.macro NONE02_cpycpx inst, arg
  .local @argvalue
  .if (.match (.left (1, {arg}), #))
    @argvalue = .right(.tcount({arg})-1, {arg})
    .byte inst, @argvalue
  .else
    @argvalue = arg
    NONE02_rmwamodes inst, @argvalue
  .endif
.endmacro

.macro cpy arg
  NONE02_cpycpx $C0, {arg}
.endmacro

.macro cpx arg
  NONE02_cpycpx $E0, {arg}
.endmacro

; ALU opcode block ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.macro NONE02_mainidxmodes inst, arg, arg2
  .local @argvalue, @lpar, @rpar, @rx, @ry, @rparindx
  @lpar = .match (.left (1, {arg}), {(})
  @rpar = .match (.right (1, {arg}), {)})
  @rx = .xmatch ({arg2}, x)
  @ry = .xmatch ({arg2}, y)
  @rparindx = .xmatch ({arg2}, {x)})
;  .out .sprintf("%d%d%d%d%d", @lpar, @rpar, @rx, @ry, @rparindx)
  .if @rparindx && @lpar=1
    @argvalue = .right (.tcount ({arg})-1, {arg})
;    .out .sprintf("(d,x) d=$%x", @argvalue)
    .byte $00 | (inst), @argvalue
  .elseif @rx
    @argvalue = arg
    .if .addrsize(@argvalue) = 1
;      .out .sprintf("d,x d=$%x", @argvalue)
      .byte $14 | (inst), @argvalue
    .else
;      .out .sprintf("a,x a=$%x", @argvalue)
      .byte $1C | (inst)
      .word @argvalue
    .endif
  .elseif @ry && @rpar && @lpar
    @argvalue = arg
;    .out .sprintf("(d),y d=$%x", @argvalue)
    .byte $10 | (inst), @argvalue
  .elseif @ry
    @argvalue = arg
;    .out .sprintf("a,y a=$%x", @argvalue)
    .byte $18 | (inst)
    .word @argvalue
  .else
    .error "2 arg other"
  .endif
.endmacro

.macro NONE02_mainamodes inst, arg
  .local @argvalue
  .if (.match (.left (1, {arg}), #))
    @argvalue = .right(.tcount({arg})-1, {arg})
;    .out .sprintf("Imm #$%x", @argvalue)
    .byte $09 | (inst), @argvalue
  .else
    @argvalue = arg
    .if .addrsize(@argvalue) = 1
;      .out .sprintf("ZP %x", @argvalue)
      .byte $04 | (inst), @argvalue
    .else
;      .out .sprintf("Abs %x", @argvalue)
      .byte $0C | (inst)
      .word @argvalue
    .endif
  .endif
.endmacro

.macro ora arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $01, {arg}, {arg2}
  .else
    NONE02_mainamodes $01, {arg}
  .endif
.endmacro

.macro and arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $21, {arg}, {arg2}
  .else
    NONE02_mainamodes $21, {arg}
  .endif
.endmacro

.macro eor arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $41, {arg}, {arg2}
  .else
    NONE02_mainamodes $41, {arg}
  .endif
.endmacro

.macro adc arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $61, {arg}, {arg2}
  .else
    NONE02_mainamodes $61, {arg}
  .endif
.endmacro

.macro sta arg, arg2
  .if (.match (.left (1, {arg}), #))
    .error "can't store to immediate; this isn't Puzznic"
  .elseif .paramcount > 1
    NONE02_mainidxmodes $81, {arg}, {arg2}
  .else
    NONE02_mainamodes $81, {arg}
  .endif
.endmacro

.macro lda arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $A1, {arg}, {arg2}
  .else
    NONE02_mainamodes $A1, {arg}
  .endif
.endmacro

.macro cmp arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $C1, {arg}, {arg2}
  .else
    NONE02_mainamodes $C1, {arg}
  .endif
.endmacro

.macro sbc arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $E1, {arg}, {arg2}
  .else
    NONE02_mainamodes $E1, {arg}
  .endif
.endmacro

; RMW opcode block ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.macro nop
  .byte $EA  ; If it's in the game, it's in the game.
.endmacro

.macro txa
  .byte $8A
.endmacro

.macro txs
  .byte $9A
.endmacro

.macro tax
  .byte $AA
.endmacro

.macro tsx
  .byte $BA
.endmacro

.macro dex
  .byte $CA
.endmacro

.macro NONE02_rmwamodes inst, arg, arg2
  .local @argvalue
  @argvalue = arg
  .if .addrsize(@argvalue) = 1
;    .out .sprintf("d d=$%x", @argvalue)
    .byte $04 | (inst), @argvalue
  .else
;    .out .sprintf("a a=$%x", @argvalue)
    .byte $0C | (inst)
    .word @argvalue
  .endif
.endmacro

.macro NONE02_rmwidxmodes inst, arg, arg2
  .local @argvalue
  .if .xmatch ({arg2}, x)=0
    .error "RMW opcodes index only on x"
  .endif
  NONE02_rmwamodes (inst)|$10, arg
.endmacro

.macro asl arg, arg2
  .if .paramcount < 1 || (.paramcount = 1 && .xmatch ({arg}, a))
    .byte $0A
  .elseif .paramcount < 2
     NONE02_rmwamodes $06, arg
  .else
     NONE02_rmwidxmodes $06, arg, arg2
  .endif
.endmacro

.macro rol arg, arg2
  .if .paramcount < 1 || (.paramcount = 1 && .xmatch ({arg}, a))
    .byte $2A
  .elseif .paramcount < 2
     NONE02_rmwamodes $26, arg
  .else
     NONE02_rmwidxmodes $26, arg, arg2
  .endif
.endmacro

.macro lsr arg, arg2
  .if .paramcount < 1 || (.paramcount = 1 && .xmatch ({arg}, a))
    .byte $4A
  .elseif .paramcount < 2
     NONE02_rmwamodes $46, arg
  .else
     NONE02_rmwidxmodes $46, arg, arg2
  .endif
.endmacro

.macro ror arg, arg2
  .if .paramcount < 1 || (.paramcount = 1 && .xmatch ({arg}, a))
    .byte $6A
  .elseif .paramcount < 2
     NONE02_rmwamodes $66, arg
  .else
     NONE02_rmwidxmodes $66, arg, arg2
  .endif
.endmacro

.macro dec arg, arg2
  .if .paramcount < 2
     NONE02_rmwamodes $C6, arg
  .else
     NONE02_rmwidxmodes $C6, arg, arg2
  .endif
.endmacro

.macro inc arg, arg2
  .if .paramcount < 2
     NONE02_rmwamodes $E6, {arg}
  .else
     NONE02_rmwidxmodes $E6, {arg}, {arg2}
  .endif
.endmacro

; STX and LDX are also in this block
.macro stx arg, arg2
  .assert .paramcount < 2 || .xmatch ({arg2}, y), error, "bad STX addressing mode"
  .local @argvalue
  @argvalue = arg
  .if .paramcount < 2
    NONE02_rmwamodes $86, @argvalue
  .else
    .byte $96, @argvalue
  .endif
.endmacro

.macro ldx arg, arg2
  .assert .paramcount < 2 || .xmatch ({arg2}, y), error, "bad LDX addressing mode"
  .local @argvalue
  .if (.match (.left (1, {arg}), #)) && .paramcount < 2
    @argvalue = .right(.tcount({arg})-1, {arg})
    .byte $A2, @argvalue
  .else
    @argvalue = arg
    .if .paramcount < 2
      NONE02_rmwamodes $A6, @argvalue
    .else
      NONE02_rmwamodes $B6, @argvalue
    .endif
  .endif
.endmacro


; RMW+ALU combined opcode block ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.macro slo arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $03, {arg}, {arg2}
  .else
    NONE02_rmwamodes $03, {arg}
  .endif
.endmacro

.macro rla arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $23, {arg}, {arg2}
  .else
    NONE02_rmwamodes $23, {arg}
  .endif
.endmacro

.macro sre arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $43, {arg}, {arg2}
  .else
    NONE02_rmwamodes $43, {arg}
  .endif
.endmacro

.macro rra arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $63, {arg}, {arg2}
  .else
    NONE02_rmwamodes $63, {arg}
  .endif
.endmacro

.macro dcp arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $c3, {arg}, {arg2}
  .else
    NONE02_rmwamodes $c3, {arg}
  .endif
.endmacro

.macro isc arg, arg2
  .if .paramcount > 1
    NONE02_mainidxmodes $e3, {arg}, {arg2}
  .else
    NONE02_rmwamodes $e3, {arg}
  .endif
.endmacro

.macro NONE02_imm inst, arg
  .local @argvalue
  .if (.match (.left (1, {arg}), #))
    @argvalue = .right(.tcount({arg})-1, {arg})
    .byte inst, @argvalue
  .else
    .error "instruction supports only immediate mode"
  .endif
.endmacro

.macro anc arg
  NONE02_imm $0B, {arg}
.endmacro

.macro alr arg
  NONE02_imm $4B, {arg}
.endmacro

.macro arr arg
  NONE02_imm $6B, {arg}
.endmacro

.macro axs arg
  NONE02_imm $CB, {arg}
.endmacro

.macro sax arg, arg2
  .local @argvalue
  .if .paramcount < 2
    @argvalue = arg
    NONE02_rmwamodes $87, @argvalue
  .elseif .xmatch ({arg2}, y)
    @argvalue = arg
    .byte $97, @argvalue
  .elseif .match (.left (1, {arg}), {(}) && .xmatch ({arg2}, {x)})
    @argvalue = .right (.tcount ({arg})-1, {arg})
    .byte $83, @argvalue
  .else
    .assert 0, error, "bad SAX addressing mode"
  .endif
.endmacro

.macro lax arg, arg2
  .local @argvalue, @lpar, @rpar, @ry, @rparindx
  .if .paramcount < 2
    @argvalue = arg
    ; Disallow immediate because it's unstable.  Reports are that
    ; it acts more like "ORA #linenoise AND #value TAX" rather than
    ; the "LDA value TAX" of the other modes.
    NONE02_rmwamodes $A7, @argvalue
    .exitmacro
  .endif
  @lpar = .match (.left (1, {arg}), {(})
  @rpar = .match (.right (1, {arg}), {)})
  @ry = .xmatch ({arg2}, y)
  @rparindx = .xmatch ({arg2}, {x)})
  .if @rparindx && @lpar=1
    @argvalue = .right (.tcount ({arg})-1, {arg})
    .byte $A3, @argvalue
  .elseif @ry && @rpar && @lpar
    @argvalue = arg
    .byte $B3, @argvalue
  .elseif @ry
    @argvalue = arg
    .if .addrsize(@argvalue) = 1
      .byte $B7, @argvalue
    .else
      .byte $BF
      .word @argvalue
    .endif
  .else
    .assert 0, error, "bad LAX addressing mode"
  .endif
.endmacro
