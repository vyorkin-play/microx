global start

section .text
bits 32
start:
  mov esp, stack_top

  call check_multiboot
  call check_cpuid
  call check_long_mode

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

; the real multiboot bootloader must write
; the magic value 0x36d76289 to eax register
; before loading a kernel
check_multiboot:
  cmp eax, 0x36d76289
  jne .error_no_multiboot
  ret

.error_no_multiboot
  mov al, "0"
  jmp error

check_cpuid:
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the
    ; ID bit back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit
    ; wasn't flipped, and CPUID isn't supported.
    cmp eax, ecx
    je .error_no_cpuid
    ret

.error_no_cpuid:
    mov al, "1"
    jmp error

check_long_mode:
    ; test if extended processor info in available
    mov eax, 0x80000000    ; implicit argument for cpuid
    cpuid                  ; get highest supported argument
    cmp eax, 0x80000001    ; it needs to be at least 0x80000001
    jb .error_no_long_mode ; if it's less, the CPU is too old for long mode

    ; use extended info to test if long mode is available
    mov eax, 0x80000001    ; argument for extended processor info
    cpuid                  ; returns various feature bits in ecx and edx
    test edx, 1 << 29      ; test if the LM-bit is set in the D-register
    jz .error_no_long_mode ; If it's not set, there is no long mode
    ret
.error_no_long_mode:
    mov al, "2"
    jmp error

; prints 'ERR: '
; and the given error code to screen and hangs
error:
  mov dword [0xb8000], 0x4f524f45
  mov dword [0xb8004], 0x4f3a4f52
  mov dword [0xb8008], 0x4f204f20
  mov byte  [0xb800a], al
  hlt

section .bss
align 4096
p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096
stack_bottom:
  resb 64
stack_top:

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
