.export bankcall_table

.macro bankcall_entry callid, banknumber, entrypoint
  .exportzp callid
  .import entrypoint
  callid = <(*-bankcall_table)
  .out .string(callid)
  .addr entrypoint-1
  .byt banknumber
.endmacro

.segment "RODATA"
; Each of these macros takes three arguments:
; the external name of the method (loaded into X before bankcall),
; which bank the method is in,
; and the entry point within the bank.
bankcall_table:
.if 0
  bankcall_entry draw_player_sprite,    2, draw_player_sprite_far
  bankcall_entry load_chr_ram,         13, load_chr_ram_far
.endif
