[bits 32]

%define BUFFER_CAPACITY 256
%define DECORATOR_CAPACITY 128
%define REG_EAX 0
%define REG_EDX 1
%define REG_ECX 2
%define REG_QUAD -2
%define ADDR_QUAD -3
%define DUAL_QUAD -4
%define CONST_ADDR -5
%define ARRAY_QUAD -6
%define CONST_OR_STACK_ADDR 0
%define GM_ADDR 1

; OPERATION ROUTINE IDS
; 0 -> intermediate op intermediate
; 1 -> intermediate op constant
; 2 -> intermediate op operand
; 3 -> operand op constant
; 4 -> operand op operand
%define ROUTINE_INTERMEDIATES 0
%define ROUTINE_INTERMEDIATE_CONSTANT 1
%define ROUTINE_INTERMEDIATE_OPERAND 2
%define ROUTINE_OPERAND_CONSTANT 3
%define ROUTINE_OPERANDS 4

; LOAD ROUTINE IDS
; 0 -> mov register, [operand]           
; 1 -> mov register, [register]          
; 2 -> mov register, [register+offset]   
; 3 -> mov [operand], register       
; 4 -> mov [operand], constant    
%define LOAD_ROUTINE_REGISTER_OPERAND 0
%define LOAD_ROUTINE_REGISTER_REGISTER 1
%define LOAD_ROUTINE_REGISTER_DUAL 2
%define LOAD_ROUTINE_DUAL_CONSTANT 3
%define LOAD_ROUTINE_OPERAND_REGISTER 4  
%define LOAD_ROUTINE_OPERAND_CONSTANT 5

; void generator(Tree_Node* parse_tree, table* var_table, table* func_table, table* type_table)
generator:
push ebp
mov ebp, esp
sub esp, 20
push 16
push 4
call get_hash_map
add esp, 8
mov dword [ebp - 12], eax
mov dword [ebp - 16], 0     ; counter for string_pool
push integer_k
push dword [ebp + 20]
call hash_map_get
add esp, 8
mov dword [reg_quad + 12], eax
mov dword [num_quad + 12], eax
push uinteger_k
push dword [ebp + 20]
call hash_map_get
add esp, 8
mov dword [unsigned_reg_quad + 12], eax
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
mov dword [ebp - 4], eax
.loop:
mov eax, dword [ebp - 4]
cmp dword [eax + 8], 0
je .exit_loop
mov eax, dword [ebp - 4]
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]
mov dword [ebp - 4], edx    ; save RFuDS
mov eax, dword [eax + 12]
mov dword [ebp - 8], eax    ; save func_node
mov eax, dword [ebp - 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax
push dword [ebp + 16]
call hash_map_get
add esp, 8
mov dword [ebp - 20], eax
lea eax, dword [ebp - 16]
push eax
push dword [ebp - 12]
push dword [ebp - 20]
call generate_strings
add esp, 12
push dword [ebp - 20] 
push dword [ebp - 8]
call generate_func
add esp, 8
jmp .loop
.exit_loop:
leave
ret

; ; new generator
; generator:
; push ebp
; mov ebp, esp
; sub esp, 20
; push 16
; push 4
; call get_hash_map
; add esp, 8
; mov dword [ebp - 12], eax
; mov dword [ebp - 16], 0     ; counter for string_pool
; push integer_k
; push dword [ebp + 20]
; call hash_map_get
; add esp, 8
; mov dword [reg_quad + 12], eax
; mov dword [num_quad + 12], eax
; push uinteger_k
; push dword [ebp + 20]
; call hash_map_get
; add esp, 8
; mov dword [unsigned_reg_quad + 12], eax
; mov eax, dword [ebp + 8]
; mov eax, dword [eax + 12]
; mov eax, dword [eax + 4]    ; load VaDS
; .gm_loop:
; cmp dword [eax + 8], 0
; je .no_variables_in_gm
; mov edx, dword [eax + 12]
; mov edx, dword [edx + 4]
; mov dword [ebp - 4], edx
; mov eax, dword [eax + 12]   
; mov eax, dword [eax]        ; load VaD
; mov eax, dword [eax + 12]   
; mov eax, dword [eax + 8]    ; load Na
; mov eax, dword [eax + 4]    ; load token
; mov eax, dword [eax + 4]    ; load lexeme
; push eax
; push dword [ebp + 12]
; call hash_map_get
; add esp, 8
; push eax
; call generate_var
; add esp, 4
; mov eax, dword [ebp - 4]
; jmp .gm_loop
; .no_variables_in_gm:
; mov eax, dword [ebp + 8]
; mov eax, dword [eax + 12]
; mov eax, dword [eax + 8]    ; load FuDS
; mov dword [ebp - 4], eax
; .loop:
; mov eax, dword [ebp - 4]
; cmp dword [eax + 8], 0
; je .exit_loop
; mov eax, dword [ebp - 4]
; mov edx, dword [eax + 12]
; mov edx, dword [edx + 4]
; mov dword [ebp - 4], edx    ; save RFuDS
; mov eax, dword [eax + 12]
; mov eax, dword [eax]
; mov dword [ebp - 8], eax    ; save func_node
; mov eax, dword [ebp - 8]
; mov eax, dword [eax + 12]
; mov eax, dword [eax + 12]
; mov eax, dword [eax + 4]
; mov eax, dword [eax + 4]
; push eax
; push dword [ebp + 16]
; call hash_map_get
; add esp, 8
; mov dword [ebp - 20], eax
; lea eax, dword [ebp - 16]
; push eax
; push dword [ebp - 12]
; push dword [ebp - 20]
; call generate_strings
; add esp, 12
; push dword [ebp - 20] 
; push dword [ebp - 8]
; call generate_func
; add esp, 8
; jmp .loop
; .exit_loop:
; leave
; ret

; void generate_var(entry* var)
generate_var:
push ebp
mov ebp, esp
sub esp, 4
mov eax, dword [ebp + 8]
push dword [eax]
call print_string_raw
add esp, 4
push colon_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push resb_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
push 10
push itoa_buffer
push eax 
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
leave
ret

; void generate_func(Tree_node* func_node, entry* func, char* buffer)
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

; void generate_strings(entry* func_entry, table* string_pool, int* counter)
generate_strings:
push ebp
mov ebp, esp
sub esp, 20
mov dword [ebp - 4], 0      ; before TAC node
mov dword [ebp - 8], 0      ; current TAC node
mov dword [ebp - 12], 0     ; char*
mov dword [ebp - 16], 0     ; token
mov dword [ebp - 20], 0     ; quad*
mov eax, dword [ebp + 8]
mov eax, dword [eax + 16]
mov dword [ebp - 8], eax
.tac_loop:
cmp dword [ebp - 8], 0
je .no_strings_left
mov eax, dword [ebp - 8]
mov eax, dword [eax]
cmp dword [eax], STR_QUAD
jne .continue
.get_string_label:
mov dword [ebp - 20], eax
mov eax, dword [eax + 4]
mov dword [ebp - 12], eax
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
mov dword [ebp - 16], eax
cmp dword [ebp - 16], 0
je .add_string_to_pool
mov eax, dword [eax + 4]
mov edx, dword [ebp - 20]
mov dword [edx + 8], eax
jmp .remove_str_quad
.add_string_to_pool:
push str_label
call print_string_raw
add esp, 4
push 10
push itoa_buffer
mov eax, dword [ebp + 16]
push dword [eax]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push colon_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push db_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push back_quote_k
call print_string_raw
add esp, 4
mov eax, dword [ebp - 20]
push dword [eax + 4]
call print_string_raw
add esp, 4
push back_quote_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push 0
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, dword [ebp + 16]
push dword [eax]
push STR_QUAD
call get_token
add esp, 8
push eax
mov eax, dword [ebp - 20]
push dword [eax + 4]
push dword [ebp + 12]
call hash_map_put
add esp, 12
mov eax, dword [ebp + 16]
mov eax, dword [eax]
mov edx, dword [ebp - 20]
mov dword [edx + 8], eax
mov eax, dword [ebp + 16]
inc dword [eax]
.remove_str_quad:
mov eax, dword [ebp - 4]
mov edx, dword [ebp - 8]
mov edx, dword [edx + 4]
mov dword [eax + 4], edx
mov dword [ebp - 8], edx
jmp .tac_loop
.continue:
mov eax, dword [ebp - 8]
mov dword [ebp - 4], eax
mov eax, dword [eax + 4]
mov dword [ebp - 8], eax
jmp .tac_loop
.no_strings_left:
leave
ret

; void generate_prologue(Tree_node* func_node, entry* func)
generate_prologue:
push ebp
mov ebp, esp
sub esp, 16
mov dword [ebp - 16], 0
mov dword [ebp - 8], 0      ; reset stack offset counter
mov eax, dword [ebp + 12]
mov eax, dword [eax + 8]
mov dword [ebp - 12], eax   ; load func var_table
mov eax, dword [ebp + 12]
push dword [eax]
call print_string_raw
add esp, 4
push colon_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push push_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ebp_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ebp_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push esp_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
; generate stack frame vars
; last variable offset is equal to the frame size
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 32]   ; load VaDS
.var_loop:
cmp dword [eax + 8], 0
je .no_variables_in_func
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]
mov dword [ebp - 4], edx
mov eax, dword [eax + 12]
mov dword [ebp - 16], eax
mov eax, dword [ebp - 4]
jmp .var_loop
.no_variables_in_func:
cmp dword [ebp - 16], 0
jne .gen_frame_vars
jmp .exit
.gen_frame_vars:
push sub_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push esp_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 16]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax
push dword [ebp - 12]
call hash_map_get
add esp, 8
mov eax, dword [eax + 8]
push 10
push itoa_buffer
push eax
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, dword [cursor_y_ptr]
mov dword [old_cursor_y], eax
mov eax, dword [cursor_x_ptr]
mov dword [old_cursor_x], eax
push nl
call print_string_raw
add esp, 4
.exit:
leave
ret



; TODO: write code in czr for an allocator
; TODO: rework free_register pointers to allocator logic
; void generate_body(entry* func_entry)
generate_body:
push ebp
mov ebp, esp
sub esp, 48
; ebp - 4   |   TAC_list
; ebp - 8   |   left_operand
; ebp - 12  |   right_operand
; ebp - 16  |   func var_table
; ebp - 20  |   char* buffer
; ebp - 24  |   free_register
; ebp - 28  |   free_register cache
; ebp - 32  |   operator quad buffer
; ebp - 36  |   quad buffer
; ebp - 40  |   quad buffer
; ebp - 44  |   buffer*
; ebp - 48  |   dual_quad_stak*
mov dword [ebp - 48], 0
push BUFFER_CAPACITY
call get_buffer
add esp, 4
mov dword [ebp - 44], eax
mov dword [ebp - 24], 0     ; initialize eax as first free register
mov eax, dword [ebp + 8]
mov eax, dword [eax + 8]
mov dword [ebp - 16], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 16]   ; load TAC_list
mov eax, dword [eax + 4]    ; load nodes after START flag
mov dword [ebp - 4], eax    ; save TAC_list
.tac_loop:
mov eax, dword [ebp - 24]   ; load last free_register
mov dword [ebp - 28], eax   ; save in cache
mov eax, dword [ebp - 4]
cmp eax, 0
je .exit
mov eax, dword [eax]        ; load quad
mov dword [ebp - 32], eax   ; save quad
mov eax, dword [ebp - 32]
mov eax, dword [eax + 4]
mov dword [ebp - 8], eax
mov eax, dword [ebp - 32]
mov eax, dword [eax + 8]
mov dword [ebp - 12], eax
mov eax, dword [ebp - 32]
cmp dword [eax], RETURN
je .RETURN
cmp dword [eax], ASSIG_OP
je .ASSIG_OP
cmp dword [eax], UNARY_MINUS_OP
je .UNARY_MINUS_OP
cmp dword [eax], NEG_OP
je .NEG_OP
cmp dword [eax], DEREF_OP
je .DEREF_OP
cmp dword [eax], ADDRESS_OP
je .ADDRESS_OP
cmp dword [eax], PLUS_OP
je .PLUS_OP
cmp dword [eax], MINUS_OP
je .MINUS_OP
cmp dword [eax], MUL_OP
je .MUL_OP
cmp dword [eax], DIV_OP
je .DIV_OP
cmp dword [eax], IF
je .IF
cmp dword [eax], GOTO
je .GOTO
cmp dword [eax], COND_GOTO
je .COND_GOTO
cmp dword [eax], LABEL
je .LABEL
cmp dword [eax], LABEL_TRUE
je .LABEL_TRUE
cmp dword [eax], LABEL_FALSE
je .LABEL_FALSE
cmp dword [eax], AND_OP
je .AND_OP
cmp dword [eax], OR_OP
je .OR_OP
cmp dword [eax], PARAM
je .PARAM
cmp dword [eax], CALL
je .CALL
cmp dword [eax], ASM_QUAD
je .ASM_QUAD
jmp .other
.RETURN:
; translate return statement
cmp dword [ebp - 24], 0
jne .free_register
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 8]
push reg_quad
call load
add esp, 20
.free_register:
mov dword [ebp - 24], 0
jmp .load_next_quad

.ASSIG_OP:
; addr = op
mov dword [ebp - 20], mov_k
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 12]
push dword [ebp - 8]
push dword [ebp - 32]
push dword [ebp - 20]
call generate_assignment_operation
add esp, 28
mov dword [ebp - 24], 0 ; reset free_register to eax
jmp .load_next_quad

; TODO: fix negating intermediates
.UNARY_MINUS_OP:
mov dword [ebp - 20], neg_k
push dword [ebp - 8]
call allocate_operand
add esp, 4
cmp eax, 0
je .negate_constant
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 8]
push reg_quad
call load
add esp, 20
push neg_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 28]
mov eax, dword [registers + eax * 4]
push eax
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .load_next_quad
.negate_constant:
mov eax, dword [ebp - 32]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
neg eax
mov edx, dword [ebp - 32]
mov dword [edx + 4], eax
mov dword [edx], NUM
mov eax, dword [ebp - 44]
mov byte [eax], 0
jmp .load_next_quad


.NEG_OP:
mov eax, dword [ebp - 32]
mov eax, dword [eax + 4]
mov dword [ebp - 8], eax
push dword [ebp - 8]
push dword [ebp - 8]
push dword [ebp - 32]
call resolve_constants
add esp, 12
cmp eax, 1
je .load_next_quad
push dword [ebp - 8]
push dword [ebp - 8]
call get_complex_operand
add esp, 8
cmp eax, 0
je .determine_neg_op
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 8]
push reg_quad
call load
add esp, 20
.determine_neg_op:
mov eax, dword [ebp - 8]
mov eax, dword [eax + 12]
cmp dword [eax + 4], PRIMITIVE
jne .negate_operand
cmp dword [eax + 8], BOOL
jne .negate_operand
.negate_bool_operand:
push xor_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 1
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .load_next_quad
.negate_operand:
push cmp_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 0
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push sete_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
dec eax
push eax
push dword [ebp - 32]
call morph_register
add esp, 8
push eax
call print_line_raw
add esp, 4
push movzx_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
dec eax
push eax
push dword [ebp - 32]
call morph_register
add esp, 8
push eax
call print_line_raw
add esp, 4
jmp .load_next_quad

.DEREF_OP:
push dword [ebp - 8]
push dword [ebp - 8]
call get_complex_operand
add esp, 8
cmp eax, 0
jne .operand_deref 
.intermediate_deref:
mov eax, dword [ebp - 32]
mov eax, dword [eax + 12]
mov dword [loaded_reg_quad + 12], eax
push dword [ebp - 16]
dec dword [ebp - 24]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push loaded_reg_quad
push unsigned_reg_quad
call load
add esp, 20
inc dword [ebp - 24]
jmp .load_next_quad

.operand_deref:
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 8]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp - 32]
mov eax, dword [eax + 12]
mov dword [loaded_reg_quad + 12], eax
push dword [ebp - 16]
dec dword [ebp - 24]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push loaded_reg_quad
push unsigned_reg_quad
call load
add esp, 20
inc dword [ebp - 24]
jmp .load_next_quad

.ADDRESS_OP:
mov dword [ebp - 20], lea_k
; push dword [ebp - 16]
; push dword [ebp - 8]
; push dword [ebp - 32]
; call upgrade_to_addr_quad
; add esp, 12
; cmp eax, 0
; je .load_next_quad
push dword [ebp - 20]
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
push dword [ebp - 44]
push dword [ebp - 16]
push dword [ebp - 8]
call generate_operand
add esp, 12
push dword [ebp - 44]
call flush_buffer
add esp, 4
push right_bracket
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
inc dword [ebp - 24]
jmp .load_next_quad

.MUL_OP:
mov dword [ebp - 20], imul_k
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 12]
push dword [ebp - 8]
push dword [ebp - 32]
push dword [ebp - 20]
call generate_arithmetic_binary_operation
add esp, 28
jmp .load_next_quad

.DIV_OP:
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 12]
push dword [ebp - 8]
push dword [ebp - 32]
push 0
call generate_arithmetic_binary_operation
add esp, 28
jmp .load_next_quad

.MINUS_OP:
mov dword [ebp - 20], sub_k
jmp .gen_plus_or_minus
.PLUS_OP:
mov dword [ebp - 20], add_k
.gen_plus_or_minus:
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 12]
push dword [ebp - 8]
push dword [ebp - 32]
push dword [ebp - 20]
call generate_arithmetic_binary_operation
add esp, 28
jmp .load_next_quad


.IF:
jmp .load_next_quad

.GOTO:
push jmp_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push label_k
call print_string_raw
add esp, 4
push dword [ebp - 8]
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .load_next_quad

.COND_GOTO:
mov eax, dword [ebp - 32]
mov eax, dword [eax + 12]
cmp dword [eax + 8], UCHAR
jge .unsigned_branch
.signed_branch:
mov eax, dword [ebp - 8]
sub eax, LT
push dword [branch_ops_signed + eax * 4]
call print_string_raw
add esp, 4
jmp .end_sign_check
.unsigned_branch:
mov eax, dword [ebp - 8]
sub eax, LT
push dword [branch_ops_unsigned + eax * 4]
call print_string_raw
add esp, 4
.end_sign_check:
push space
call print_string_raw
add esp, 4
push label_k
call print_string_raw
add esp, 4
push dword [ebp - 12]
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .load_next_quad

.LABEL:
push label_k
call print_string_raw
add esp, 4
push dword [ebp - 8]
call print_number_raw
add esp, 4
push colon_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .load_next_quad

.LABEL_TRUE:
push label_k
call print_string_raw
add esp, 4
push dword [ebp - 8]
call print_number_raw
add esp, 4
push colon_k
call print_line_raw
add esp, 4
inc dword [ebp - 24]
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 1
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .load_next_quad


.LABEL_FALSE:
push label_k
call print_string_raw
add esp, 4
push dword [ebp - 8]
call print_number_raw
add esp, 4
push colon_k
call print_line_raw
add esp, 4
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 0
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push label_k
call print_string_raw
add esp, 4
push dword [ebp - 12]
call print_number_raw
add esp, 4
push colon_k
call print_line_raw
add esp, 4
jmp .load_next_quad

.AND_OP:
.OR_OP:
jmp .load_next_quad

.PARAM:
mov dword [ebp - 20], push_k
cmp dword [ebp - 24], 0
je .push_other
.push_register:
push dword [ebp - 20]
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 24]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov dword [ebp - 24], 0
jmp .load_next_quad

.push_other:
mov eax, dword [ebp - 8]
cmp dword [eax], id
je .push_operand
cmp dword [eax], ADDR_QUAD
je .push_operand
jmp .push_constant
.push_operand:
mov eax, dword [ebp - 8]
mov eax, dword [eax + 12]
cmp dword [eax + 4], ARRAY
je .load_param
cmp dword [eax + 12], 4
jl .load_param
jmp .dword_size
.load_param:
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 8]
push reg_quad
call load
add esp, 20
jmp .push_register
.no_array:
.dword_size:
push dword [ebp - 44]
push dword [ebp - 16]
push dword [ebp - 8]
call generate_operand
add esp, 12
push dword [ebp - 20]
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp - 8]
call get_size_prefix
add esp, 4
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
push dword [ebp - 44]
call flush_buffer
add esp, 4
push right_bracket
call print_line_raw
add esp, 4
mov dword [ebp - 24], 0
jmp .load_next_quad

.push_constant:
push dword [ebp - 44]
push dword [ebp - 16]
push dword [ebp - 8]
call generate_operand
add esp, 12
push dword [ebp - 20]
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp - 44]
call flush_buffer
add esp, 4
push nl
call print_string_raw
add esp, 4
mov dword [ebp - 24], 0
jmp .load_next_quad

.ASM_QUAD:
push dword [ebp - 8]
call print_line_raw
add esp, 4
jmp .load_next_quad

.CALL:
mov dword [ebp - 20], call_k
push dword [ebp - 20]
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 8]
push dword [eax]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push add_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push esp_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp - 8]
mov eax, dword [eax + 12]
push eax
call linked_list_size
add esp, 4
sal eax, 2
push 10
push itoa_buffer
push eax
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
cmp dword [ebp - 12], 0
je .load_next_quad
mov dword [ebp - 24], 1
jmp .load_next_quad

; .TYPE_CAST_OP:
; push not_implemented
; call print_line_raw
; add esp, 4
; jmp .load_next_quad

.other:
mov eax, dword [ebp - 32]
cmp dword [eax], ACCESS_OP
jl .logic_quad
cmp dword [eax], LT
jge .logic_quad
.selectors:
lea eax, dword [ebp - 48]
push eax
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 32]
call handle_selector
add esp, 20
jmp .load_next_quad

.logic_quad:
push dword [ebp - 16]
lea eax, dword [ebp - 24]
push eax
push dword [ebp - 44]
push dword [ebp - 12]
push dword [ebp - 8]
push dword [ebp - 32]
push dword [ebp - 4]
call generate_logical_binary_operation
add esp, 28
jmp .load_next_quad


.load_next_quad:
mov eax, dword [ebp - 4]
mov eax, dword [eax + 4]
mov dword [ebp - 4], eax
jmp .tac_loop

.exit:
leave
ret

; void generate_epilogue()
generate_epilogue:
push ebp
mov ebp, esp
cmp dword [non_scratch_reg_used], 1
jne .skip
push pop_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ebx_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
.skip:
push leave_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push ret_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
leave
ret

; void handle_selector(quad* op_quad, buffer* buffer, int* free_register, table* func_var_table, node* dual_quad_stack)
handle_selector:
push ebp
mov ebp, esp
sub esp, 16
mov dword [ebp - 4], 0
mov eax, dword [ebp + 8]
mov eax, dword [eax]
mov dword [ebp - 8], eax
cmp dword [ebp - 8], MEMBER_OP
jge .member_operation
jmp .access_operation
; access ops are a bit tricky since they also facilitate inline pointer derefrencing
; let us focus on array operations first
; all array operations generate a subscript and update the dual_quad
.access_operation:
; if pointer type left_operand, go over to deref routine
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
cmp dword [eax + 4], POINTER
je .inline_deref_operation
push dword [ebp - 8]
push dword [ebp + 24]
call get_top_dual_quad
add esp, 8
mov dword [ebp - 4], eax
mov eax, dword [ebp - 4]
cmp dword [eax + 12], 0
jne .skip_l_1
mov edx, dword [ebp + 8]
mov edx, dword [edx + 4]
mov dword [eax + 12], edx
.skip_l_1:
; main access operation
; mov eax, dword [ebp + 8]
; mov eax, dword [eax + 12]
; push dword [eax + 12]
push dword [ebp + 8]
push dword [ebp - 4]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
mov eax, dword [ebp + 8]
push dword [eax + 8]
call generate_array_subscript
add esp, 24
; ; scale the dual_quad
; mov eax, dword [ebp + 16]
; push dword [eax]
; push dword [ebp + 8]
; push dword [ebp - 4]
; call scale_dual_quad_data
; add esp, 12
; determine concrete access operation
cmp dword [ebp - 8], ACCESS_OP
je .exit
cmp dword [ebp - 8], FIRST_ACCESS_OP
je .exit
cmp dword [ebp - 8], LVAL_ACCESS_OP
je .create_addr_quad
mov eax, dword [ebp + 16]
mov eax, dword [eax]
mov edx, dword [ebp - 4]
mov edx, dword [edx + 8]
sub eax, edx
mov edx, dword [ebp + 16]
mov dword [edx], eax
jmp .create_addr_quad

.inline_deref_operation:
push dword [ebp - 8]
push dword [ebp + 24]
call get_top_dual_quad
add esp, 8
mov dword [ebp - 4], eax
mov eax, dword [ebp - 4]
cmp dword [eax + 12], 0
jne .skip_l_2
mov edx, dword [ebp + 8]
mov edx, dword [edx + 4]
mov dword [eax + 12], edx
.skip_l_2:
push dword [ebp - 4]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 8]
call generate_pointer_address
add esp, 20
cmp dword [ebp - 8], FIRST_ACCESS_OP
je .exit
cmp dword [ebp - 8], ACCESS_OP
je .exit
cmp dword [ebp - 8], LVAL_ACCESS_OP
je .lval_access_deref
jmp .load_quad
.lval_access_deref:
; set addr_quad
mov eax, dword [ebp + 8]
mov dword [eax], DUAL_QUAD
mov edx, dword [ebp - 4]
mov ecx, dword [edx + 8]
mov dword [eax + 8], ecx
mov edx, dword [edx + 4]
mov dword [eax + 4], edx
jmp .pop_stack

.lval_member_deref:
mov eax, dword [ebp - 4]
mov eax, dword [eax + 12]
cmp dword [eax], REG_QUAD
jne .pop_stack
mov eax, dword [ebp + 8]
mov dword [eax], DUAL_QUAD
mov edx, dword [ebp - 4]
mov ecx, dword [edx + 8]
mov dword [eax + 8], ecx
mov edx, dword [edx + 4]
mov dword [eax + 4], edx
jmp .pop_stack

.member_operation:
push dword [ebp - 8]
push dword [ebp + 24]
call get_top_dual_quad
add esp, 8
mov dword [ebp - 4], eax
mov eax, dword [ebp - 4]
cmp dword [eax + 12], 0
jne .skip_l
mov edx, dword [ebp + 8]
mov edx, dword [edx + 4]
mov dword [eax + 12], edx
.skip_l:
; main member operation
mov eax, dword [ebp + 8]
mov eax, dword [eax + 8]
mov eax, dword [eax + 8]
mov edx, dword [ebp - 4]
add dword [edx + 4], eax
; determinte concrete member operation
cmp dword [ebp - 8], MEMBER_OP
je .exit
cmp dword [ebp - 8], FIRST_MEMBER_OP
je .exit
; other operations create the addr_quad
; last_member_op and single_member_op load it, lval lets it be
mov eax, dword [ebp + 16]
mov eax, dword [eax]
mov edx, dword [ebp - 4]
mov edx, dword [edx + 8]
sub eax, edx
mov edx, dword [ebp + 16]
mov dword [edx], eax
jmp .create_addr_quad

.create_addr_quad:
mov eax, dword [ebp + 8]
mov edx, dword [ebp - 4]
mov dword [eax + 8], edx
mov edx, dword [edx + 12]
mov dword [eax + 4], edx
mov dword [eax], ADDR_QUAD
cmp dword [ebp - 8], LVAL_MEMBER_OP
je .lval_member_deref
cmp dword [ebp - 8], LVAL_ACCESS_OP
je .pop_stack
jmp .load_quad
; void handle_selector(quad* op_quad, buffer* buffer, int* free_register, table* func_var_table, node* dual_quad_stack)
.load_quad:
mov eax, dword [ebp - 4]
mov eax, dword [eax + 12]
cmp dword [eax], REG_QUAD
je .load_register
; load the addr_quad
.load_addr_quad:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
cmp dword [eax + 4], ARRAY
jne .skip_array_fix
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov dword [eax + 4], ARRAY_QUAD
.skip_array_fix:
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 8]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 8]
mov dword [eax], REG_QUAD

mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
cmp dword [eax + 4], ARRAY_QUAD
jne .skip_array_revert
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov dword [eax + 4], ARRAY
.skip_array_revert:
jmp .pop_stack
.load_register:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [ebp - 4]
mov dword [edx + 12], eax
mov eax, dword [ebp + 16]
dec dword [eax]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp - 4]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 8]
mov dword [eax], REG_QUAD
mov eax, dword [ebp + 16]
inc dword [eax]
jmp .pop_stack

.pop_stack:
mov eax, dword [ebp + 24]
mov eax, dword [eax]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 24]
mov dword [edx], eax
.exit:
leave
ret


; VARIANTS
; INLINE IDS
; 0 -> reg_sub and intermediate
; 1 -> reg_sub and operand
; 2 -> no_reg_sub and intermediate
; 3 -> no_reg_sub and operand

%define INLINE_ROUTINE_REG_INTERMEDIATE     0
%define INLINE_ROUTINE_REG_OPERAND          1
%define INLINE_ROUTINE_NO_REG_INTERMEDIATE  2
%define INLINE_ROUTINE_NO_REG_OPERAND       3


; void generate_pointer_address(quad* op_quad, buffer* buffer, int* free_register, table* func_var_table, quad* dual_quad)
generate_pointer_address:
push ebp
mov ebp, esp
sub esp, 24
mov dword [ebp - 4],    0  ; before flag
mov dword [ebp - 8],    0  ; after flag
mov dword [ebp - 12],   0  ; routine id
mov dword [ebp - 20],   0
mov eax, dword [ebp + 24]
mov eax, dword [eax + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 8]
push eax
push eax
call get_complex_operand
add esp, 8
mov dword [ebp - 8], eax
; cache current operation type
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov dword [ebp - 24], eax
; determine preload and postload operations
cmp dword [ebp - 4], 0
je .no_prev_sub
.yes_prev_sub:
cmp dword [ebp - 8], 0
je .prev_reg_sub_and_intermediate
jmp .prev_reg_sub_and_operand
.no_prev_sub:
cmp dword [ebp - 8], 0
je .no_prev_reg_sub_and_intermediate
jmp .no_prev_reg_sub_and_operand

.prev_reg_sub_and_operand:
mov eax, dword [ebp + 16]
push dword [eax]
push dword [ebp + 8]
push dword [ebp + 24]
call scale_dual_quad_data
add esp, 12
mov eax, dword [ebp + 16]
dec dword [eax]
mov dword [ebp - 12], INLINE_ROUTINE_REG_OPERAND
jmp .loading_sequence

.prev_reg_sub_and_intermediate:
mov eax, dword [ebp + 16]
dec dword [eax]
mov eax, dword [ebp + 16]
push dword [eax]
push dword [ebp + 8]
push dword [ebp + 24]
call scale_dual_quad_data
add esp, 12
mov eax, dword [ebp + 16]
dec dword [eax]
mov dword [ebp - 12], INLINE_ROUTINE_REG_INTERMEDIATE
jmp .loading_sequence

.no_prev_reg_sub_and_intermediate:
mov eax, dword [ebp + 24]
mov dword [eax + 8], 1
mov eax, dword [ebp + 16]
push dword [eax]
push dword [ebp + 8]
push dword [ebp + 24]
call scale_dual_quad_data
add esp, 12
mov eax, dword [ebp + 24]
mov dword [eax + 8], 0
mov dword [ebp - 12], INLINE_ROUTINE_NO_REG_INTERMEDIATE
mov eax, dword [ebp + 24]
mov eax, dword [eax + 12]
cmp dword [eax], REG_QUAD
jne .loading_sequence
mov eax, dword [ebp + 16]
dec dword [eax]
mov dword [ebp - 20], 1
jmp .loading_sequence

.no_prev_reg_sub_and_operand:
mov dword [ebp - 12], INLINE_ROUTINE_NO_REG_OPERAND
jmp .loading_sequence

.loading_sequence:
; update the operator type to match prev operation type
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
mov edx, dword [ebp + 8]
mov dword [edx + 12], eax
; cache the current op subscript
mov eax, dword [ebp + 8]
mov eax, dword [eax + 8]
mov dword [ebp - 16], eax
; create addr_quad
mov eax, dword [ebp + 8]
mov edx, dword [ebp + 24]
mov dword [eax + 8], edx
mov edx, dword [edx + 12]
mov dword [eax + 4], edx
mov dword [eax], ADDR_QUAD
mov eax, dword [ebp + 24]
mov eax, dword [eax + 12]
cmp dword [eax], REG_QUAD
je .load_inline_register
.load_inline_quad:
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 8]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 8]
mov dword [eax], REG_QUAD
jmp .update_dual
.load_inline_register:
mov eax, dword [ebp + 24]
mov edx, dword [ebp - 24]
mov dword [eax + 12], edx
mov eax, dword [ebp + 16]
dec dword [eax]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 24]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 8]
mov dword [eax], REG_QUAD
mov eax, dword [ebp + 16]
inc dword [eax]
.update_dual:
mov eax, dword [ebp + 24]
mov dword [eax + 4], 0
mov dword [eax + 8], 0
mov dword [eax + 12], reg_quad
.cache:
; load cache
mov eax, dword [ebp - 16]
mov edx, dword [ebp + 8]
mov dword [edx + 8], eax
; restore type
mov eax, dword [ebp - 24]
mov edx, dword [ebp + 8]
mov dword [edx + 12], eax
; INLINE ROUTINE IDS
; 0 -> reg_sub and intermediate
; 1 -> reg_sub and operand
; 2 -> no_reg_sub and intermediate
; 3 -> no_reg_sub and operand

; determine postload operation
cmp dword [ebp - 12], INLINE_ROUTINE_REG_INTERMEDIATE
je .routine_0
cmp dword [ebp - 12], INLINE_ROUTINE_REG_OPERAND
je .routine_1
cmp dword [ebp - 12], INLINE_ROUTINE_NO_REG_INTERMEDIATE
je .routine_2
jmp .routine_3

.routine_0:
mov eax, dword [ebp + 16]
inc dword [eax]
mov eax, dword [ebp + 24]
mov dword [eax + 8], 1
mov eax, dword [ebp + 16]
push dword [eax]
push dword [ebp + 8]
push dword [ebp + 24]
call scale_dual_quad_data
add esp, 12
mov eax, dword [ebp + 16]
push dword [eax]
call generate_add
add esp, 4
mov eax, dword [ebp + 16]
dec dword [eax]
mov eax, dword [ebp + 24]
mov dword [eax + 4], 0
jmp .exit

.routine_1:
; mov eax, dword [ebp + 8]
; mov eax, dword [eax + 12]
; push dword [eax + 12]
push dword [ebp + 8]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
mov eax, dword [ebp + 8]
push dword [eax + 8]
call generate_array_subscript
add esp, 24
; mov eax, dword [ebp + 16]
; push dword [eax]
; push dword [ebp + 8]
; push dword [ebp + 24]
; call scale_dual_quad_data
; add esp, 12
mov eax, dword [ebp + 24]
cmp dword [eax + 8], 0
je .add_constant
mov eax, dword [ebp + 16]
push dword [eax]
call generate_add
add esp, 4
mov eax, dword [ebp + 16]
dec dword [eax]
mov eax, dword [ebp + 24]
mov dword [eax + 4], 0
jmp .exit


.routine_2:
mov eax, dword [ebp + 16]
mov edx, dword [ebp - 20]
add dword [eax], edx
mov eax, dword [ebp + 16]
push dword [eax]
call generate_add
add esp, 4
mov eax, dword [ebp + 16]
dec dword [eax]
mov eax, dword [ebp + 24]
mov dword [eax + 4], 0
jmp .exit

.routine_3:
; mov eax, dword [ebp + 8]
; mov eax, dword [eax + 12]
; push dword [eax + 12]
push dword [ebp + 8]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
mov eax, dword [ebp + 8]
push dword [eax + 8]
call generate_array_subscript
add esp, 24
; mov eax, dword [ebp + 16]
; push dword [eax]
; push dword [ebp + 8]
; push dword [ebp + 24]
; call scale_dual_quad_data
; add esp, 12
mov eax, dword [ebp + 24]
cmp dword [eax + 8], 0
je .add_constant
mov eax, dword [ebp + 16]
push dword [eax]
call generate_add
add esp, 4
mov eax, dword [ebp + 16]
dec dword [eax]
mov eax, dword [ebp + 24]
mov dword [eax + 4], 0
jmp .exit

.add_constant:
mov eax, dword [ebp + 24]
mov dword [eax + 4], 0
mov eax, dword [ebp + 8]
mov eax, dword [eax + 8]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 8]
mov edx, dword [edx + 12]
mov edx, dword [edx + 12]
imul eax, edx
mov edx, dword [ebp + 24]
mov dword [edx + 4], eax
jmp .exit

.exit:
mov eax, dword [ebp + 24]
mov dword [eax + 8], 0
mov dword [eax + 12], reg_quad
leave
ret

; void generate_add(int free_register)
generate_add:
push ebp
mov ebp, esp
push add_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 8]
sub eax, 2
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 8]
dec eax
push dword [registers + eax * 4]
call print_line_raw
add esp, 4
leave
ret

; TODO: fix scaling order on intermediate and ending accesses
; void generate_array_subscript(quad* sub_quad, buffer* buffer, int* free_register, table* func_var_table, quad* dual_quad, quad* op_quad)
generate_array_subscript:
push ebp
mov ebp, esp
sub esp, 8
mov dword [ebp - 4], 0  ; old_subscript flag
mov dword [ebp - 8], 0  ; scale flag
push dword [ebp + 8]
push dword [ebp + 8]
call get_complex_operand
add esp, 8
cmp eax, 0
je .old_subscript_check
mov eax, dword [ebp + 8]
cmp dword [eax], NUM
je .constant_subscript
cmp dword [eax], BOOL 
je .constant_subscript
jmp .operand_subscript
.constant_subscript:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 24]
mov ecx, dword [ebp + 28]
mov ecx, dword [ecx + 12]
mov ecx, dword [ecx + 12]
imul eax, ecx
add dword [edx + 4], eax    ; increment offset by current constant
jmp .exit
.operand_subscript:
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 8]
push reg_quad
call load
add esp, 20
.old_subscript_check:
mov eax, dword [ebp + 24]
cmp dword [eax + 8], 1
je .add_old_subscript
mov dword [ebp - 8], 1
jmp .no_old_subscript
.add_old_subscript:
mov eax, dword [ebp + 28]
cmp dword [eax], SINGLE_ACCESS_OP
je .no_pre_scale
cmp dword [eax], LAST_ACCESS_OP
je .no_pre_scale
cmp dword [eax], LVAL_ACCESS_OP
je .no_pre_scale
jmp .pre_scale
.no_pre_scale:
mov dword [ebp - 8], 1
jmp .post_scale
.pre_scale:
mov eax, dword [ebp + 16]
push dword [eax]
push dword [ebp + 28]
push dword [ebp + 24]
call scale_dual_quad_data
add esp, 12
mov dword [ebp - 8], 0
.post_scale:
push add_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 16]
mov eax, dword [eax]
sub eax, 2
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 16]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_line_raw
add esp, 4
mov eax, dword [ebp + 16]
dec dword [eax]
.no_old_subscript:
mov eax, dword [ebp + 24]
mov dword [eax + 8], 1      ; set subscript_in_reg flag to true
cmp dword [ebp - 8], 0
je .exit
mov eax, dword [ebp + 16]
push dword [eax]
push dword [ebp + 28]
push dword [ebp + 24]
call scale_dual_quad_data
add esp, 12
.exit:
leave
ret

; void scale_dual_quad_data(quad* dual_quad, quad* op_quad, int free_register)
scale_dual_quad_data:
push ebp
mov ebp, esp
sub esp, 4
; register subscript scale
mov eax, dword [ebp + 8]
cmp dword [eax + 8], 0
je .no_reg_scale
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
cmp dword [eax + 12], 1
je .no_reg_scale
push imul_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 16]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
cmp dword [eax + 4], POINTER
je .scale_by_item_size
mov eax, dword [ebp + 12]
cmp dword [eax], FIRST_ACCESS_OP
je .scale_by_arr_size
cmp dword [eax], ACCESS_OP
je .scale_by_arr_size
jmp .scale_by_item_size
.scale_by_arr_size:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
mov eax, dword [eax + 12]   ; item size
mov dword [ebp - 4], eax
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
mov eax, dword [eax + 12]   ; array size
xor edx, edx
div dword [ebp - 4]
; array size in eax
push eax
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .no_reg_scale
.scale_by_item_size:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
mov eax, dword [eax + 12]
push eax
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
.no_reg_scale:
leave
ret

; addr_quad* get_dual_quad(int offset, int sub_reg_flag)
get_dual_quad:
push ebp
mov ebp, esp
push 0
push dword [ebp + 12]
push dword [ebp + 8]
push DUAL_QUAD
call get_quad
add esp, 16
leave
ret

; dual_quad* get_top_dual_quad(node** dual_quad_stack, int op_type)
get_top_dual_quad:
push ebp
mov ebp, esp
cmp dword [ebp + 12], FIRST_ACCESS_OP
je .push
cmp dword [ebp + 12], ACCESS_OP
je .top
cmp dword [ebp + 12], SINGLE_ACCESS_OP
je .push
cmp dword [ebp + 12], LAST_ACCESS_OP
je .top
cmp dword [ebp + 12], LVAL_ACCESS_OP
je .peek
cmp dword [ebp + 12], FIRST_MEMBER_OP
je .push
cmp dword [ebp + 12], MEMBER_OP
je .top
cmp dword [ebp + 12], SINGLE_MEMBER_OP
je .push
cmp dword [ebp + 12], LAST_MEMBER_OP
je .top
cmp dword [ebp + 12], LVAL_MEMBER_OP
je .peek
.peek:
mov eax, dword [ebp + 8]
cmp dword [eax], 0
je .push
.top:
mov eax, dword [ebp + 8]
mov eax, dword [eax]
mov eax, dword [eax]
leave
ret
.push:
push 0
push 0
call get_dual_quad
add esp, 8
push dword [ebp + 8]
push eax
call push_dual_quad
add esp, 8
leave
ret

; dual_quad* push_dual_quad(quad* dual_quad, node* stack)
push_dual_quad:
push ebp
mov ebp, esp
mov eax, dword [ebp + 12]
cmp dword [eax], 0
jne .push
.empty_stack:
push 0
push dword [ebp + 8]
call get_linked_list
add esp, 8
mov edx, dword [ebp + 12]
mov dword [edx], eax
jmp .exit
.push:
mov eax, dword [ebp + 12]
mov eax, dword [eax]
push eax
push dword [ebp + 8]
call get_linked_list
add esp, 8
mov edx, dword [ebp + 12]
mov dword [edx], eax
.exit:
mov eax, dword [ebp + 8]
leave
ret
; int get_complex_operand(quad* left_operand, quad* right_operand)
; COMPLEXITY MOST TO LEST
; ID => ADDR_QUAD => NUM | BOOL | STR_QUAD => INTERMEDIATES
; comparator style return => -1 for left | 0 for intermediate | 1 for right
get_complex_operand:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8] 
cmp dword [eax], id
je .left
mov eax, dword [ebp + 12]
cmp dword [eax], id
je .right
mov eax, dword [ebp + 8]
cmp dword [eax], ADDR_QUAD
je .left
mov eax, dword [ebp + 12]
cmp dword [eax], ADDR_QUAD
je .right
mov eax, dword [ebp + 8]
cmp dword [eax], NUM
je .left
cmp dword [eax], BOOL
je .left
mov eax, dword [ebp + 12]
cmp dword [eax], NUM
je .right
cmp dword [eax], BOOL
je .right
; STR_QUAD can only appear on the right since syntax only permits assignment of string constants right now
cmp dword [eax], STR_QUAD
je .right
jmp .intermediate
.left:
mov eax, -1
jmp .exit
.right:
mov eax, 1
jmp .exit
.intermediate:
xor eax, eax
.exit:
leave
ret

; void subscript_correction(int free_register, uint size)
subscript_correction:
push ebp
mov ebp, esp
push imul_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 8]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 12]
call print_number_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
leave
ret

; void deref_addr_quad(quad* quad, table* func_var_table, buffer* buffer, int* free_register)
deref_addr_quad:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
push dword [ebp + 12]
push dword [ebp + 20]
push dword [ebp + 16]
push eax
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 8]
cmp dword [eax + 8], 0
je .no_reg_subscript_3
inc dword [ebp + 20]
push add_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
sub eax, 2
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
sub eax, 2
mov dword [ebp + 20], eax
.no_reg_subscript_3:
leave
ret

; char* get_mov_operation(quad* left_operand, quad* right_operand)
get_mov_operation:
push ebp
mov ebp, esp
mov eax, dword [ebp + 12]
cmp dword [eax], NUM
je .regular_ret
cmp dword [eax], BOOL
je .regular_ret
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
mov eax, dword [eax + 12]   ; right_operand size in bytes
mov edx, dword [ebp + 8]
mov edx, dword [edx + 12]
mov edx, dword [edx + 12]   ; left operand size in bytes
cmp edx, eax
jle .regular_ret 
.check_type:
mov eax, dword [ebp + 12]   ; load right_operand_quad
mov eax, dword [eax + 12]   ; load type
cmp dword [eax + 8], UCHAR
jl .sign_extend
mov eax, movzx_k
jmp .exit
.sign_extend:
mov eax, movsx_k
jmp .exit
.regular_ret:
mov eax, mov_k
.exit:
leave
ret

; TODO: add implicit type conversion
; void load(quad* dest_quad, quad* src_quad, char* buffer, int* free_register, table* func_var_table)
; if dest_quad is reg_quad, loads the src into a register pointer specified by free_register
; if dest_quad is an operand or addr_quad, loads the src into the dest addr
; if dest_quad is reg_quad and src_quad is reg_quad, execute deref routine
; LOAD ROUTINES
; 0 - mov register, [operand]            |   dest=REG_QUAD ,  src=ID
; 1 - mov register, [register]           |   dest=REG_QUAD ,  src=REG_QUAD
; 2 - mov register, [register+offset]    |   dest=REG_QUAD ,  src=DUAL_QUAD    | dest=DUAL_QUAD, src=REG_QUAD
; 3 - mov [register + offset], [operand] |   dest=DUAL_QUAD,  scc=NUM,BOOL     
; 4 - mov [operand], register            |   dest=ID       ,  src=REG_QUAD     | dest=ADDR_QUAD, src=REG_QUAD
; 5 - mov [operand], constant            |   dest=ID       ,  src=NUM,BOOL     | dest=ADDR_QUAD, src=REG_QUAD
load:
push ebp
mov ebp, esp
push dword [ebp + 8]
push dword [ebp + 8]
call get_complex_operand
add esp, 8
cmp eax, 0
je .operand_src
.operand_dest:
mov eax, dword [ebp + 12]
cmp dword [eax], REG_QUAD
je .load_routine_4
jmp .load_routine_5
.operand_src:
push dword [ebp + 12]
push dword [ebp + 12]
call get_complex_operand
add esp, 8
cmp eax, 0
je .check_routine_1
mov eax, dword [ebp + 8]
cmp dword [eax], DUAL_QUAD
je .load_routine_3
jmp .load_routine_0
.check_routine_1:
mov eax, dword [ebp + 8]
mov eax, dword [eax]
mov edx, dword [ebp + 12]
mov edx, dword [edx]
add eax, edx
cmp eax, (REG_QUAD * 2)
je .load_routine_1
mov eax, dword [ebp + 8]
cmp dword [eax], REG_QUAD
je .load_routine_2
mov eax, dword [ebp + 12]
cmp dword [eax], REG_QUAD
je .load_routine_2_reverse

.load_routine_0:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
cmp dword [eax + 4], ARRAY_QUAD
je .load_routine_0_array
cmp dword [eax + 4], ARRAY
jne .check_others
mov eax, dword [ebp + 12]
cmp dword [eax], id
je .load_routine_0_array
.check_others:
mov eax, dword [ebp + 12]
cmp dword [eax], id
je .load_operand
cmp dword [eax], ADDR_QUAD
je .load_operand
.load_constant:
push dword [ebp + 12]
push dword [ebp + 8]
call get_mov_operation
add esp, 8
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20] 
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
push dword [eax]
push dword [ebp + 16]
push dword [ebp + 24]
push dword [ebp + 12]
call generate_operand
add esp, 16
push dword [ebp + 16]
call flush_buffer
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
inc dword [eax]
leave
ret
.load_operand:
push dword [ebp + 12]
push dword [ebp + 8]
call get_mov_operation
add esp, 8
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20] 
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
push dword [eax]
push dword [ebp + 16]
push dword [ebp + 24]
push dword [ebp + 12]
call generate_operand
add esp, 16
push dword [ebp + 12]
call get_size_prefix
add esp, 4
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
push dword [ebp + 16]
call flush_buffer
add esp, 4
push right_bracket
call print_line_raw
add esp, 4
mov eax, dword [ebp + 20]
inc dword [eax]
leave
ret

.load_routine_0_array:
mov eax, dword [ebp + 20]
push dword [eax]
push dword [ebp + 16]
push dword [ebp + 24]
push dword [ebp + 12]
call generate_operand
add esp, 16
push lea_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
push dword [ebp + 16]
call flush_buffer
add esp, 4
push right_bracket
call print_line_raw
add esp, 4
mov eax, dword [ebp + 20]
inc dword [eax]
leave
ret

.load_routine_1:
push dword [ebp + 12]
push dword [ebp + 8]
call get_mov_operation
add esp, 8
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 12]
call get_size_prefix
add esp, 4
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push right_bracket
call print_line_raw
add esp, 4
leave
ret

.load_routine_2:
push dword [ebp + 12]
push dword [ebp + 8]
call get_mov_operation
add esp, 8
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 12]
call get_size_prefix
add esp, 4
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
push dword [eax + 4]
call print_offset
add esp, 4
push right_bracket
call print_line_raw
add esp, 4
leave
ret

.load_routine_2_reverse:
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 8]
call get_size_prefix
add esp, 4
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
mov eax, dword [ebp + 8]
push dword [eax + 4]
call print_offset
add esp, 4
push right_bracket
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
xor eax, 1
push eax
push dword [ebp + 8]
call morph_register
add esp, 8
push eax
call print_line_raw
add esp, 4
leave
ret

.load_routine_3:
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 8]
call get_size_prefix
add esp, 4
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
mov eax, dword [ebp + 8]
push dword [eax + 4]
call print_offset
add esp, 4
push right_bracket
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
push dword [eax]
push dword [ebp + 16]
push dword [ebp + 24]
push dword [ebp + 12]
call generate_operand
add esp, 16
push dword [ebp + 16]
call flush_buffer
add esp, 4
push nl
call print_string_raw
add esp, 4
leave
ret

.load_routine_4:
mov eax, dword [ebp + 20]
push dword [eax]
push dword [ebp + 16]
push dword [ebp + 24]
push dword [ebp + 8]
call generate_operand
add esp, 16
push dword [ebp + 12]
push dword [ebp + 8]
call get_mov_operation
add esp, 8
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 8]
call get_size_prefix
add esp, 4
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
push dword [ebp + 16]
call flush_buffer
add esp, 4
push right_bracket
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax]
mov edx, dword [ebp + 8]
cmp dword [edx], ADDR_QUAD
jne .skip_xor
mov edx, dword [ebp + 8]
mov edx, dword [edx + 8]
cmp dword [edx + 8], 0
je .skip_xor
xor eax, 1
.skip_xor:
push eax
push dword [ebp + 8]
call morph_register
add esp, 8
push eax
call print_line_raw
add esp, 4
leave
ret

.load_routine_5:
mov eax, dword [ebp + 20]
push dword [eax]
push dword [ebp + 16]
push dword [ebp + 24]
push dword [ebp + 8]
call generate_operand
add esp, 16
push dword [ebp + 12]
push dword [ebp + 8]
call get_mov_operation
add esp, 8
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 8]
call get_size_prefix
add esp, 4
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push left_bracket
call print_string_raw
add esp, 4
push dword [ebp + 16]
call flush_buffer
add esp, 4
push right_bracket
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
push dword [eax]
push dword [ebp + 16]
push dword [ebp + 24]
push dword [ebp + 12]
call generate_operand
add esp, 16
push dword [ebp + 16]
call flush_buffer
add esp, 4
push nl
call print_string_raw
add esp, 4
leave
ret


; void print_offset(int offset)
print_offset:
push ebp
mov ebp, esp
cmp dword [ebp + 8], 0
je .zero
cmp word [ebp + 8], 0
jg .plus
jmp .minus
.plus:
push plus_k
call print_string_raw
add esp, 4
.minus:
push dword [ebp + 8]
call print_number_raw
add esp, 4
.zero:
leave
ret

; void generate_logical_binary_operation(node* TAC_list, quad* op_quad, quad* left_operand, quad* right_operand, char* buffer, int* free_register, table* func_var_table)
generate_logical_binary_operation:
push ebp
mov ebp, esp
sub esp, 8
mov dword [ebp - 4], 0  ; need_to_be_loaded count
mov dword [ebp - 8], 0
; constants
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
call resolve_constants
add esp, 12
cmp eax, 0
jne .exit
; register allocation
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
call allocate_operands
add esp, 12
mov dword [ebp - 4], eax

; OPERATION ROUTINE IDS
; 0 -> intermediate op intermediate
; 1 -> intermediate op constant
; 2 -> intermediate op operand
; 3 -> operand op constant
; 4 -> operand op operand

cmp dword [ebp - 4], 2
je .routine_4
cmp dword [ebp - 4], 0
je .check_routine_0
cmp dword [ebp - 4], 1
je .check_routine_2

.check_routine_0:
push dword [ebp + 20]
push dword [ebp + 20]
call get_complex_operand
add esp, 8
cmp eax, 0
jne .routine_1
push dword [ebp + 16]
push dword [ebp + 16]
call get_complex_operand
add esp, 8
cmp eax, 0
je .routine_0
jmp .routine_1
.check_routine_2:
push dword [ebp + 20]
push dword [ebp + 20]
call get_complex_operand
add esp, 8
cmp eax, 0
je .routine_2
push dword [ebp + 16]
push dword [ebp + 16]
call get_complex_operand
add esp, 8
cmp eax, 0
je .routine_2
jmp .routine_3

.routine_0:
push cmp_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
sub eax, 2
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_line_raw
add esp, 4
mov eax, dword [ebp + 28]
dec dword [eax]
jmp .exit

.routine_1:
push dword [ebp + 16]
push dword [ebp + 16]
call get_complex_operand
add esp, 8
cmp eax, 0
je .regular_routine_1
jmp .routine_1_constant_left
.regular_routine_1:
push cmp_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
push dword [eax]
push dword [ebp + 24]
push dword [ebp + 32]
push dword [ebp + 20]
call generate_operand
add esp, 16
push dword [ebp + 24]
call flush_buffer
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .exit

.routine_1_constant_left:
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
inc eax
push dword [registers + eax * 4]
call generate_swap
add esp, 8
mov eax, dword [ebp + 28]
dec dword [eax]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 28]
inc dword [eax]
jmp .routine_0

.routine_2:
push dword [ebp + 16]
push dword [ebp + 16]
call get_complex_operand
add esp, 8
cmp eax, 0
je .regular_routine_2
.routine_2_operand_on_the_left:
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
inc eax
push dword [registers + eax * 4]
call generate_swap
add esp, 8
mov eax, dword [ebp + 28]
dec dword [eax]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 28]
inc dword [eax]
jmp .routine_0

.regular_routine_2:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push reg_quad
call load
add esp, 20
jmp .routine_0

.routine_3:
mov eax, dword [ebp + 16]
cmp dword [eax], id
je .regular_routine_3
cmp dword [eax], ADDR_QUAD
je .regular_routine_3
.routine_3_constant_on_the_left:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push reg_quad
call load
add esp, 20
jmp .routine_0
.regular_routine_3:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
jmp .regular_routine_1


.routine_4:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push reg_quad
call load
add esp, 20
jmp .routine_0

.exit:
mov eax, dword [ebp + 12]
cmp dword [eax], LT
jge .rel_op
jmp .branch_op
.rel_op:
push dword [ebp + 12]
call get_rel_op_common_type
add esp, 4
cmp eax, 1
je .signed_rel_op
.unsigned_rel_op:
mov eax, dword [ebp + 12]
mov eax, dword [eax]
sub eax, LT
push dword [rel_ops_unsigned + eax * 4]
call print_string_raw
add esp, 4
jmp .end_sign_check
.signed_rel_op:
mov eax, dword [ebp + 12]
mov eax, dword [eax]
sub eax, LT
push dword [rel_ops_signed + eax * 4]
call print_string_raw
add esp, 4
.end_sign_check:
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push eax
push dword [ebp + 12]
call morph_register
add esp, 8
push eax
call print_line_raw
add esp, 4
; resize
push movzx_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push eax
push dword [ebp + 12]
call morph_register
add esp, 8
push eax
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
leave
ret
.branch_op:
mov eax, dword [ebp + 28]
dec dword [eax]
leave
ret

; int get_rel_op_common_type(quad* rel_op)
get_rel_op_common_type:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
cmp dword [eax + 4], PRIMITIVE
jne .unsigned
cmp dword [eax + 8], UCHAR
jge .unsigned
mov eax, dword [ebp + 8]
mov eax, dword [eax + 8]
mov eax, dword [eax + 12]
cmp dword [eax + 4], PRIMITIVE
jne .unsigned
cmp dword [eax + 8], UCHAR
jge .unsigned
jmp .signed
.unsigned:
xor eax, eax
jmp .exit
.signed:
mov eax, 1
jmp .exit
.exit:
leave
ret

; void resolve_preload(quad* left_operand, quad* right_operand, char* buffer, int* free_register, table* func_var_table)
resolve_preload:
push ebp
mov ebp, esp

leave
ret

; TODO: add preload constant resolution and resizing
; void generate_assignment_operation(char* op_k, quad* op_quad, quad* left_operand, quad* right_operand, char* buffer, int* free_register, table* func_var_table)
generate_assignment_operation:
push ebp
mov ebp, esp
sub esp, 12
mov eax, dword [ebp + 28]
mov eax, dword [eax]
mov dword [ebp - 12], eax
; resolve constants
; push dword [ebp + 20]
; push dword [ebp + 16]
; push dword [ebp + 12]
; call resolve_constants
; add esp, 12
; register allocation
push dword [ebp + 20]
call allocate_operand
add esp, 4
mov dword [ebp - 4], eax
; DETERMINE ROUTINE
; 1 alloc   ->   operand op intermediate
; 1 alloc   ->   opernad op constant
; 2 allocs  ->   operand op operand 
; ROUTINE IDS
; 2 -> operand op intermediate
; 3 -> operand op constant
; 4 -> operand op operand
inc dword [ebp - 4]
cmp dword [ebp - 4], 2
je .set_routine_4
.check_routine_2:
push dword [ebp + 20]
push dword [ebp + 20]
call get_complex_operand
add esp, 8
cmp eax, 0
jne .set_routine_3
.set_routine_2:
mov dword [ebp - 8], ROUTINE_INTERMEDIATE_OPERAND
jmp .routine_2
.set_routine_3:
mov dword [ebp - 8], ROUTINE_OPERAND_CONSTANT
jmp .routine_3
.set_routine_4:
mov dword [ebp - 8], ROUTINE_OPERANDS
jmp .routine_4

.routine_4:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push reg_quad
call load
add esp, 20
jmp .routine_2

.routine_3:
mov eax, dword [ebp + 16]
cmp dword [eax], ADDR_QUAD
jne .skip_routine_3_fix
mov eax, dword [eax + 8]
mov eax, dword [eax + 8]
mov edx, dword [ebp + 28]
sub dword [edx], eax
.skip_routine_3_fix:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
call load
add esp, 20
jmp .exit

.routine_2:
mov eax, dword [ebp + 16]
cmp dword [eax], DUAL_QUAD
je .reg_correction
cmp dword [eax], ADDR_QUAD
jne .load_into_operand
.load_into_addr:
mov eax, dword [ebp + 16]
mov eax, dword [eax + 8]
cmp dword [eax + 8], 0
je .load_into_operand
; ebp - 12  | free_register before allocation
; ebp - 28  | free_register after allocation
; 0 allocs  | impossible since this routine accepts: operand = operand or operand = intermediate
; 1 allocs  | either rvalue has an intermediate, or lvalue has a register subscript
; 2 allocs  | rvalue has an intermediate and lvalue has a register subscript
; arr[x] = x;
; BEGIN:
; alloc  = 1 | subscript x is loaded beforehand
; ebp-12 = 1 | load ebp-12
; alloc  = 2 | rvalue x is loaded
; subscript_reg = ebp - 12

; arr[x] = x + 1;
; BEGIN:
; alloc  = 1 | x + 1 intermediate is loaded beforehand
; alloc  = 2 | subscript x is loaded beforehand
; ebp-12 = 2 | load ebp-12
; alloc  = 2 | rvalue is an intermediate
; subscript_reg = ebp - 12
.reg_correction:
push dword [ebp + 32]
mov eax, dword [ebp - 12]
dec eax
mov edx, dword [ebp + 28]
mov dword [edx], eax
push dword [ebp + 28]
push dword [ebp + 24]
push reg_quad
push dword [ebp + 16]
call load
add esp, 20
leave
ret
.load_into_operand:
mov eax, dword [ebp + 28]
dec dword [eax]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push reg_quad
push dword [ebp + 16]
call load
add esp, 20
jmp .exit

mov eax, dword [ebp + 28]
mov dword [eax], 0
.exit:
leave
ret


; TODO: add constant multiplication protocol
; TODO: add pointer arithmetic protocol
; TODO: rewrite snippet generation as functions like generate_swap
; void generate_arithmetic_binary_operation(char* op_k, quad* op_quad, quad* left_operand, quad* right_operand, char* buffer, int* free_register, table* func_var_table)
generate_arithmetic_binary_operation:
push ebp
mov ebp, esp
sub esp, 16
mov dword [ebp - 4],  0     ; allocated_registers count
mov dword [ebp - 16], 0     ; routine_id
; resolve constant operands
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
call resolve_constants
add esp, 12
cmp eax, 0
jne .exit


; register allocation
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
call allocate_operands
add esp, 12
mov dword [ebp - 4], eax
; DETERMINE ROUTINE
; 0 allocs  ->   intermediate op intermediate
; 0 allocs  ->   intermediate op constant
; 1 alloc   ->   intermediate op operand <-> operand op intermediate
; 1 alloc   ->   opernad op constant <-> constant op operand
; 2 allocs  ->   operand op operand 
; ROUTINE IDS
; 0 -> intermediate op intermediate
; 1 -> intermediate op constant
; 2 -> intermediate op operand
; 3 -> operand op constant
; 4 -> operand op operand
cmp dword [ebp - 4], 0
je .check_for_routine_1
cmp dword [ebp - 4], 1
je .check_for_routine_2 
cmp dword [ebp - 4], 2
je .routine_4

.check_for_routine_1:
push dword [ebp + 20]
push dword [ebp + 16]
call get_complex_operand
add esp, 8
cmp eax, 0
je .routine_0
jmp .routine_1
.check_for_routine_2:
push dword [ebp + 16]
push dword [ebp + 16]
call get_complex_operand
add esp, 8
mov dword [ebp - 16], eax
push dword [ebp + 20]
push dword [ebp + 20]
call get_complex_operand
add esp, 8
add dword [ebp - 16], eax
cmp dword [ebp - 16], -2
je .routine_3
jmp .routine_2

.routine_0:
mov dword [ebp - 16], ROUTINE_INTERMEDIATES
jmp .routine_chosen
.routine_1:
mov dword [ebp - 16], ROUTINE_INTERMEDIATE_CONSTANT
jmp .routine_chosen
.routine_2:
mov dword [ebp - 16], ROUTINE_INTERMEDIATE_OPERAND
jmp .routine_chosen
.routine_3:
mov dword [ebp - 16], ROUTINE_OPERAND_CONSTANT
jmp .routine_chosen
.routine_4:
mov dword [ebp - 16], ROUTINE_OPERANDS
jmp .routine_chosen


.routine_chosen:
mov eax, dword [ebp + 12]
cmp dword [eax], DIV_OP
je .div_routine

push dword [ebp - 16]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 8]
call execute_routine
add esp, 32

jmp .exit



.mul_routine:
mov eax, dword [ebp + 20]
cmp dword [eax], NUM
je .constant_multiplier
cmp dword [eax], BOOL
je .constant_multiplier





.constant_multiplier:
mov eax, dword [ebp + 16]
mov eax, dword [eax + 4]
cmp eax, 0
je .zero_product
cmp eax, 1
je .identity_product

.zero_product:
mov edx, dword [ebp + 12]
mov dword [edx], NUM
mov dword [edx + 4], 0
mov dword [edx + 8], 0
jmp .clear_buffer

.identity_product:
jmp .clear_buffer

.div_routine:
mov eax, dword [ebp + 16]
cmp dword [eax], NUM
je .constant_numerator
cmp dword [eax], BOOL
je .constant_numerator
mov eax, dword [ebp + 20]
cmp dword [eax], NUM
je .constant_denominator
cmp dword [eax], BOOL
je .constant_denominator
.normal_operand:
; load first operand
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
dec dword [ebp - 8]
mov eax, dword [ebp + 32]
cmp eax, dword [ebp - 8]
je .skip_second_operand_load
; load second operand
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push reg_quad
call load
add esp, 20
dec dword [ebp - 8]
.skip_second_operand_load:
mov eax, dword [ebp + 28]
push dword [eax]
call generate_div_swaps
add esp, 4
.gen_prologue:
mov eax, dword [ebp + 28]
push dword [eax]
push dword [ebp + 12]
call generate_div_prologue
add esp, 8
push eax
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
cmp dword [ebp - 4], 1
je .address_operand
.register_operand:
mov eax, dword [ebp + 28]
mov eax, dword [eax]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .gen_epilogue
.address_operand:
push dword [ebp + 24]
push dword [ebp + 32]
push dword [ebp + 20]
call generate_operand
add esp, 12
push dword [ebp + 24]
call flush_buffer
add esp, 4
push nl
call print_string_raw
add esp, 4
.gen_epilogue:
push dword [ebp + 28]
call generate_div_epilogue
add esp, 4
jmp .exit

; TODO: rework this mess
.constant_numerator:
mov eax, dword [ebp + 28]
mov eax, dword [eax]
sub eax, dword [ebp - 4]
cmp eax, 0
je .no_swap
push eax_k
push ecx_k
call generate_swap
add esp, 8
.no_swap:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
jmp .gen_prologue

.constant_denominator:
; load operand
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 20]
mov eax, dword [eax + 4]
cmp eax, 1
je .clear_buffer
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
cmp dword [eax + 8], UINT
jne .signed_constant
.unsigned_constant:
mov eax, dword [ebp + 20]
mov eax, dword [eax + 4]
cmp eax, 0
je .zero
push eax
call check_if_power_of_two
add esp, 4
cmp eax, 0
je .unsigned_non_power_of_two
cmp eax, -1
je .unsigned_negative
jmp .unsigned_power_of_two
.unsigned_power_of_two:
push shr_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 20]
mov eax, dword [eax + 4]
bsf eax, eax
push 10
push itoa_buffer
push eax
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .clear_buffer
.unsigned_non_power_of_two:
mov eax, dword [ebp + 20]
cmp dword [eax + 4], 0
jl .unsigned_negative
mov eax, dword [ebp + 28]
mov eax, dword [eax]
push eax
mov eax, dword [ebp + 20]
mov eax, dword [eax + 4]
push eax
call generate_div_by_constant_unsign
add esp, 8
jmp .clear_buffer 

.unsigned_negative:
; truncated  ceil division on large numbers
push cmp_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 24]
call flush_buffer
add esp, 4
push nl
call print_string_raw
add esp, 4
push setnb_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [byte_registers + eax * 4]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push movzx_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .exit

.signed_constant:
mov eax, dword [ebp + 20]
mov eax, dword [eax + 4]    ; const value here
cmp eax, 0
je .zero
cmp eax, 0
je .signed_power_of_two
mov eax, dword [ebp + 20]
mov eax, dword [eax + 4]    ; const value here
push eax
call check_if_power_of_two
add esp, 4
cmp eax, 0
je .signed_non_power_of_two
.signed_power_of_two:
mov eax, dword [ebp + 28]
push dword [eax]
mov eax, dword [ebp + 20]
push dword [eax + 4]
call generate_div_by_constant_sign_pt
add esp, 8
jmp .clear_buffer
.signed_non_power_of_two:
mov eax, dword [ebp + 28]
cmp dword [eax], 2
jne .end_ebx_check
cmp dword [non_scratch_reg_used], 1
je .end_ebx_check
push ebx_k
call preserve_reg
add esp, 4
.end_ebx_check:
mov eax, dword [ebp + 28]
push dword [eax]
mov eax, dword [ebp + 20]
push dword [eax + 4]
call generate_div_by_constant_sign
add esp, 8
jmp .clear_buffer

.zero:
jmp .clear_buffer

.clear_buffer:
push dword [ebp + 24]
call clear_buffer
add esp, 4
jmp .exit

.exit:
leave
ret


; TODO: implement wasteful operation filtering
; void execute_routine(char* op_k, quad* op_quad, quad* left_operand, quad* right_operand, char* buffer, int* free_register, table* func_var_table, int routine)
; ROUTINE IDS
; 0 -> intermediate op intermediate
; 1 -> intermediate op constant
; 2 -> intermediate op operand
; 3 -> operand op constant
; 4 -> operand op operand
; operand op constant 
; intermediate op constant
execute_routine:
push ebp
mov ebp, esp
sub esp, 8
; ebp - 4   |   left_operand
; ebp - 8   |   right_operand
mov eax, dword [ebp + 16]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 20]
mov dword [ebp - 8], eax

jmp .general_routine

; TODO: fix this
mov eax, dword [ebp + 12]
cmp dword [eax], MUL_OP
jne .general_routine
.mul_routine:
cmp dword [ebp + 36], ROUTINE_OPERAND_CONSTANT
je .gen_const_mul
cmp dword [ebp + 36], ROUTINE_INTERMEDIATE_CONSTANT
je .gen_const_mul
jmp .general_routine

.gen_const_mul:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 8]
call generate_constant_multiplication
add esp, 28
jmp .exit

.general_routine:
cmp dword [ebp + 36], ROUTINE_OPERANDS
je .routine_4
cmp dword [ebp + 36], ROUTINE_OPERAND_CONSTANT
je .routine_3
cmp dword [ebp + 36], ROUTINE_INTERMEDIATE_OPERAND
je .routine_2
cmp dword [ebp + 36], ROUTINE_INTERMEDIATE_CONSTANT
je .routine_1
cmp dword [ebp + 36], ROUTINE_INTERMEDIATES
je .routine_0
jmp .exit

; operand op operand
.routine_4:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 16]
push reg_quad
call load
add esp, 20
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push reg_quad
call load
add esp, 20
jmp .routine_0


; operand op constant
.routine_3:
mov eax, dword [ebp + 12]
cmp dword [eax], MINUS_OP
jne .skip_routine_3_fix
mov eax, dword [ebp + 16]
cmp dword [eax], id
je .skip_routine_3_fix
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp - 4]
push reg_quad
call load
add esp, 20
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp - 8]
push reg_quad
call load
add esp, 20
jmp .routine_0
.skip_routine_3_fix:
lea eax, dword [ebp - 8]
push eax
lea eax, dword [ebp - 4]
push eax
push dword [ebp - 8]
push dword [ebp - 4]
push dword [ebp + 12]
call swap_operands
add esp, 20
; load operand
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp - 4]
push reg_quad
call load
add esp, 20
mov dword [ebp - 4], reg_quad
jmp .routine_1

; intermediate op operand
.routine_2:
push dword [ebp - 4]
push dword [ebp - 4]
call get_complex_operand
add esp, 8
cmp eax, 0
je .no_swap_1
mov eax, dword [ebp + 12]
cmp dword [eax], MINUS_OP
je .minus_fix
mov eax, dword [ebp - 8]
mov edx, dword [ebp - 4]
mov dword [ebp - 4], eax
mov dword [ebp - 8], edx
jmp .no_swap_1
.minus_fix:
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
inc eax
push dword [registers + eax * 4]
call generate_swap
add esp, 8
mov eax, dword [ebp - 8]
mov edx, dword [ebp - 4]
mov dword [ebp - 4], eax
mov dword [ebp - 8], edx
mov eax, dword [ebp + 28]
dec dword [eax]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp - 8]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 28]
inc dword [eax]
jmp .routine_0
; load operand
.no_swap_1:
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp - 8]
push reg_quad
call load
add esp, 20
jmp .routine_0


; intermediate op constant
.routine_1:
push dword [ebp - 4]
push dword [ebp - 4]
call get_complex_operand
add esp, 8
cmp eax, 0
je .no_swap
mov eax, dword [ebp + 12]
cmp dword [eax], MINUS_OP
je .minus_div_fix
cmp dword [eax], DIV_OP
je .minus_div_fix
jmp .no_preload
.minus_div_fix:
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
inc eax
push dword [registers + eax * 4]
call generate_swap
add esp, 8
mov eax, dword [ebp + 28]
dec dword [eax]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp - 4]
push reg_quad
call load
add esp, 20
mov eax, dword [ebp + 28]
inc dword [eax]
jmp .routine_0
.no_preload:
mov eax, dword [ebp - 4]
mov dword [ebp - 8], eax
.no_swap:
push dword [ebp + 8]
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 24]
push dword [ebp + 32]
push dword [ebp - 8]
call generate_operand
add esp, 12
push dword [ebp + 24]
call flush_buffer
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .exit

; intermediate op intermediate
.routine_0:
push dword [ebp + 8]
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
sub eax, 2
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
mov eax, dword [eax]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, dword [ebp + 28]
dec dword [eax]
jmp .exit

.exit:
leave
ret

generate_constant_multiplication:
push ebp
mov ebp, esp
sub esp, 12
mov byte [ebp-12], 0
push dword [ebp+16]
push dword [ebp+16]
call get_complex_operand
add esp, 8
cmp eax, 0
je .L2
.L1:
push dword [ebp+16]
call allocate_operand
add esp, 4
cmp eax, 0
je .L5
.L4:
mov eax, dword [ebp+16]
mov dword [ebp-4], eax
mov eax, dword [ebp+20]
mov dword [ebp-8], eax
mov byte [ebp-12], 1
jmp .L6
.L5:
push dword [ebp+20]
call allocate_operand
add esp, 4
cmp eax, 0
je .L8
.L7:
mov byte [ebp-12], 1
.L8:
mov eax, dword [ebp+20]
mov dword [ebp-4], eax
mov eax, dword [ebp+16]
mov dword [ebp-8], eax
.L6:
jmp .L3
.L2:
mov eax, dword [ebp+16]
mov dword [ebp-4], eax
mov eax, dword [ebp+20]
mov dword [ebp-8], eax
mov byte [ebp-12], 0
.L3:
movzx eax, byte [ebp-12]
cmp eax, 0
je .L10
.L9:
push dword [ebp+32]
push dword [ebp+28]
push dword [ebp+24]
push dword [ebp-4]
lea eax, [reg_quad]
push eax
call load
add esp, 20
.L10:
mov eax, 0
leave
ret

; ; bool is_power_of_two(uint n)
is_power_of_two:
push ebp
mov ebp, esp
mov eax, dword [ebp+8]
mov edx, eax
dec edx
and eax, edx
cmp eax, 0
sete al
leave
ret

; uint log2(uint n)
log2:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
bsr eax, eax
leave
ret

; void swap_operands(quad* op_quad, quad* left_operand, quad* right_operand, quad** left_ptr, quad** right)
; swaps operands in most to least complexity
swap_operands:
push ebp
mov ebp, esp
push dword [ebp + 16]
push dword [ebp + 12]
call get_complex_operand
add esp, 8
cmp eax, -1
je .exit
.swap:
mov eax, dword [ebp + 12]
mov edx, dword [ebp + 24]
mov dword [edx], eax
mov eax, dword [ebp + 16]
mov edx, dword [ebp + 20]
mov dword [edx], eax
.exit:
leave
ret



; routin
; bool detect_wasteful_operation(int routine_id, quad* op, quad* left_operand, quad* right_operand)
detect_wasteful_operation:
push ebp
mov ebp, esp
cmp dword [ebp + 8], 3
je .start_detection
cmp dword [ebp + 8], 1


.start_detection:
cmp dword [eax], PLUS_OP
je .add_sub_filter
cmp dword [eax], MINUS_OP


.add_sub_filter:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
cmp eax, 0
je .true
jmp .false


.true:
mov eax, 1
jmp .exit
.false:
xor eax, eax
jmp .exit

.exit:
leave
ret



; int check_if_power_of_two(int n)
; returns -1 for negative power of two -(2*p), 1 for positive power of two, 0 otherwise
check_if_power_of_two:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
mov edx, eax
dec edx
and eax, edx
cmp eax, 0
je .pos
mov eax, dword [ebp + 8]
neg eax
mov edx, eax
dec edx
and eax, edx
cmp eax, 0
je .neg
jmp .not
.pos:
mov eax, 1
jmp .exit
.neg:
mov eax, -1
jmp .exit
.not:
xor eax, eax
.exit:
leave
ret

; bool allocate_operands(quad* op_quad, quad* left_operand, quad* right_operand)
; returns true if any operand bas been assigned a register
; false if an atomic operation was performed aka reduced constants
allocate_operands:
push ebp
mov ebp, esp
sub esp, 4
mov dword [ebp - 4], 0
push dword [ebp + 16]
push dword [ebp + 12]
call get_complex_operand
add esp, 8
cmp eax, 0
je .exit
push dword [ebp + 12]
call allocate_operand
add esp, 4
add dword [ebp - 4], eax
push dword [ebp + 16]
call allocate_operand
add esp, 4
add dword [ebp - 4], eax
.exit:
mov eax, dword [ebp - 4]
leave
ret


; bool resolve_constant(quad* op_quad, quad* left_quad, quad* right_quad)
resolve_constants:
push ebp
mov ebp, esp
push dword [ebp + 16]
push dword [ebp + 12]
call check_if_numeric_constants
add esp, 8
cmp eax, 0
je .false
mov eax, dword [ebp + 8]
cmp dword [eax], PLUS_OP
je .add_constants
cmp dword [eax], MINUS_OP
je .subtract_constants
cmp dword [eax], MUL_OP
je .multiply_constants
cmp dword [eax], DIV_OP
je .divide_constants
cmp dword [eax], NEG_OP
je .neg_constant
cmp dword [eax], AND_OP
je .intersect_constants
cmp dword [eax], OR_OP
je .union_constants
jmp .relative_operation
.add_constants:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
add eax, edx
jmp .update_to_constant
.subtract_constants:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
sub eax, edx
jmp .update_to_constant
.multiply_constants:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
imul eax, edx
jmp .update_to_constant
.divide_constants:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov ecx, dword [ebp + 16]
mov ecx, dword [ecx + 4]
cdq
idiv ecx
jmp .update_to_constant
.neg_constant:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
cmp eax, 0
je .set_true
.union_constants:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
cmp eax, 0
jne .set_true
mov eax, dword [ebp + 16]
mov eax, dword [eax + 4]
cmp eax, 0
jne .set_true
jmp .set_false
.intersect_constants:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
cmp eax, 0
je .set_false
mov eax, dword [ebp + 16]
mov eax, dword [eax + 4]
cmp eax, 0
je .set_false
jmp .set_true
.relative_operation:
mov eax, dword [ebp + 8]
push dword [eax]
call quad_tag_to_rel_tag
add esp, 4
mov ecx, eax
cmp ecx, LT
je .less_than
cmp ecx, LE
je .less_or_equal
cmp ecx, GT
je .greater_than
cmp ecx, GE
je .greater_or_equal
cmp ecx, EQ
je .equal
jmp .not_equal
.less_than:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
cmp eax, edx
jl .set_true
jmp .set_false
.less_or_equal:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
cmp eax, edx
jle .set_true
jmp .set_false
.greater_than:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
cmp eax, edx
jg .set_true
jmp .set_false
.greater_or_equal:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
cmp eax, edx
jge .set_true
jmp .set_false
.equal:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
cmp eax, edx
je .set_true
jmp .set_false
.not_equal:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 4]
mov edx, dword [ebp + 16]
mov edx, dword [edx + 4]
cmp eax, edx
jne .set_true
jmp .set_false
.set_false:
xor eax, eax
jmp .update_to_bool_constant
.set_true:
mov eax, 1
jmp .update_to_bool_constant
.update_to_bool_constant:
mov edx, dword [ebp + 8]
mov dword [edx], BOOL
mov dword [edx + 4], eax
mov dword [edx + 8], 0
jmp .true
.update_to_constant:
mov edx, dword [ebp + 8]
mov dword [edx], NUM
mov dword [edx + 4], eax
mov dword [edx + 8], 0
jmp .true
.true:
mov eax, 1
jmp .exit
.false:
xor eax, eax
jmp .exit
.exit:
leave
ret


; bool allocate_operand(quad* operand)
allocate_operand:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
cmp dword [eax], id
je .allocate
cmp dword [eax], ADDR_QUAD
je .allocate
jmp .exit
.allocate:
mov eax, 1
leave
ret
.exit:
xor eax, eax
leave
ret


; void generate_operand(quad* operand, table* func_var_table, char* buffer, int free_register)
generate_operand:
push ebp
mov ebp, esp
sub esp, 4
mov eax, dword [ebp + 8]
cmp dword [eax], id
je .gen_id
cmp dword [eax], NUM
je .gen_num
cmp dword [eax], BOOL
je .gen_bool
cmp dword [eax], ADDR_QUAD
je .gen_addr
cmp dword [eax], STR_QUAD
je .gen_str_addr
jmp .exit
.gen_id:
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 8]
call generate_id_operand
add esp, 12
jmp .exit

.gen_num:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
push 10
push itoa_buffer
push eax
call itoa
add esp, 12
push itoa_buffer
push dword [ebp + 16]
call write_to_buffer
add esp, 8
jmp .exit

.gen_bool:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
push 10
push itoa_buffer
push eax
call itoa
add esp, 12
push itoa_buffer
push dword [ebp + 16]
call write_to_buffer
add esp, 8
jmp .exit

.gen_addr:
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp + 8]
call generate_addr_quad_operand
add esp, 16
jmp .exit

.gen_str_addr:
push str_label
push dword [ebp + 16]
call write_to_buffer
add esp, 8
mov eax, dword [ebp + 8]
push 10
push itoa_buffer
push dword [eax + 8]
call itoa
add esp, 12
push itoa_buffer
push dword [ebp + 16]
call write_to_buffer
add esp, 8
jmp .exit

.exit:
leave
ret


; STRUCTURE OF ADDR_QUAD
; TAG -> ADDR_QUAD
; OPERAND -> id
; DUAL_QUAD -> DUAL_QUAD
; TYPE -> preserved type of operation
; void generate_addr_quad_operand(quad* operand, table* func_var_table, char* buffer, int free_register)
generate_addr_quad_operand:
push ebp
mov ebp, esp
sub esp, 16
; ebp - 4   | offset
; ebp - 8   | id_quad
; ebp - 12  | offset
; epb - 16  | reg_flag
mov dword [ebp - 4], 0
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov dword [ebp - 8], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 8]
mov edx, dword [eax + 4]
mov eax, dword [eax + 8]
mov dword [ebp - 12], edx
mov dword [ebp - 16], eax
push dword [ebp + 12]
push dword [ebp - 8]
call check_in_gm
add esp, 8
cmp eax, 0
je .in_func
jmp .in_gm
.in_func:
mov eax, dword [ebp - 8]
cmp dword [eax + 8], 0
je .in_func_var
.in_func_struct_var:
mov eax, dword [ebp - 8]
mov eax, dword [eax + 4]
mov eax, dword [eax + 8]
mov edx, dword [ebp - 8]
mov edx, dword [edx + 8]
mov edx, dword [edx + 8]
sub eax, edx
mov edx, 0
sub edx, eax
mov eax, edx
mov dword [ebp - 4], eax
; TODO: check if this is valid in SystemV abi when struct is a parameter
.in_func_var:
mov eax, dword [ebp - 8]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, 0
sub eax, edx
mov dword [ebp - 4], eax
push ebp_k
push dword [ebp + 16]
call write_to_buffer
add esp, 8
mov eax, dword [ebp - 12]
add dword [ebp - 4], eax
jmp .end_var_gen

.in_gm:
mov eax, dword [ebp - 8]
mov eax, dword [eax + 12]
cmp dword [eax + 4], STRUCTURE
jne .in_gm_var
.in_gm_struct_var:
mov eax, dword [ebp - 8]
mov eax, dword [eax + 4]
push dword [eax]
push dword [ebp + 16]
call write_to_buffer
add esp, 8
cmp dword [ebp - 12], 0
je .end_var_gen
mov eax, dword [ebp - 12]
add dword [ebp - 4], eax
jmp .end_var_gen
.in_gm_var:
mov eax, dword [ebp - 8]
mov eax, dword [eax + 4]
push dword [eax]
push dword [ebp + 16]
call write_to_buffer
add esp, 8
.end_var_gen:
cmp dword [ebp - 4], 0
jl .minus
cmp dword [ebp - 4], 0
je .zero
.plus:
push plus_k
push dword [ebp + 16]
call write_to_buffer
add esp, 4
.minus:
push 10
push itoa_buffer
push dword [ebp - 4]
call itoa
add esp, 12
push itoa_buffer
push dword [ebp + 16]
call write_to_buffer
add esp, 8
.zero:
cmp dword [ebp - 16], 0
je .exit
push plus_k
push dword [ebp + 16]
call write_to_buffer
add esp, 4
mov eax, dword [ebp + 20]
push dword [registers + eax * 4]
push dword [ebp + 16]
call write_to_buffer
add esp, 8
.exit:
leave
ret 

; void generate_id_operand(quad* operand, table* func_var_table, char* buffer)
generate_id_operand:
push ebp
mov ebp, esp
sub esp, 4
mov dword [ebp - 4], 0
push dword [ebp + 12]
push dword [ebp + 8]
call check_in_gm
add esp, 8
cmp eax, 0
je .in_func_var
jmp .in_gm_var
.in_func_var:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, 0
sub eax, edx
mov dword [ebp - 4], eax
push ebp_k
push dword [ebp + 16]
call write_to_buffer
add esp, 8
cmp dword [ebp - 4], 0
jl .var
.param:
push plus_k
push dword [ebp + 16]
call write_to_buffer
add esp, 8
.var:
push 10
push itoa_buffer
push dword [ebp - 4]
call itoa
add esp, 12
push itoa_buffer
push dword [ebp + 16]
call write_to_buffer
add esp, 8
jmp .end_var_gen
.in_gm_var:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
push dword [eax]
push dword [ebp + 16]
call write_to_buffer
add esp, 8
.end_var_gen:
leave
ret

; char* get_size_prefix(quad* operand)
get_size_prefix:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
cmp dword [eax + 4], PRIMITIVE
jne .dword_size
cmp dword [eax + 12], 4
je .dword_size
cmp dword [eax + 12], 2
je .word_size 
.byte_size:
mov eax, byte_k
leave
ret
.word_size:
mov eax, word_k
leave
ret
.dword_size:
mov eax, dword_k
leave
ret

; char* morph_register(quad* dest_operand, int register)
morph_register:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
cmp dword [eax + 12], 4
jge .no_shrink
.shrink:
cmp dword [eax + 12], 2
je .word_shrink
.byte_shrink:
mov eax, dword [ebp + 12]
mov eax, dword [byte_registers + eax * 4]
jmp .exit
.word_shrink:
mov eax, dword [ebp + 12]
mov eax, dword [word_registers + eax * 4]
jmp .exit
.no_shrink:
mov eax, dword [ebp + 12]
mov eax, dword [registers + eax * 4]
.exit:
leave
ret

; void generate_div_swaps(int free_register)
generate_div_swaps:
push ebp
mov ebp, esp
.check_swap:
cmp dword [ebp + 8], 2
je .single_swap
cmp dword [ebp + 8], 3
je .double_swap
jmp .exit
.single_swap:
push edx_k
push ecx_k
call generate_swap
add esp, 8
jmp .exit
.double_swap:
push eax_k
push ecx_k
call generate_swap
add esp, 8
push edx_k
push eax_k
call generate_swap
add esp, 8
.exit:
leave
ret

; char* generate_div_prologue(quad* div_quad, int free_register)
generate_div_prologue:
push ebp
mov ebp, esp
.determine_sign:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
cmp dword [eax + 8], INT
je .signed_division
.unsigned_division:
push xor_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, div_k
jmp .exit
.signed_division:
push cdq_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, idiv_k
.exit:
leave
ret

; void generate_div_epilogue(int* free_register)
generate_div_epilogue:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
cmp dword [eax], 3
je .double_swap
cmp dword [eax], 2
je .single_swap
jmp .dec
.double_swap:
push eax_k
push edx_k
call generate_swap
add esp, 8
.single_swap:
push ecx_k
push eax_k
call generate_swap
add esp, 8
.dec:
mov eax, dword [ebp + 8]
cmp dword [eax], 1
je .exit
dec dword [eax]
.exit:
leave
ret

; bool check_in_gm(quad* id_quad, table* func_var_table)
check_in_gm:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
.check_in_gm:
mov eax, dword [eax + 4]
push dword [eax]
push dword [ebp + 12]
call hash_map_get
add esp, 8
cmp eax, 0
je .in_gm
jmp .in_func
.in_gm:
mov eax, 1
jmp .exit
.in_func:
xor eax, eax
jmp .exit
.exit:
leave
ret 

; bool upgrade_to_addr_quad(quad* op_quad, quad* id_quad, table* func_var_table)
; returns true if addr_quad needs to be generated afterwards else false (gm labels)
upgrade_to_addr_quad:
push ebp
mov ebp, esp
; sub esp, 4
; push dword [ebp + 16]
; push dword [ebp + 12]
; call check_in_gm
; add esp, 8
; cmp eax, 0
; je .in_func
; .in_gm:
; mov dword [ebp - 4], 0
; jmp .upgrade
; .in_func:
; mov dword [ebp - 4], 1
; jmp .exit
; .upgrade:
; mov eax, dword [ebp + 12]
; cmp dword [eax], ADDR_QUAD
; je .copy_over
; push 0
; push 0
; push 0
; push dword [ebp + 8]
; call load_addr_quad
; add esp, 16
; jmp .exit
; .copy_over:
; mov edx, dword [ebp + 12]
; mov eax, dword [ebp + 8]
; mov edx, dword [edx + 8]
; mov dword [eax + 8], edx
; .exit:
; mov eax, dword [ebp - 4]
leave
ret

; void generate_swap(char* dest_register, char* src_register)
generate_swap:
push ebp
mov ebp, esp
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 8]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 12]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
leave
ret

; bool check_if_const_operands(quad* left_operand, quad* right_operand)
check_if_numeric_constants:
push ebp
mov ebp, esp
sub esp, 4
mov eax, dword [ebp + 12]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
cmp dword [eax], NUM
je .check_other_operand
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 12]
cmp dword [eax], NUM
je .check_other_operand
mov eax, dword [ebp + 8]
cmp dword [eax], BOOL
jne .false
mov eax, dword [ebp + 12]
cmp dword [eax], BOOL
je .true
jmp .false
.check_other_operand:
mov eax, dword [ebp - 4]
cmp dword [eax], NUM
je .true
cmp dword [eax], BOOL
je .true
.false:
xor eax, eax
jmp .exit
.true:
mov eax, 1
.exit:
leave
ret

; void generate_div_by_constant_sign_pt(int constant, int free_register)
generate_div_by_constant_sign_pt:
push ebp
mov ebp, esp
sub esp, 8
mov dword [ebp - 4], 0
mov dword [ebp - 8], 0  ; neg check
cmp dword [ebp + 8], 0
jg .skip_check
mov dword [ebp - 8], 1
.skip_check:
mov eax, dword [ebp + 8]
mov edx, eax
bsf eax, edx
mov dword [ebp - 4], eax
cmp eax, 0
je .shift_right_unsigned
.form_the_integer:
mov eax, dword [ebp - 4]
dec eax
cmp eax, 0
je .shift_right_unsigned
mov eax, dword [ebp + 12]
dec eax 
push dword [registers + eax * 4]
inc eax
push dword [registers + eax * 4]
call generate_swap
add esp, 8
push sar_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push dword [ebp - 4]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
.shift_right_unsigned:
push shr_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, 32
sub eax, dword [ebp - 4]
push 10
push itoa_buffer
push eax
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
.add_to_constant:
push add_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
.shift_right_by_k:
push sar_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push dword [ebp - 4]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
cmp dword [ebp - 8], 0
je .exit
.negate:
push neg_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
dec eax
push dword [registers + eax * 4]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
.exit:
leave
ret

; void generate_div_by_constant_sign(int constant, int free_register)
generate_div_by_constant_unsign:
push ebp
mov ebp, esp
sub esp, 16
mov dword [ebp - 8], 0  ; shift amount
mov dword [ebp - 12], 0 ; add flag
cmp dword [ebp + 8], 3
je .magic_3
cmp dword [ebp + 8], 7
je .magic_7
jmp .gen_number_and_shift
.magic_3:
mov eax, dword [magic_num_3_unsigned]
mov dword [ebp - 4], eax
mov dword [ebp - 8], 1
mov dword [ebp - 12], 0 
jmp .a_flag_check
.magic_7:
mov eax, dword [magic_num_7_unsigned]
mov dword [ebp - 4], eax
mov dword [ebp - 8], 3
mov dword [ebp - 12], 1
jmp .a_flag_check
.gen_number_and_shift:
lea eax, dword [ebp - 12]
push eax
lea eax, dword [ebp - 8]
push eax
push dword [ebp + 8]
call get_magic_number_unsigned
add esp, 12
mov dword [ebp - 4], eax
.a_flag_check:
cmp dword [ebp - 12], 1
jne .gen
cmp dword [ebp + 8], 1
je .gen
.check_preserver:
cmp dword [non_scratch_reg_used], 1
je .gen
push ebx_k
call preserve_reg
add esp, 4
.gen:
cmp dword [ebp - 12], 1
je .a_flag_code
.no_a_flag_code:
cmp dword [ebp + 12], 1
je .skip_1
push eax_k
push ecx_k
call generate_swap
add esp, 8
push edx_k
push eax_k
call generate_swap
add esp, 8
.skip_1:
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push dword [ebp - 4]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push mul_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push shr_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push dword [ebp - 8]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, dword [ebp + 12]
push dword [registers + eax * 4]
push eax_k
call generate_swap
add esp, 8
jmp .exit
.a_flag_code:
cmp dword [ebp + 12], 1
je .skip_2
push edx_k
push ecx_k
call generate_swap
add esp, 8
push eax_k
push ebx_k
call generate_swap
add esp, 8
push edx_k
push eax_k
call generate_swap
add esp, 8
jmp .skip_2_else
.skip_2:
push eax_k
push ecx_k
call generate_swap
add esp, 8
.skip_2_else:
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push dword [ebp - 4]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push mul_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push sub_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ecx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push shr_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ecx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push 1
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push add_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ecx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push nl
push shr_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ecx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
mov eax, dword [ebp - 8]
dec eax
push eax
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
cmp dword [ebp + 12], 1
je .skip_3
push ecx_k
push edx_k
call generate_swap
add esp, 8
push ebx_k
push eax_k
call generate_swap
add esp, 8
jmp .exit
.skip_3:
push ecx_k
push eax_k
call generate_swap
add esp, 8
.exit:
leave
ret

; void generate_div_by_constant_sign(int constant, int free_register)
generate_div_by_constant_sign:
push ebp
mov ebp, esp
sub esp, 12
mov dword [ebp - 8], 0 ; shift amount
mov eax, dword [ebp + 8]
mov dword [ebp - 12], eax
cmp dword [ebp + 8], 3
je .magic_3
cmp dword [ebp + 8], 5
je .magic_5
cmp dword [ebp + 8], 7
je .magic_7
jmp .gen_number_and_shift
.magic_3:
mov eax, dword [magic_num_3]
mov dword [ebp - 4], eax
jmp .gen
.magic_5:
mov eax, dword [magic_num_5]
mov dword [ebp - 4], eax
jmp .gen
.magic_7:
mov eax, dword [magic_num_7]
mov dword [ebp - 4], eax
jmp .gen
.gen_number_and_shift:
lea eax, dword [ebp - 8]
push eax
push dword [ebp + 8]
call get_magic_number_signed
add esp, 8
mov dword [ebp - 4], eax
.gen:
cmp dword [ebp + 8], 0
jg .skip_negation
mov eax, dword [ebp + 8]
neg eax
mov dword [ebp + 8], eax
.skip_negation:
push eax_k
push ecx_k
call generate_swap
add esp, 8
cmp dword [ebp + 12], 2
jne .skip_swaps
push edx_k
push eax_k
call generate_swap
add esp, 8
push edx_k
push ebx_k
call generate_swap
add esp, 8
.skip_swaps:
push mov_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push dword [ebp - 4]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push imul_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
cmp dword [ebp + 8], 3
je .skip_shift
cmp dword [ebp + 8], 5
je .shift_5
cmp dword [ebp + 8], 7
je .add_shift_7
.shift_for_other:
push sar_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push dword [ebp - 8]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .skip_shift
.shift_5:
push sar_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push 1
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
jmp .skip_shift
.add_shift_7:
push add_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
cmp dword [ebp + 12], 2
je .num_in_ebx
.num_in_ecx:
mov eax, ecx_k
jmp .shift_7
.num_in_ebx:
mov eax, ebx_k
.shift_7:
push eax
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
push sar_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push 2
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
.skip_shift:
cmp dword [ebp + 12], 2
jne .skip_swap_2
; mov eax, ecx
; mov ecx, ebx
push ecx_k
push eax_k
call generate_swap
add esp, 8
push ebx_k
push ecx_k
call generate_swap
add esp, 8
.skip_swap_2:
push sar_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ecx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push 10
push itoa_buffer
push 31
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
cmp dword [ebp - 12], 0
jl .exit_negative
push sub_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ecx_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
cmp dword [ebp + 12], 2
je .exit
push edx_k
push eax_k
call generate_swap
add esp, 8
jmp .exit
.exit_negative:
push sub_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push ecx_k
call print_string_raw
add esp, 4
push comma_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push edx_k
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
cmp dword [ebp + 12], 2
je .exit
push ecx_k
push eax_k
call generate_swap
add esp, 8
.exit:
leave
ret

; int get_magic_number_unsigned(int denominator, int* shift_ptr, int* add_flag_ptr)
get_magic_number_unsigned:
push ebp
mov ebp, esp
sub esp, 56
; ebp - 4  | lower max
; ebp - 8  | upper max
; ebp - 12 | n_c
; ebp - 16 | w
; ebp - 20 | remainder
; ebp - 24 | lower 2^p
; ebp - 28 | upper 2^p
; ebp - 32 | power
; ebp - 36 | lower right_side
; ebp - 40 | upper right_side
; ebp - 44 | lower m
; ebp - 48 | upper m
; ebp - 52 | null ptr
; ebp - 56 | null ptr
mov dword [ebp - 4], 0
mov dword [ebp - 8], 1
mov dword [ebp - 16], 32
mov dword [ebp - 24], 0
mov dword [ebp - 28], 1
mov dword [ebp - 32], 32
mov eax, dword [ebp - 4]
mov edx, dword [ebp - 8]
div dword [ebp + 8]
mov dword [ebp - 20], edx
mov eax, dword [ebp - 4]
sub eax, edx
sub eax, 1
mov dword [ebp - 12], eax
.loop:
mov eax, dword [ebp - 24]
mov edx, dword [ebp - 28]
sub eax, 1
sbb edx, 0
lea ecx, dword [ebp - 52]
push ecx
lea ecx, dword [ebp - 56]
push ecx
push dword [ebp + 8]
push eax
push edx
call get_remainder
add esp, 20
mov dword [ebp - 20], eax
mov edx, dword [ebp - 20]
mov eax, dword [ebp + 8]
sub eax, 1
sub eax, edx
xor edx, edx
mul dword [ebp - 12]
mov dword [ebp - 36], eax
mov dword [ebp - 40], edx
mov eax, dword [ebp - 24]
sub eax, dword [ebp - 36]
mov edx, dword [ebp - 28]
sbb edx, dword [ebp - 40]
jnc .end_loop
mov edx, dword [ebp - 28]
shl edx, 1
mov dword [ebp - 28], edx
jmp .loop
.end_loop:
mov eax, dword [ebp - 24]
mov edx, dword [ebp - 28]
add eax, dword [ebp + 8]
adc edx, 0
sub eax, 1
sbb edx, 0
sub eax, dword [ebp - 20]
sbb edx, 0
lea ecx, dword [ebp - 44]
push ecx
lea ecx, dword [ebp - 48]
push ecx
push dword [ebp + 8]
push eax
push edx
call get_remainder
add esp, 20
bsf eax, dword [ebp - 28]
add eax, 32
sub eax, dword [ebp - 16]
mov edx, dword [ebp + 12]
mov dword [edx], eax
mov eax, dword [ebp - 44]
cmp eax, dword [ebp - 4]
mov edx, dword [ebp - 48]
sbb edx, dword [ebp - 8]
mov eax, dword [ebp + 16]
mov dword [eax], 0
jl .exit
.correction:
mov eax, dword [ebp - 44]
sub eax, dword [ebp - 4]
mov edx, dword [ebp - 48]
sbb edx, dword [ebp - 8]
mov dword [ebp - 44], eax
mov eax, dword [ebp + 16]
mov dword [eax], 1
.exit:
mov eax, dword [ebp - 44]
leave
ret

; int get_magic_number_signed(int denominator, int* shift_ptr)
; TODO: add generation for unique negative denominators
get_magic_number_signed:
push ebp
mov ebp, esp
sub esp, 52
; ebp - 4  | lower max
; ebp - 8  | upper max
; ebp - 12 | n_c
; ebp - 16 | w
; ebp - 20 | remainder
; ebp - 24 | lower 2^p
; ebp - 28 | upper 2^p
; ebp - 32 | power
; ebp - 36 | lower right_side
; ebp - 40 | upper right_side
; ebp - 44 | lower m
; ebp - 48 | upper m
; ebp - 52 | -n_c
mov dword [ebp - 4], 0x8000_0000
mov dword [ebp - 8], 0
mov dword [ebp - 16], 32
mov dword [ebp - 24], 0
mov dword [ebp - 28], 1
mov dword [ebp - 32], 32
cmp dword [ebp + 8], 0
jg .pos
.negate_divisor:
mov eax, dword [ebp + 8]
neg eax
mov dword [ebp + 8], eax
.pos:
mov eax, dword [ebp - 4]
mov edx, dword [ebp - 8]
div dword [ebp + 8]
mov dword [ebp - 20], edx
mov eax, dword [ebp - 4]
sub eax, edx
sub eax, 1
mov dword [ebp - 12], eax
.loop:
mov eax, dword [ebp - 24]
mov edx, dword [ebp - 28]
div dword [ebp + 8]
mov dword [ebp - 20], edx
mov eax, dword [ebp + 8]
sub eax, edx
xor edx, edx
mul dword [ebp - 12]
mov dword [ebp - 36], eax
mov dword [ebp - 40], edx
mov eax, dword [ebp - 24]
sub eax, dword [ebp - 36]
mov edx, dword [ebp - 28]
sbb edx, dword [ebp - 40]
jnc .end_loop
mov edx, dword [ebp - 28]
shl edx, 1
mov dword [ebp - 28], edx
jmp .loop
.end_loop:
mov eax, dword [ebp - 24]
add eax, dword [ebp + 8]
mov edx, dword [ebp - 28]
adc edx, 0
sub eax, dword [ebp - 20]
sbb edx, 0
div dword [ebp + 8]
mov dword [ebp - 44], eax
mov dword [ebp - 48], edx
bsf eax, dword [ebp - 28]
add eax, 32
sub eax, dword [ebp - 16]
mov edx, dword [ebp + 12]
mov dword [edx], eax
mov eax, dword [ebp - 44]
cmp eax, dword [ebp - 4]
mov edx, dword [ebp - 48]
sbb edx, 0
jl .exit
.correction:
mov dword [ebp - 24], 0
mov dword [ebp - 28], 1
mov eax, dword [ebp - 44]
sub eax, dword [ebp - 24]
mov edx, dword [ebp - 48]
sbb edx, dword [ebp - 28]
mov dword [ebp - 44], eax
.exit:
mov eax, dword [ebp - 44]
leave
ret

; uint get_remainder(uint high_bits, uint low_hits, uint denominator, uint* quotient_high, uint* quotient_low)
get_remainder:
push ebp
mov ebp, esp
sub esp, 24
mov dword [ebp - 4], 0x8000_0000    ; m
mov dword [ebp - 8], 0              ; b
mov dword [ebp - 12], 0             ; bit
mov dword [ebp - 16], 0             ; q_low
mov dword [ebp - 20], 0             ; q_high
mov dword [ebp - 24], 0
.loop_1:
cmp dword [ebp - 4], 0
je .end_loop_1
cmp dword [ebp + 8], 0
je .end_loop_1
mov eax, dword [ebp + 8]
mov edx, dword [ebp - 4]
and eax, edx
cmp eax, 0
jne .one_1
.zero_1:
mov eax, 0
jmp .shift_1
.one_1:
mov eax, 1
.shift_1:
mov edx, dword [ebp - 8]
shl edx, 1
or edx, eax
mov dword [ebp - 8], edx
cmp edx, dword [ebp + 16]
jb .skip_1
mov eax, dword [ebp + 16]
sub edx, eax
mov dword [ebp - 8], edx
mov eax, dword [ebp - 16]
shl eax, 1
or eax, 1
mov dword [ebp - 16], eax 
jmp .shift
.skip_1:
shl dword [ebp - 16], 1
.shift:
shr dword [ebp - 4], 1
jmp .loop_1
.end_loop_1:
; reset m
mov dword [ebp - 4], 0x8000_0000
.loop_2:
cmp dword [ebp - 4], 0
je .end_loop_2
mov eax, dword [ebp + 12]
mov edx, dword [ebp - 4]
and eax, edx
cmp eax, 0
jne .one_2
.zero_2:
mov dword [ebp - 12], 0
jmp .check
.one_2:
mov dword [ebp - 12], 1
.check:
mov eax, dword [ebp - 8]
bsr eax, eax
add eax, 1
cmp eax, 32
jne .shift_2
.sub_high:
mov eax, dword [ebp + 12]
and eax, dword [ebp - 4]
cmp eax, 0
jne .no_borrow
.borrow:
mov eax, dword [ebp - 8]
sub eax, 1
mov edx, dword [ebp + 16]
shr edx, 1
sub eax, edx
shl eax, 1
or eax, 1
mov dword [ebp - 8], eax
shr dword [ebp - 4], 1
mov eax, dword [ebp - 16]
shl eax, 1
setc cl
movzx ecx, cl
mov edx, dword [ebp - 20]
shl edx, 1
or edx, ecx
mov dword [ebp - 20], edx
or eax, 1
mov dword [ebp - 16], eax
jmp .loop_2
.no_borrow:
mov eax, dword [ebp - 8]
mov edx, dword [ebp + 16]
shr edx, 1
sub eax, edx
shl eax, 1
mov dword [ebp - 8], eax
shr dword [ebp - 4], 1
mov eax, dword [ebp - 16]
shl eax, 1
setc cl
movzx ecx, cl
mov edx, dword [ebp - 20]
shl edx, 1
or edx, ecx
mov dword [ebp - 20], edx
or eax, 1
mov dword [ebp - 16], eax
jmp .loop_2

.shift_2:
mov eax, dword [ebp - 8]
shl eax, 1
or eax, dword [ebp - 12]
mov dword [ebp - 8], eax
mov dword [ebp - 12], 0
cmp eax, dword [ebp + 16]
jb .skip_3
mov edx, dword [ebp + 16]
sub eax, edx
mov dword [ebp - 8], eax
mov dword [ebp - 12], 1
.skip_3:
mov eax, dword [ebp - 16]
shl eax, 1
setc cl
movzx ecx, cl
mov edx, dword [ebp - 20]
shl edx, 1
or edx, ecx
mov dword [ebp - 20], edx
or eax, dword [ebp - 12]
mov dword [ebp - 16], eax
shr dword [ebp - 4], 1
jmp .loop_2
.end_loop_2:
mov edx, dword [ebp + 24]
mov eax, dword [ebp - 16]
mov dword [edx], eax
mov edx, dword [ebp + 20]
mov eax, dword [ebp - 20]
mov dword [edx], eax
mov eax, dword [ebp - 8]
leave
ret

; void preserve_reg(char* reg)
preserve_reg:
push ebp
mov ebp, esp
mov dword [non_scratch_reg_used], 1
mov eax, dword [old_cursor_x]
mov edx, dword [cursor_x_ptr]
mov dword [old_cursor_x], edx
mov dword [cursor_x_ptr], eax
mov eax, dword [old_cursor_y]
mov edx, dword [cursor_y_ptr]
mov dword [old_cursor_y], edx
mov dword [cursor_y_ptr], eax
push push_k
call print_string_raw
add esp, 4
push space
call print_string_raw
add esp, 4
push dword [ebp + 8]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
mov eax, dword [old_cursor_x]
mov dword [cursor_x_ptr], eax
mov eax, dword [old_cursor_y]
mov dword [cursor_y_ptr], eax
leave
ret

; int quad_tag_to_rel_tag(int rel_op_tag)
quad_tag_to_rel_tag:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
cmp eax, BRANCH_NE
jg .exit
sub eax, BRANCH_LT
add eax, LT
.exit:
leave
ret

; int rotate_rel_op(int rel_tag)
rotate_rel_op:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
sub eax, LT
mov eax, dword [rel_ops_signed_rot_table + eax * 4]
leave
ret

; BUFFER UTILS
; STRUCTURE: buffer<int buffer_type, char* raw_buffer, char* left_decorator, char* gm_label, char* right_decorator, quad* offset>
; buffer* get_buffer(int bytes)
get_buffer:
push ebp
mov ebp, esp
sub esp, 4
push 16
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax
push dword [ebp + 8]
call heap_alloc
add esp, 4
mov byte [eax], 0
mov edx, dword [ebp -4]
mov dword [edx + 4], eax
mov dword [edx], 0
mov dword [edx + 8], 0
mov dword [edx + 12], 0
mov eax, edx
leave
ret

; void write_to_buffer(buffer* buffer, char* str)
write_to_buffer:
push ebp
mov ebp, esp
sub esp, 8
mov eax, dword [ebp + 8]
mov dword [eax], CONST_OR_STACK_ADDR
mov dword [ebp - 4], 0      ; counter
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov dword [ebp - 8], eax    ; buffer pointer
;find null terminator
.null_loop:
mov eax, dword [ebp - 8]
cmp byte [eax], 0   ; null terminator
je .write_loop
inc dword [ebp - 4]
inc dword [ebp - 8]
jmp .null_loop
.write_loop:
; ; buffer overflow safeguard
cmp dword [ebp - 4], BUFFER_CAPACITY
jne .continue
.flush:
push dword [ebp + 8]
call flush_buffer
add esp, 4
mov eax, dword [ebp + 8]
mov dword [ebp - 8], eax    ; reset pointer
mov dword [ebp - 4], 0      ; reset counter
.continue:
mov eax, dword [ebp + 12]
cmp byte [eax], 0
je .end_write
; write char
mov edx, dword [ebp - 8]
mov al, byte [eax]
mov byte [edx], al
inc dword [ebp - 4]
inc dword [ebp - 8]
inc dword [ebp + 12]
jmp .write_loop
.end_write:
mov eax, dword [ebp - 8]
mov byte [eax], 0
leave
ret

; void flush_buffer(buffer* buffer)
flush_buffer:
push ebp
mov ebp, esp
.regular_flush:
mov eax, dword [ebp + 8]
push dword [eax + 4]
call print_string_raw
add esp, 4
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov byte dword [eax], 0
leave
ret

; void clear_buffer(buffer* buffer)
clear_buffer:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
cmp dword [eax], GM_ADDR
je .gm_clear
.reg_clear:
mov eax, dword [ebp + 8]
mov dword [eax], 0
mov eax, dword [eax + 4]
mov byte [eax], 0
jmp .exit
.gm_clear:

.exit:
leave
ret

print_number_raw:
push ebp
mov ebp, esp
push 10
push itoa_buffer
push dword [ebp+8]
call itoa
add esp, 12
push itoa_buffer
call print_string_raw
add esp, 4
mov eax, 0
leave
ret

print_line_raw:
push ebp
mov ebp, esp
push dword [ebp+8]
call print_string_raw
add esp, 4
push nl
call print_string_raw
add esp, 4
leave
ret

print_string_raw:
push ebp
mov ebp, esp
.L3:
mov eax, dword [ebp+8]
movsx eax, byte [eax]
cmp eax, 0
je .L2
.L1:
mov eax, dword [ebp+8]
movsx eax, byte [eax]
mov edx, dword [output_p]
mov edx, dword [edx]
mov ecx, dword [output_addr]
add edx, ecx
mov byte [edx], al
mov eax, dword [output_p]
mov eax, dword [eax]
add eax, 1
mov edx, dword [output_p]
mov dword [edx], eax
mov eax, dword [ebp+8]
add eax, 1
mov dword [ebp+8], eax
jmp .L3
.L2:
mov eax, 0
leave
ret

output_addr: dd output_buffer_ptr
output_p: dd 0

; sizes
byte_k: db "byte", 0
word_k: db "word", 0
dword_k: db "dword", 0
; registers
al_k: db "al", 0
dl_k: db "dl", 0
cl_k: db "cl", 0
bl_k: db "bl", 0
ax_k: db "ax", 0
cx_k: db "cx", 0
dx_k: db "dx", 0
bx_k: db "bx", 0
di_k: db "di", 0
si_k: db "si", 0
eax_k: db "eax", 0
ecx_k: db "ecx", 0
edx_k: db "edx", 0
ebx_k: db "ebx", 0
edi_k: db "edi", 0
esi_k: db "esi", 0
rax_k: db "rax", 0
rcx_k: db "rcx", 0
rdx_k: db "rdx", 0
ebp_k: db "ebp", 0
esp_k: db "esp", 0
; operations
push_k: db "push", 0
pop_k: db "pop", 0
cmp_k: db "cmp", 0
setnb_k: db "setnb", 0
mov_k: db "mov", 0
movsx_k: db "movsx", 0
movzx_k: db "movzx", 0
shr_k: db "shr", 0
sar_k: db "sar", 0
xor_k: db "xor", 0
neg_k: db "neg", 0
sub_k: db "sub", 0
add_k: db "add", 0
mul_k: db "mul", 0
imul_k: db "imul", 0
idiv_k: db  "idiv", 0
div_k: db "div", 0
cdq_k: db "cdq", 0
lea_k: db "lea", 0
call_k: db "call", 0
jl_k: db "jl", 0
jle_k: db "jle", 0
jg_k: db "jg", 0
jge_k: db "jge", 0
jb_k: db "jb", 0
jbe_k: db "jbe", 0
ja_k: db "ja", 0
jae_k: db "jae", 0
je_k: db "je", 0
jne_k: db "jne", 0
jmp_k: db "jmp", 0
setl_k: db "setl", 0
setle_k: db "setle", 0
setg_k: db "setg", 0
setge_k: db "setge", 0
setb_k: db "setb", 0
setbe_k: db "setbe", 0
seta_k: db "seta", 0
setae_k: db "setae", 0
sete_k: db "sete", 0
setne_k: db "setne", 0
leave_k: db "leave", 0
ret_k: db "ret", 0
; misc
not_implemented: db "This operand generation is not yet implemented", 0
double_quote_k: db '"', 0
back_quote_k: db "`", 0
db_k: db "db", 0
str_label: db "..@LC", 0
magic_num_3: dd 0x55555556
magic_num_5: dd 0x66666667
magic_num_7: dd 0x92492493
magic_num_3_unsigned: dd 0xAAAAAAAB 
magic_num_7_unsigned: dd 0x24924925
func_prologue_end: dd 0
old_cursor_x: dd 0
old_cursor_y: dd 0
non_scratch_reg_used: dd 0
resb_k: db "resb", 0
minus_k: db "-", 0
plus_k: db "+", 0
rel_ops_signed_rot_table:
dd GT 
dd GE
dd LT
dd LE
dd EQ
dd NE
branch_ops_signed:
dd jl_k
dd jle_k
dd jg_k
dd jge_k
dd je_k
dd jne_k
branch_ops_unsigned:
dd jb_k
dd jbe_k
dd ja_k
dd jae_k
dd je_k
dd jne_k
rel_ops_signed:
dd setl_k
dd setle_k
dd setg_k
dd setge_k
dd sete_k
dd setne_k
rel_ops_unsigned:
dd setb_k
dd setbe_k
dd seta_k
dd setae_k
dd sete_k
dd setne_k
byte_registers:
dd al_k 
dd dl_k
dd cl_k
dd bl_k
word_registers:
dd ax_k
dd dx_k
dd cx_k
dd bx_k
dd di_k
dd si_k
registers: 
dd eax_k 
dd edx_k
dd ecx_k
dd ebx_k
dd edi_k
dd esi_k
ext_registers:
dd rax_k
dd rdx_k
dd rdx_k
num_quad:
dd NUM
dd 0
dd 0
dd 0
addr_quad:
dd ADDR_QUAD
dd 0
dd 0
dd 0
dual_quad:
dd DUAL_QUAD
dd 0
dd 0
dd 0
reg_quad:
dd REG_QUAD
dd 0
dd 0
dd 0
unsigned_reg_quad:
dd REG_QUAD
dd 0
dd 0
dd 0
loaded_reg_quad:
dd REG_QUAD
dd 0
dd 0
dd 0