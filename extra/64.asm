section .data

text1 db "base" , 10
text2 db "power" , 10
buffer db 0 , 10
section .bss
num1 resb 5
num2 resb 5
section .text
global _start:
_start:
call _ft
call _fi
call _st
call _si
call _output

mov rax,60
syscall

_output:

mov eax, [num1]
sub eax, 0x30
        mov edx, [num2]
sub edx, 0x30
mul edx
add eax, 0x30
mov rcx, rax
mov byte [buffer], al
mov rax, 1
mov rdi, 1
mov rsi, buffer
mov rdx, 4
syscall

ret

_ft:
mov rax, 1
mov rdi, 1
mov rsi, text1
mov rdx, 5
syscall
ret


_st:
        mov rax, 1
        mov rdi, 1
        mov rsi, text2
        mov rdx, 6
        syscall
        ret

_fi:
        mov rax, 0
        mov rdi, 0
        mov rsi, num1
        mov rdx, 4
        syscall
        ret


_si:
        mov rax, 0
        mov rdi, 0
        mov rsi, num2
        mov rdx, 4
        syscall
        ret

_int_to_string_base_10:
pushf
PUSH EAX
PUSH ECX
PUSH EDX
PUSH EBX
MOV EDI, EBX
MOV EAX, ECX
MOV EBX, 10
_loop:
CMP EAX, 0x00
JE .exit_loop
CDQ
IDIV EBX
PUSH EAX
MOV EAX, EDX
ADD EAX, 0x30          
STOSB
POP EAX
JMP .loop
_exit_loop:
MOV BYTE [EDI], 0x00    
DEC DWORD EDI          
POP EBX
PUSH EBX
STD        
_rev_loop:
CMP EBX, EDI
JG .exit_rev_loop
MOV BYTE DL, [EBX]    
MOV BYTE DH, [EDI]
MOV BYTE [EBX], DH
MOV BYTE [EDI], DL
DEC DWORD EDI
INC DWORd EBX
JMP .rev_loop
_exit_rev_loop:


POP EBX
POP EDX
POP ECX
POP EAX
POPF
RET