global start

section .text
bits 32
start:
  mov word [0xb8000], 0x024D ; M
  mov word [0xb8002], 0x0249 ; I
  mov word [0xb8004], 0x0243 ; C
  mov word [0xb8006], 0x0252 ; R
  mov word [0xb8008], 0x024F ; O
  mov word [0xb800A], 0x0258 ; X
  hlt
