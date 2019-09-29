PPUCTRL = $2000
PPUADDR = $2006
PPUDATA = $2007
VBLANK_NMI = $80
VRAM_DOWN = $04

; Uncomment this to make popslide return normally instead of jumping
; to popslide_return.  Comment it out to use a custom return point
; in order to save cycles in an NMI handler.
popslide_return = popslide_rts

; cc65 interface ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.export _popslide_buf, _popslide_used, _popslide_clearbuf
.export _popslide_init, _popslide_terminate_blit, _popslide_blit

_popslide_buf = popslide_buf

;;
; extern unsigned char popslide_used;
; Index into popslide_buf
_popslide_used = popslide_used

;;
; void popslide_init();
; Prepares computed jump vectors and clears update buffer.
_popslide_init = popslide_init

;;
; void popslide_clearbuf();
; Clears update buffer.
_popslide_clearbuf = popslide_clearbuf

;;
; void popslide_terminate_blit();
; Assuming &(popslide_buf[popslide_used]) points at end of buffer,
; terminates, blits, and jumps to popslide_return.
_popslide_terminate_blit = popslide_terminate_blit

_popslide_blit = popslide_blit
