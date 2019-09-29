;
; Pently audio engine
; NSF player shell
;
; Copyright 2012-2017 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;

.import __ROM7_START__
NUM_SONGS = 3

.include "global.inc"

.segment "NSFHDR"
  .byt "NESM", $1A, $01  ; signature
  .byt NUM_SONGS
  .byt 1  ; first song to play
  .addr __ROM7_START__  ; load address (should match link script)
  .addr pick_a_player
  .addr run_player_once
names_start:
  .byt "DAC nonlinearity test"
  .res names_start+32-*, $00
  .byt "Damian Yerrick"
  .res names_start+64-*, $00
  .byt "2017 Damian Yerrick"
  .res names_start+96-*, $00
  .word 16640  ; NTSC frame length (canonically 16666)
  .byt $00,$00,$00,$00,$00,$00,$00,$00  ; bankswitching disabled
  .word 19998  ; PAL frame length  (canonically 20000)
  .byt $02  ; NTSC/PAL dual compatible; NTSC preferred
  .byt $00  ; Famicom mapper sound not used

.zeropage
playeraddress: .res 2

.code
.proc pick_a_player
  asl a
  tax
  lda players+1,x
  sta playeraddress+1
  lda players+0,x
  sta playeraddress+0
  jmp set_tri_ultrasonic
.endproc

.proc run_player_once
  jsr jmp_playeraddress

  ; And don't run it again
  lda #<knownrts
  sta playeraddress
  lda #>knownrts
  sta playeraddress+1

jmp_playeraddress:
  jmp (playeraddress)
knownrts:
  rts
.endproc

.rodata
players:
  .addr dacpulseramp, triramp, noiseramp