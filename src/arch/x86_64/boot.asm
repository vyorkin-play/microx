global start
extern long_mode_start

section .text
bits 32
start:
  mov esp, stack_top

  call check_multiboot
  call check_cpuid
  call check_long_mode

  call setup_page_tables
  call enable_paging

  ; load GDT
  lgdt [gdt64.pointer]

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

; see http://wiki.osdev.org/Setting_Up_Long_Mode#Detecting_the_Presence_of_Long_Mode
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

; see http://wiki.osdev.org/Setting_Up_Long_Mode#x86_or_x86-64
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

; points the table entries at each other
setup_page_tables:
  ; point the first entry of the level-4 page table
  ; to the first entry in the level-3 table
  mov eax, p3_table
  or eax, 0b11                    ; set the "present" and "writable" bits
  mov dword [p4_table + 0], eax   ; link tables

  ; same shit for p3 and p2 page tables
  mov eax, p2_table
  or eax, 0b11
  mov dword [p3_table + 0], eax

  ; setup the level-2 page table
  ; to have valid references to pages
  mov ecx, 0
.map_p2_table:
  mov eax, 0x200000               ; each page is 2MiB
  mul ecx                         ; move by page size
  ; set the "present", "writable" and "huge page" bits
  ; without the "huge page" bit, we'd have 4KiB pages instead of 2MiB pages
  or eax, 0b10000011
  mov [p2_table + ecx * 8], eax   ;
  inc ecx
  cmp ecx, 512
  jne .map_p2_table
  ret

enable_paging:
  ; move level-4 page table address to cr3
  mov eax, p4_table
  mov cr3, eax

  ; enable physical address extension (PAE)
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; set the long mode bit in the EFER MSR (model specific register)
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  ; enable paging (in the cr0 register)
  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax

  ret

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
  dq 0 ; zero entry
.code: equ $ - gdt64
  dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53) ; code segment
.pointer:
  dw $ - gdt64 - 1
  dq gdt64
