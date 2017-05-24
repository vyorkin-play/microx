global start

section .text
bits 32
start:
  mov eax, p3_table
  or eax, 0b11
  mov dword [p4_table + 0], eax

  mov eax, p2_table
  or eax, 0b11
  mov dword [p3_table + 0], eax

  ; setup the level-2 page table
  ; to have valid references to pages
  mov ecx, 0
.map_p2_table:
  mov eax, 0x200000               ; each page is 2MiB
  mul ecx                         ; move by page size
  or eax, 0b10000011              ; present, writable, huge page
  mov [p2_table + ecx * 8], eax   ;

  inc ecx
  cmp ecx, 512
  jne .map_p2_table

  ; move page table address to cr3
  mov eax, p4_table
  mov cr3, eax

  ; enable physical address extension (PAE)
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; set the long mode bit
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  ; enable paging
  mov eax, cr0
  or eax, 1 << 31
  or eax, 1 << 16
  mov cr0, eax

  ; load GDT
  lgdt [gdt64.pointer]

  ; update selectors
  mov ax, gdt64.data
  mov ss, ax
  mov ds, ax
  mov es, ax

  ; jump to the long mode
  jmp gdt64.code:long_mode_start

  mov word [0xb8000], 0x024D ; M
  mov word [0xb8002], 0x0249 ; I
  mov word [0xb8004], 0x0243 ; C
  mov word [0xb8006], 0x0252 ; R
  mov word [0xb8008], 0x024F ; O
  mov word [0xb800A], 0x0258 ; X
  hlt

section .bss
align 4096
p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096

section .rodata
gdt64:
  dq 0
.code: equ $ - gdt64
  dq (1 << 44) | (1 << 47) | (1 << 41) | (1 << 43) | (1 << 53)
.data: equ $ - gdt64
  dq (1 << 44) | (1 << 47) | (1 << 41)
.pointer:
  dw .pointer - gdt64 - 1
  dq gdt64

section .text
bits 64
long_mode_start:
  mov rax, 0x2f592f412f4b2f4f
  mov qword [0xb8000], rax
  hlt
