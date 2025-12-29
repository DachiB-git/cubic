; void generator(Tree_Node* parse_tree, table* var_table, table* func_table)
generator:
push ebp
mov ebp, esp
sub esp, 8
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]    ; load VaDS
.gm_loop:
cmp dword [eax + 8], 0
je .no_variables_in_gm
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]
mov dword [ebp - 4], edx
mov eax, dword [eax + 12]   ; load VaD
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]    ; load Na
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
push eax
push dword [ebp + 12]
call hash_map_get
add esp, 8
push eax
call generate_var
add esp, 4
mov eax, dword [ebp - 4]
jmp .gm_loop
.no_variables_in_gm:
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]    ; load FuDS
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]
mov dword [ebp - 4], edx    ; save RFuDS
mov eax, dword [eax + 12]
mov dword [ebp - 8], eax    ; save func_node
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax
push dword [ebp + 16]
call hash_map_get
add esp, 8
push eax 
push dword [ebp - 8]
call generate_func
add esp, 8
leave
ret


; void generate_var(entry* var)
generate_var:
push ebp
mov ebp, esp
sub esp, 4
mov dword [ebp - 4], eax
push dword [eax]
call print_string
add esp, 4
push colon_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push zero_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
mov eax, dword [ebp - 4]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
push 10
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
leave
ret

; void generate_func(Tree_node* func_node, entry* func)
generate_func:
push ebp
mov ebp, esp
push dword [ebp + 12]
push dword [ebp + 8]
call generate_prologue
add esp, 8
push dword [ebp + 12]
call generate_body
add esp, 4
call generate_epilogue
leave
ret

; void generate_epilogue(Tree_node* func_node, entry* func)
generate_prologue:
push ebp
mov ebp, esp
sub esp, 12
mov dword [ebp - 8], 0      ; reset stack offset counter
mov eax, dword [ebp + 12]
mov eax, dword [eax + 8]
mov dword [ebp - 12], eax   ; load func var_table
mov eax, dword [ebp + 12]
push dword [eax]
call print_string
add esp, 4
push colon_k
call print_string
add esp, 4
push nl
call print_string
add esp, 4
push push_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push ebp_k
call print_string
add esp, 4
push nl
call print_string
add esp, 4
push mov_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push ebp_k
call print_string
add esp, 4
push comma_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push esp_k
call print_string
add esp, 4
push nl
call print_string
add esp, 4
; generate stack frame vars
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 32]   ; load VaDS
.var_loop:
cmp dword [eax + 8], 0
je .no_variables_in_func
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]
mov dword [ebp - 4], edx
mov eax, dword [eax + 12]   ; load VaD
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]    ; load Na
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
push eax
push dword [ebp - 12]
call hash_map_get
add esp, 8
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
cmp eax, 4
jge .no_pad
add eax, 3
.no_pad:
add dword [ebp - 8], eax
mov eax, dword [ebp - 4]
jmp .var_loop
.no_variables_in_func:
cmp dword [ebp - 8], 0
jne .gen_frame_vars
jmp .vars_generated
.gen_frame_vars:
push sub_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push esp_k
call print_string
add esp, 4
push comma_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push 10
push itoa_buffer
push dword [ebp - 8]
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push nl
call print_string
add esp, 4
.vars_generated:
leave
ret

; void generate_body(entry* func_entry)
generate_body:
push ebp
mov ebp, esp
sub esp, 20
; ebp - 4   |   TAC_list
; ebp - 8   |   return quad
; ebp - 12  |   return operand quad
; ebp - 16  |   func var_table
; ebp - 20  |   char* buffer
mov eax, dword [ebp + 8]
mov eax, dword [eax + 8]
mov dword [ebp - 16], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 16]   ; load TAC_list
mov eax, dword [eax + 4]    ; load nodes after START flag
mov dword [ebp - 4], eax    ; save TAC_list
mov eax, dword [ebp - 4]
mov eax, dword [eax]        ; load quad
cmp dword [eax], RETURN
jne .next
; translate return statement
mov dword [ebp - 8], eax    ; save return quad
mov eax, dword [eax + 4]    ; load quad
mov dword [ebp - 12], eax   ; save operand quad
cmp dword [eax], ID
je .gen_id
cmp dword [eax], NUM
je .gen_num
cmp dword [eax], BOOL
je .gen_bool
jmp .next
.gen_id:
mov eax, dword [eax + 4]    ; get var_entry
push dword [eax]
push dword [ebp - 16]
call hash_map_get
add esp, 8
cmp eax, 0
je .var_in_gm
.var_in_frame:
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]   ; operand size in bytes
mov edx, dword [ebp + 8]
mov edx, dword [edx + 4]
mov edx, dword [edx + 12]   ; func return type size in bytes
cmp edx, eax
jg .expand
cmp edx, eax
je .check_char
jmp .regular_ret
.expand:
push movsx_k
call print_string
add esp, 4
mov dword [ebp - 20], byte_k
jmp .gen_rest
.check_char:
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]
cmp dword [eax + 4], PRIMITIVE
jne .regular_ret
cmp dword [eax + 8], CHAR
je .char_or_bool
cmp dword [eax + 8], BOOL
je .char_or_bool
jmp .regular_ret
.char_or_bool:
push movzx_k
call print_string
add esp, 4
mov dword [ebp - 20], byte_k
jmp .gen_rest
.regular_ret:
push mov_k
call print_string
add esp, 4
mov dword [ebp - 20], dword_k
.gen_rest:
push space
call print_string
add esp, 4
push eax_k
call print_string
add esp, 4
push comma_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push dword [ebp - 20]
call print_string
add esp, 4
push space
call print_string
add esp, 4
push left_bracket
call print_string
add esp, 4
push ebp_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push minus_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 8]
push 10
push itoa_buffer
push eax
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push right_bracket
call print_string
add esp, 4
push nl
call print_string
add esp, 4
jmp .exit

.var_in_gm:


.gen_num:
push mov_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push eax_k
call print_string
add esp, 4
push comma_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]
push 10
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
jmp .exit

.gen_bool:
push mov_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
push eax_k
call print_string
add esp, 4
push comma_k
call print_string
add esp, 4
push space
call print_string
add esp, 4
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]
push 10
push itoa_buffer
push eax
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
xor eax, eax
jmp .false
.true:
mov eax, 1
.false:
push 10
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


.next:
.exit:
leave
ret

; void generate_prologue()
generate_epilogue:
push ebp
mov ebp, esp
push leave_k
call print_string
add esp, 4
push nl
call print_string
add esp, 4
push ret_k
call print_string
add esp, 4
push nl
call print_string
add esp, 4
leave
ret

; sizes
byte_k: db "byte", 0
word_k: db "word", 0
dword_k: db "dword", 0
; misc
zero_k: db ".zero", 0
minus_k: db "-", 0
; registers
eax_k: db "eax", 0
ebp_k: db "ebp", 0
esp_k: db "esp", 0
; operations
push_k: db "push", 0
mov_k: db "mov", 0
movsx_k: db "movsx", 0
movzx_k: db "movzx", 0
sub_k: db "sub", 0
add_k: db "add", 0
leave_k: db "leave", 0
ret_k: db "ret", 0