[bits 32]

%define numeric_value 0x1000_0058
%define op_tag 0x1000_0060
%define peek 0x1000_0004

; struct lexer_state 
;{
    ; char* buffer_addr; 
    ; int* pointer;
    ; builder* str_builder_ptr
    ; table* table_ptr
    ; int* line
    ; bool* type_detect
    ; bool* func_detect
;}

; VARIABLES
; peek - [ebp - 4]
; numerical_value - [ebp - 8]
; op_tag - [ebp - 12]
; lexem_size - [ebp - 16]
; char* buffer_addr - [ebp - 20]
; int* pointer - [ebp - 24]
; builder* str_builder_ptr - [ebp - 28]
; table* table_ptr - [ebp - 32]
; int* line - [ebp - 36]
; type_detect - [ebp - 40]
; func_detect - [ebp - 44]
; lexeme - [ebp - 48]
; token - [ebp - 52]
; char* - [ebp - 56]
; LEXER
; token* lexer_get_token(lexer_state* state)
lexer_get_token:
push ebp 
mov ebp, esp 
sub esp, 56
; init variables
; peek - [ebp - 4]
; numerical_value - [ebp - 8]
; op_tag - [ebp - 12]
mov dword [ebp - 4], 0
mov dword [ebp - 16], 0     ; lexeme_size = 0 
mov eax, dword [ebp + 8]
mov edx, dword [eax]
mov dword [ebp - 20], edx   ; buffer_addr = state.buffer_addr
mov edx, dword [eax + 4]
mov dword [ebp - 24], edx   ; pointer = state.pointer
mov edx, dword [eax + 8]
mov dword [ebp - 28], edx   ; str_builder_ptr = state.str_builder_ptr
mov edx, dword [eax + 12]   
mov dword [ebp - 32], edx   ; table_ptr = state.table_ptr
mov edx, dword [eax + 16]
mov dword [ebp - 36], edx   ; line = state.line
mov edx, dword [eax + 20]
mov dword [ebp - 40], edx   ; type_detect = state.type_detect
mov edx, dword [eax + 24]   
mov dword [ebp - 44], edx   ; func_detect = state.func_detect
.continue:
; filter ' ', '\r', '\t'
; inc line if peek == '\n'
; get next character 
push dword [ebp - 24]
push dword [ebp - 20]
call get_char
add esp, 8
mov byte [ebp - 4], al ; peek = get_char()
; if (peek is eof) end lexing
cmp byte [ebp - 4], EOF 
jne .no_end
push EOF_k
push EOF 
call get_token
add esp, 8 
leave
ret
.no_end:
; if (peek == ' ' || peek == '\r' || peek == '\t') continue
cmp byte [ebp - 4], 0x20
je .continue 
cmp byte [ebp - 4], 0x0D
je .continue
cmp byte [ebp - 4], 0x09
je .continue
; else if (peek == '\n') line++;
cmp byte [ebp - 4], 0x0A
jne .end_loop
; else break
mov eax, dword [ebp - 36]
inc dword [eax]
jmp .continue
.end_loop:
; else if (peek is a digit)
push dword [ebp - 4]
call is_a_digit
add esp, 4
cmp eax, 0
je .not_a_digit
mov dword [ebp - 8], 0        ; v = 0;
.get_integer:
; v = v * 10 + to_digit(peek)
mov edx, dword [ebp - 8]
mov eax, edx                        ; y = v
shl eax, 2                          ; y *= 4 => y = 4v
add eax, edx                        ; y += x => y = 5v
add eax, eax                        ; y += y => y = 10v
movsx edx, byte [ebp - 4]           ; load peek
sub edx, 0x30                       ; to_digit(peek)
add eax, edx                        ; y += to_digit(peek) 
mov dword [ebp - 8], eax            ; v = y
push dword [ebp - 24]
push dword [ebp - 20]
call get_char
add esp, 8
mov byte [ebp - 4], al              ; peek = get_char()
push dword [ebp - 4]
call is_a_digit
add esp, 4
cmp eax, 0
je .ret_integer_token
jmp .get_integer
.ret_integer_token:
push dword [ebp - 24]
call retract
add esp, 4
; return new num token <tag, val>
push dword [ebp - 8]
push NUM 
call get_token
add esp, 8
leave
ret
.not_a_digit:
push dword [ebp - 4]
call is_a_letter
add esp, 4
cmp eax, 0 
je .not_a_letter
.get_word:
lea eax, dword [ebp - 16]
push eax 
push dword [ebp - 28]    
push dword [ebp - 4]                    ; load current char
call string_builder_append              ; add to current buffer
add esp, 12
push dword [ebp - 24]
push dword [ebp - 20]
call get_char                           ; load next char
add esp, 8
mov byte [ebp - 4], al
push dword [ebp - 4]
call is_a_letter
add esp, 4
cmp eax, 1
je .get_word
push dword [ebp - 4]
call is_a_digit
add esp, 4
cmp eax, 1
je .get_word
.ret_word_token:
push dword [ebp - 24]
call retract                            ; rectact pointer
add esp, 4
; fetch string from string_builder
push dword [ebp - 16] 
push dword [ebp - 28]  
call string_builder_to_string
add esp, 8
mov dword [ebp - 48], eax
; check if lexeme present in symbol_table
push dword [ebp - 48]
push dword [ebp - 32]
call hash_map_get
add esp, 8
mov dword [ebp - 52], eax   ; save the return token
cmp eax, 0 
je .init_new_token
mov eax, dword [ebp - 52]
cmp dword [eax], TYPEDEF
jne .check_func_decl
mov eax, dword [ebp - 40]
mov dword [eax], 1          ; set type_detect flag to true
jmp .new_decl_check
.check_func_decl:
mov eax, dword [ebp - 52]
cmp dword [eax], FUNC
jne .new_decl_check
mov eax, dword [ebp - 44]   ; set func_detect flag to true
mov dword [eax], 1
.new_decl_check:
; if not null return the token
; string_builder clean up
lea eax, dword [ebp - 16]
push eax 
push dword [ebp - 28]
call string_builder_clear
add esp, 8
mov eax, dword [ebp - 52]
; flags cleanup
cmp dword [eax], TYNAME
jne .check_funcname
mov eax, dword [ebp - 40]
mov dword [eax], 0
jmp .exit
.check_funcname:
cmp dword [eax], FUNCNAME
jne .exit
mov eax, dword [ebp - 44]
mov dword [eax], 0
.exit
mov eax, dword [ebp - 52]
leave 
ret 
.init_new_token:
mov eax, dword [ebp - 40]
cmp dword [eax], 1          ; check if type_detect flag is set
jne .no_type_name
push dword [ebp - 48]
push TYNAME
call get_token 
add esp, 8
mov dword [ebp - 52], eax 
mov eax, dword [ebp - 40]
mov dword [eax], 0          ; reset flag
jmp .post_name_promotion
.no_type_name:
mov eax, dword [ebp - 44]
cmp dword [eax], 1          ; check if func_detect flag is set
jne .no_func_name
push dword [ebp - 48]
push FUNCNAME
call get_token 
add esp, 8
mov dword [ebp - 52], eax 
mov eax, dword [ebp - 44]
mov dword [eax], 0          ; reset flag
jmp .post_name_promotion
.no_func_name:
push dword [ebp - 48]
push NAME
call get_token
add esp, 8
mov dword [ebp - 52], eax 
.post_name_promotion:
push dword [ebp - 52]
push dword [ebp - 48]
push dword [ebp - 32]
call hash_map_put
add esp, 12
; string_builder clean up
lea eax, dword [ebp - 16]
push eax 
push dword [ebp - 28]
call string_builder_clear
add esp, 8
mov eax, dword [ebp - 52]
leave 
ret 

.not_a_letter:
.get_operator: 
cmp byte [ebp - 4], 0x3C       ; '<'
jne .check1
mov eax, LE
mov dword [ebp - 56], le_op
jmp .check_equals
.check1:
cmp byte [ebp - 4], 0x3E       ; '>'
jne .check2
mov eax, GE
mov dword [ebp - 56], ge_op
jmp .check_equals
.check2:
cmp byte [ebp - 4], 0x3D       ; '='
jne .check3
mov eax, EQ
mov dword [ebp - 56], eq_op
jmp .check_equals
.check3:
cmp byte [ebp - 4], 0x21       ; '!'
jne .check4
mov eax, NE
mov dword [ebp - 56], ne_op
jmp .check_equals
.check4:
cmp byte [ebp - 4], 0x26       ; '&'
jne .check5
mov eax, AND_OP
mov dword [ebp - 56], and_op
jmp .check_twin
.check5:
cmp byte [ebp - 4], 0x7C       ; '|'
jne .not_an_operator
mov eax, OR_OP
mov dword [ebp - 56], or_op
jmp .check_twin
.check_equals:
mov dword [ebp - 12], eax 
push dword [ebp - 24]
push dword [ebp - 20]
call get_char
add esp, 8
cmp eax, 0x3D       ; '='
jne .no_equals
; <=. >=, == 
mov eax, dword [ebp - 12]
push dword [ebp - 56]
push eax
call get_token
add esp, 8
leave
ret 
.no_equals:
push dword [ebp - 24]
call retract
add esp, 4
cmp byte [ebp - 4], 0x3C ; <
jne .check_gt
mov dword [ebp - 56], lt_op
mov eax, LT
jmp .end_tag_check
.check_gt:
cmp byte [ebp - 4], 0x3E ; >
jne .not_an_operator
mov dword [ebp - 56], gt_op
mov eax, GT
.end_tag_check:
push dword [ebp - 56]
push eax 
call get_token
add esp, 8
leave
ret
.check_twin:
mov dword [ebp - 12], eax
push dword [ebp - 24]
push dword [ebp - 20]
call get_char
add esp, 8
mov ah, byte [ebp - 4]
cmp al, ah 
jne .not_a_twin
mov eax, dword [ebp - 12]
push dword [ebp - 56]
push eax
call get_token
add esp, 8
leave
ret 
.not_a_twin:
push dword [ebp - 24]
call retract
add esp, 4
mov eax, dword [ebp - 4]
push 0
push eax 
call get_token
add esp, 8
leave 
ret
.not_an_operator:
mov eax, dword [ebp - 4]
push 0 
push eax
call get_token
add esp, 8
leave
ret

type_msg: db 'getting new type_name', 10, 0