; a simple boot sector (question 3)

  mov bx, 30

  cmp bx, 4
  jle set_a
  cmp bx, 40
  jl set_b

  mov al, 'C'

set_a:
  mov al, 'A'
  jmp the_end

set_b:
  mov al, 'B'

the_end:

  mov ah, 0x0e          ; scrolling teletype BIOS routine
  int 0x10              ; print the character in al

  jmp $                 ; jump to the current address (i.e. forever)

  times 510-($-$$) db 0	; pad with 510 zeros
  dw 0xaa55             ; tell BIOS that we are a boot sector
