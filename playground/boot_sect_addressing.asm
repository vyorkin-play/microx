; a simple boot sector program that loops forever

  mov ah, 0x0e          ; scrolling teletype BIOS routine

  ; 3
  mov bx, the_secret
  add bx, 0x7c00
  mov al, [bx]
  int 0x10

  ; 4
  mov al, [0x7c14]
  int 0x10

  jmp $                 ; jump to the current address (i.e. forever)

the_secret:
  db "X"

  times 510-($-$$) db 0	; pad with 510 zeros
  dw 0xaa55             ; tell BIOS that we are a boot sector
