Rules of blackjack
==================

Shuffling
---------
The deck comes preloaded with 104 cards, and they're dealt with 32 LRU.

Hand valuation
--------------
The hard value of a hand is the sum of cards' values with face cards treated as 10: A=1, 2=2, 3=3, ..., 10=10, JQK=10.

* A hand with a hard value 11 or less with an ace gets 10 more; a hand with this bonus is called soft.
* A hand with a hard value more than 21 is a "bust" and worth 0.
* A hand with seven cards that is not a bust is a "charlie" and worth 21.
* A two-card soft 21 (10 and an ace) that does not arise from a split is a "blackjack" and is worth 31 (displayed as BJ).

Play
----
Player buys one or more hands by placing a bet in the betting box at the bottom of each column. Spectators can place their own bets in the same column.

Dealer is dealt one card, and each player is dealt two.
(We use the no-hole-card rule to simplify programming.)

If the dealer's upcard is an ace, the player can insure the hand.  This bet has a house advantage, as one-third of insurances would need to win but tens are only 31% of cards.  But when a lot of tens are in the deck, or if the player is trying to reduce variation, it can be a good deal.

If there is an open column, a pair may be split. Those playing behind may choose to join or not to join the split hand. Splits are recommended for A-A and 8-8 against 2 through 9. A split hand can be played as normal, but A-10 resulting from a split is not blackjack, and split A cannot be hit past 2 cards.

A two-card hand may be doubled down. It's recommended for hands valued 10 or 11, especially if there are a lot of high cards left in the deck.

A hand with value less than 21 may be hit. Hitting a soft hand cannot bust it, but hitting a hard hand can bust it and eliminate the player.

Or with a hand valued at least 12, the player can stand. Standing is recommended for all hands valued 17 or more and for specific combinations of player hand value and the dealer's card value dictated by a basic strategy.

After all columns have stood or busted, the dealer hits until he busts or his hand has a value at least 17.  Then follow these rules:

* Blackjack beats other 21.
* Dealer bust beats a player bust.
* Otherwise, the highest value wins.
* Player blackjack without dealer blackjack pays 3 to 2.

The house advantage that a dealer bust beats a player bust is mostly balanced by a winning player blackjack paying 3 to 2, leaving a remaining advantage of about 5.5 percent for the player to overcome by choosing when to stand below 17 in expectation that the dealer will bust.

Basic strategy
--------------
There are more tens in the deck than anything else, and having more tens means more busts for the dealer's automatic strategy of hitting on 16. HowStuffWorks points out that dealers bust more often with a high upcard. It recommends playing conservatively to a low upcard and aggressively otherwise.  The overall gist is as follows:

* Stand on 12 against 2-3.
* Stand on 13 against 4-6.
* Stand on 17 against 7-10 or A.

The basic strategy card at Gambling Castle makes a few refinements:

* Double down 9 against a low upcard.
* Double down 10 or 11 against any upcard but A.
* Hit soft 17.
* Double down soft 13-18.
* Split pair of A and 8 always.
* Split pair of 2, 3, 6, 7, or 9 against a low upcard.

Card counting is a way to estimate the prevalence of tens in the deck. Whenever a 2-6 is dealt, add 1; whenever a 10 or A is dealt, subtract 1.  When the count is over 4 times the number of decks left in the shoe, bet higher.

Glossary
--------

* Backdoor Kenny: 10-A blackjack, which is much less common than A-10
* Behind: Betting on another player's hand as a spectator
* Blackjack: 10-A or A-10 hand not resulting from a split
* Basic strategy: The player's best choice for each given total and dealer upcard, disregarding undealt cards
* Bust: Hit to a hard total of 22 or more, for an instant loss
* Charlie: Hit to the table's maximum number of cards without busting
* Cut card: Bottom of playable portion of deck; reshuffle after this is dealt
* Double down: Double the bet, hit once, and stand
* Even money: Fully insuring a player's blackjack, which always pays 1:1
* First base: The right-hand column (dealer's left), which plays first
* Hard hand: A hand without an ace counted as 11
* Hard total: The sum of the values (A=1, 2=2, 3=3, ..., 10/J/Q/K=10)
* High card: 7 through 10 or A
* Hit: Draw another card
* Hole card: Dealing the dealer's second card face down; not used here
* Insure: When dealer shows A, place a side bet up to half the original bet that pays 2:1 if the next card is 10
* Low card: 2 through 6
* Pair: Hand with two cards, both of the same value (e.g. 3-3 or 10-Q)
* Penetration: Depth down the decks where the cut card is placed, e.g. 4.5/6 or 75%
* Push: Tie; player has not busted and player's total equals dealer's
* Shoe: Device to hold 4 to 8 decks and deal from them
* Soft hand: A hand with an ace counted as 11
* Split: Moving the second card of a pair to an open column, placing an equal * bet there, and hitting once on each column
* Stand: Stop drawing cards
* Stiff hand: Hard hand that may bust if hit, with value 12 through 16
* Surrender: Return an unbusted hand to the dealer; costs half the bet
* Ten: A card with face value 10, J, Q, or K
* Third base: The left-hand column, which plays last
* Total: Hard total, plus 10 if an ace is present and hard total is 11 or less
* Upcard: The card dealt face up to the dealer before players play
