.include "nes.inc"

OAM = $200

; main.s
.globalzp cursorX, cursorY, cursorTool, cursorColor, oamAddress
.global emblemData
.global emblemMeta
emblemPal = emblemMeta + 24
.globalzp newKeys, keys
.global readPad
.global drawFrame

; editor.s
.globalzp lastPPUCTRL
.globalzp retraces
.globalzp dirtyRow
.global loadSampleIcon
.global emblemEditor
.global loadEmblemIntoEditor
.global emblemPixels
.global getEmblemFromEditor
.globalzp actualSizeData

; chr.s
.global loadFont
.global loadCHR

.global thingOrTeam_nam, colorPicker_nam
.global presetsAnames, presetsBnames, presetsB16, presetsA16

.enum FRAMETILE
  TL = 128
  T
  TR
  L
  R
  BL
  B
  BR
.endenum

; pads.s
.globalzp dasKeys, dasTimer

; unpkb.s
.global PKB_unpackblk


; sel.s
.globalzp srb4LoadState, curPage, curBank, curEmblemX
.globalzp fromBank, fromPage, fromX
.globalzp xferBufferDstLo, xferBufferDstHi, xferBufferLen
.global bankNames
.global pageselPrepareUpdate
.global blastXferBuffer
.global doSel
.global clearRestOfOAM
.globalzp isSaveDialog
xferBuffer = emblemPixels

; sprcels.s
.global drawSpriteCel
.global getSpriteCelTileData

; studio.s
.global loadStudio, updateWeebleAnim

; osk.s
.global doKeyboard
.globalzp keyboardCurLen, keyboardMaxLen
.globalzp keyboardName
.globalzp keyboardShifted

keyboardText = emblemPixels + 224

; colorpicker.s
.global colorPicker
.global screenOn

; savedata.s
sramPrefsData = $6080
.global getEmblemMetadata, getEmblemData, getBankAndPage

; login.s
.global doLogin

; dialog.s
.global doMenu

