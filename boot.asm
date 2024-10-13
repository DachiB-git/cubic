[BITS 16]
[ORG 0x7C00]
%define BOOT_DRIVE_PTR 0x0000_8E00
%define DRIVE_READ_BUFFER 0x0000_7E00
%define SOURCE_CODE_START 0x0000_8400
%define FRAME_BUFFER_PTR 0x000B_8000

; save the boot drive number for later use
MOV BYTE [BOOT_DRIVE_PTR], DL


; enter video mode 3 (text 80x25 color)
MOV AH, 0x00
MOV AL, 0x03
INT 0x10

; disable vga cursor
MOV AH, 0x01
MOV CX, 0x2607
INT 0x10


; load the source code for the compiler
; TODO : upgrade to a double buffer system with current_lexeme and forward pointers
; REF : dragon pg 138 3.2 Input buffering

; void read_sector(int sector_count, int cylinder, int sector, int head)
read_sector:
; PUSH BP
; MOV BP, SP
MOV AH, 0x02                        ; BIOS read sector disk service function
MOV AL, 0x06                        ; sector_count
MOV CH, 0x00                        ; cylinder
MOV CL, 0x02                        ; sector
MOV DH, 0x00                        ; head
MOV BYTE DL, [BOOT_DRIVE_PTR]       ; active disk number
MOV BX, DRIVE_READ_BUFFER           ; read buffer ptr
INT 0x13
; MOV SP, BP
; POP BP
; RET

; activate A20 gate
MOV AX, 0x2401   
INT 0x15

; disable interrupts
CLI        

; load GDT in GDTR
LGDT [gdt_desc]

; set PE bit in CR0
MOV EAX, CR0
OR EAX, 1
MOV CR0, EAX

JMP CODE:protected_mode ; far jump into PM code segment of GDT index 1 + offset

; declare GDT structures
gdt_start:
gdt_null:
DQ 0

gdt_kernel_code:
DW 0xFFFF           ; max limit (in this case 4 GiB)
DW 0                ; base addr 0-15
DB 0                ; base addr 16-23
DB 0b10011010       ; access byte (preset, kernel-level, is code or data, is exec, growing up, readable, access)
DB 0b11001111       ; flags (granularit, is 32bit, long mode, intel reserved) + upper 4 bits of the limit
DB 0                ; base addr 24-31

gdt_kernel_data:
DW 0xFFFF           ; max limit (in this case 4 GiB)
DW 0                ; base addr 0-15
DB 0                ; base addr 16-23
DB 0b10010010       ; access byte (preset, kernel-level, is code or data, is exec, growing up, readable, access)
DB 0b11001111       ; flags (granularize, is 32bit, long mode, intel reserved) + upper 4 bits of the limit
DB 0                ; base addr 24-31
gdt_end:

gdt_desc:
DW gdt_end - gdt_start - 1
DD gdt_start 

CODE equ gdt_kernel_code - gdt_start
DATA equ gdt_kernel_data - gdt_start   

TIMES 510 - ($ - $$) DB 0 ; fill remaining bytes with 0s
DW 0xAA55                 ; write 511-512 with boot_loader magic numbers  

[BITS 32]
%include "compiler.asm"
%include "utils.asm"

%define pointer 0x1000_0000
%define peek 0x1000_0004
%define symbol_table_ptr 0x1000_0008
%define heap_base_ptr 0x1000_000C
%define heap_ptr 0x1000_0010
%define symbol_table_size 0x1000_0014
%define new_str_ptr 0x1000_0018
%define hash_ptr 0x1000_002C
%define FNV_basis_ptr 0x1000_0030
%define FNV_prime_ptr 0x1000_0034
%define string_builder_ptr 0x1000_0038
%define string_builder_size 0x1000_004C
%define cursor_x_ptr 0x1000_0050
%define line 0x1000_0054
%define numeric_value 0x1000_0058
%define cursor_y_ptr 0x1000_005C
%define op_addr 0x1000_0060
%define linked_list_ptr 0x1000_0097

; itoa buffer
%define itoa_buffer 0x1000_0064

; hashing constants
%define FNV_prime 0x0100_0193
%define FNV_offset_basis 0x811C_9DC5

; screen constants
%define VGA_WIDTH 80
%define VGA_HEIGHT 25

protected_mode:
MOV AX, DATA            ; load PM data segment offset in GDT index 2
MOV DS, AX
MOV ES, AX
MOV FS, AX
MOV GS, AX
MOV SS, AX
MOV ESP, 0x90000        ; init stack

MOV DWORD [cursor_x_ptr], 0
MOV DWORD [cursor_y_ptr], 0

CALL reset_screen

; int line = 1
MOV DWORD [line], 1

; init heap
MOV DWORD [heap_base_ptr], 0x3000_0000
MOV DWORD [heap_ptr], 0x3000_0000

; init symbol_table
MOV DWORD [symbol_table_ptr], 0x2000_0000
MOV DWORD [symbol_table_size], 0

; init string_builder
CALL get_string_builder
MOV DWORD [string_builder_ptr], EAX 
MOV DWORD [string_builder_size], 0

; .begin_lexing:
; CALL lexer_get_token
; CMP ECX, 0x00 
; JE .finish_lexing
; MOV EBX, itoa_buffer
; CALL int_to_string_base_10
; MOV ESI, itoa_buffer
; CALL print_string
; MOV ESI, space
; CALL print_string
; JMP .begin_lexing
; .finish_lexing:

JMP $

; LEXER 
lexer_get_token:
.continue:
; filter ' ', '\r', '\t'
; inc line if peek == '\n'
; get next character 
MOV DWORD EBX, SOURCE_CODE_START
MOV DWORD ECX, pointer
CALL get_char
MOV BYTE [peek], AL ; peek = get_char()

; if (peek == ' ' || peek == '\r' || peek == '\t') continue
CMP BYTE [peek], 0x20
JE .continue 
CMP BYTE [peek], 0xD0
JE .continue
CMP BYTE [peek], 0x90
JE .continue
; else if (peek == '\n') line++;
CMP BYTE [peek], 0xA0
JNE .end_loop
; else break
INC DWORD [line]
; if (peek is EOF) end lexing
CMP BYTE [peek], 0x00 
JNE .end_loop
MOV ECX, 0x00
RET 
.end_loop:
; else if (peek is a digit)
CALL is_a_digit
CMP AL, 0x00
JE .not_a_digit
MOV DWORD [numeric_value], 0        ; v = 0;
.get_integer:
; v = v * 10 + to_digit(peek)
MOV DWORD EBX, [numeric_value]      ; x = v
MOV ECX, EBX                        ; y = x
SHL ECX, 2                          ; y *= 4 => y = 4x
ADD ECX, EBX                        ; y += x => y = 5x
ADD ECX, ECX                        ; y += y => y = 10x
MOV BYTE AL, [peek]                 ; load peek
SUB AL, 0x30                        ; to_digit(peek)
ADD ECX, EAX                        ; y += to_digit(peek) 
MOV DWORD [numeric_value], ECX      ; v = y
MOV DWORD EBX, SOURCE_CODE_START
MOV DWORD ECX, pointer
CALL get_char
MOV BYTE [peek], AL                 ; peek = get_char()
CALL is_a_digit
CMP AL, 0x00 
JE .ret_integer_token
JMP .get_integer
.ret_integer_token:
MOV DWORD ECX, pointer
CALL retract
; integral token to symbol_table
; setup new Num Token <tag, val>
MOV EBX, NUM 
MOV DWORD ECX, [numeric_value]
CALL get_token
; TODO : add token to symbol_table
.not_a_digit:
CALL is_a_letter
CMP AL, 0x00 
JE .not_a_letter
.get_word:
MOV BYTE AL, [peek]                     ; load current char
MOV DWORD ECX, [string_builder_size]
MOV DWORD EBX, [string_builder_ptr]     
CALL string_builder_append              ; add to current buffer
MOV DWORD EBX, SOURCE_CODE_START
MOV DWORD ECX, pointer
CALL get_char                           ; load next char
MOV BYTE [peek], AL
CALL is_a_letter
CMP AL, 0x00 
JE .ret_word_token
CALL is_a_digit
CMP AL, 0x00 
JE .ret_word_token
JMP .get_word
.ret_word_token:
MOV DWORD ECX, pointer
CALL retract                            ; rectact pointer
; fetch string from string_builder
MOV DWORD EBX, [string_builder_ptr]
MOV DWORD ECX, [string_builder_size]
CALL string_builder_to_string
; check if lexeme present in symbol_table
MOV ECX, EAX 
MOV EBX, ID

; string_builder clean up

MOV ECX, ID
RET
.not_a_letter:
.get_operator: 
; XOR EAX, EAX
CMP BYTE [peek], 0x3C       ; '<'
JNE .check1
MOV EAX, LT
JMP .check_equals
.check1:
CMP BYTE [peek], 0x3E       ; '>'
JNE .check2
MOV EAX, GT
JMP .check_equals
.check2:
CMP BYTE [peek], 0x3D       ; '='
JNE .check3
MOV EAX, AS
JMP .check_equals
.check3:
CMP BYTE [peek], 0x21       ; '!'
JNE .check4
MOV EAX, NG 
JMP .check_equals
.check4:
CMP BYTE [peek], 0x26       ; '&'
JNE .check5
MOV EAX, AND_OP
JMP .check_twin
.check5:
CMP BYTE [peek], 0x7C       ; '|'
JNE .not_an_operator
MOV EAX, OR_OP
JMP .check_twin
.check_equals:
MOV DWORD [op_addr], EAX 
MOV DWORD EBX, SOURCE_CODE_START
MOV DWORD ECX, pointer
CALL get_char
MOV BYTE [peek], AL 
CMP BYTE [peek], 0x3D       ; '='
JNE .no_equals
; <=. >=, == 
MOV DWORD EAX, [op_addr]
INC DWORD EAX 
; store token in symbol table
MOV ECX, EAX 
RET
.no_equals:
MOV DWORD ECX, pointer
CALL retract
MOV ECX, EAX
RET
.check_twin:
MOV DWORD [op_addr], EAX 
MOV BYTE AH, [peek]
MOV DWORD EBX, SOURCE_CODE_START
MOV DWORD ECX, pointer
CALL get_char
MOV BYTE [peek], AL 
CMP AL, AH 
JNE .not_an_operator
MOV DWORD EAX, [op_addr]
MOV ECX, EAX 
RET 
.not_an_operator:
MOV ECX, 0x00
RET

; FUNCTIONS

; check if char in peek is a digit
; returns 1 if true else 0 in AL
is_a_digit:
CMP BYTE [peek], 0x30
JS .not_a_digit
CMP BYTE [peek], 0x39
JG .not_a_digit
MOV EAX, 0x01 
RET
.not_a_digit:
MOV EAX, 0x00
RET
; check if char in peek is a letter c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z' || c == '_'
; returns 1 if true else 0 in AL
is_a_letter:
CMP BYTE [peek], 0x41   ; 'A'
JL .check_lower 
CMP BYTE [peek], 0x5A   ; 'Z'
JG .check_lower 
MOV EAX, 0x01 
RET
.check_lower:
CMP BYTE [peek], 0x61   ; 'a'
JL .check_underscore
CMP BYTE [peek], 0x7A   ; 'z'
JG .check_underscore
MOV EAX, 0x01
RET
.check_underscore:
CMP BYTE [peek], 0x5F   ; '_'
JNZ .not_a_letter
MOV EAX, 0x01 
RET 
.not_a_letter:
MOV EAX, 0x00
RET

; returns a pointer to allocated mem block of size in EBX bytes into EAX 
heap_alloc:
MOV DWORD EAX, [heap_ptr]
ADD DWORD [heap_ptr], EBX
RET 

; clears the whole screen to BSOD color
reset_screen:
PUSH EBX
MOV EBX, FRAME_BUFFER_PTR
.loop:
CMP EBX, 0xB8FA0        ; page 0 full cover 80 * 25 * 2
JE .end_reset
MOV BYTE [EBX], 0x00    
INC EBX
MOV BYTE [EBX], 0x1F
INC EBX
JMP .loop
.end_reset:
POP EBX
RET

; prints the supplied string to screen
; move string pointer into ESI
; resets to the start on a new line if '\n' is seen
; 32 Kb video memory starting from 0x00B8_000
; 80 x 25 per page, 8 pages
print_string:
PUSH EAX 
PUSH EBX 
PUSH ECX
PUSH EDX
MOV DWORD ECX, [cursor_x_ptr]
MOV DWORD EDX, [cursor_y_ptr]
CALL calculate_offset
.loop:
; check cursors bounds
.horizontal_check:
CMP ECX, VGA_WIDTH
JNE .check_finished
CALL new_line
CALL calculate_offset
.check_finished:
LODSB
CMP AL, 0x00        ; '\0'
JE .end_of_string
CMP AL, 0x0A        ; '\n'
JNE .no_new_line
CALL new_line
CALL calculate_offset
JMP .loop
.no_new_line:
MOV BYTE [EBX], AL
INC EBX
MOV BYTE [EBX], 0x1F
INC EBX
INC ECX 
JMP .loop
.end_of_string:
; update cursor location
MOV DWORD [cursor_x_ptr], ECX
MOV DWORD [cursor_y_ptr], EDX
POP EDX 
POP ECX 
POP EBX
POP EAX
RET

new_line:
XOR ECX, ECX        ; zero the horizontal position
INC EDX             ; move cursor down
RET 

calculate_offset:
PUSH ECX 
MOV EAX, EDX 
SHL EAX, 2      ; offset = y * 4 => 4y
ADD EAX, EDX    ; offset = offset + y => 5y
ADD EAX, EAX    ; offset = offset + offset => 10y
SHL EAX, 3      ; offset = offset * 8 => 80y 
SHL ECX, 1      ; x = x * 2 (16 bit offset)
SHL EAX, 1      ; y = y * 2 (16 bit offset)
ADD EAX, ECX    ; offset = offset + x => 80y + x
MOV EBX, FRAME_BUFFER_PTR
ADD EBX, EAX    ; buffer_addr = buffer_addr + offset
POP ECX
RET

get_register_data_hex:
; get register name and fetch data
; print format => [regName]: [data]
; move address into DX
MOV CL, 32   ; bit length 
; MOV DWORD [cursor_x_ptr], FRAME_BUFFER_PTR
.get_bits:
CMP CL, 0      ; check if all bits displayed
JE .exit_loop   
PUSH CX
MOV CL, 4
XOR BL, BL
.get_hex:
CMP CL, 0
JE .exit_hex
CLC
SHL BL, 1       ; shift left for next bit
CLC
SHL EDX, 1      ; shift out the MSB to set CF
SETC AL         ; set AL to shifted out bit
CLC             ; clear CF 
OR BL, AL       ; load bit into BL
SUB CL, 1
JMP .get_hex
.exit_hex:
POP CX
SUB CL, 4
MOV AL, BL
CMP AL, 9
JG .alpha
ADD AL, 0x30
JMP .post_alpha_check
.alpha:
ADD AL, 0x37
.post_alpha_check:
PUSH EBX 
; MOV DWORD EBX, FRAME_BUFFER_PTR
MOV DWORD EBX, [cursor_x_ptr]
SHL EBX, 1
ADD DWORD EBX, FRAME_BUFFER_PTR
MOV BYTE [EBX], AL 
INC EBX 
MOV BYTE [EBX], 0x1F 
INC EBX 
INC DWORD [cursor_x_ptr]
POP EBX 
JMP .get_bits
.exit_loop:
RET


; move key pointer into SI
fnv32_1:
PUSH EAX
PUSH EBX
XOR EAX, EAX
MOV DWORD EAX, [FNV_basis_ptr]
.hash_loop:
PUSH EAX
LODSB 
CMP AL, 0x00
JE .hash_end
XOR EBX, EBX
MOV BL, AL
POP EAX
MUL DWORD [FNV_prime_ptr]
XOR EAX, EBX
JMP .hash_loop
.hash_end:
POP EAX
MOV DWORD [hash_ptr], EAX
POP EBX
POP EAX
RET

here: db "started lexing the operator", 10, 0
msg: db "Hello world! ", 10, 0
space: db " ", 0
TIMES 2048 - ($ - $$) DB 0