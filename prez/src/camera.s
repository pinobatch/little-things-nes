.include "global.inc"
.export limitScrollingTo16, updateColDecodeX

; set this to nonzero if we want to test worst case behavior by
; decoding a column on EVERY frame even if there is no scroll
ALWAYS_DECODE = 0

.segment "ZEROPAGE"
slidingWindowFaceDir: .res 1

.segment "CODE"
.proc updateColDecodeX
  lda camX
  lsr a
  lsr a
  lsr a
  lsr a
  sec
  sbc slidingWindowBaseX
  bcs :+
    adc #16
    clc
  :
  sta 0
  lda camPage
  sbc slidingWindowBasePage
  sta 1
  bcs notToLeft
  dec slidingWindowBaseX
  bpl :+
    dec slidingWindowBasePage
    lda #15
    sta slidingWindowBaseX
  :
  lda slidingWindowBaseX
  sta colDecodeX
  lda slidingWindowBasePage
decodePageFinish:
  sta colDecodePage
  rts

notToLeft:
  lda 1
  bne toRight
  lda 0
  cmp #15
  bcs toRight
notRightOrLeft:
  .if !::ALWAYS_DECODE
    lda #$FF
    sta colDecodePage
  .endif
  rts

toRight:
  inc slidingWindowBaseX
  lda slidingWindowBaseX
  cmp #16
  bcc :+
    inc slidingWindowBasePage
    lda #0
    sta slidingWindowBaseX
  :
  lda slidingWindowBaseX
  clc
  adc #14
  cmp #16
  bcc :+
    sbc #16
  :
  sta colDecodeX
  lda slidingWindowBasePage
  adc #1
  jmp decodePageFinish
  
.endproc

.proc limitScrollingTo16
  lda camPage
  bpl notNegative
    lda #0
    sta camX
    sta camPage
  notNegative:
  cmp #31
  bcc notRightWall
    lda #0
    sta camX
    lda #31
    sta camPage
  notRightWall:

  sec
  lda camX
  sbc lastCamX
  sta 0
  lda camPage
  sbc lastCamPage
  sta 1
  bpl updateToRight

  ; clip movement to left
  lda #$F0
  cmp 0
  lda #$FF
  sbc 1
  bcc doneClippingVel
    lda #$FF
    sta 1
    lda #$F0
    sta 0
    bne doneClippingVel

updateToRight:
  lda 0
  cmp #$10
  lda 1
  sbc #$00
  bcc doneClippingVel
    lda #$00
    sta 1
    lda #$10
    sta 0

doneClippingVel:
  clc
  lda lastCamX
  adc 0
  sta camX
  sta lastCamX
  lda lastCamPage
  adc 1
  sta camPage
  sta lastCamPage
  rts
.endproc


.proc moveCameraTowardActor0
  focusX = 0
  focusPage = 1
  tmpX = 2
  tmpPage = 3
  slidingXPixels = 4

  ; First, put sliding window X in pixels, and then find the
  ; displacement between the sliding window and the actor.
  lda slidingWindowBaseX
  asl a
  asl a
  asl a
  asl a
  sta slidingXPixels
  sec
  lda actorXHi+0
  sbc slidingXPixels
  sta focusX
  lda actorPage+0
  sbc slidingWindowBasePage
  sta focusPage

  ; If the player hasn't turned since the last sliding window move,
  ; keep going as if moving the sliding window.  
  lda actorFaceDir
  and #$40
  cmp slidingWindowFaceDir
  beq moveTheWindow
  
  ; If the difference is not in range $0078-$0177, the actor wants to
  ; move the sliding window.
  sec
  lda focusX
  sbc #$78
  sta tmpX
  lda focusPage
  sbc #$00
  bne @checkWindowVsLevelWalls
  lda tmpX
  cmp #$F0
  bcc moveInsideWindow

@checkWindowVsLevelWalls:
  ; However, if the sliding window and the actor are both at the left
  ; or right side of the map, the actor does not want to move the
  ; sliding window.
  lda slidingWindowBasePage
  cmp #32-2
  bcc @notAtRightWall
  lda actorPage
  cmp #32-1
  bcc moveTheWindow
  ; FIXME: case with the actor at the right side still needs testing
  jmp moveInsideWindow
@notAtRightWall:
  ; If the window is at the left side, and the actor is on the first
  ; page, don't move the window either.
  ora slidingXPixels
  ora actorPage
  beq moveInsideWindow

moveTheWindow:
  ; When the sliding window moves, the camera should point 120 pixels
  ; to the left of the ACTOR.
  sec
  lda actorXHi
  sbc #$78
  sta focusX
  lda actorPage
  sbc #$0
  sta focusPage
  
  ; And put the camera into sliding-window mode.
  lda #$40
  and actorFaceDir
  sta slidingWindowFaceDir
  sta debugHex1
  jmp moveCamTowardFocus
  
moveInsideWindow:
  ; Map focusX from [120-378] into [90-282]
.if 0
  lda focusPage
  lsr a
  sta tmpPage
  lda focusX
  ror a
  sta tmpX
  adc focusX
  sta focusX
  lda tmpPage
  adc focusPage
  lsr a
  sta focusPage
  ror focusX
.endif
  ; if facing left, add $FFC8; otherwise, add $FF48`
  lda #$C8
  bit actorFaceDir
  bvc :+
    lda #$48
  :
  clc
  adc focusX
  sta focusX
  lda #$FF
  sta slidingWindowFaceDir  ; force free-movement mode
  sta debugHex1
  adc focusPage
  sta focusPage
  
  ; if the left edge ends up left of the window, set focus = the start
  ; of the window
  bpl @notNeg
  lda slidingXPixels
  sta focusX
  lda slidingWindowBasePage
  sta focusPage
  jmp moveCamTowardFocus
@notNeg:

  lda focusPage
  ; if the left edge ends up more than 240 pixels to the right of the
  ; window, don't move itset focus = the end of the window
  bne @isPos
  lda focusX
  cmp #$F0
  bcc @notPos
@isPos:
  clc
  lda slidingXPixels
  adc #$EF
  sta focusX
  lda slidingWindowBasePage
  adc #0
  sta focusPage
  jmp moveCamTowardFocus
@notPos:

  ; so it's within the window.
  clc
  lda slidingXPixels
  adc focusX
  sta focusX
  lda slidingWindowBasePage
  adc focusPage
  sta focusPage

moveCamTowardFocus:

  ; First clip the desired camera position to within [$0000, $2000]
  lda focusPage
  bpl @notNeg
  lda #0
  sta focusPage
  sta focusX
  beq @toward2
@notNeg:

  cmp #32
  bcc @toward2
  lda #32
  sta focusPage
  lda #0
  sta focusX

@toward2:

  sec
  lda focusX
  sbc camX
  sta focusX
  lda focusPage
  sbc camPage
  sta focusPage

  ; divide by 4, rounding away from zero
  lda focusX
  bit focusPage
  bmi :+
    clc
    adc #3
    bcc :+
      inc focusPage
  :
  lsr focusPage
  ror a
  lsr focusPage
  ror a
  clc
  adc camX
  php
  sta camX
  
  lda focusPage
  eor #$20
  clc
  adc #$E0
  sta focusPage

  ; debug!
  lda focusPage
  plp
  adc camPage
  sta camPage

  rts
.endproc
