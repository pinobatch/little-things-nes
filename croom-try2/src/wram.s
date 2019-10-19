; This defines all global variables for Concentration Room try 2.
; Nothing else should define BSS
; In the absence of useful stack addressing modes, keeping
; declarations of global variables in thsi file allows the sharing of
; physical variables between different contexts.

.include "global.inc"
.segment "ZEROPAGE"

; NES video
retraces: .res 1  ; incremented by nmi handler; used to detect vblank
lastPPUCTRL: .res 1
oamAddress: .res 1  ; number of first free OAM entry (4, 8, 12, ...)
dirtyRow: .res 1  ; Y position of top dirty row

; NES transfers to VRAM
srb4LoadState: .res 1  ; state of multi-frame transfers to VRAM
xferBufferDstHi: .res 1
xferBufferDstLo: .res 1
xferBufferLen: .res 1

; NES gamepad
keys: .res 1
newKeys: .res 1
dasKeys: .res 1
dasTimer: .res 1

; Editor variables
cursorX: .res 1
cursorY: .res 1
cursorTool: .res 1
cursorColor: .res 1

; On-screen keyboard variables
keyboardCurLen: .res 1
keyboardMaxLen: .res 1
keyboardName: .res 2
keyboardShifted: .res 1


; Semi-shared variables

; Actual-size tile data for current row of emblem
; while it is in the editor
actualSizeData: .res 4

curPage: .res 1
curBank: .res 1
curEmblemX: .res 1
fromPage: .res 1  ; were these for the copy functionality?
fromBank: .res 1
fromX: .res 1
isSaveDialog: .res 1


.segment "BSS"

; Copy of emblem that is loaded into the editor, in
; packed pixel format
emblemPixels: .res 256

; Metadata and pixels for the emblem that is loaded into the editor
emblemMeta: .res 32
emblemData: .res 64

; Metadata and pixels for the emblem that has been copied
clipboardMeta: .res 32
clipboardData: .res 64

