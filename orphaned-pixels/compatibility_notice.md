Compatibility notice
====================

This is themed after the user interface appearance of Bloodlust
Software's NESticle, an NES emulator that showed surprising staying
power despite having been far surpassed in compatibility and
accuracy.  Perhaps it was the debug tools or the built-in CHR ROM
editor, I don't know.

Here's how I had planned to use it:  The game runs several basic
self-tests for behaviors that emulators have known to get wrong
in the past.  The easiest behavior to test for is NESticle's
habit of not clearing the vertical blank interrupt bit of the
PPU's status register once the program has read it.

    @vwait1:
      bit $2002
      bpl @vwait1  ; wait for bit 7 to become true
      bit $2002    ; the first $2002 read should have cleared it
      bmi is_nesticle  ; branch to the code

At `is_nesticle` there would be a routine to display the message
and wait for the user to press the Start Button.  By imitating the
emulator's interface, it momentarily fools the user into thinking
the emulator is displaying the message.

* Intended NES palette: `120F2220120224321200221012242424`
* Unique tile count: <= 128
