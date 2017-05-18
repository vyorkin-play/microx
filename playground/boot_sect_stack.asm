; a simple boot sector

  mov ah, 0x0e          ; scrolling teletype BIOS routine

  mov bp, 0x8000        ; set the base of the stack a little above where BIOS
  mov sp, bp            ; loads our boot sector - so it won't overwrite us

  push 'A'              ; push some characters on the stack for later retreival
  push 'B'              ; these are pushed on as 16-bit values
  push 'C'              ; so the most significat byte will be added as 0x00

  pop bx                ; we can only pop 16-bits, so pop to bx
  mov al, bl            ; then copy bl (8-bit char) to al
  int 0x10              ; and print whats in al

  pop bx                ; pop the next value
  mov al, bl
  int 0x10              ; print al

  ; to demonstate that our stack grows downwards from bp,
  ; fetch the char at 0x8000 - 0x2 (2 bytes / 16 bits)
  ; and print it

  mov al, [0x7ffe]
  int 0x10

  jmp $                 ; jump to the current address (i.e. forever)

  times 510-($-$$) db 0	; pad with 510 zeros
  dw 0xaa55             ; tell BIOS that we are a boot sector
