[bits 16]
[org 0x7C00]
%define drive_read_buffer 0x0000_7E00
%define boot_drive_ptr 0x0000_0500
%define source_code_start 0x0000_C200
%define frame_buffer_ptr 0x000B_8000

; boot sector and BPB declarations
BS_jumpBoot:        jmp short boot_code
                    nop 
BS_OEMName:         db "MSWIN4.1"
BPB_BytesPerSec:    dw 512 
BPB_SecPerClus:     db 1
BPB_RsvdSecCnt:     dw 1
BPB_NumFATs:        db 2
BPB_RootEntCnt:     dw 512          ; TODO: figure out a better number 
BPB_TotSec16:       dw 2 * 80 * 16  ; 2 sides, 80 tracks per side, 16 sectors per track
BPB_Media:          db 0xF0         ; 1.44MB floppy
BPB_FATSz16:        dw 9            ; 9 sectors for each FAT (2880 sectors, 341 full entries in each sector)
BPB_SecPerTrk:      dw 16
BPB_NumHeads:       dw 2
BPB_HiddSec:        dd 0
BPB_TotSec32:       dd 0
BS_DrvNum:          db 0x00 
BS_Reserved1:       db 0
BS_BootSig:         db 0x29
BS_VolID:           dd 0
BS_VolLab:          db "FLOPPY     "
BS_FileSysType:     db "FAT12   "

boot_code:
; save the boot drive number for later use
mov byte [boot_drive_ptr], dl

; enter video mode 3 (text 80x25 color)
mov ah, 0x00
mov al, 0x03
; mov al, 0x12 ; graphics 640x480
int 0x10

; disable vga cursor
mov ah, 0x01
mov cx, 0x2607
int 0x10


; load the source code for the compiler
; todo : upgrade to a double buffer system with current_lexeme and forward pointers
; ref : dragon pg 138 3.2 input buffering
read_sectors:
mov ah, 0x02    ; function
mov al, 40      ; sector_count
mov ch, 0x00    ; low eight bits of cylinder
mov cl, 0x02    ; sector after vbr and second boot, upper two bits cylinder hdd only
mov dh, 0x00    ; head
mov dl, 0x00
mov bx, drive_read_buffer
int 0x13

; activate a20 gate
mov ax, 0x2401   
int 0x15

; disable interrupts
cli        

; load gdt in gdtr
lgdt [gdt_desc]

; set pe bit in cr0
mov eax, cr0
or eax, 1
mov cr0, eax

jmp 0x08:protected_mode ; far jump into pm code segment of gdt index 1 + offset

; declare gdt structures
gdt_start:
gdt_null:
dq 0

gdt_kernel_code:
dw 0xFFFF           ; max limit (in this case 4 gib)
dw 0                ; base addr 0-15
db 0                ; base addr 16-23
db 0b10011010       ; access byte (preset, kernel-level, is code or data, is exec, growing up, readable, access)
db 0b11001111       ; flags (granularit, is 32bit, long mode, intel reserved) + upper 4 bits of the limit
db 0                ; base addr 24-31

gdt_kernel_data:
dw 0xFFFF           ; max limit (in this case 4 gib)
dw 0                ; base addr 0-15
db 0                ; base addr 16-23
db 0b10010010       ; access byte (preset, kernel-level, is code or data, is exec, growing up, readable, access)
db 0b11001111       ; flags (granularize, is 32bit, long mode, intel reserved) + upper 4 bits of the limit
db 0                ; base addr 24-31
gdt_end:

gdt_desc:
dw gdt_end - gdt_start - 1
dd gdt_start 

times 510 - ($ - $$) db 0 ; fill remaining bytes with 0s
dw 0xAA55                 ; write 511-512 with boot_loader magic numbers  

[bits 32]
%define heap_base_ptr 0x1000_000c
%define heap_ptr 0x1000_0010
%define symbol_table_size 0x1000_0014
%define symbol_table_ptr 0x2000_0000
%define new_str_ptr 0x1000_0018
%define hash_ptr 0x1000_002c

; cursors positions
%define cursor_x_ptr 0x1000_0050
%define cursor_y_ptr 0x1000_005c

%define linked_list_ptr 0x1000_0097

; itoa buffer
%define itoa_buffer 0x1000_0064

; screen constants
%define vga_width 80
%define vga_height 25
%define vga_color_16_frame_buffer 0x000A_0000

protected_mode:
mov ax, 0x10            ; load pm data segment offset in gdt index 2
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
mov esp, 0x0100_0000        ; init stack

mov dword [cursor_x_ptr], 0
mov dword [cursor_y_ptr], 0

call reset_screen

; ; int line = 1
; ; mov dword [line], 1

; ; init heap
mov dword [heap_base_ptr], 0x3000_0000
mov dword [heap_ptr], 0x3000_0000

call main
mov ebx, eax 
push exit_success
call print_string
push 10
push itoa_buffer
push ebx 
call itoa
push itoa_buffer
call print_string
jmp $

main:
push ebp
mov ebp, esp
; TODO: change parse tree structure and update printing method
call compiler_compile
; call lspci
xor eax, eax
leave
ret


lspci: 
push ebp
mov ebp, esp 
sub esp, 16
mov dword [ebp - 4], 0  ; bus number
; bus loop
.bus_loop:
cmp dword [ebp - 4], 256
je .bus_loop_end
mov dword [ebp - 8], 0  ; device number
.device_loop:
cmp dword [ebp - 8], 32
je .device_loop_end
mov dword [ebp - 12], 0 ; function number
.function_loop:
cmp dword [ebp - 12], 8
je .function_loop_end
push dword [ebp - 12]
push dword [ebp - 8]
push dword [ebp - 4]
call pci_config_read
add esp, 12
cmp eax, 0xffff_ffff
je .function_loop_end
mov dword [ebp - 16], eax
; print vendor id
mov eax, dword [ebp - 16]
and eax, 0xffff
push 16
push itoa_buffer
push eax 
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push space
call print_string
add esp, 4
; print device id
mov eax, dword [ebp - 16]
shr eax, 16
push 16 
push itoa_buffer
push eax 
call itoa 
add esp, 12 
push itoa_buffer
call print_string
add esp, 4
push nl
call print_string
add esp, 4
inc dword [ebp - 12]
jmp .function_loop
.function_loop_end:
inc dword [ebp - 8]
jmp .device_loop
.device_loop_end:
inc dword [ebp - 4]
jmp .bus_loop
.bus_loop_end:
leave 
ret

; returns a pointer to allocated mem block of size in bytes
; void* heap_alloc(int bytes)
heap_alloc:
push ebp 
mov ebp, esp 
mov dword eax, [heap_ptr]
mov edx, dword [ebp + 8]
add dword [heap_ptr], edx
leave 
ret 

; DANGER : only use in case of contiguous allocated memory, as the function 
; simply decrements the pointer by n bytes
; void heap_free(int bytes)
heap_free:
push ebp 
mov ebp, esp 
mov eax, dword [ebp + 8]
sub dword [heap_ptr], eax
leave
ret 

; clears the whole screen to bsod color
reset_screen:
push ebx
mov ebx, frame_buffer_ptr
.loop:
cmp ebx, 0xb8fa0        ; page 0 full cover 80 * 25 * 2
je .end_reset
mov byte [ebx], 0x00    
inc ebx
mov byte [ebx], 0x1f
inc ebx
jmp .loop
.end_reset:
pop ebx
ret

; get register name and fetch data
; print format => [regname]: [data]
get_register_data_hex:
push ebp 
mov ebp, esp 
sub esp, 12
mov dword [ebp - 4], 32   ; bit length 
; mov dword [cursor_x_ptr], frame_buffer_ptr
.get_bits:
cmp dword [ebp - 4], 0      ; check if all bits displayed
je .exit_loop   
mov dword [ebp - 8], 4
mov dword [ebp - 12], 0
.get_hex:
cmp dword [ebp - 8], 0
je .exit_hex
shl dword [ebp - 12], 1     ; shift left for next bit
shl dword [ebp + 8], 1      ; shift out the msb to set cf
setc al                  ; set al to shifted out bit
movzx eax, al
or dword [ebp - 12], eax    ; load bit into bl
sub dword [ebp - 8], 1
jmp .get_hex
.exit_hex:
sub dword [ebp - 4], 4
cmp dword [ebp - 12], 9
jg .alpha
add dword [ebp - 12], 0x30
jmp .post_alpha_check
.alpha:
add dword [ebp - 12], 0x37
.post_alpha_check:
; mov dword ebx, frame_buffer_ptr
mov dword eax, [cursor_x_ptr]
shl eax, 1
add eax, frame_buffer_ptr
mov edx, dword [ebp - 12]
mov byte [eax], dl  
inc eax  
mov byte [eax], 0x1F 
inc eax 
inc dword [cursor_x_ptr]
jmp .get_bits
.exit_loop:
leave
ret

; prints the supplied string to screen
; move string pointer into esi
; resets to the start on a new line if '\n' is seen
; 32 kb video memory starting from 0x00b8_000
; 80 x 25 per page, 8 pages
print_string:
push ebp 
mov ebp, esp 
sub esp, 8
push esi
mov esi, dword [ebp + 8]
push dword [cursor_y_ptr]
push dword [cursor_x_ptr]
call calculate_offset
add esp, 8
mov dword [ebp - 4], eax    ; save offset
.loop:
; check cursors bounds
.horizontal_check:
cmp dword [cursor_x_ptr], vga_width
jne .check_finished
push cursor_y_ptr
push cursor_x_ptr
call new_line
add esp, 8
push dword [cursor_y_ptr]
push dword [cursor_x_ptr]
call calculate_offset
add esp, 8
mov dword [ebp - 4], eax
.check_finished:
lodsb
mov byte [ebp - 8], al
cmp byte [ebp - 8], 0x00        ; '\0'
je .end_of_string
cmp byte [ebp - 8], 0x0A        ; '\n'
jne .no_new_line
push cursor_y_ptr
push cursor_x_ptr
call new_line
add esp, 8
push dword [cursor_y_ptr]
push dword [cursor_x_ptr]
call calculate_offset
add esp, 8
mov dword [ebp - 4], eax
jmp .loop
.no_new_line:
mov edx, dword [ebp - 4]
mov al, byte [ebp - 8]
mov byte [edx], al
inc edx 
mov byte [edx], 0x1F
inc edx
mov dword [ebp - 4], edx
inc dword [cursor_x_ptr]
jmp .loop
.end_of_string:
pop esi
leave
ret

new_line:
push ebp 
mov ebp, esp
mov eax, dword [ebp + 8]
xor edx, edx 
mov dword [eax], edx                ; zero the horizontal position 
mov eax, dword [ebp + 12]
inc dword [eax]                     ; move cursor down
leave
ret 

calculate_offset:
push ebp 
mov ebp, esp
mov edx, dword [ebp + 12]
mov eax, edx 
shl eax, 2      ; offset = y * 4 => 4y
add eax, edx    ; offset = offset + y => 5y
add eax, eax    ; offset = offset + offset => 10y
shl eax, 3      ; offset = offset * 8 => 80y 
mov edx, dword [ebp + 8]
shl eax, 1      ; x = x * 2 (16 bit offset)
shl edx, 1      ; y = y * 2 (16 bit offset)
add eax, edx    ; offset = offset + x => 80y + x
mov edx, frame_buffer_ptr
add eax, edx    ; buffer_addr = buffer_addr + offset
leave
ret




%include "compiler.asm"
%include "network_driver.asm"
exit_success: db "Process terminated with exit code: 0x", 0
error_msg: db "hash miss", 10, 0
space: db " ", 0
vertical_bar: db " | ", 0
here: db "started lexing a keyword", 10, 0
string_a: db "hello world", 0
string_b: db "hello world", 0
true: db "strings are equal", 0
false: db "strings are not equal", 0
nl: db 10, 0
null: db "NULL", 0
times 17920 - ($ - $$) db 0