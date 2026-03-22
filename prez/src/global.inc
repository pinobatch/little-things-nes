; constants determing data structure sizes
COL_HEIGHT = 12
MAX_ACTORS = 24

; 0000-000F: registers
; 0010-00FF: zero page, allocated with .res

; 0100-019F: VRAM copy buffers
copyBuf0        = $0100
copyBuf1        = $0120
copyBuf2        = $0140
copyBuf3        = $0160
copyBuf4        = $0180

ntCopyBufTL = copyBuf3
ntCopyBufTR = copyBuf3+COL_HEIGHT
ntCopyBufBL = copyBuf3+COL_HEIGHT*2
ntCopyBufBR = copyBuf3+COL_HEIGHT*3
attrCopyBuf = copyBuf3+COL_HEIGHT*4
attrCopyDstLo = attrCopyBuf+COL_HEIGHT/2
ntCopyDstLo = attrCopyDstLo+1
ntCopyDstHi = attrCopyDstLo+2
; appear to have allocated $160-$198 of this, leaving 9 bytes free

; 01A0-01FF: stack
OAM             = $0200
; 0300-03FF: music, etc
; 0400-05FF: actor state
actorXLo        = $0400
actorXHi        = actorXLo + MAX_ACTORS
actorYLo        = actorXHi + MAX_ACTORS
actorYHi        = actorYLo + MAX_ACTORS
actorDXLo       = actorYHi + MAX_ACTORS
actorDXHi       = actorDXLo + MAX_ACTORS
actorDYLo       = actorDXHi + MAX_ACTORS
actorDYHi       = actorDYLo + MAX_ACTORS
actorType       = actorDYHi + MAX_ACTORS
actorPage       = actorType + MAX_ACTORS
; 04F0-04FF unallocated
actorAniType    = $0500
actorAniFrame   = actorAniType + MAX_ACTORS
actorAniSubF    = actorAniFrame + MAX_ACTORS
actorAniSpeed   = actorAniSubF + MAX_ACTORS
actorState0     = actorAniSpeed + MAX_ACTORS
actorState1     = actorState0 + MAX_ACTORS
actorState2     = actorState1 + MAX_ACTORS
actorState3     = actorState2 + MAX_ACTORS
actorState4     = actorState3 + MAX_ACTORS
actorFaceDir    = actorState4 + MAX_ACTORS
; 05F0-05FF unallocated
; 0600-07FF: store the partially decoded level
blockBuf0 = $0600
destroyedCols = $06C0
blockBuf1 = $0700

.globalzp nmis
.globalzp new_keys, cur_keys
.globalzp colDecodeBuf, colDecodeX, colDecodePage
.globalzp slidingWindowBaseX, slidingWindowBasePage
.globalzp slidingWindowFaceDir
.globalzp lastCamPage, lastCamX, camX, camPage
.globalzp debugHex1
.global main
.global putSprite, putActor
.globalzp putSpriteX, putSpriteY, putSpritePage, putSpriteTile
.globalzp putSpriteAttr, putSpriteW, putSpriteH
.globalzp oam_used
.global moveCameraTowardActor0
