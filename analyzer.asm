[bits 32]

%define PRIMITIVE 0
%define POINTER 1
%define ARRAY 2
%define STRUCTURE 3


%define ARITHMETIC_ADD_SUB_OP 1
%define ARITHMETIC_MUL_DIV_OP 2
%define LOGIC_OP 3

%define START -1
%define ASSIG_OP 0
%define UNARY_MINUS_OP 1
%define NEG_OP 2
%define DEREF_OP 3
%define ADDRESS_OP 4
%define ACCESS_OP 5
%define PLUS_OP 6
%define MINUS_OP 7
%define MUL_OP 8
%define DIV_OP 9
%define GOTO 10
%define LABEL 11
%define PARAM 12
%define CALL 13

; RE -> + T RE | - T RE | eps  
; RT -> * F RT | / F RT | eps                     // first(RT) = {*, /, eps}
; RelOp -> > | >= | < | <= | == | !=              // first(RelOp) = {>, >=, <, <=, ==, !=}
; UnionT -> || RelE Intersect UnionT | eps
; Intersect -> && RelE Intersect | eps


; bool analyzer(Tree_Node* root, table* type_table, table* var_table, table* func_table)
analyzer:
push ebp 
mov ebp, esp 
sub esp, 8
mov dword [ebp - 4], 0      ; **DS pointer
mov dword [ebp - 8], 0      ; table pointer
; analyze the constructed parse tree
; Tree_Node <int tag, token* token, int child_count, Tree_Node* children> 
; add all declared types to type_table
mov eax, dword [ebp + 8]    ; parse tree root pointer
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax]        ; load first child
mov dword [ebp - 4], eax
.declared_types_loop:
mov eax, dword [ebp - 4]    ; load TyDS
cmp dword [eax + 8], 0      ; check if there is a type declaration
je .no_types_declared
lea eax, dword [eax + 12]   ; load children
mov edx, dword [eax + 4]
mov dword [ebp - 4], edx    ; save rest of TyDS
mov eax, dword [eax]        ; deref TyD
lea eax, dword [eax + 12]   ; get TyD children
mov edx, dword [eax + 4]    ; get TE
push dword [ebp + 12]
push edx 
call add_type
add esp, 8
cmp eax, 0
je .error_exit
jmp .declared_types_loop
.no_types_declared:
; add all declared variables to gm (var_table)
mov eax, dword [ebp + 8]    ; load parse tree root
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load second child VaDS
mov dword [ebp - 4], eax    ; save VaDS
.declared_vars_loop:
mov eax, dword [ebp - 4]    ; load VaDS
cmp dword [eax + 8], 0      ; check if any gm variables declared
je .no_vars_declared
lea eax, dword [eax + 12]   ; load children baddr
mov edx, dword [eax + 4]    ; load next VaDS
mov dword [ebp - 4], edx    ; save next VaDS
mov eax, dword [eax]        ; load VaD
push 0
push dword [ebp + 16]
push dword [ebp + 12]
push eax 
call add_var
add esp, 16
cmp eax, 0  ; error while adding var
je .error_exit
jmp .declared_vars_loop
.no_vars_declared:
; add all declared functios to func_table
mov eax, dword [ebp + 8]    ; load parse tree root
lea eax, dword [eax + 12]   ; children baddr
mov eax, dword [eax + 8]    ; load third child FuDS
mov dword [ebp - 4], eax    ; save FuDS
.declared_funcs_loop:
mov eax, dword [ebp - 4]
cmp dword [eax + 8], 0
je .exit
lea eax, dword [eax + 12]
mov edx, dword [eax + 4]   ; load next FuDS
mov dword [ebp - 4], edx   ; save FuDS
mov eax, dword [eax]       ; load FuD
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax 
call add_func
add esp, 16
cmp eax, 0      ; error while adding func
je .error_exit
jmp .declared_funcs_loop
.exit:
mov eax, 1
leave
ret 
.error_exit:
xor eax, eax
leave
ret

; entry* get_var_entry(char* key, hash_map* type_entry)
get_var_entry:
push ebp 
mov ebp, esp 
sub esp, 4
push 12
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax
mov eax, dword [ebp - 4]
mov edx, dword [ebp + 8]
mov dword [eax], edx 
mov edx, dword [ebp + 12]
mov dword [eax + 4], edx
mov dword [eax + 8], 0
leave
ret


; entry* get_func_entry(char* key, entry* r_type, hash_map* var_table, linked_list* params, Tree_node* body)
get_func_entry:
push ebp
mov ebp, esp 
sub esp, 4
push 20
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax
mov eax, dword [ebp - 4]
mov edx, dword [ebp + 8]
mov dword [eax], edx 
mov edx, dword [ebp + 12]
mov dword [eax + 4], edx 
mov edx, dword [ebp + 16]
mov dword [eax + 8], edx 
mov edx, dword [ebp + 20]
mov dword [eax + 12], edx
mov edx, dword [ebp + 24]
mov dword [eax + 16], edx
leave
ret

; entry* get_primitive_entry(char* key, int type, uint size)
get_primitive_entry:
push ebp
mov ebp, esp 
sub esp, 4
push 16 
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax 
mov eax, dword [ebp - 4]
mov edx, dword [ebp + 8]
mov dword [eax], edx 
mov dword [eax + 4], PRIMITIVE
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
mov edx, dword [ebp + 16]
mov dword [eax + 12], edx
leave
ret 

; entry* get_composite_p_entry(char* key, entry* entry)
get_composite_p_entry:
push ebp
mov ebp, esp 
sub esp, 4
push 16 
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax 
mov eax, dword [ebp - 4]
mov edx, dword [ebp + 8]
mov dword [eax], edx 
mov dword [eax + 4], POINTER
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
mov dword [eax + 12], 4
leave
ret

; entry* get_composite_arr_entry(char* key, entry* entry, uint size)
get_composite_arr_entry:
push ebp
mov ebp, esp 
sub esp, 8
push 16 
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax 
mov eax, dword [ebp - 4]
mov edx, dword [ebp + 8]
mov dword [eax], edx 
mov dword [eax + 4], ARRAY
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
mov edx, dword [ebp + 16]
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
mul edx
mov dword [ebp - 8], eax
mov eax, dword [ebp - 4]
mov edx, dword [ebp - 8]
mov dword [eax + 12], edx
leave
ret 

; entry* get_composite_struct_entry(char* key, hash_map* var_table, uint size)
get_composite_struct_entry:
push ebp 
mov ebp, esp 
sub esp, 4
push 20 
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax 
mov eax, dword [ebp - 4]
mov edx, dword [ebp + 8]
mov dword [eax], edx 
mov dword [eax + 4], STRUCTURE
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
mov edx, dword [ebp + 16]
mov dword [eax + 12], edx
mov dword [eax + 16], 0
leave
ret

; entry* construct_type(Tree_node* node, hash_map* type_table)
construct_type:
push ebp
mov ebp, esp
sub esp, 24 
mov dword [ebp - 4], 0      ; TE pointer
mov dword [ebp - 8], 0      ; new_name_lexeme pointer
mov dword [ebp - 12], 0     ; ref_type_lexeme pointer
mov dword [ebp - 16], 0     ; TyDeco pointer
mov dword [ebp - 20], 0     ; composite contruction entry pointer
mov dword [ebp - 24], 0     ; Decorator pointer
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax    ; save TE|VaD
lea eax, dword [eax + 12]   ; get TE children
mov edx, dword [eax]
cmp dword [edx], FUNC       ; check if func type
jne .not_a_func
mov edx, dword [eax + 4]    ; load Ty
mov dword [ebp - 28], edx   ; save Ty 
mov edx, dword [eax + 8]    ; load TyDeco
mov dword [ebp - 32], edx   ; save TyDeco
.not_a_func:
cmp dword [edx], STRUCT     ; check if TE is a struct
jne .not_a_struct
push dword [ebp + 12]
push dword [ebp - 4]
call construct_struct
add esp, 8
cmp eax, 0
je .error_exit
leave
ret
; add struct parsing
jmp .end_check
.not_a_struct:
mov eax, dword [eax + 8]    ; get TyNa|Na
.end_check: 
mov eax, dword [eax + 4]    ; get token
mov eax, dword [eax + 4]    ; get lexeme
mov dword [ebp - 8], eax   ; save new_type_lexeme|new_var_lexeme
; detect type complexity
; get ref_type_lexeme
mov eax, dword [ebp - 4]    ; load TE|VaD 
mov eax, dword [eax + 12]   ; load Ty
mov eax, dword [eax + 12]   ; load child
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 12], eax   ; save ref_type_lexeme
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
mov dword [ebp - 20], eax   ; save ref_type entry
; start chain construction of pointer/array types
mov eax, dword [ebp - 4]    ; load TE
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load TyDeco 
mov dword [ebp - 16], eax   ; save TyDeco
cmp dword [eax + 8], 0      ; check if any decorators are present
je .simple_type
; go over the pointer chains
mov eax, dword [eax + 12]   ; load PDeco
mov dword [ebp - 24], eax   ; save PDeco
.pointer_loop:
mov eax, dword [ebp - 24]
cmp dword [eax + 8], 0
je .check_arrays
push dword [ebp - 20]
push pointer
call get_composite_p_entry
add esp, 8
mov dword [ebp - 20], eax
mov eax, dword [ebp - 24]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov dword [ebp - 24], eax
jmp .pointer_loop
.check_arrays:
mov eax, dword [ebp - 16]   ; load TyDeco
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]    ; load ArrDeco
mov dword [ebp - 24], eax   ; save ArrDeco
.array_loop:
mov eax, dword [ebp - 24]
cmp dword [eax + 8], 0
je .composite_type
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load Num node
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
push eax 
push dword [ebp - 20]
push array
call get_composite_arr_entry
add esp, 12
mov dword [ebp - 20], eax
mov eax, dword [ebp - 24]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov dword [ebp - 24], eax
jmp .array_loop
.composite_type:
mov eax, dword [ebp - 8]
mov edx, dword [ebp - 20]
mov dword [edx], eax 
mov eax, edx
leave
ret
; simple type aka shadow name
; pass the declared type entry to the new type
.simple_type:
mov eax, dword [ebp - 20]
leave
ret
.error_exit:
xor eax, eax 
leave
ret


; entry* construct_struct(Tree_node* node, hash_map* type_table)
construct_struct:
push ebp 
mov ebp, esp
sub esp, 48
mov dword [ebp - 24], 0     ; alignment_size
mov dword [ebp - 28], 0     ; variable name pointer     
mov dword [ebp - 32], 0     ; prev_size aka the alignment of the last variable
mov dword [ebp - 36], 0     ; streak_size
mov dword [ebp - 40], 0     ; total_size
mov dword [ebp - 44], 0     ; variable_entry buffer
push 16
push 4
call get_hash_map
add esp, 8
mov dword [ebp - 12], eax   ; save struct var_table
mov dword [ebp - 8], 0      ; entry pointer
mov eax, dword [ebp + 8]    ; load TE
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load TyNa
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 16], eax   ; save TyNa lexeme
push 0
push dword [ebp - 12]
push dword [ebp - 16]
call get_composite_struct_entry
add esp, 12
mov dword [ebp - 20], eax   ; save struct_entry
; load struct_entry into type_table for self referencing
push dword [ebp - 20]
push dword [ebp - 16]
push dword [ebp + 12]
call hash_map_put
add esp, 12
mov eax, dword [ebp + 8]    ; load TE
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 12]   ; load VaDS
mov dword [ebp - 4], eax    ; save VaDS
.declared_vars_loop:
mov eax, dword [ebp - 4]    ; load VaDS
cmp dword [eax + 8], 0      ; check if any gm variables declared
je .no_vars_declared
lea eax, dword [eax + 12]   ; load children baddr
mov edx, dword [eax + 4]    ; load next VaDS
mov dword [ebp - 4], edx    ; save next VaDS
mov eax, dword [eax]        ; load VaD
lea edx, dword [eax + 12]   ; load children baddr
mov edx, dword [edx + 8]    ; load Na
mov edx, dword [edx + 4]    ; load token
mov edx, dword [edx + 4]    ; load lexeme
mov dword [ebp - 28], edx
push dword [ebp + 8]
push dword [ebp - 12]
push dword [ebp + 12]
push eax 
call add_var
add esp, 16
cmp eax, 0  ; error while adding var
je .error_exit
push dword [ebp - 28]
push dword [ebp - 12]
call hash_map_get
add esp, 8
push eax
call get_var_alignment
add esp, 4
cmp eax, dword [ebp - 24]
jl .declared_vars_loop
mov dword [ebp - 24], eax
jmp .declared_vars_loop
.no_vars_declared:
.alignment_routine:
mov eax, dword [ebp + 8]    ; load TE
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 12]   ; load VaDS
mov dword [ebp - 4], eax    ; save VaDS
.alignment_loop:
mov eax, dword [ebp - 4]    ; load VaDS
cmp dword [eax + 8], 0
je .tail_pad_check
lea eax, dword [eax + 12]   ; load children baddr
mov edx, dword [eax + 4]    ; load next VaDS
mov dword [ebp - 4], edx
mov eax, dword [eax]        ; load VaD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 8]    ; load Na
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
push eax
push dword [ebp - 12]
call hash_map_get
add esp, 8
mov dword [ebp - 44], eax   ; save variable_entry
push eax 
call get_var_alignment
add esp, 4
cmp dword [ebp - 32], 0
jne .else
mov dword [ebp - 32], eax   ; save current alignment as prev_size
mov eax, dword [ebp - 44]   ; load var_entry
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]   ; get size
mov dword [ebp - 40], eax   ; total_size = cur_size
mov dword [ebp - 36], eax   ; streak_size = cur_size
jmp .alignment_loop
.else:
cmp eax, dword [ebp - 32]   ; align > prev_size
jle .less
mov dword [ebp - 32], eax   ; prev_size = align
sub eax, dword [ebp - 36]   ; delta = align - streak_size
add dword [ebp - 40], eax 
add dword [ebp - 36], eax
jmp .equal
.less:
cmp eax, dword [ebp - 32]   ; align < prev_size
je .equal
mov dword [ebp - 32], eax   ; prev_size = align
mov dword [ebp - 36], 0     ; streak_size = 0
.equal:
mov eax, dword [ebp - 44]   ; load var_entry
mov edx, dword [ebp - 40]   ; load total_size
mov dword [eax + 8], edx    ; offset = total_size
mov eax, dword [eax + 4]    ; load type
mov eax, dword [eax + 12]   ; load cur_size
add dword [ebp - 40], eax
add dword [ebp - 36], eax
jmp .alignment_loop
.tail_pad_check:
cmp dword [ebp - 24], 1
je .no_tail_pad
mov eax, dword [ebp - 40]
and eax, 3
cmp eax, 0
je .no_tail_pad
mov eax, dword [ebp - 40]
add eax, 4
shr eax, 2
shl eax, 2
mov dword [ebp - 40], eax
.no_tail_pad:
mov eax, dword [ebp - 20]
mov edx, dword [ebp - 40]
mov dword [eax + 12], edx 
mov edx, dword [ebp - 24]
mov dword [eax + 16], edx
leave
ret
.error_exit:
xor eax, eax
leave
ret

; entry* construct_struct_var(Tree_node* node, hash_map* type_table, char* struct_name)
construct_struct_var:
push ebp 
mov ebp, esp
sub esp, 24 
mov dword [ebp - 4], 0      ; VaD pointer
mov dword [ebp - 8], 0      ; new_name_lexeme pointer
mov dword [ebp - 12], 0     ; type_lexeme pointer
mov dword [ebp - 16], 0     ; TyDeco pointer
mov dword [ebp - 20], 0     ; composite contruction entry pointer
mov dword [ebp - 24], 0     ; Decorator pointer
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax    ; save VaD
lea eax, dword [eax + 12]   ; get VaD children
mov eax, dword [eax + 8]    ; load Na
mov eax, dword [eax + 4]    ; get token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 8], eax    ; save new_var_lexeme
; detect type complexity
; get type_lexeme
mov eax, dword [ebp - 4]    ; load VaD 
mov eax, dword [eax + 12]   ; load Ty
mov eax, dword [eax + 12]   ; load child
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 12], eax   ; save type_lexeme
push dword [ebp - 12]
push dword [ebp + 16]
call string_equals
cmp eax, 0                  ; no struct self reference
je .no_self_ref
; self referencing struct vars must be declared with at least a single pointer decorator
mov eax, dword [ebp - 4]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
cmp dword [eax + 8], 0
je .self_ref_error
mov eax, dword [eax + 12]
cmp dword [eax + 8], 0
je .self_ref_error
; else is valid ref structure
.valid_self_ref:
.no_self_ref:
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
mov dword [ebp - 20], eax   ; save type entry
; start chain construction of pointer/array types
mov eax, dword [ebp - 4]    ; load VaD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load TyDeco 
mov dword [ebp - 16], eax   ; save TyDeco
cmp dword [eax + 8], 0      ; check if any decorators are present
je .simple_type
; go over the pointer chains
mov eax, dword [eax + 12]   ; load PDeco
mov dword [ebp - 24], eax   ; save PDeco
.pointer_loop:
mov eax, dword [ebp - 24]
cmp dword [eax + 8], 0
je .check_arrays
push dword [ebp - 20]
push pointer
call get_composite_p_entry
add esp, 8
mov dword [ebp - 20], eax
mov eax, dword [ebp - 24]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov dword [ebp - 24], eax
jmp .pointer_loop
.check_arrays:
mov eax, dword [ebp - 16]   ; load TyDeco
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]    ; load ArrDeco
mov dword [ebp - 24], eax   ; save ArrDeco
.array_loop:
mov eax, dword [ebp - 24]
cmp dword [eax + 8], 0
je .composite_type
cmp dword [eax + 8], 2
je .parameter_arr
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load Num node
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
push eax 
jmp .end_check
.parameter_arr:
push 0
.end_check:
push dword [ebp - 20]
push array
call get_composite_arr_entry
add esp, 12
mov dword [ebp - 20], eax
mov eax, dword [ebp - 24]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov dword [ebp - 24], eax
jmp .array_loop
.composite_type:
push dword [ebp - 20]
push dword [ebp - 8]
call get_var_entry
add esp, 8
leave
ret
; declare simple type
.simple_type:
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
push eax
push dword [ebp - 8]
call get_var_entry
add esp, 8
leave
ret
.self_ref_error:
push struct_self_ref
call print_string
add esp, 4
push dword [ebp - 8]
call print_string
add esp, 4
push struct_self_ref_end
call print_string
add esp, 4
push dword [ebp + 16]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
xor eax, eax 
leave
ret



; entry* construct_var(Tree_node* node, hash_map* type_table)
construct_var:
push ebp
mov ebp, esp
sub esp, 24 
mov dword [ebp - 4], 0      ; VaD pointer
mov dword [ebp - 8], 0      ; new_name_lexeme pointer
mov dword [ebp - 12], 0     ; type_lexeme pointer
mov dword [ebp - 16], 0     ; TyDeco pointer
mov dword [ebp - 20], 0     ; composite contruction entry pointer
mov dword [ebp - 24], 0     ; Decorator pointer
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax    ; save VaD
lea eax, dword [eax + 12]   ; get VaD children
mov eax, dword [eax + 8]    ; load Na
mov eax, dword [eax + 4]    ; get token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 8], eax    ; save new_var_lexeme
; detect type complexity
; get type_lexeme
mov eax, dword [ebp - 4]    ; load VaD 
mov eax, dword [eax + 12]   ; load Ty
mov eax, dword [eax + 12]   ; load child
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 12], eax   ; save type_lexeme
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
mov dword [ebp - 20], eax   ; save type entry
; start chain construction of pointer/array types
mov eax, dword [ebp - 4]    ; load VaD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load TyDeco 
mov dword [ebp - 16], eax   ; save TyDeco
cmp dword [eax + 8], 0      ; check if any decorators are present
je .simple_type
; go over the pointer chains
mov eax, dword [eax + 12]   ; load PDeco
mov dword [ebp - 24], eax   ; save PDeco
.pointer_loop:
mov eax, dword [ebp - 24]
cmp dword [eax + 8], 0
je .check_arrays
push dword [ebp - 20]
push pointer
call get_composite_p_entry
add esp, 8
mov dword [ebp - 20], eax
mov eax, dword [ebp - 24]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov dword [ebp - 24], eax
jmp .pointer_loop
.check_arrays:
mov eax, dword [ebp - 16]   ; load TyDeco
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]    ; load ArrDeco
mov dword [ebp - 24], eax   ; save ArrDeco
.array_loop:
mov eax, dword [ebp - 24]
cmp dword [eax + 8], 0
je .composite_type
cmp dword [eax + 8], 2
je .parameter_arr
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load Num node
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
push eax 
jmp .end_check
.parameter_arr:
push 0
.end_check:
push dword [ebp - 20]
push array
call get_composite_arr_entry
add esp, 12
mov dword [ebp - 20], eax
mov eax, dword [ebp - 24]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov dword [ebp - 24], eax
jmp .array_loop
.composite_type:
push dword [ebp - 20]
push dword [ebp - 8]
call get_var_entry
add esp, 8
leave
ret
; declare simple type
.simple_type:
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
push eax
push dword [ebp - 8]
call get_var_entry
add esp, 8
leave
ret


; bool add_type(Tree_node* node, hash_map* type_table)
add_type:
push ebp 
mov ebp, esp
sub esp, 4
mov eax, dword [ebp + 8]    ; load TE
mov edx, dword [eax + 12]
cmp dword [edx], STRUCT
jne .non_struct_type
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
mov dword [ebp - 4], eax 
jmp .const_call
.non_struct_type:
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 8]    ; get TyName
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 4], eax    ; save ref_type_lexeme
.const_call:
push dword [ebp + 12]
push dword [ebp + 8]
call construct_type
add esp, 8
cmp eax, 0
je .error_exit
push eax 
push dword [ebp - 4]
push dword [ebp + 12]
call hash_map_put
add esp, 12
mov eax, 1
leave
ret 
.error_exit:
xor eax, eax
leave
ret


; bool add_var(Tree_node* node, hash_map* type_table, hash_map* var_table, Tree_node* parent)
add_var:
push ebp 
mov ebp, esp 
sub esp, 4
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
mov dword [ebp - 4], eax
push eax 
push dword [ebp + 16]
call hash_map_get
add esp, 8
cmp eax, 0
jne .var_redeclaration
mov eax, dword [ebp + 20]
cmp dword [eax], TE
jne .no_struct_var
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push dword [eax + 4]
push dword [ebp + 12]
push dword [ebp + 8]
call construct_struct_var
add esp, 12
cmp eax, 0
je .error_exit
jmp .const_end
.no_struct_var:
push dword [ebp + 12]
push dword [ebp + 8]
call construct_var
add esp, 8
.const_end:
push eax 
push dword [ebp - 4]
push dword [ebp + 16]
call hash_map_put
add esp, 12 
mov eax, 1
leave
ret
.var_redeclaration:
cmp dword [ebp + 20], 0 ; if null parent, gm redeclaration
jne .struct_var_redeclaration
.gm_var_redeclaration:
push var_red
call print_string
add esp, 4
push dword [ebp - 4]
call print_string
add esp, 4
push var_red_gm
call print_string
add esp, 4
xor eax, eax 
leave
ret
.struct_var_redeclaration:
mov eax, dword [ebp + 20]
cmp dword [eax], TE
jne .func_redeclaration
push var_red
call print_string
add esp, 4
push dword [ebp - 4]
call print_string
add esp, 4
push var_red_struct
call print_string
add esp, 4
mov eax, dword [ebp + 20]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push dword [eax + 4]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
xor eax, eax 
leave
ret
.func_redeclaration:
mov eax, dword [ebp + 8]
cmp dword [eax], PaD        ; param redeclaration
jne .func_var_redeclaration
.func_param_redeclaration:
push param_red
call print_string
add esp, 4
push dword [ebp - 4]
call print_string
add esp, 4
push var_red_func
call print_string
add esp, 4
; load function name
mov eax, dword [ebp + 20]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [eax + 4]
call print_string
add esp, 4
push single_quote_close 
call print_string
add esp, 4
xor eax, eax
leave
ret
.func_var_redeclaration:
push var_red
call print_string
add esp, 4
push dword [ebp - 4]
call print_string
add esp, 4
push var_red_func
call print_string
add esp, 4
; load function name
mov eax, dword [ebp + 20]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [eax + 4]
call print_string
add esp, 4
push single_quote_close 
call print_string
add esp, 4
xor eax, eax
leave
ret
.error_exit:
xor eax, eax 
leave
ret

; bool add_func(Tree_node* node, hash_map* type_table, hash_map* var_table, hash_map* func_table)
add_func:
push ebp
mov ebp, esp 
sub esp, 24
mov dword [ebp - 4], 0      ; FuD pointer
mov dword [ebp - 8], 0      ; new_funcna_lexeme pointer
mov dword [ebp - 12], 0     ; r_type_lexeme pointer
mov dword [ebp - 16], 0     ; TyDeco pointer
mov dword [ebp - 20], 0     ; composite contruction entry pointer
mov dword [ebp - 24], 0     ; Decorator pointer
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax    ; load FuD
lea eax, dword [eax + 12]   ; load children
mov eax, dword [eax + 12]   ; load FuncNa
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 8], eax    ; load new_funcna_lexeme
push dword [ebp - 8]
push dword [ebp + 20]
call hash_map_get
add esp, 8
cmp eax, 0
jne .func_redeclaration
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp - 4]
call construct_func
add esp, 16
cmp eax, 0      ; semantic error in func declaration
je .error_exit
push eax
push dword [ebp - 8]
push dword [ebp + 20]
call hash_map_put
add esp, 12
mov eax, 1
leave
ret 

.func_redeclaration:
push func_red
call print_string
add esp, 4
push dword [ebp - 8]
call print_string
add esp, 4
push func_red_end
call print_string
add esp, 4
.error_exit:
xor eax, eax 
leave
ret

; entry* construct_func(Tree_node* node, hash_map* type_table, hash_map* var_table, hash_map* func_table)
construct_func:
push ebp
mov ebp, esp
sub esp, 86
mov dword [ebp - 4], 0      ; FuD pointer
mov dword [ebp - 8], 0      ; new_name_lexeme pointer
mov dword [ebp - 12], 0     ; type_lexeme pointer
mov dword [ebp - 16], 0     ; TyDeco pointer
mov dword [ebp - 20], 0     ; composite contruction entry pointer
mov dword [ebp - 24], 0     ; Decorator pointer
mov dword [ebp - 28], 0     ; function var_table pointer
mov dword [ebp - 32], 0     ; VaDS pointer
mov dword [ebp - 36], 1     ; array_ret flag
mov dword [ebp - 40], 0     ; type_entry pointer
mov dword [ebp - 44], 1     ; struct_ret flag
mov dword [ebp - 48], 0     ; offset counter
mov dword [ebp - 52], 0     ; var lexeme pointer
mov dword [ebp - 56], 0     ; var_entry pointer
mov dword [ebp - 60], 0     ; body pointer
mov dword [ebp - 64], 0     ; StS pointer
mov dword [ebp - 68], 0     ; St pointer
mov dword [ebp - 72], 0     ; TAC_list head node
mov dword [ebp - 76], 0     ; branch_label counter
mov dword [ebp - 82], 0     ; func_entry buffer
mov dword [ebp - 86], 0     ; params linked_list
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax    ; save FuD
lea eax, dword [eax + 12]   ; get FuD children
mov eax, dword [eax + 12]    ; load Na
mov eax, dword [eax + 4]    ; get token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 8], eax    ; save new_funcNa_lexeme
; detect type complexity
; get type_lexeme
mov eax, dword [ebp - 4]    ; load FuD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load Ty
mov eax, dword [eax + 12]   ; load child
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 12], eax   ; save type_lexeme
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
mov dword [ebp - 20], eax   ; save type entry
; start chain construction of pointer/array types
mov eax, dword [ebp - 4]    ; load FuD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 8]    ; load TyDeco 
mov dword [ebp - 16], eax   ; save TyDeco
cmp dword [eax + 8], 0      ; check if any decorators are present
je .simple_type
; go over the pointer chains
mov eax, dword [eax + 12]   ; load PDeco
mov dword [ebp - 24], eax   ; save PDeco
.pointer_loop:
mov eax, dword [ebp - 24]
cmp dword [eax + 8], 0
je .check_arrays
mov dword [ebp - 36], 0     ; reset array_ret flag
push dword [ebp - 20]
push pointer
call get_composite_p_entry
add esp, 8
mov dword [ebp - 20], eax
mov eax, dword [ebp - 24]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov dword [ebp - 24], eax
jmp .pointer_loop
.check_arrays:
cmp dword [ebp - 36], 1     ; check array_ret flag
je .error_array_ret
mov eax, dword [ebp - 16]   ; load TyDeco
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]    ; load ArrDeco
mov dword [ebp - 24], eax   ; save ArrDeco
.array_loop:
mov eax, dword [ebp - 24]
cmp dword [eax + 8], 0
je .composite_type
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load Num node
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
push eax 
push dword [ebp - 20]
push array
call get_composite_arr_entry
add esp, 12
mov dword [ebp - 20], eax
mov eax, dword [ebp - 24]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov dword [ebp - 24], eax
jmp .array_loop
.composite_type:
mov eax, dword [ebp - 8]
mov edx, dword [ebp - 20]
mov dword [edx], eax 
mov eax, edx
jmp .func_entry
; declare simple type
.simple_type:
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
mov dword [ebp - 40], eax
; check if array type in return
cmp dword [eax + 4], ARRAY
je .error_array_ret
.no_array_ret:
mov eax, dword [ebp - 40]
.func_entry:
; eax has r_type entry at this point
mov dword [ebp - 20], eax
; load temp entry into the func table with r_type and key
mov dword [ebp - 48], -8    ; init offset counter
push 16 
push 4
call get_hash_map
add esp, 8
mov dword [ebp - 28], eax
; loop through params
mov eax, dword [ebp - 4]    ; load FuD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 20]   ; load PaDS
mov dword [ebp - 16], eax   ; save PaDS
; load first param
mov eax, dword [ebp - 16]   ; load PaDS
cmp dword [eax + 8], 0      ; no params
je .end_param_loop
lea eax, dword [eax + 12]
mov edx, dword [eax]        ; load PaD
lea edx, dword [edx + 12]   ; load children baddr
mov edx, dword [edx + 8]    ; load Na
mov edx, dword [edx + 4]    ; load token
mov edx, dword [edx + 4]    ; load lexeme
mov dword [ebp - 52], edx   ; save var lexeme
mov edx, dword [eax + 4]    ; load RPaDS
mov dword [ebp - 16], edx   ; save RPaDS
mov eax, dword [eax]        ; load PaD
push dword [ebp - 4]
push dword [ebp - 28]
push dword [ebp + 12]
push eax
call add_var
add esp, 16
cmp eax, 0  ; error while adding param
je .error_exit
; load rest
push dword [ebp - 52]
push dword [ebp - 28]
call hash_map_get
add esp, 8
mov dword [ebp - 56], eax
push 0
push dword [ebp - 56]
call get_linked_list
add esp, 8
mov dword [ebp - 86], eax
mov eax, dword [ebp - 56]
mov edx, dword [ebp - 48]
mov dword [eax + 8], edx
mov eax, dword [eax + 4]
.loop1:
cmp dword [eax + 4], ARRAY
jne .check1
mov eax, dword [eax + 8]
jmp .loop1
.check1:
.end_check1:
mov eax, dword [eax + 12]
mov edx, eax
and edx, 3
jz .skip1
add eax, 4
shr eax, 2
shl eax, 2
.skip1:
sub dword [ebp - 48], eax
mov eax, dword [ebp - 56]
.param_loop:
mov eax, dword [ebp - 16]   ; load RPaDS
cmp dword [eax + 8], 0
je .end_param_loop
lea eax, dword [eax + 12]
mov edx, dword [eax + 8]    ; load RPaD
mov dword [ebp - 16], edx   ; save next RPaDS
mov eax, dword [eax + 4]    ; load PaD
lea edx, dword [eax + 12]
mov edx, dword [edx + 8]
mov edx, dword [edx + 4]
mov edx, dword [edx + 4]
mov dword [ebp - 52], edx   ; save ver lexeme
push dword [ebp - 4]
push dword [ebp - 28]
push dword [ebp + 12]
push eax 
call add_var
add esp, 16
cmp eax, 0  ; error while adding param
je .error_exit
push dword [ebp - 52]
push dword [ebp - 28]
call hash_map_get
add esp, 8
mov dword [ebp - 56], eax
push dword [ebp - 56]
push dword [ebp - 86]
call linked_list_append
add esp, 8
mov eax, dword [ebp - 56]
mov edx, dword [ebp - 48]
mov dword [eax + 8], edx
mov eax, dword [eax + 4]
.loop2:
cmp dword [eax + 4], ARRAY
jne .check2
mov eax, dword [eax + 8]
jmp .loop2
.check2:
.end_check2:
mov eax, dword [eax + 12]
mov edx, eax
and edx, 3
jz .skip2
add eax, 4
shr eax, 2
shl eax, 2
.skip2:
sub dword [ebp - 48], eax
mov eax, dword [ebp - 56]
jmp .param_loop
.end_param_loop:
; add declared variables
mov dword [ebp - 48], 0     ; reset offset counter
mov eax, dword [ebp - 4]    ; load FuD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 32]   ; load VaDS
mov dword [ebp - 32], eax   ; save VaDS
.declared_vars_loop:
mov eax, dword [ebp - 32]   ; load VaDS
cmp dword [eax + 8], 0      ; check if any gm variables declared
je .no_vars_declared
lea eax, dword [eax + 12]   ; load children baddr
mov edx, dword [eax + 4]    ; load next VaDS
mov dword [ebp - 32], edx   ; save next VaDS
mov eax, dword [eax]        ; load VaD
lea edx, dword [eax + 12]
mov edx, dword [edx + 8]
mov edx, dword [edx + 4]
mov edx, dword [edx + 4]
mov dword [ebp - 52], edx
push dword [ebp - 4]
push dword [ebp - 28]
push dword [ebp + 12]
push eax 
call add_var
add esp, 16
cmp eax, 0  ; error while adding var
je .error_exit
push dword [ebp - 52]
push dword [ebp - 28]
call hash_map_get
add esp, 8
mov dword [ebp - 56], eax
mov eax, dword [eax + 4]
.loop3:
cmp dword [eax + 4], ARRAY
jne .check3
mov eax, dword [eax + 8]
jmp .loop3
.check3:
.end_check3:
mov eax, dword [eax + 12]
mov edx, eax
and edx, 3
jz .skip3
add eax, 4
shr eax, 2
shl eax, 2
.skip3:
add dword [ebp - 48], eax
mov eax, dword [ebp - 56]
mov edx, dword [ebp - 48]
mov dword [eax + 8], edx
mov eax, dword [ebp - 56]
jmp .declared_vars_loop
.no_vars_declared:
push 0                      ; null pointer for TAC_list
push dword [ebp - 86]       ; load params_linked_list
push dword [ebp - 28]       ; load func var_table
push dword [ebp - 20]       ; load r_type
push dword [ebp - 8]        ; load FuncNa
call get_func_entry
add esp, 20
mov dword [ebp - 82], eax
push dword [ebp - 82]
push dword [ebp - 8]
push dword [ebp + 20]
call hash_map_put
add esp, 12
; static type checking and transformation to three address code of func body
; init TAC_list with start quad
push 0
push 0
push 0
push START
call get_quad
add esp, 16
push 0
push eax
call get_linked_list
add esp, 8
mov dword [ebp - 72], eax   ; store TAC_list
mov eax, dword [ebp - 4]    ; load FuD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 36]   ; load body
mov dword [ebp - 60], eax   ; save body
mov eax, dword [eax + 12]   ; load StS
mov dword [ebp - 64], eax   ; save StS
.statements_loop:
mov eax, dword [ebp - 64]
cmp dword [eax + 8], 0
je .end_statements_loop
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]    ; load StS
mov dword [ebp - 64], edx   ; save next StS
mov eax, dword [eax + 12]   ; load St
mov dword [ebp - 68], eax   ; save St
push dword [ebp - 8]        ; FuncName
push dword [ebp + 20]       ; func_table
push dword [ebp - 28]       ; func var_table
push dword [ebp + 16]       ; var_table
push dword [ebp + 12]       ; type_table
push dword [ebp - 72]       ; TAC_list
lea edx, dword [ebp - 76]
push edx                    ; label_counter
mov eax, dword [ebp - 68]   ; load St
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
jmp .statements_loop
.end_statements_loop:
push dword [ebp - 8]        ; FuncName
push dword [ebp + 20]       ; func_table
push dword [ebp - 28]       ; func var_table
push dword [ebp + 16]       ; var_table
push dword [ebp + 12]       ; type_table
push dword [ebp - 72]       ; TAC_list
lea edx, dword [ebp - 76]   ; label_counter
push edx
mov eax, dword [ebp - 60]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]    ; load rSt
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp - 82]
mov edx, dword [ebp - 72]
mov dword [eax + 16], edx
leave
ret

.error_array_ret:
push func_red
call print_string
add esp, 4
push dword [ebp - 8]
call print_string
add esp, 4
push func_arr_ret
call print_string
add esp, 4
.error_exit:
xor eax, eax 
leave
ret

; uint get_var_alignment(var_entry* var)
get_var_alignment:
push ebp 
mov ebp, esp
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
.get_alignment_loop:
cmp dword [eax + 4], STRUCTURE
jne .array
; get struct alignment
mov eax, dword [eax + 16]
leave
ret
.array:
cmp dword [eax + 4], ARRAY
jne .other
mov eax, dword [eax + 8]
jmp .get_alignment_loop
.other:
mov eax, dword [eax + 12]
leave
ret

; bool detect_main(Tree_node* FuDS)
; detect_main:
; push ebp 
; mov ebp, esp   
; sub esp, 12
; mov dword [ebp - 4], 0      ; zero out the flag
; mov dword [ebp - 8], 0      ; FuDS pointer
; .check:
; mov eax, dword [ebp + 8]
; cmp dword [eax + 8], 0
; je .exit
; lea eax, dword [eax + 12]
; mov edx, dword [eax + 4]
; mov dword [ebp + 8], edx
; mov eax, dword [eax]
; mov dword [ebp - 8], eax   ; save FuD
; lea eax, dword [eax + 12]
; mov eax, dword [eax + 4]
; mov eax, dword [eax + 12]
; mov eax, dword [eax + 4]
; mov eax, dword [eax]
; cmp eax, INTEGER
; jne .check
; mov eax, dword [ebp - 8]
; lea eax, dword [eax + 12]
; mov eax, dword [eax + 8]
; mov eax, dword [eax + 4]
; mov eax, dword [eax + 4]
; push eax 
; push main_k
; call string_equals
; add esp, 8
; cmp eax, 0
; je .check 

; .exit:
; leave
; ret 

; node* visit_node(Tree_Node* node, uint* label_counter, node* TAC_list, table* type_table, table* var_table, table* func_var_table, table* func_table, char* func_name)
; returns a linked_list of TAC quads or null if an error is found turing translation
; TODO: add error checking
; TODO: add function translation to TAC quads
; TODO: add TAC quad append code to TAC_list at every quad generating step
visit_node:
push ebp
mov ebp, esp 
sub esp, 32
mov dword [ebp - 4], 0      ; char* buffer
mov dword [ebp - 8], 0      ; quad* left_operand
mov dword [ebp - 12], 0     ; quad* right_operand
mov dword [ebp - 16], 0     ; entry*
mov dword [ebp - 20], 0     ; node buffer
mov dword [ebp - 24], 0     ; op buffer
mov dword [ebp - 28], 0     ; params list
mov dword [ebp - 32], 0     ; argument counter
mov eax, dword [ebp + 8]    ; load node
cmp dword [eax], St
je .translate_statement
cmp dword [eax], rSt
je .translate_return_statement
cmp dword [eax], GenE
je .GenE
cmp dword [eax], JointE
je .JointE
cmp dword [eax], Union
je .Union
cmp dword [eax], UnionT
je .UnionT
cmp dword [eax], Intersect
je .Intersect
cmp dword [eax], RelE
je .RelE
cmp dword [eax], RRelE
je .RRelE
cmp dword [eax], ID
je .id
cmp dword [eax], Rid
je .Rid
cmp dword [eax], idSel
je .idSel
cmp dword [eax], E          
je .is_E_or_T
; E -> T RE
; E.val = RE.val
; RE.inh = T.val
; traverse the tree first
cmp dword [eax], T
jne .check_RE_or_RT
.is_E_or_T:
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
mov eax, dword [ebp + 8]                ; load E
lea eax, dword [eax + 12]               ; load children baddr
mov eax, dword [eax]                    ; load T
push dword [ebp + 16]
push dword [ebp + 12]
push eax 
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]                ; load E
lea eax, dword [eax + 12]               ; load children baddr
mov eax, dword [eax + 4]                ; load RE
mov edx, dword [eax + 8]                ; load child count
lea eax, dword [eax + 12 + edx * 4 + 4] ; get RE.inh addr
mov dword [ebp - 4], eax                ; save RE.inh addr
mov eax, dword [ebp + 8]                ; load E
mov eax, dword [eax + 12]               ; load T
mov edx, dword [eax + 8]                ; load child count
mov eax, dword [eax + 12 + edx * 4 + 8] ; load T.val
mov edx, dword [ebp - 4]
mov dword [edx], eax                    ; RE.inh = T.val
mov eax, dword [ebp + 8]                ; load E
lea eax, dword [eax + 12]               ; load children baddr
mov eax, dword [eax + 4]                ; load RE
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax 
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
; modify the attributes later
mov eax, dword [ebp + 8]                ; load E
mov edx, dword [eax + 8]                ; load child count
lea eax, dword [eax + 12 + edx * 4 + 8] ; load E.val addr
mov dword [ebp - 4], eax                ; save E.val addr
mov eax, dword [ebp + 8]                ; load E
lea eax, dword [eax + 12]               ; load children baddr
mov eax, dword [eax + 4]                ; load RE
mov edx, dword [eax + 8]                ; load child count
mov eax, dword [eax + 12 + edx * 4 + 8] ; load RE.val addr
mov edx, dword [ebp - 4]
mov dword [edx], eax                    ; E.val = RE.val
mov eax, 1
jmp .exit
.check_RE_or_RT:
cmp dword [eax], RE
je .is_RE_or_RT
cmp dword [eax], RT
jne .check_F
.is_RE_or_RT:
; RE -> + T RE1 | - T RE1 | eps
; + | -
; RE1.inh = RE.inh + T.val | RE.inh - T.val
; RE.val = RE1.val
; eps 
; RE.val = RE.inh
cmp dword [eax + 8], 0
je .epsilon_prod
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load T
push dword [ebp + 16]
push dword [ebp + 12]
push eax 
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov eax, dword [eax]
mov dword [ebp - 24], eax
lea eax, dword [ebp - 24]
mov dword [ebp - 4], eax 
push dword [ebp + 20]
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 12], eax
push eax
mov eax, dword [ebp + 8]                    ; load RE | RT
mov edx, dword [eax + 8]                    ; load child count
mov eax, dword [eax + 12 + edx * 4 + 4]     ; load RE.inh
mov dword [ebp - 8], eax
push eax
mov eax, dword [ebp + 8]
cmp dword [eax], RE
jne .mul_div
.add_sub:
push ARITHMETIC_ADD_SUB_OP
jmp .end_op_check
.mul_div:
push ARITHMETIC_MUL_DIV_OP
.end_op_check: 
call check_if_valid_binary
add esp, 16
cmp eax, 0
je .invalid_binary
push eax
push dword [ebp - 12]
push dword [ebp - 8]
cmp dword [ebp - 24], '+'
jne .minus
push PLUS_OP
jmp .end
.minus:
cmp dword [ebp - 24], '-'
jne .mul
push MINUS_OP
jmp .end
.mul:
cmp dword [ebp - 24], '*'
jne .div
push MUL_OP
jmp .end
.div:
push DIV_OP
.end:
call get_quad
add esp, 16
mov dword [ebp - 8], eax
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov edx, dword [ebp - 8]
mov dword [eax], edx
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
mov eax, dword [ebp + 8]    ; load RE | RT
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 8]    ; load RE1
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]     ; get RE1.val , RT1.val
mov dword [ebp - 4], eax                    ; save
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]     ; get RE.val | RT.val
mov edx, dword [ebp - 4]
mov dword [eax], edx
mov eax, 1
jmp .exit
.epsilon_prod:
mov edx, dword [eax + 8]
lea edx, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], edx
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 4]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit
.check_F:
; F -> id | -F | !F | *F | &F | ( E ) | Num | true | false
; F.val = id.val | Num.val | true | false
; F.val = - F.val | ! F.val | * F.val | & F.val | E.val
cmp dword [eax + 8], 1
jne .unary_or_brackets
mov edx, dword [eax + 12]
cmp dword [edx], ID
jne .not_id
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
mov eax, dword [eax + 12]                   ; load id
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]     ; F.val addr
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]     ; id.val
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit
.id:
; id -> Na Rid
; id.val = Rid.val
; Rid.inh = Na.val
mov eax, dword [eax + 12]                   ; load Na
mov eax, dword [eax + 4]                    ; get token
mov eax, dword [eax + 4]                    ; get lexeme
mov dword [ebp - 4], eax
; check if id is declared in function frame or gm
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp - 4]
call get_var_decl
add esp, 12
mov dword [ebp - 16], eax
cmp eax, 0
jne .valid_variable
.undeclared_variable:
push var_undec
call print_string
add esp, 4
push dword [ebp - 4]
call print_string
add esp, 4
push var_undec_func
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit

.valid_variable:
mov eax, dword [ebp - 16]                   ; load var_entry
push dword [eax + 4]                        ; type_entry
push 0                                      ; right_operand
push dword [ebp - 16]                       ; left_operand
push ID                                     ; op
call get_quad
add esp, 16
mov dword [ebp - 8], eax                    ; save quad
mov eax, dword [ebp + 8]                    ; load id
lea eax, dword [eax + 12]                   ; load children baddr
mov eax, dword [eax + 4]                    ; load Rid
mov edx, dword [eax + 8]                    ; load child count
lea eax, dword [eax + 12 + edx * 4 + 4]     ; load Rid.inh addr
mov edx, dword [ebp - 8]                    ; load quad
mov dword [eax], edx                        ; Rid.inh = Na.val
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]     ; load Rid.val
mov dword [ebp - 8], eax
mov eax, dword [eax + 12]
cmp dword [eax + 4], ARRAY
jne .skip
.check_array_id:
mov eax, dword [ebp - 8]
cmp dword [eax], ID
jne .skip
.gen_array_addr:
mov eax, dword [ebp - 8]
mov eax, dword [eax + 12]
push eax
push 0
push dword [ebp - 8]
push ADDRESS_OP
call get_quad
add esp, 16
mov dword [ebp - 8], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]     ; load id.val addr
mov edx, dword [ebp - 8]
mov dword [eax], edx
push dword [ebp - 8]
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit
.skip:
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]     ; load id.val addr
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]     ; load Rid.val
mov edx, dword [ebp - 4]
mov dword [edx], eax                        ; id.val = Rid.val
mov eax, 1
jmp .exit

.Rid:
; Rid -> idSel Rid | eps
; idSel.inh = Rid.inh 
; Rid1.inh = idSel.val
; Rid.val = Rid1.val
; eps -> Rid.val = Rid.inh
cmp dword [eax + 8], 0
je .empty_rid
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 4]     ; load Rid.inh value
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]     ; load idSel.inh addr
mov edx, dword [ebp - 4]
mov dword [eax], edx                        ; idSel.inh = Rid.inh
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov edx, dword [ebp - 4]
mov eax, dword [edx]
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit
.empty_rid:
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]     ; load Rid.val addr
mov edx, eax
sub edx, 4                                  ; get Rid.inh addr
mov edx, dword [edx]                        ; load Rid.inh value
mov dword [eax], edx                        ; Rid.val = Rid.inh
mov eax, 1
jmp .exit
.idSel:
; idSel -> .Na | [GenE]
; new_temp = idSel.inh[offset(Na.val)]
; new_temp = idSel.inh[GenE.val]
; idSel.val = temp_label
cmp dword [eax + 8], 3
je .array_access
.struct_access:
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 4] ; inherited quad
mov dword [ebp - 8], eax
mov eax, dword [eax + 4]    ; get var_entry
mov eax, dword [eax + 4]    ; get type_entry
cmp dword [eax + 4], STRUCTURE
je .check_if_member_present
.nonstruct_type:
push var_nonstruct
call print_string
add esp, 4
mov eax, dword [ebp - 8]    ; get left_operand quad
mov eax, dword [eax + 4]    ; get Var_entry
mov eax, dword [eax]        ; get key
push eax
call print_string
add esp, 4
push in_func_seg
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit
.check_if_member_present:
push dword [ebp - 4]        ; member Na lexeme
mov eax, dword [ebp - 8]    ; quad
mov eax, dword [eax + 4]    ; var_entry
mov eax, dword [eax + 4]    ; type_entry
mov eax, dword [eax + 8]    ; children var_table
push eax
call hash_map_get
add esp, 4
cmp eax, 0
jne .valid_access
.member_not_present:
push struct_nonmember
call print_string
add esp, 4
push dword [ebp - 4]
call print_string
add esp, 4
push struct_nonmember_2
call print_string
add esp, 4
mov eax, dword [ebp - 8]
mov eax, dword [eax + 4]
mov eax, dword [eax]
push eax
call print_string
add esp, 4
push in_func_seg
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit
.valid_access:
; ebp - 8 | left_operand quad
; eax | accessed member var
mov dword [ebp - 12], eax
mov eax, dword [eax + 4]    ; accessed variable type_entry
push eax
push 0
push dword [ebp - 12]
push ID
call get_quad
add esp, 16
mov dword [ebp - 12], eax   ; save right_operand
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax
push dword [ebp - 12]
push dword [ebp - 8]
push ACCESS_OP
call get_quad
add esp, 16
mov dword [ebp - 8], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 8]
mov dword [eax], edx
mov eax, 1
jmp .exit

.array_access:
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 4] ; inherited quad
mov dword [ebp - 8], eax                ; save left_operand
mov eax, dword [eax + 4]                ; get var_entry
mov eax, dword [eax + 4]                ; get type_entry
cmp dword [eax + 4], PRIMITIVE
je .not_subscriptable
cmp dword [eax + 4], STRUCTURE
je .not_subscriptable
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 12], eax
mov eax, dword [eax + 12]   ; get right_operand type_entry
cmp dword [eax + 4], PRIMITIVE
jne .invalid_subscript_type
.valid_subscript:
mov eax, dword [ebp - 8]    ; left_operand
mov eax, dword [eax + 12]   ; type_entry
mov eax, dword [eax + 8]    ; child_type
push eax
push dword [ebp - 12]
push dword [ebp - 8]
push ACCESS_OP
call get_quad
add esp, 16
mov dword [ebp - 8], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 8]
mov dword [eax], edx
mov eax, 1
jmp .exit


.not_subscriptable:
push var_not_subscript
call print_string
add esp, 4
mov eax, dword [ebp - 8]
mov eax, dword [eax + 4]
mov eax, dword [eax]
push eax
call print_string
add esp, 4
push in_func_seg
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit

.invalid_subscript_type:
push var_subscript_type
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit

.not_id:
cmp dword [edx], NUM
jne .not_num
push integer_k
push dword [ebp + 20]
call hash_map_get
add esp, 8
push eax
push 0
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]   ; load Num
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
push eax
push NUM
call get_quad
add esp, 16
mov dword [ebp - 8], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 8]
mov dword [eax], edx
mov eax, 1
jmp .exit
.not_num:
push bool_k
push dword [ebp + 20]
call hash_map_get
add esp, 8
push eax
push 0
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax]
push eax
push BOOL
call get_quad
add esp, 16
mov dword [ebp - 8], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 8]
mov dword [eax], edx
mov eax, 1
jmp .exit
.unary_or_brackets:
cmp dword [eax + 8], 3
jne .unary
.brackets:
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit

.unary:
mov eax, dword [ebp + 8]    ; load F
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 4]    ; load F1
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax 
call visit_node
add esp, 32
cmp eax, 0
je .error_exit

mov eax, dword [ebp + 8]                    ; load F
lea eax, dword [eax + 12]                   ; load children baddr
mov eax, dword [eax + 4]                    ; load F1
mov edx, dword [eax + 8]                    ; load child count
mov eax, dword [eax + 12 + edx * 4 + 8]     ; load F1.val
mov dword [ebp - 8], eax

mov eax, dword [ebp + 8]    ; load F
mov eax, dword [eax + 12]   ; load unary operator
mov eax, dword [eax]
mov dword [ebp - 4], eax
cmp dword [ebp - 4], '-'
jne .check_neg
mov dword [ebp - 24], UNARY_MINUS_OP
jmp .end_check
.check_neg:
cmp dword [ebp - 4], '!'
jne .check_deref
mov dword [ebp - 24], NEG_OP
jmp .end_check
.check_deref:
cmp dword [ebp - 4], '*'
jne .check_addr
mov dword [ebp - 24], DEREF_OP
jmp .end_check
.check_addr:
mov dword [ebp - 24], ADDRESS_OP
jmp .end_check

.end_check:
push dword [ebp + 20]
push dword [ebp - 8]
push dword [ebp - 24]
call check_if_valid_unary
add esp, 12
cmp eax, 0
je .invalid_unary
push eax
push 0
push dword [ebp - 8]
push dword [ebp - 24]
call get_quad
add esp, 16
mov dword [ebp - 8], eax
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 8]
mov dword [eax], edx
mov eax, 1
jmp .exit

.invalid_unary:
push unary_error
call print_string
add esp, 4
lea eax, dword [ebp - 4]
push eax
call print_string
add esp, 4
push in_func_seg
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit

.translate_return_statement:
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 8], eax    ; return quad
push dword [ebp + 36]
push dword [ebp + 32]
call hash_map_get
add esp, 8
mov eax, dword [eax + 4]
push eax
push 0
push 0
push RETURN
call get_quad
add esp, 16
mov dword [ebp - 16], eax
push dword [ebp + 20]
push dword [ebp - 8]
push dword [ebp - 16]
push eax
push ASSIG_OP
call check_if_valid_binary
add esp, 16
cmp eax, 0
je .invalid_return_type
mov eax, dword [ebp - 16]
mov edx, dword [ebp - 8]
mov dword [eax + 4], edx
push dword [ebp - 16]
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit

.invalid_return_type:
push invalid_return
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit

.translate_statement:
mov eax, dword [eax + 12]
cmp dword [eax], ID
je .assignment_st
cmp dword [eax], IF
je .if_statement
cmp dword [eax], DO
je .do_while_statement
cmp dword [eax], WHILE
je .while_statement
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [eax], 0  ; clear GenE val
jmp .func_call
.assignment_st:
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
; left_operand
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 8], eax
; right_operand
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 12], eax

push dword [ebp + 20]
mov eax, dword [ebp - 12]
push eax
mov eax, dword [ebp - 8]
push eax
push ASSIG_OP
call check_if_valid_binary
add esp, 16
mov dword [ebp - 4], equals
cmp eax, 0
je .invalid_binary
push 0
push dword [ebp - 12]
push dword [ebp - 8]
push ASSIG_OP
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit

.if_statement:
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
; if bool goto label_true
; goto label_false
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 8], eax
push dword [ebp + 12]
call get_new_label
add esp, 4
mov dword [ebp - 12], eax
push 0
push dword [ebp - 12]
push dword [ebp - 8]
push IF
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
push dword [ebp + 12]
call get_new_label
add esp, 4
mov dword [ebp - 8], eax    
mov eax, dword [ebp - 12]
mov edx, dword [ebp - 8]
mov dword [ebp - 8], eax    ; label_true
mov dword [ebp - 12], edx   ; label_false
push 0
push 0
push dword [ebp - 12]
push GOTO
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
push 0
push 0
push dword [ebp - 8]   ; label_true
push LABEL
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8

mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 20]
mov dword [ebp - 20], eax   ; save Sts
.statements_loop:
mov eax, dword [ebp - 20]
cmp dword [eax + 8], 0
je .end_statements_loop
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]    ; load StS
mov dword [ebp - 20], edx   ; save next StS
mov eax, dword [eax + 12]   ; load St
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
jmp .statements_loop
.end_statements_loop:
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 28]   ; load MatchedElse
mov dword [ebp - 20], eax
cmp dword [eax + 8], 0
je .no_else_part
; generate the else
mov eax, dword [ebp - 12]
mov dword [ebp - 8], eax    ; move second label to the first slot
push dword [ebp + 12]
call get_new_label
add esp, 4
mov dword [ebp - 12], eax
push 0
push 0
push dword [ebp - 12]
push GOTO
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
push 0
push 0
push dword [ebp - 8]
push LABEL
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp - 20]   ; load MatchedElse
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]    ; load StS
mov dword [ebp - 20], eax
.statements_loop_2:
mov eax, dword [ebp - 20]
cmp dword [eax + 8], 0
je .end_statements_loop_2
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]    ; load StS
mov dword [ebp - 20], edx   ; save next StS
mov eax, dword [eax + 12]   ; load St
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
jmp .statements_loop_2
.end_statements_loop_2:
push 0
push 0
push dword [ebp - 12]
push LABEL
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit
.no_else_part:
push 0
push 0
push dword [ebp - 12]
push LABEL
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit

.do_while_statement:
push dword [ebp + 12]
call get_new_label
add esp, 4
mov dword [ebp - 8], eax
push 0
push 0
push dword [ebp - 8]
push LABEL
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]    ; load StS
mov dword [ebp - 20], eax
.statements_loop_3:
mov eax, dword [ebp - 20]
cmp dword [eax + 8], 0
je .end_statements_loop_3
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]    ; load StS
mov dword [ebp - 20], edx   ; save next StS
mov eax, dword [eax + 12]   ; load St
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
jmp .statements_loop_3
.end_statements_loop_3:
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 24]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
push 0
push dword [ebp - 8]
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 24]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
push eax
push IF
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit

.while_statement:
push dword [ebp + 12]
call get_new_label
add esp, 4
mov dword [ebp - 8], eax
push 0
push 0
push dword [ebp - 8]
push LABEL
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
push dword [ebp + 12]
call get_new_label
add esp, 4
push 0
mov dword [ebp - 12], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
push eax
push dword [ebp - 12]
push IF
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
push dword [ebp + 12]
call get_new_label
add esp, 4
mov dword [ebp - 4], eax
push 0
push 0
push dword [ebp - 4]
push GOTO
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
push 0
push 0
push dword [ebp - 8]
push LABEL
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 20]
mov dword [ebp - 20], eax
.statements_loop_4:
mov eax, dword [ebp - 20]
cmp dword [eax + 8], 0
je .end_statements_loop_4
lea edx, dword [eax + 12]
mov edx, dword [edx + 4]    ; load StS
mov dword [ebp - 20], edx   ; save next StS
mov eax, dword [eax + 12]   ; load St
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
jmp .statements_loop_4
.end_statements_loop_4:
push 0
push 0
push dword [ebp - 8]
push GOTO
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
push 0
push 0
push dword [ebp - 4]
push LABEL
call get_quad
add esp, 16
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit

.func_call:
; load params list
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax
push dword [ebp + 32]
call hash_map_get
add esp, 8
mov eax, dword [eax + 12]
mov dword [ebp - 28], eax   ; load list
mov dword [ebp - 32], 0     ; zero out the counter
; start translating arguments
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]    ; load ArgS
; load first Arg 
cmp dword [eax + 8], 0
je .end_args_loop
cmp dword [ebp - 28], 0
je .invalid_argument_amount_more
inc dword [ebp - 32]
mov edx, dword [eax + 12]   ; load Arg
mov edx, dword [edx + 12]   ; load GenE
mov dword [ebp - 4], edx
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]    ; load RArgs
mov dword [ebp - 20], eax   ; save RArgs
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push edx
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp - 28]   ; load params list
mov eax, dword [eax]        ; load var_entry
mov eax, dword [eax + 4]    ; load type_entry
push eax
push 0
push 0
push PARAM
call get_quad
add esp, 16
mov dword [ebp - 16], eax
mov eax, dword [ebp - 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8] ; load GenE.val quad
mov dword [ebp - 8], eax
push dword [ebp + 20]
push dword [ebp - 8]
push dword [ebp - 16]
push ASSIG_OP
call check_if_valid_binary
add esp, 16
cmp eax, 0
je .invalid_param_type
mov eax, dword [ebp - 16]
mov edx, dword [ebp - 8]
mov dword [eax + 4], edx
push dword [ebp - 16]
push dword [ebp + 16]
call linked_list_append
add esp, 8
; move param list pointer
mov eax, dword [ebp - 28]
mov eax, dword [eax + 4]
mov dword [ebp - 28], eax
.args_loop:
mov eax, dword [ebp - 20]
cmp dword [eax + 8], 0
je .end_args_loop
cmp dword [ebp - 28], 0
je .invalid_argument_amount_more
inc dword [ebp - 32]
lea eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov dword [ebp - 20], edx
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
mov dword [ebp - 4], eax
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp - 28]   ; load params list
mov eax, dword [eax]        ; load var_entry
mov eax, dword [eax + 4]    ; load type_entry
push eax
push 0
push 0
push PARAM
call get_quad
add esp, 16
mov dword [ebp - 16], eax
mov eax, dword [ebp - 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8] ; load GenE.val quad
mov dword [ebp - 8], eax
push dword [ebp + 20]
push dword [ebp - 8]
push dword [ebp - 16]
push ASSIG_OP
call check_if_valid_binary
add esp, 16
cmp eax, 0
je .invalid_param_type
mov eax, dword [ebp - 16]
mov edx, dword [ebp - 8]
mov dword [eax + 4], edx
push dword [ebp - 16]
push dword [ebp + 16]
call linked_list_append
add esp, 8
; move param list pointer
mov eax, dword [ebp - 28]
mov eax, dword [eax + 4]
mov dword [ebp - 28], eax
jmp .args_loop
.end_args_loop:
cmp dword [ebp - 28], 0
jne .invalid_argument_amount_less
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax
push dword [ebp + 32]
call hash_map_get
add esp, 8
mov edx, dword [eax + 4]
push edx
push dword [ebp - 32]
push eax
push CALL 
call get_quad
add esp, 16
mov dword [ebp - 8], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 8]
mov dword [eax], edx
push dword [ebp - 8]
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, 1
jmp .exit

.invalid_param_type:
push func_call_wrong_type
call print_string
add esp, 4
mov eax, dword [ebp - 28]
mov eax, dword [eax]
mov eax, dword [eax]
push eax
call print_string
add esp, 4
push func_call_wrong_type_param
call print_string
add esp, 4
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax
call print_string
add esp, 4
push in_func_seg
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit

.invalid_argument_amount_less:
push func_call_argument_amount_less
jmp .invalid_argument
.invalid_argument_amount_more:
push func_call_argument_amount_more
.invalid_argument:
call print_string
add esp, 4
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax
call print_string
add esp, 4
push in_func_seg
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit

.GenE:
cmp dword [eax + 8], 1
jne .func_call
.translate_expression:
mov eax, dword [eax + 12]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit

; .pre_func_call:
; push dword [ebp + 12]
; call get_new_temp
; add esp, 4
; mov dword [ebp - 8], eax
; mov eax, dword [ebp + 8]
; mov edx, dword [eax + 8]
; lea eax, dword [eax + 12 + edx * 4 + 8]
; mov edx, dword [ebp - 8]
; mov dword [eax], edx
; jmp .func_call

.JointE:
; JointE -> RelE Union
; Union.inh = RelE.val
; JointE.val = Union.val
mov eax, dword [eax + 12]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit

.RelE:
; RelE -> E RRelE
; RRelE.inh = E.val
; RelE.val = RRelE.val
mov eax, dword [eax + 12]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit


.RRelE:
; RRelE -> RelOp E RRelE | eps
; new_temp = RRelE.inh RelOp.val E.val
; RRelE1.inh = new_temp
; RRelE.val = RRelE1.val
; eps
; RRelE.val = RRelE.inh
cmp dword [eax + 8], 0
je .empty_rrele
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
push dword [ebp + 20]
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 12], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 4]
mov dword [ebp - 8], eax
push LOGIC_OP
call check_if_valid_binary
add esp, 16
cmp eax, 0
je .invalid_binary
push eax
push dword [ebp - 12]
push dword [ebp - 8]
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov eax, dword [eax]
push eax
call get_quad
add esp, 16
mov dword [ebp - 8], eax
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov edx, dword [ebp - 8]
mov dword [eax], edx
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit

.empty_rrele:
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
sub eax, 4
mov eax, dword [eax]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit


; Union -> Intersect UnionT
; Intersect.inh = Union.inh
; UnionT.inh = Intersect.val
; Union.val = UnionT.val
; eps
; Union.val = Union.inh
.Union:
cmp dword [eax + 8], 0
je .empty_union
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 4]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov edx, dword [ebp - 4]
mov dword [eax], edx
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov edx, dword [ebp - 4]
mov dword [eax], edx
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1 
jmp .exit

.empty_union:
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
sub eax, 4
mov eax, dword [eax]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit


; UnionT -> || RelE Intersect UnionT | eps
; Intersect.inh = RelE.val
; new_temp = UnionT.inh || Intersect.val
; UnionT1.inh = new_temp
; UnionT.val = UnionT1.val
; eps 
; UnionT.val = UnionT.inh
.UnionT:
cmp dword [eax + 8], 0
je .empty_uniont
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov edx, dword [ebp - 4]
mov dword [eax], edx
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
push dword [ebp + 20]
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 12], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 4]
mov dword [ebp - 8], eax
push LOGIC_OP
call check_if_valid_binary
add esp, 16
mov dword [ebp - 4], or_op
cmp eax, 0
je .invalid_binary
push eax
push dword [ebp - 12]
push dword [ebp - 8]
push OR_OP
call get_quad
add esp, 16
mov dword [ebp - 8], eax
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 4]
mov edx, dword [ebp - 8]
mov dword [eax], edx
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 12]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit

.empty_uniont:
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
sub eax, 4
mov eax, dword [eax]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit


; Intersect -> && JointE | eps
; new_temp = Intersect.inh && JointE.val
; Intersect.val = new_temp
; eps
; Intersect.val = Intersect.inh
.Intersect:
cmp dword [eax + 8], 0
je .empty_intersect
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
push dword [ebp + 36]
push dword [ebp + 32]
push dword [ebp + 28]
push dword [ebp + 24]
push dword [ebp + 20]
push dword [ebp + 16]
push dword [ebp + 12]
push eax
call visit_node
add esp, 32
cmp eax, 0
je .error_exit
push dword [ebp + 20]
mov eax, dword [ebp + 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 12], eax
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
mov eax, dword [eax + 12 + edx * 4 + 4]
mov dword [ebp - 8], eax
push LOGIC_OP
call check_if_valid_binary
add esp, 16
mov dword [ebp - 4], and_op
cmp eax, 0
je .invalid_binary
push eax
push dword [ebp - 12]
push dword [ebp - 8]
push AND_OP
call get_quad
add esp, 16
mov dword [ebp - 8], eax
push eax
push dword [ebp + 16]
call linked_list_append
add esp, 8
mov eax, dword [ebp + 8]
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov edx, dword [ebp - 8]
mov dword [eax], edx
mov eax, 1
jmp .exit

.empty_intersect:
mov edx, dword [eax + 8]
lea eax, dword [eax + 12 + edx * 4 + 8]
mov dword [ebp - 4], eax
sub eax, 4
mov eax, dword [eax]
mov edx, dword [ebp - 4]
mov dword [edx], eax
mov eax, 1
jmp .exit

.invalid_binary:
push binary_error
call print_string
add esp, 4
push dword [ebp - 4]
call print_string
add esp, 4
push in_func_seg
call print_string
add esp, 4
push dword [ebp + 36]
call print_string
add esp, 4
push single_quote_close
call print_string
add esp, 4
jmp .error_exit

.error_exit:
xor eax, eax 
leave
ret

.exit:
leave
ret

; char* get_new_label(uint* branch_label_counter)
get_new_label:
push ebp
mov ebp, esp
sub esp, 8
mov dword [ebp - 4], 0
mov dword [ebp - 8], itoa_buffer
mov eax, dword [ebp + 8]
inc dword [eax]
push 10
push itoa_buffer
push dword [eax]
call itoa
add esp, 12
push 13
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax
mov eax, dword [ebp - 4]
mov dword [eax], '.'    
inc dword eax
mov dword [eax], 'L'
.loop:
mov edx, dword [ebp - 8]
cmp byte [edx], 0
je .end_loop
inc dword eax
mov dl, byte [edx]
mov byte [eax], dl
inc dword [ebp - 8]
jmp .loop
.end_loop:
inc dword eax
mov byte [eax], 0
mov eax, dword [ebp - 4]
leave
ret


; char* get_new_temp(uint* temp_counter)
get_new_temp:
push ebp
mov ebp, esp
sub esp, 8
mov dword [ebp - 4], 0
mov dword [ebp - 8], itoa_buffer
mov eax, dword [ebp + 8]
inc dword [eax]
push 10
push itoa_buffer
push dword [eax]
call itoa
add esp, 12
push 12
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax
mov eax, dword [ebp - 4]
mov dword [eax], 't'     ; load temp label
.loop:
mov edx, dword [ebp - 8]
cmp byte [edx], 0
je .end_loop
inc dword eax
mov dl, byte [edx]
mov byte [eax], dl
inc dword [ebp - 8]
jmp .loop
.end_loop:
inc dword eax
mov byte [eax], 0
mov eax, dword [ebp - 4]
leave
ret

; VarEntry* get_var_decl(char* var_name, table* var_table, table* func_var_table)
get_var_decl:
push ebp
mov ebp, esp 
push dword [ebp + 8]
push dword [ebp + 16]
call hash_map_get
add esp, 8
cmp eax, 0
jne .exit
push dword [ebp + 8]
push dword [ebp + 12]
call hash_map_get
add esp, 8
cmp eax, 0
jne .exit
.error_exit:
xor eax, eax
.exit:
leave
ret

; STRUCTURE: quad <int op, int arg1, int arg2, int arg3> 
; quad* get_quad(int op, auto left_operand, auto right_operand, entry* type)
get_quad:
push ebp
mov ebp, esp 
sub esp, 4
push 16
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax
mov edx, dword [ebp + 8]
mov dword [eax], edx
mov edx, dword [ebp + 12]
mov dword [eax + 4], edx
mov edx, dword [ebp + 16]
mov dword [eax + 8], edx
mov edx, dword [ebp + 20]
mov dword [eax + 12], edx
leave
ret

; entry* check_if_valid_unary(int op, quad operand, table* type_table)
; returns the new type of the subsequent operation or null if invalid operand types are present
check_if_valid_unary:
push ebp
mov ebp, esp 
cmp dword [ebp + 8], UNARY_MINUS_OP
je .unary_minus
cmp dword [ebp + 8], NEG_OP
je .neg
cmp dword [ebp + 8], DEREF_OP
je .deref
cmp dword [ebp + 8], ADDRESS_OP
je .address
jmp .next
.unary_minus:
mov eax, dword [ebp + 12]       ; load left_operand
mov eax, dword [eax + 12]       ; load type_entry
cmp dword [eax + 4], PRIMITIVE  ; unary minus only valid for primitive types (int, uint, char, bool)
jne .false
cmp dword [eax + 8], UINTEGER
je .true
push integer_k
push dword [ebp + 16]
call hash_map_get
add esp, 8
jmp .true
.deref:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
cmp dword [eax + 4], PRIMITIVE
je .false
cmp dword [eax + 4], STRUCTURE
je .false
mov eax, dword [eax + 8]    ; load child type
jmp .true
.address:
mov eax, dword [ebp + 12]
cmp dword [eax], ID         ; & op only valid for lvalues
je .valid
cmp dword [eax], ACCESS_OP  ; access produces an lvalue
jne .false
.valid:
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
push eax
push pointer
call get_composite_p_entry
add esp, 8
jmp .true
.next:
.neg:
push bool_k
push dword [ebp + 16]
call hash_map_get
add esp, 8
.true:
leave
ret

.false:
xor eax, eax
leave
ret

; entry* check_if_valid_binary(int op_type, quad* left_operand, quad* right_operant, table* type_table)
; returns the subsequent type after valid operation or null if invalid types are provided
; TODO: add better error reporting since the operands are now quads
check_if_valid_binary:
push ebp
mov ebp, esp
sub esp, 8
mov eax, dword [ebp + 12]
mov eax, dword [eax + 12]
mov dword [ebp - 4], eax
mov eax, dword [ebp + 16]
mov eax, dword [eax + 12]
mov dword [ebp - 8], eax
cmp dword [ebp + 8], ARITHMETIC_ADD_SUB_OP
je .arithmetic_add_sub
cmp dword [ebp + 8], ARITHMETIC_MUL_DIV_OP
je .arithmetic_mul_div
cmp dword [ebp + 8], LOGIC_OP
je .logical
jmp .assignment
.arithmetic_add_sub:
; check for primitive arithmetic
mov eax, dword [ebp - 4]
mov edx, dword [ebp - 8]
mov eax, dword [eax + 4]
add eax, dword [edx + 4]
cmp eax, 0
je .primitive_arithmetic
cmp eax, 1
je .pointer_arithmetic
cmp eax, 2
je .array_decay
jmp .error_exit
.primitive_arithmetic:
mov eax, dword [ebp - 4]
cmp dword [eax + 8], UINTEGER
je .exit
mov eax, dword [ebp - 8]
cmp dword [eax + 8], UINTEGER
je .exit
push integer_k
push dword [ebp + 20]
call hash_map_get
add esp, 8
jmp .exit
.pointer_arithmetic:
mov eax, dword [ebp - 4]
cmp dword [eax + 4], POINTER
je .exit
mov eax, dword [ebp - 8]
jmp .exit
.array_decay:
mov eax, dword [ebp - 4]
cmp dword [eax + 4], POINTER
je .error_exit
cmp dword [eax + 4], ARRAY
je .exit
mov eax, dword [ebp - 8]
jmp .exit
.arithmetic_mul_div:
mov eax, dword [ebp - 4]
mov eax, dword [eax + 4]
mov edx, dword [ebp - 8]
mov eax, dword [edx + 4]
add eax, edx
cmp eax, 0
jne .error_exit
jmp .primitive_arithmetic
.logical:
mov eax, dword [ebp - 4]
cmp dword [eax + 4], STRUCTURE
je .error_exit
mov eax, dword [ebp - 8]
cmp dword [eax + 4], STRUCTURE
je .error_exit
push bool_k
push dword [ebp + 20]
call hash_map_get
add esp, 8
jmp .exit
.assignment:
mov eax, dword [ebp - 4]
cmp dword [eax + 4], ARRAY
je .error_exit
mov edx, dword [ebp - 8]
mov eax, dword [eax + 4]
mov edx, dword [edx + 4]
cmp eax, edx
je .equal_complexity
.mixed_complexity:
mov eax, dword [ebp - 4]
cmp dword [eax + 4], PRIMITIVE
je .error_exit
cmp dword [eax + 4], STRUCTURE
je .error_exit
mov eax, dword [ebp - 8]
cmp dword [eax + 4], PRIMITIVE
je .check_null_pointer
cmp dword [eax + 4], STRUCTURE
je .error_exit
.equal_complexity:
mov eax, dword [ebp - 4]
cmp dword [eax + 4], STRUCTURE
je .structs
cmp dword [eax + 4], POINTER
je .pointer_loop
cmp dword [eax + 4], ARRAY
jne .primitives
.pointer_loop:
mov eax, dword [ebp - 4]
mov eax, dword [eax + 8]
mov dword [ebp - 4], eax
mov eax, dword [ebp - 8]
mov eax, dword [eax + 8]
mov dword [ebp - 8], eax
push dword [ebp - 8]
push dword [ebp - 4]
call can_follow_pointer
add esp, 8
cmp eax, 0
jne .pointer_loop
.end_pointer_loop:
mov eax, dword [ebp - 4]
mov edx, dword [ebp - 8]
mov eax, dword [eax + 4]
cmp eax, dword [edx + 4]
jne .error_exit
mov eax, dword [ebp - 4]
cmp dword [eax + 4], PRIMITIVE
jne .structs
mov edx, dword [edx + 8]
cmp dword [eax + 8], edx
jne .error_exit
mov eax, dword [ebp - 4]
jmp .exit
.structs:
mov eax, dword [eax]
push eax
mov eax, dword [ebp - 8]
mov eax, dword [eax]
push eax
call string_equals
add esp, 8
cmp eax, 0
je .error_exit
mov eax, dword [ebp - 4]
jmp .exit
.primitives:
mov eax, dword [ebp - 4]
jmp .exit
.check_null_pointer:
mov eax, dword [ebp - 4]
cmp dword [eax + 4], POINTER
jne .error_exit
mov eax, dword [ebp + 16]
cmp dword [eax], NUM
jne .error_exit
cmp dword [eax + 4], 0
jne .error_exit
mov eax, dword [ebp - 4]
jmp .exit
.error_exit:
xor eax, eax
.exit:
leave
ret

; bool can_follow_pointer(entry* left_operand_type, entry* right_operand_type)
can_follow_pointer:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
cmp dword [eax + 4], POINTER
je .skip_to_right
cmp dword [eax + 4], ARRAY
jne .error_exit
.skip_to_right:
mov eax, dword [ebp + 12]
cmp dword [eax + 4], POINTER
je .exit
cmp dword [eax + 4], ARRAY
je .exit
.error_exit:
xor eax, eax
leave
ret
.exit:
mov eax, 1
leave
ret

struct_self_ref: db "ERROR: semantic error, incomplete type for variable '", 0
struct_self_ref_end: db "' in struct '", 0
var_red: db "ERROR: semantic error, variable '", 0
var_red_gm: db "' redeclared in global memory", 10, 0
var_red_func: db "' redeclared in function '", 0
var_red_struct: db "' redeclared in struct '", 0
var_undec: db "ERROR: semantic error, undeclared variable '", 0
var_undec_func: db "' detected in function '", 0
var_nonstruct: db "ERROR: semantic error, member access requested on nonstruct variable '", 0
in_func_seg: db "' in function '", 0
struct_nonmember: db "ERROR: semantic error, member '", 0
struct_nonmember_2: db "' not present in struct '", 0
unary_error: db "ERROR: semantic error, invalid type supplied to unary operator '", 0
binary_error: db "ERROR: semantic error, incompatible types supplied to operator '", 0
var_not_subscript: db "ERROR: semantic error, subscript access requested on not subscriptable variable '", 0
var_subscript_type: db "ERROR: semantic error, subscript value not integer type in function '", 0
invalid_return: db "ERROR: semantic error, returning invalid type in function '", 0
func_call_wrong_type: db "ERROR: semantic error, type mismatch for parameter '", 0
func_call_wrong_type_param: db "' for function call '", 0
func_call_argument_amount_more: db "ERROR: semantic error, excess amount of arguments passed to called function '", 0
func_call_argument_amount_less: db "ERROR: semantic error, less than expected amount of arguments passed to called function '", 0
single_quote_close: db "'.", 10, 0
param_red: db "ERROR: semantic error, parameter '", 0
func_red: db "ERROR: semantic error, function '", 0
func_red_end: db "' redeclared.", 10, 0
func_arr_ret: db "' declared with an array type return value.", 10, 0
func_main_missing: db "ERROR: semantic error, parameterless function main not declared", 0
is_primitive: db "primitive type ref", 0
is_simple: db "simple type registered", 0
is_composite: db "composite type registered", 0
is_nonprimitive: db "nonprimitive type ref", 0
main_k: db "main", 0
pointer: db "*", 0
array: db "[]", 0
offset_k: db "offset", 0
label_k: db ".L", 0
colon_k: db ":", 0
comma_k: db ",", 0
goto_k: db "goto", 0
param_k: db "param", 0
call_k: db "call", 0
var_test: db "x", 0