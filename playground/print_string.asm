print_string:
  mov al, [bx]
  cmp al, 0
  je print_string_end
  call print_char
  add bx, 0x1
  jmp print_string
print_string_end:
  ret

print_char:
  mov ah, 0x0e
  int 0x10
  ret
