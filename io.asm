[bits 32]

; loads a char from the mem[drive_read_buffer + pointer] into al
; and increments the passed pointer
; char get_char(char* buffer_addr, int* pointer)
get_char:
push ebp 
mov ebp, esp 
mov eax, dword [ebp + 8]
mov edx, dword [ebp + 12]
add eax, dword [edx]
mov al, byte [eax]
movsx eax, al
mov edx, dword [ebp + 12]
inc dword [edx] 
leave
ret 

; peek at the next character, without incrementing the pointer
peek_char:
push ebx 
add ebx, [ecx]
mov al, byte [ebx]
pop ebx
ret

; decrement buffer pointer in ecx
retract:
push ebp 
mov ebp, esp 
mov eax, dword [ebp + 8]
dec dword [eax]
leave
ret