%define PRIMITIVE 0
%define SIMPLE 1
%define COMPOSITE 2
%define POINTER 3
%define ARRAY 4


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
push dword [ebp + 16]
push dword [ebp + 12]
push eax 
call add_var
add esp, 12
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

.exit:
mov eax, 1
leave
ret 

; entry* get_primitive_entry(char* key, int type)
get_primitive_entry:
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
mov dword [eax + 4], PRIMITIVE
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
leave
ret 

; entry* get_simple_entry(char* key, entry* entry)
get_simple_entry:
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
mov dword [eax + 4], SIMPLE
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
leave
ret 

; entry* get_composite_p_entry(char* key, entry* entry)
get_composite_p_entry:
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
mov dword [eax + 4], POINTER
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
leave
ret

; entry* get_composite_arr_entry(char* key, entry* entry, uint size)
get_composite_arr_entry:
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
mov dword [eax + 4], ARRAY
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
mov edx, dword [ebp + 16]
mov dword [eax + 12], edx
leave
ret 

; entry* get_function_entry(char* key, entry* r_type, table* param_table, table* var_table, Tree_node body)
get_function_entry:
push ebp 
mov ebp, esp 

leave 
ret 

; void construct_type(Tree_node* node, table* type_table)
construct_type:
push ebp
mov ebp, esp
sub esp, 24 
mov dword [ebp - 4], 0      ; TE|VaD pointer
mov dword [ebp - 8], 0      ; new_name_lexeme pointer
mov dword [ebp - 12], 0     ; ref_type_lexeme pointer
mov dword [ebp - 16], 0     ; TyDeco pointer
mov dword [ebp - 20], 0     ; composite contruction entry pointer
mov dword [ebp - 24], 0     ; Decorator pointer
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax    ; save TE|VaD
lea eax, dword [eax + 12]   ; get TE children
mov edx, dword [eax]
cmp dword [edx], STRUCT     ; check if TE is a struct
jne .not_a_struct
mov eax, dword [eax + 4]    ; get TyNa
jmp .end_check
.not_a_struct:
mov eax, dword [eax + 8]    ; get TyNa
.end_check: 
mov eax, dword [eax + 4]    ; get token
mov eax, dword [eax + 4]    ; get lexeme
mov dword [ebp - 8], eax   ; save new_type_lexeme
; detect type complexity
; get ref_type_lexeme
mov eax, dword [ebp - 4]    ; load TE 
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
push edx
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

; void add_type(Tree_node* node, table* type_table)
add_type:
push ebp 
mov ebp, esp
sub esp, 4
mov eax, dword [ebp + 8]    ; load TE 
lea eax, dword [eax + 12]   ; load children baddr
mov eax, dword [eax + 8]    ; get TyName
mov eax, dword [eax + 4]    ; load token
mov eax, dword [eax + 4]    ; load lexeme
mov dword [ebp - 4], eax    ; save ref_type_lexeme
push dword [ebp + 12]
push dword [ebp + 8]
call construct_type
add esp, 8
push eax 
push dword [ebp - 4]
push dword [ebp + 12]
call hash_map_put
add esp, 12
leave
ret 


; void add_var(Tree_node* node, table* type_table, table* var_table)
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
push dword [ebp + 12]
push dword [ebp + 8]
call construct_type
add esp, 8
push eax 
push dword [ebp - 4]
push dword [ebp + 16]
call hash_map_put
add esp, 12 
leave
ret
.var_redeclaration:
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


add_func:
push ebp
mov ebp, esp 
sub esp, 16
mov dword [ebp - 4], 0  
mov dword [ebp - 8], 0
mov dword [ebp - 12], 0
mov dword [ebp - 16], 0
leave
ret 

; bool detect_main(Tree_node* FuDS)
detect_main:
push ebp 
mov ebp, esp 
sub esp, 12
mov dword [ebp - 4], 0      ; zero out the flag
mov dword [ebp - 8], 0      ; FuDS pointer
.check:
mov eax, dword [ebp + 8]
cmp dword [eax + 8], 0
je .exit
lea eax, dword [eax + 12]
mov edx, dword [eax + 4]
mov dword [ebp + 8], edx
mov eax, dword [eax]
mov dword [ebp - 8], eax   ; save FuD
lea eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax + 12]
mov eax, dword [eax + 4]
mov eax, dword [eax]
cmp eax, INTEGER
jne .check
mov eax, dword [ebp - 8]
lea eax, dword [eax + 12]
mov eax, dword [eax + 8]
mov eax, dword [eax + 4]
mov eax, dword [eax + 4]
push eax 
push main_k
call string_equals
add esp, 8
cmp eax, 0
je .check 

.exit:
leave
ret 

var_red: db "ERROR: semantic error, variable '", 0
var_red_gm: db "' redeclared in global memory.", 10, 0
var_red_func: db "' redeclared in function ", 0
func_main_missing: db "ERROR: semantic error, parameterless function main not declared"
is_primitive: db "primitive type ref", 0
is_simple: db "simple type registered", 0
is_composite: db "composite type registered", 0
is_nonprimitive: db "nonprimitive type ref", 0
main_k: db "main", 0
pointer: db "*", 0
array: db "[]", 0