[bits 32]
%define drive_read_buffer 0x0001_0000 
[org drive_read_buffer]
%define SECTORS 108
%define SOURCE_CODE_SECTORS 80
%define source_code_start (drive_read_buffer + SECTORS * 512)
%define output_buffer_ptr 0x0004_0000
; %define output_buffer_ptr 0x000B_8000
%define frame_buffer_ptr 0x000B_8000

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


kernel_main:
push ebp
mov ebp, esp

; ; ; init heap
mov dword [heap_base_ptr], 0x3000_0000
mov dword [heap_ptr], 0x3000_0000

; ; ; init vga pointer
mov dword [cursor_x_ptr], 0
mov dword [cursor_y_ptr], 0

; ; ; reset screen to blue
call reset_screen

; ; ; load IDT entries
; call load_idt_table

; ; ; init hardware interrupts
; call init_IRQs

call compiler_compile

; call main

jmp $

; %include "./output/main.asm"


; clears the whole screen to bsod color
reset_screen:
push ebp
mov ebp, esp
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
mov edx, dword [ebp - 4]
mov byte [edx], 0x0A    ; \n
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

; void print_line(char* string)
; calls print_string with the specified argument and prints a new line character afterwards
print_line:
push ebp
mov ebp, esp
push dword [ebp+8]
call print_string
add esp, 4
push nl
call print_string
add esp, 4
leave
ret

; void print_number(int n)
; outputs the converted number to base 10 to stdout
print_binary:
push ebp
mov ebp, esp
push 2
push itoa_buffer
push dword [ebp+8]
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
mov eax, 0
leave
ret

; void print_number(int n)
; outputs the converted number to base 10 to stdout
print_number:
push ebp
mov ebp, esp
push 10
push itoa_buffer
push dword [ebp+8]
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
mov eax, 0
leave
ret

print_hex:
push ebp
mov ebp, esp
push 16
push itoa_buffer
push dword [ebp+8]
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
mov eax, 0
leave
ret

get_time:
push ebp
mov ebp, esp
sub esp, 4
mfence
lfence
rdtsc   ; returns lo in eax
lfence
; vm running at cpu base freq 2.3 GHz
mov dword [ebp - 4], 0x88D45D6D
div dword [ebp - 4]
; returns time in seconds since last reset
leave
ret

; pauses the execution of the programme for the specified number of seconds
; TODO: increase accuracy to milliseconds
; void sleep(uint seconds)
sleep:
push ebp
mov ebp, esp
sub esp, 4
call get_time
mov dword [ebp - 4], eax    ; save new time
.timer_loop:
call get_time
mov edx, dword [ebp - 4]
sub eax, edx
cmp eax, dword [ebp + 8]    ; check if specified interval has passed
jl .timer_loop
leave
ret


; %include "isr.asm"
; %include "pic.asm"
; %include "irq.asm"
; %include "utils.asm"
; %include "io.asm"
%include "compiler.asm"
; %include "math.asm"
; %include "network_driver.asm"
exit_success: db "Process terminated with exit code: 0x", 0
error_msg: db "hash miss", 10, 0
space: db " ", 0
size_t: db "size: ", 0
vertical_bar: db " | ", 0
here: db "started lexing a keyword", 10, 0
string_a: db "hello world", 0
string_b: db "hello world", 0
true: db "strings are equal", 0
false: db "strings are not equal", 0
nl: db 10, 0

times (SECTORS * 512) - ($ - $$) db 1