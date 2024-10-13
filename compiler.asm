%define ID  256
%define NUM 257
%define INT 258
%define UINT 259
%define BOOL 260
%define CHAR 261
%define TYPEDEF 262
%define LT 263
%define LE 264
%define GT 265
%define GE 266
%define EQ 267
%define NE 268
%define AND_OP 269
%define OR_OP 270

; load buffer address into EBX
; load offset pointer into ECX
; loads a char from the mem[drive_read_buffer + pointer] into AL
; and increments ECX
get_char:
PUSH EBX 
PUSH ECX 
ADD EBX, [ECX]
MOV BYTE AL, [EBX]
INC DWORD [ECX]
POP ECX
POP EBX
RET 

; decrement buffer pointer in ECX
retract:
DEC DWORD [ECX]

; peek at the next character, without incrementing the pointer
peek_char:
PUSH EBX 
ADD EBX, [ECX]
MOV BYTE AL, [EBX]
POP EBX
RET




; move char array pointer into ESI
; returns a pointer to the stored string in EAX 
; heap_add_string:
; PUSHF
; PUSH EBX
; MOV DWORD EAX, [heap_ptr]
; PUSH EAX 
; MOV EBX, EAX
; CLD
; .loop:
; CLC
; LODSB
; CMP AL, 0x00
; JE .end_of_string
; MOV BYTE [EBX], AL
; INC EBX
; JMP .loop
; .end_of_string:
; MOV BYTE [EBX], AL
; INC EBX
; MOV DWORD [heap_ptr], EBX
; POP EAX
; POP EBX
; POPF
; RET 



; reserved words
char: db "char", 0
integer: db "int", 0
if: db "if", 0
else: db "else", 0
do: db "do", 0
while: db "while", 0