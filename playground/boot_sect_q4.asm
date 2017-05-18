; a simple boot sector (question 4)

[org 0x7c00]            ; tell the assembler where this code will be loaded

  mov bx, HELLO_MSG     ; use bx as a parameter to our function
  call print_string

  mov bx, GOODBYE_MSG
  call print_string

  jmp $                 ; jump to the current address (i.e. forever)

%include "print_string.asm"

HELLO_MSG:
  db 'Hello, World!', 0
GOODBYE_MSG:
  db 'Goodbye!', 0

  times 510-($-$$) db 0	; pad with 510 zeros
  dw 0xaa55             ; tell BIOS that we are a boot sector
