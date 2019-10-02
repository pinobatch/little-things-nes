; Untested code for evaluating blackjack hands

; == Cards ==
; $00: Spades
; $10: Hearts
; $20: Diamonds
; $30: Clubs
; $80: Inactive

; Need way to draw a card as sprites and way to draw a card as
; background

; == Shuffling cards ==

DECK_SIZE = 52
NUM_DECKS = 2  ; limit 4 on an 8-bit platform

; This controls how deep the LRU queue is.
; Lower numbers mean less randomness mixed in, fewer repeats
; in adjacent hands, and more opportunity for card counting.
; It MUST be a power of two.
; It MUST be less than the number of cards in the shoe.
; The shoe size minus LRU_DEPTH MUST be at least
; as high as the number of cards seen in one hand
; so that dupes are never handed out.
LOG_LRU_DEPTH = 5
LRU_DEPTH = 1 << LOG_LRU_DEPTH

.segment "BSS"
shoe: .res DECK_SIZE * NUM_DECKS

;;
; Generates a fresh, unshuffled deck into the shoe.
.proc genInitialShoe
decksLeft = 0
  ldx #0
  clc
deckLoop:
  lda #1
suitLoop:
  ldy #13
cardLoop:
  sta shoe,x
  adc #1
  inx
  dey
  bne cardLoop
  adc #3
  cmp #$40
  bcc suitLoop
  cpx #DECK_SIZE*NUM_DECKS
  bcc deckLoop
  rts
.endproc
.assert NUM_DECKS = 2, error, "genInitialShoe requires 52-card deck"
.assert NUM_DECKS * DECK_SIZE < 256, error, "genInitialShoe requires 8-bit-addressable deck"

;;
; Shuffles the cards in the shoe. 
.proc shuffleShoe
  ldx #0

cardloop:

  ; choose a number from 0 to 255
  txa
  jsr crc16

  ; modulo deck size
  .if DECK_SIZE*NUM_DECKS*4 < 256
    cmp #DECK_SIZE*NUM_DECKS*4
    bcc :+
      sbc #DECK_SIZE*NUM_DECKS*4
    :
  .endif
  .if DECK_SIZE*NUM_DECKS*2 < 256
    cmp #DECK_SIZE*NUM_DECKS*2
    bcc :+
      sbc #DECK_SIZE*NUM_DECKS*2
    :
  .endif
  .if DECK_SIZE*NUM_DECKS*1 < 256
    cmp #DECK_SIZE*NUM_DECKS*1
    bcc :+
      sbc #DECK_SIZE*NUM_DECKS*1
    :
  .endif

  ; and swap the cards
  tay
  lda shoe,x
  sta 0
  lda shoe,y
  sta shoe,x
  lda 0
  sta shoe,y
  inx
  cpx
  bcc cardloop
  rts
.endproc


;;
; Moves a random card from the first LRU_DEPTH
; to the end of the deck.
; @return Y the card that was put at the end
.proc dealCard
  lda #0
  jsr crc16
  and #LRU_DEPTH - 1
  tax
  ldy shoe,x  ; Y holds the 
shift_loop:
  lda shoe+1,x
  sta shoe,x
  inx
  cpx #DECK_SIZE*NUM_DECKS-1
  bcc shiftLoop
  sty shoe+DECK_SIZE*NUM_DECKS-1
  rts
.endproc
.assert (LRU_DEPTH & (LRU_DEPTH - 1)) == 0, error, "LRU_DEPTH must be power of two"
.assert LRU_DEPTH < DECK_SIZE * NUM_DECKS, error, "LRU_DEPTH must be smaller than shoe"

; == Hand value calculation =================================

; bj_cardsInPlay is 
; [card1, card2, card3, card4, card5, card6, card7,
;  hand option flags, betAmountLo, betAmountHi]
; We use the "seven card Charlie" rule, where seven cards
; without busting are worth 21, because it simplifies
; implementation while taking only 0.01% from house edge.

NUM_PLAYER_COLUMNS = 4
CARD_CHARLIE = 7
COLUMN_RECORD_LENGTH = 3 + CARD_CHARLIE
BJ_DEALER_COLUMN = COLUMN_RECORD_LENGTH * NUM_PLAYER_COLUMNS

BJ_HAND_CAN_DOUBLE = $80
BJ_HAND_HAS_DOUBLED = $40  ; if true, hit to 3 and stop
BJ_HAND_CAN_SPLIT = $20
BJ_HAND_HAS_SPLIT = $10  ; if true, 2-card S21 is not a BJ

.segment "BSS"
bj_cardsInPlay:
  .res BJ_DEALER_COLUMN+CARD_CHARLIE

; 1: hand is eligible for increased winnings if blackjack
bj_handFlags = bj_cardsInPlay + CARD_CHARLIE

; bet amount in bells
bj_betAmountLo = bj_handFlags + 1
bj_betAmountHi = bj_betAmountLo + 1

.segment "RODATA"
; Offsets of each player column (because LUT is faster than multiply)
bj_playerColumns:
  .repeat NUM_PLAYER_COLUMNS, I
    .byt COLUMN_RECORD_LENGTH * I
  .endrepeat

.segment "CODE"
;;
; Clears a hand to 0 cards.
; @param Y which column to clear (0, 10, 20, 30: player; 40: dealer)
.proc clearHand



;;
; Calculates the hard value (sum of face values, with A=1 and JQK=10)
; and the soft value (counting bust, ace +10, and charlie)
; of a blackjack hand.
; @param Y which column to check (0, 10, 20, 30: player; 40: dealer)
; @return 0: hard value; 1: soft value; 2: number of cards; 3: number of aces
.proc getHandValue
hardValue = 0
softValue = 1
numCards = 2
numAces = 3
  lda #0
  sta hardValue
  sta numCards
  sta numAces
  ldx #CARD_CHARLIE
loop:
  lda bj_cardsInPlay,y
  bmi noCard
  inc numCards
  and #$0F
  cmp #1
  bne notAce
  inc numAces
notAce:
  cmp #11
  bcc notFaceCard
  lda #10
  clc
notFaceCard:
  adc hardValue
  sta hardValue
  inc numCards
noCard:
  iny
  dex
  bne loop

  ; A hand with a hard value 22 or more is a bust.
  ; FACT: The entire house advantage in blackjack is that
  ; the dealer wins if both the player and dealer bust.
  lda hardValue
  cmp #22
  bcc notBust
  lda #0
  beq haveSoft
notBust:

  ; A hand with a hard value 11 or less, at least one of the cards
  ; being an ace, is "soft" and receives a bonus of 10 value.
  ldx numAces
  beq hardHand
  cmp #12
  bcs hardHand
  adc #10
hardHand:

  ldx numCards
  cpx #CARD_CHARLIE
  bcc notCharlie
  cmp #21
  bcs notCharlie
  lda #21
notCharlie:

  ; A hand with 2 cards and a soft value of 21 is blackjack.
  cpx #2
  bne haveSoft
  cmp #21
  bne haveSoft
  ldx #31

haveSoft:
  sta softValue
  rts
.endproc

