[bits 32]

%define PRIMITIVE 0
%define SIMPLE 1
%define POINTER 2
%define ARRAY 3
%define STRUCTURE 4

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


; entry* get_func_entry(char* key, entry* r_type, hash_map* var_table, Tree_node* body)
get_func_entry:
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
mov edx, dword [ebp + 12]
mov dword [eax + 4], edx 
mov edx, dword [ebp + 16]
mov dword [eax + 8], edx 
mov edx, dword [ebp + 20]
mov dword [eax + 12], edx
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

; entry* get_simple_entry(char* key, entry* entry)
get_simple_entry:
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
mov dword [eax + 4], SIMPLE
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
mov edx, dword [ebp + 12]
mov edx, dword [edx + 12]
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
; declare simple type
.simple_type:
push dword [ebp - 12]
push dword [ebp + 12]
call hash_map_get
add esp, 8
push eax 
push dword [ebp - 8]
call get_simple_entry
add esp, 8
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
push nl 
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
push nl 
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
push dword [ebp + 16]
push dword [ebp + 12]
push dword [ebp - 4]
call construct_func
add esp, 12
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
.error_exit:
xor eax, eax 
leave
ret

; entry* construct_func(Tree_node* node, hash_map* type_table, hash_map* var_table, hash_map* func_table)
construct_func:
push ebp
mov ebp, esp
sub esp, 40
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
.check_array_type_loop:
cmp dword [eax + 4], ARRAY
je .error_array_ret
cmp dword [eax + 4], SIMPLE
jne .no_array_ret
mov eax, dword [eax + 8]
jmp .check_array_type_loop
.no_array_ret:
push eax 
push dword [ebp - 8]
call get_simple_entry
add esp, 8
.func_entry:
; eax has r_type entry at this point
mov dword [ebp - 20], eax
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
mov edx, dword [eax]
mov eax, dword [eax + 4]    ; load RPaDS
mov dword [ebp - 16], eax   ; save RPaDS
push dword [ebp - 4]
push dword [ebp - 28]
push dword [ebp + 12]
push edx
call add_var
add esp, 16
cmp eax, 0  ; error while adding param
je .error_exit
; load rest
.param_loop:
mov eax, dword [ebp - 16]   ; load RPaDS
cmp dword [eax + 8], 0
je .end_param_loop
lea eax, dword [eax + 12]
mov edx, dword [eax + 8]    ; load RPaD
mov dword [ebp - 16], edx   ; save next RPaDS
mov eax, dword [eax + 4]    ; load PaD
push dword [ebp - 4]
push dword [ebp - 28]
push dword [ebp + 12]
push eax 
call add_var
add esp, 16
cmp eax, 0  ; error while adding param
je .error_exit
jmp .param_loop
.end_param_loop:
; add declared variables
mov eax, dword [ebp - 4]    ; load FuD
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 32]   ; load VaDS
mov dword [ebp - 32], eax   ; save VaDS
.declared_vars_loop:
mov eax, dword [ebp - 32]    ; load VaDS
cmp dword [eax + 8], 0      ; check if any gm variables declared
je .no_vars_declared
lea eax, dword [eax + 12]   ; load children baddr
mov edx, dword [eax + 4]    ; load next VaDS
mov dword [ebp - 32], edx    ; save next VaDS
mov eax, dword [eax]        ; load VaD
push dword [ebp - 4]
push dword [ebp - 28]
push dword [ebp + 12]
push eax 
call add_var
add esp, 16
cmp eax, 0  ; error while adding var
je .error_exit
jmp .declared_vars_loop
.no_vars_declared:
; get func body
mov eax, dword [ebp - 4]    ; load FuD
lea eax, dword [eax + 12]   ; load children baddr
push dword [eax + 36]       ; load body
push dword [ebp - 28]       ; load func var_table
push dword [ebp - 20]       ; load r_type
push dword [ebp - 8]        ; load FuncNa
call get_func_entry
add esp, 16
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

struct_self_ref: db "ERROR: semantic error, incomplete type for variable '", 0
struct_self_ref_end: db "' in struct '", 0
var_red: db "ERROR: semantic error, variable '", 0
var_red_gm: db "' redeclared in global memory", 10, 0
var_red_func: db "' redeclared in function '", 0
var_red_struct: db "' redeclared in struct '", 0
single_quote_close: db "'", 10, 0
param_red: db "ERROR: semantic error, parameter '", 0
func_red: db "ERROR: semantic error, function '", 0
func_red_end: db "' redeclared.", 10, 0
func_arr_ret: db "' declared with an array type return value.", 10, 0
func_main_missing: db "ERROR: semantic error, parameterless function main not declared"
is_primitive: db "primitive type ref", 0
is_simple: db "simple type registered", 0
is_composite: db "composite type registered", 0
is_nonprimitive: db "nonprimitive type ref", 0
main_k: db "main", 0
pointer: db "*", 0
array: db "[]", 0

; TODO: add boolean checks to add_* functions for error detection