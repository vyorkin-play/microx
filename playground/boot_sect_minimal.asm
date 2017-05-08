; a simple boot sector program that loops forever

loop:
  jmp loop		; loop forever
  times 510-($-$$) db 0	; pad with 510 zeros
  dw 0xaa55             ; tell BIOS that we are a boot sector
