[bits 32]
%define cur_token_ptr 0x1000_1000
%define lexer_state_ptr 0x1000_1004
%define terminals 300 
%define nonterminals 42
%define jump_table_size terminals*nonterminals*4
%define word_map_size 66 * 4

; void parser_parse(lexer_state* state)
parser_parse:
push ebp 
mov ebp, esp 
sub esp, jump_table_size            ; jump_table with 300 free indexes per 41 nonterminals
sub esp, 32                       
sub esp, word_map_size

push word_map_size/4
lea eax, dword [ebp - jump_table_size - 32 - word_map_size]
push eax 
call array_sanitize
add esp, 8

lea eax, dword [ebp - jump_table_size - 32 - word_map_size]
push eax 
call load_word_map
add esp, 4

push jump_table_size/4
lea eax, dword [ebp - jump_table_size]
push eax 
call array_sanitize
add esp, 8

lea eax, dword [ebp - jump_table_size]
push eax
call load_jump_table
add esp, 4


push dword [ebp + 8]
call lexer_get_token
add esp, 4


mov dword [ebp - jump_table_size - 4], eax      ; cache cur_token
mov dword [ebp - jump_table_size - 12], 0
mov dword [ebp - jump_table_size - 16], 0       ; init parse_tree stack
mov dword [ebp - jump_table_size - 20], 0       ; init parse_tree root
mov dword [ebp - jump_table_size - 24], 0       ; new node variable
mov dword [ebp - jump_table_size - 28], 0       ; new node child count


lea eax, dword [ebp - jump_table_size - 20]
push eax 
lea eax, dword [ebp - jump_table_size - 16]
push eax
call stack_push
add esp, 8

; init stack with start config
push EOF
push prog 

.parse_loop:

; cmp dword [ebp - jump_table_size - 12], 25
; jl .skip 
; lea eax, dword [esp]
; push eax 
; call print_stack
; add esp, 4
; .skip:
; inc dword [ebp - jump_table_size - 12]

mov eax, dword [esp]
mov dword [ebp - jump_table_size - 8], eax      ; cache stack top symbol
cmp dword [ebp - jump_table_size - 8], EOF      ; check if EOF 
je .end_parsing
mov eax, dword [ebp - jump_table_size - 4]      ; load cur_token
mov eax, dword [eax]                            ; token.tag
cmp dword [ebp - jump_table_size - 8], eax      ; check if token.tag = stack.top
jne .check_if_terminal
; found a match 
add esp, 4
mov eax, dword [ebp - jump_table_size - 4]
cmp dword [eax], NAME
jge .nonterm_token
push 0
jmp .end_check
.nonterm_token:
push dword [ebp - jump_table_size - 4]
.end_check:
push dword [ebp - jump_table_size - 8]
call get_leaf
add esp, 8
mov dword [ebp - jump_table_size - 24], eax 
lea eax, dword [ebp - jump_table_size - 16]
push eax
call stack_pop
add esp, 4
mov edx, dword [ebp - jump_table_size - 24]
mov dword [eax], edx
push dword [ebp + 8]
call lexer_get_token
add esp, 4
mov dword [ebp - jump_table_size - 4], eax 
jmp .parse_loop
.check_if_terminal:
cmp dword [ebp - jump_table_size - 8], prog
jae .check_if_error_production
jmp .error
.check_if_error_production:
mov eax, dword [ebp - jump_table_size - 4]
mov eax, dword [eax]
push eax 
push dword [ebp - jump_table_size - 8] 
lea eax, dword [ebp - jump_table_size]
push eax 
call jump_table_get_production
add esp, 12
cmp eax, EPSILON
je .epsilon_production
cmp eax, 0
je .error
; proceed to production
add esp, 4
push eax 
call linked_list_reverse
add esp, 4
xor ecx, ecx
.production_loop:
cmp eax, 0
je .end_production
push dword [eax]
mov eax, dword [eax + 4]
add ecx, 8
jmp .production_loop 
.end_production:
push ecx 
call heap_free
add esp, 4
; child count = ecx >> 3 (ecx / 8)
shr ecx, 3
mov dword [ebp - jump_table_size - 28], ecx
push ecx 
push dword [ebp - jump_table_size - 8]
call get_node
add esp, 8
mov dword [ebp - jump_table_size - 24], eax 
lea eax, dword [ebp - jump_table_size - 16]
push eax 
call stack_pop          ; pop the top address on the stack
add esp, 4
mov edx, dword [ebp - jump_table_size - 24]
mov dword [eax], edx    ; load new node into the tree
.tree_loop:
cmp dword [ebp - jump_table_size - 28], 0
je .parse_loop
mov edx, dword [ebp - jump_table_size - 28]
mov eax, dword [ebp - jump_table_size - 24]
lea eax, dword [eax + 8 + edx * 4]
push eax
lea eax, dword [ebp - jump_table_size - 16]
push eax 
call stack_push
add esp, 8
dec dword [ebp - jump_table_size - 28]
jmp .tree_loop
; jmp .parse_loop
.epsilon_production:
add esp, 4
push 0
push dword [ebp - jump_table_size - 8]
call get_leaf
add esp, 8
mov dword [ebp - jump_table_size - 24], eax 
lea eax, dword [ebp - jump_table_size - 16]
push eax
call stack_pop
add esp, 4
mov edx, dword [ebp - jump_table_size - 24]
mov dword [eax], edx 
jmp .parse_loop
.error:
; lea eax, dword [ebp - jump_table_size - 32 - word_map_size]
; push eax 
; mov eax, dword [ebp - jump_table_size - 20]
; lea eax, dword [eax + 12]
; mov eax, dword [eax + 8]
; mov eax, dword [eax + 12]
; push eax
; call print_tree
; add esp, 8

mov eax, dword [ebp - jump_table_size - 4]
push 10
push itoa_buffer
push dword [eax]
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push nl
call print_string
add esp, 4
mov eax, dword [ebp - jump_table_size - 4]
push 10
push itoa_buffer
push dword [eax + 4]
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push nl
call print_string
add esp, 4
; lea eax, dword [ebp - jump_table_size - 32 - word_map_size]
; push eax
; mov eax, dword [ebp - jump_table_size - 4]
; push dword [eax]
; call tag_to_str
; add esp, 4
; push eax
; call print_string
; add esp, 4
; push nl
; call print_string
; add esp, 4
; mov eax, dword [ebp - jump_table_size - 4]
; push dword [eax + 4]
; call print_string
; add esp, 4
; push nl 
; call print_string
; add esp, 4
push error_line
call print_string
add esp, 4
mov eax, dword [ebp + 8] ; load lexer state
mov eax, dword [eax + 16] ; load line counter
push 10
push itoa_buffer
push dword [eax] 
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push nl 
call print_string
add esp, 4
xor eax, eax
leave
ret
.end_parsing:

; lea eax, dword [ebp - jump_table_size - 32 - word_map_size]
; push eax 
; mov eax, dword [ebp - jump_table_size - 20]
; lea eax, dword [eax + 12]
; mov eax, dword [eax + 8]
; mov eax, dword [eax + 12]
; lea eax, dword [eax + 12]
; mov eax, dword [eax + 36]
; mov eax, dword [eax + 12]
; mov eax, dword [eax + 12]
; lea eax, dword [eax + 12]
; mov eax, dword [eax + 8]
; push eax
; call print_tree
; add esp, 8


mov eax, dword [ebp - jump_table_size - 20]
leave
ret

.unexpected_eof:
push error_unexpected_eof
call print_string
add esp, 4
xor eax, eax
leave
ret 

; void load_word_map(char* word_map)
load_word_map:
push ebp 
mov ebp, esp 
mov eax, dword [ebp + 8]
mov dword [eax], TYNAME_k
mov dword [eax + (FUNCNAME - TYNAME) * 4], FUNCNAME_k
mov dword [eax + (prog - TYNAME) * 4], prog_k
mov dword [eax + (TyDS - TYNAME) * 4], TyDS_k
mov dword [eax + (VaDS - TYNAME) * 4], VaDS_k
mov dword [eax + (FuDS - TYNAME) * 4], FuDS_k
mov dword [eax + (TyD - TYNAME) * 4], TyD_k
mov dword [eax + (TE - TYNAME) * 4], TE_k
mov dword [eax + (Ty - TYNAME) * 4], Ty_k
mov dword [eax + (TyDeco - TYNAME) * 4], TyDeco_k
mov dword [eax + (VaD - TYNAME) * 4], VaD_k
mov dword [eax + (FuD - TYNAME) * 4], FuD_k
mov dword [eax + (RFuDS - TYNAME) * 4], RFuDS_k
mov dword [eax + (PaDS - TYNAME) * 4], PaDS_k
mov dword [eax + (PaD - TYNAME) * 4], PaD_k
mov dword [eax + (RPaDS - TYNAME) * 4], RPaDS_k
mov dword [eax + (body - TYNAME) * 4], body_k
mov dword [eax + (StS - TYNAME) * 4], StS_k
mov dword [eax + (rSt - TYNAME) * 4], rSt_k
mov dword [eax + (St - TYNAME) * 4], St_k
mov dword [eax + (GenE - TYNAME) * 4], GenE_k
mov dword [eax + (ArgS - TYNAME) * 4], ArgS_k
mov dword [eax + (MatchedElse - TYNAME) * 4], MatchedElse_k
mov dword [eax + (id - TYNAME) * 4], ID_k
mov dword [eax + (Rid - TYNAME) * 4], Rid_k
mov dword [eax + (idSel - TYNAME) * 4], idSel_k
mov dword [eax + (E - TYNAME) * 4], E_k
mov dword [eax + (T - TYNAME) * 4], T_k
mov dword [eax + (RE - TYNAME) * 4], RE_k
mov dword [eax + (F - TYNAME) * 4], F_k
mov dword [eax + (RT - TYNAME) * 4], RT_k
mov dword [eax + (JointE - TYNAME) * 4], JointE_k
mov dword [eax + (RRelE - TYNAME) * 4], RRelE_k
mov dword [eax + (RelOp - TYNAME) * 4], RelOp_k
mov dword [eax + (Union - TYNAME) * 4], Union_k
mov dword [eax + (UnionT - TYNAME) * 4], UnionT_k
mov dword [eax + (Intersect - TYNAME) * 4], Intersect_k
mov dword [eax + (RelE - TYNAME) * 4], RelE_k
mov dword [eax + (Arg - TYNAME) * 4], Arg_k
mov dword [eax + (RArgS - TYNAME) * 4], RArgS_k
mov dword [eax + (PaDTyDeco - TYNAME) * 4], PaDTyDeco_k
mov dword [eax + (PDeco - TYNAME) * 4], PDeco_k
mov dword [eax + (ArrDeco - TYNAME) * 4], ArrDeco_k
mov dword [eax + (PaDArrDeco - TYNAME) * 4], PaDArrDeco_k
leave
ret 


load_jump_table:
push ebp 
mov ebp, esp 
push dword [ebp + 8]
call init_prog
add esp, 4
push dword [ebp + 8]
call init_TyDS
add esp, 4
push dword [ebp + 8]
call init_TyD
add esp, 4
push dword [ebp + 8]
call init_TE
add esp, 4
push dword [ebp + 8]
call init_Ty
add esp, 4
push dword [ebp + 8]
call init_TyDeco
add esp, 4
push dword [ebp + 8]
call init_PDeco
add esp, 4
push dword [ebp + 8]
call init_ArrDeco
add esp, 4
push dword [ebp + 8]
call init_VaDS
add esp, 4
push dword [ebp + 8]
call init_VaD 
add esp, 4
push dword [ebp + 8]
call init_FuDS
add esp, 4
push dword [ebp + 8]
call init_FuD
add esp, 4
push dword [ebp + 8]
call init_RFuDS
add esp, 4
push dword [ebp + 8]
call init_PaDS
add esp, 4
push dword [ebp + 8]
call init_PaDTyDeco
add esp, 4
push dword [ebp + 8]
call init_PaDArrDeco
add esp, 4
push dword [ebp + 8]
call init_PaD
add esp, 4
push dword [ebp + 8]
call init_RPaDS
add esp, 4
push dword [ebp + 8]
call init_body
add esp, 4
push dword [ebp + 8]
call init_rSt
add esp, 4
push dword [ebp + 8]
call init_StS
add esp, 4
push dword [ebp + 8]
call init_St
add esp, 4
push dword [ebp + 8]
call init_MatchedElse
add esp, 4
push dword [ebp + 8]
call init_id
add esp, 4
push dword [ebp + 8]
call init_Rid
add esp, 4
push dword [ebp + 8]
call init_idSel
add esp, 4
push dword [ebp + 8]
call init_GenE
add esp, 4
push dword [ebp + 8]
call init_ArgS
add esp, 4
push dword [ebp + 8]
call init_Arg
add esp, 4
push dword [ebp + 8]
call init_RArgS
add esp, 4
push dword [ebp + 8]
call init_JointE
add esp, 4
push dword [ebp + 8]
call init_RelE
add esp, 4
push dword [ebp + 8]
call init_Union
add esp, 4
push dword [ebp + 8]
call init_RRelE
add esp, 4
push dword [ebp + 8]
call init_UnionT
add esp, 4
push dword [ebp + 8]
call init_Intersect
add esp, 4
push dword [ebp + 8]
call init_RelOp
add esp, 4
push dword [ebp + 8]
call init_E 
add esp, 4
push dword [ebp + 8]
call init_RE 
add esp, 4
push dword [ebp + 8]
call init_T
add esp, 4 
push dword [ebp + 8]
call init_RT 
add esp, 4
push dword [ebp + 8]
call init_F 
add esp, 4
leave
ret 

; void jump_table_init(table* jump_table_ptr, int nonterminal, int terminal, auto production_body)
jump_table_init:
push ebp 
mov ebp, esp 
sub esp, 4
mov dword [ebp - 4], terminals 
mov eax, dword [ebp + 12]
sub eax, prog                           ; offset by prog to get index
mul dword [ebp - 4]
add eax, dword [ebp + 16]
shl eax, 2
add eax, dword [ebp + 8]
mov edx, dword [ebp + 20]
mov dword [eax], edx                    ; load production_body
leave
ret 

; auto jump_table_get_production(table* jump_table, int nonterminal, int terminal)
jump_table_get_production:
push ebp 
mov ebp, esp 
sub esp, 4
mov dword [ebp - 4], terminals 
mov eax, dword [ebp + 12]
sub eax, prog                           ; offset by prog to get index
mul dword [ebp - 4]
add eax, dword [ebp + 16]
shl eax, 2
add eax, dword [ebp + 8]
mov eax, dword [eax]
leave
ret 

init_prog:
push ebp
mov ebp, esp
sub esp, 4
push 0
push TyDS
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push VaDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push FuDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push TYPEDEF
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push SHORT
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FUNC
push prog
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_TyDS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push TyD
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push TyDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push TYPEDEF
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push SHORT
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push CHAR
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push INT
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push FUNC
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push BOOL
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push UINT
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push UCHAR
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push USHORT
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push TYNAME
push TyDS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_TyD:
push ebp
mov ebp, esp
sub esp, 4
push 0
push TYPEDEF
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push TE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x3b
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push TYPEDEF
push TyD
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_TE:
push ebp
mov ebp, esp
sub esp, 4
push 0
push Ty
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push TyDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push TYNAME
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push SHORT
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push STRUCT
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push TYNAME
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7b
push dword [ebp-4]
call linked_list_append
add esp, 8
push VaDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7d
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push STRUCT
push TE
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_TyDeco:
push ebp
mov ebp, esp
sub esp, 4
push 0
push PDeco
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push ArrDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2a
push TyDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x5b
push TyDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NAME
push TyDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push FUNCNAME
push TyDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push TYNAME
push TyDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_PDeco:
push ebp
mov ebp, esp
sub esp, 4
push 0
push 0x2a
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push PDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2a
push PDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NAME
push PDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push FUNCNAME
push PDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x21
push PDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push TYNAME
push PDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x5b
push PDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_ArrDeco:
push ebp
mov ebp, esp
sub esp, 4
push 0
push 0x5b
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push NUM
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x5d
push dword [ebp-4]
call linked_list_append
add esp, 8
push ArrDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x5b
push ArrDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NAME
push ArrDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push FUNCNAME
push ArrDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push TYNAME
push ArrDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_Ty:
push ebp
mov ebp, esp
sub esp, 4
push 0
push CHAR
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push CHAR
push Ty
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push SHORT
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push SHORT
push Ty
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push INT
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push INT
push Ty
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push UCHAR
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push UCHAR
push Ty
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push USHORT
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push USHORT
push Ty
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push UINT
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push UINT
push Ty
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push BOOL
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push BOOL
push Ty
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push TYNAME
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push TYNAME
push Ty
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_VaDS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push VaD
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push VaDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push SHORT
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NAME
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x7d
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push ASM
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push FUNC
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push DO
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push FUNCNAME
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push IF
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push WHILE
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push RETURN
push VaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_VaD:
push ebp
mov ebp, esp
sub esp, 4
push 0
push Ty
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push TyDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push NAME
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x3b
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push SHORT
push VaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push VaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push VaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push VaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push VaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push VaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push VaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push VaD
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_FuDS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push FuD
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RFuDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push FUNC
push FuDS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_RFuDS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push FuD
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RFuDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push FUNC
push RFuDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push EOF
push RFuDS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_FuD:
push ebp
mov ebp, esp
sub esp, 4
push 0
push FUNC
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push Ty
push dword [ebp-4]
call linked_list_append
add esp, 8
push TyDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push FUNCNAME
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x28
push dword [ebp-4]
call linked_list_append
add esp, 8
push PaDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x29
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7b
push dword [ebp-4]
call linked_list_append
add esp, 8
push VaDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push body
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7d
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push FUNC
push FuD
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_PaD:
push ebp
mov ebp, esp
sub esp, 4
push 0
push Ty
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push PaDTyDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push NAME
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push SHORT
push PaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push PaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push PaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push PaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push PaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push PaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push PaD
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push PaD
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_PaDTyDeco:
push ebp
mov ebp, esp
sub esp, 4
push 0
push PDeco
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push PaDArrDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2a
push PaDTyDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x5b
push PaDTyDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NAME
push PaDTyDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_PaDArrDeco:
push ebp
mov ebp, esp
sub esp, 4
push 0
push 0x5b
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push NUM
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x5d
push dword [ebp-4]
call linked_list_append
add esp, 8
push ArrDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x5b
push PaDArrDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NAME
push PaDArrDeco
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_PaDS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push PaD
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RPaDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push SHORT
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push PaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_RPaDS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push 0x2c
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push PaD
push dword [ebp-4]
call linked_list_append
add esp, 8
push RPaDS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2c
push RPaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push RPaDS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_body:
push ebp
mov ebp, esp
sub esp, 4
push 0
push StS
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push rSt
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push body
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FUNCNAME
push body
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push IF
push body
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push WHILE
push body
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push ASM
push body
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push DO
push body
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push RETURN
push body
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_rSt:
push ebp
mov ebp, esp
sub esp, 4
push 0
push RETURN
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push GenE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x3b
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push RETURN
push rSt
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_StS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push St
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push StS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push StS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FUNCNAME
push StS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push IF
push StS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push WHILE
push StS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push ASM
push StS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push DO
push StS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x7d
push StS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push RETURN
push StS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_St:
push ebp
mov ebp, esp
sub esp, 4
push 0
push IF
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push 0x28
push dword [ebp-4]
call linked_list_append
add esp, 8
push GenE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x29
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7b
push dword [ebp-4]
call linked_list_append
add esp, 8
push StS
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7d
push dword [ebp-4]
call linked_list_append
add esp, 8
push MatchedElse
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push IF
push St
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push WHILE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push 0x28
push dword [ebp-4]
call linked_list_append
add esp, 8
push GenE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x29
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7b
push dword [ebp-4]
call linked_list_append
add esp, 8
push StS
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7d
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push WHILE
push St
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push DO
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push 0x7b
push dword [ebp-4]
call linked_list_append
add esp, 8
push StS
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7d
push dword [ebp-4]
call linked_list_append
add esp, 8
push WHILE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x28
push dword [ebp-4]
call linked_list_append
add esp, 8
push GenE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x29
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x3b
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push DO
push St
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push id
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push 0x3d
push dword [ebp-4]
call linked_list_append
add esp, 8
push GenE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x3b
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push St
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push FUNCNAME
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push 0x28
push dword [ebp-4]
call linked_list_append
add esp, 8
push ArgS
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x29
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x3b
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push FUNCNAME
push St
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push ASM
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push 0x28
push dword [ebp-4]
call linked_list_append
add esp, 8
push STRLIT
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x29
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x3b
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push ASM
push St
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_MatchedElse:
push ebp
mov ebp, esp
sub esp, 4
push 0
push ELSE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push 0x7b
push dword [ebp-4]
call linked_list_append
add esp, 8
push StS
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x7d
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push ELSE
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NAME
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x7d
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push ASM
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push DO
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push FUNCNAME
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push IF
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push WHILE
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push RETURN
push MatchedElse
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_GenE:
push ebp
mov ebp, esp
sub esp, 4
push 0
push FUNCNAME
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push 0x28
push dword [ebp-4]
call linked_list_append
add esp, 8
push ArgS
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x29
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push FUNCNAME
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push JointE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push NAME
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2a
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2d
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push NUM
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x26
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FALSE
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push SHORT
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TRUE
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x28
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x21
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push STRLIT
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push STRLIT
push GenE
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_Arg:
push ebp
mov ebp, esp
sub esp, 4
push 0
push GenE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push NAME
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2a
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2d
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push NUM
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push STRLIT
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x26
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FALSE
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push SHORT
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TRUE
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FUNCNAME
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x28
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x21
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push Arg
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_ArgS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push Arg
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RArgS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2a
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2d
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push NUM
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push STRLIT
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x26
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FALSE
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push SHORT
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TRUE
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FUNCNAME
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x28
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x21
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push ArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_RArgS:
push ebp
mov ebp, esp
sub esp, 4
push 0
push 0x2c
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push Arg
push dword [ebp-4]
call linked_list_append
add esp, 8
push RArgS
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2c
push RArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push RArgS
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_id:
push ebp
mov ebp, esp
sub esp, 4
push 0
push NAME
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push Rid
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push id
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_Rid:
push ebp
mov ebp, esp
sub esp, 4
push 0
push idSel
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push Rid
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2e
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x5b
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2c
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push GE
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2f
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push AND_OP
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2a
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2d
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2b
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NE
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x3d
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push GT
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push LT
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x5d
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x3b
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push LE
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push OR_OP
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push EQ
push Rid
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_idSel:
push ebp
mov ebp, esp
sub esp, 4
push 0
push 0x2e
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push NAME
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2e
push idSel
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push 0x5b
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push GenE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x5d
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x5b
push idSel
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_E:
push ebp
mov ebp, esp
sub esp, 4
push 0
push T
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RE
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2a
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2d
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push NUM
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x26
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FALSE
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push SHORT
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TRUE
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x28
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x21
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push E
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_RE:
push ebp
mov ebp, esp
sub esp, 4
push 0
push 0x2b
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push T
push dword [ebp-4]
call linked_list_append
add esp, 8
push RE
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2b
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push 0x2d
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push T
push dword [ebp-4]
call linked_list_append
add esp, 8
push RE
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2d
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2c
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push GE
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push AND_OP
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NE
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push GT
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push LT
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x5d
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x3b
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push LE
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push OR_OP
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push EQ
push RE
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_T:
push ebp
mov ebp, esp
sub esp, 4
push 0
push F
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RT
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push SHORT
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TRUE
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2a
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2d
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x28
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push NUM
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x26
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x21
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FALSE
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push T
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_RT:
push ebp
mov ebp, esp
sub esp, 4
push 0
push 0x2a
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push F
push dword [ebp-4]
call linked_list_append
add esp, 8
push RT
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2a
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push 0x2f
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push F
push dword [ebp-4]
call linked_list_append
add esp, 8
push RT
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2f
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2c
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push GE
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push AND_OP
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2d
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2b
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push NE
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push GT
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push LT
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x5d
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x3b
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push LE
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push OR_OP
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push EQ
push RT
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_F:
push ebp
mov ebp, esp
sub esp, 4
push 0
push id
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push NAME
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push 0x2d
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push F
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2d
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push 0x21
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push F
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x21
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push 0x2a
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push F
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x2a
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push 0x26
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push F
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x26
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push Ty
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push PDeco
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x21
push dword [ebp-4]
call linked_list_append
add esp, 8
push F
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push SHORT
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push 0x28
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RelE
push dword [ebp-4]
call linked_list_append
add esp, 8
push 0x29
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push 0x28
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push NUM
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push NUM
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push TRUE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push TRUE
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push FALSE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push FALSE
push F
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_RelE:
push ebp
mov ebp, esp
sub esp, 4
push 0
push E
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RRelE
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2a
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2d
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push NUM
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x26
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FALSE
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push SHORT
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TRUE
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x28
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x21
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push RelE
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_RRelE:
push ebp
mov ebp, esp
sub esp, 4
push 0
push RelOp
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push E
push dword [ebp-4]
call linked_list_append
add esp, 8
push RRelE
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push GT
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push LE
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push LT
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push GE
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push NE
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push EQ
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2c
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x5d
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push AND_OP
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x3b
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push OR_OP
push RRelE
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_RelOp:
push ebp
mov ebp, esp
sub esp, 4
push 0
push GT
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push GT
push RelOp
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push GE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push GE
push RelOp
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push LT
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push LT
push RelOp
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push LE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push LE
push RelOp
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push EQ
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push EQ
push RelOp
push dword [ebp+8]
call jump_table_init
add esp, 16
push 0
push NE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push dword [ebp-4]
push NE
push RelOp
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_JointE:
push ebp
mov ebp, esp
sub esp, 4
push 0
push RelE
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push Union
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push NAME
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push INT
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2a
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x2d
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push BOOL
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push NUM
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x26
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push FALSE
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push SHORT
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TRUE
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push CHAR
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UINT
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push UCHAR
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x28
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push USHORT
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push 0x21
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push TYNAME
push JointE
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_Union:
push ebp
mov ebp, esp
sub esp, 4
push 0
push Intersect
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push UnionT
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push AND_OP
push Union
push dword [ebp+8]
call jump_table_init
add esp, 16
push dword [ebp-4]
push OR_OP
push Union
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push Union
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2c
push Union
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x5d
push Union
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x3b
push Union
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_UnionT:
push ebp
mov ebp, esp
sub esp, 4
push 0
push OR_OP
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RelE
push dword [ebp-4]
call linked_list_append
add esp, 8
push Intersect
push dword [ebp-4]
call linked_list_append
add esp, 8
push UnionT
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push OR_OP
push UnionT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push UnionT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2c
push UnionT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x5d
push UnionT
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x3b
push UnionT
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret
init_Intersect:
push ebp
mov ebp, esp
sub esp, 4
push 0
push AND_OP
call get_linked_list
add esp, 8
mov dword [ebp-4], eax
push RelE
push dword [ebp-4]
call linked_list_append
add esp, 8
push Intersect
push dword [ebp-4]
call linked_list_append
add esp, 8
push dword [ebp-4]
push AND_OP
push Intersect
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x29
push Intersect
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x2c
push Intersect
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x5d
push Intersect
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push 0x3b
push Intersect
push dword [ebp+8]
call jump_table_init
add esp, 16
push EPSILON
push OR_OP
push Intersect
push dword [ebp+8]
call jump_table_init
add esp, 16
leave
ret

; prints the supplied error message and cached line on which the error is expected from lexer_state
print_error:
push ebp 
mov ebp, esp 
push dword [ebp + 8]
call print_string
add esp, 4
push error_tail
call print_string
add esp, 4
mov eax, dword [lexer_state_ptr]
mov eax, dword [eax + 16]
mov eax, dword [eax]
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

print_stack:
push ebp 
mov ebp, esp 
.loop:
mov eax, dword [ebp + 8]
cmp dword [eax], EOF 
je .exit 
mov edx, eax 
add edx, 4 
mov dword [ebp + 8], edx 
push 10 
push itoa_buffer
push dword [eax]
call itoa
add esp, 4 
push itoa_buffer
call print_string
add esp, 4
push space
call print_string
add esp, 4
jmp .loop
.exit:
push nl 
call print_string
add esp, 4
leave
ret 

; void stack_push(Node* stack, auto item)
stack_push:
push ebp 
mov ebp, esp 
mov eax, dword [ebp + 8]
push dword [eax]
push dword [ebp + 12]
call get_linked_list
mov edx, dword [ebp + 8]
mov dword [edx], eax
add esp, 8
leave 
ret 

; Node stack_pop(Node* stack)
stack_pop:
push ebp 
mov ebp, esp 
sub esp, 8
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax 
cmp dword [eax], 0
je .exit 
mov eax, dword [eax]
mov edx, dword [eax + 4]
mov eax, dword [eax]
mov dword [ebp - 8], eax 
mov eax, dword [ebp - 4]
mov dword [eax], edx 
mov eax, dword [ebp - 8]
leave 
ret
.exit:
xor eax, eax 
leave
ret 

; Tree_Node get_node(int tag, int child_count)
; STRUCTURE : Tree_Node <int tag, token* token, int child_count, Tree_Node* children, void* inh, void* val>
get_node:
push ebp 
mov ebp, esp 
sub esp, 4
mov eax, dword [ebp + 12]
shl eax, 2
add eax, 20
push eax 
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax 
mov edx, dword [ebp + 8]
mov dword [eax], edx
mov dword [eax + 4], 0
mov edx, dword [ebp + 12]
mov dword [eax + 8], edx
push dword [ebp + 12]
mov eax, dword [ebp - 4]
lea eax, dword [eax + 12]
push eax 
call array_sanitize
add esp, 8
mov eax, dword [ebp - 4]
mov edx, dword [ebp + 12]
mov dword [eax + 12 + edx * 4 + 4], 0    ; zero out inh 
mov dword [eax + 12 + edx * 4 + 8], 0    ; zero out val
mov eax, dword [ebp - 4]
leave
ret 

; Tree_Node get_leaf(int tag, token* token)
get_leaf:
push ebp 
mov ebp, esp 
push 1
push dword [ebp + 8]
call get_node 
add esp, 8
mov edx, dword [ebp + 12]
mov dword [eax + 4], edx 
mov dword [eax + 8], 0
leave
ret 

; void print_tree(Tree_Node node, char* word_map)
print_tree:
push ebp 
mov ebp, esp 
sub esp, 20
cmp dword [ebp + 8], 0
je .exit
mov eax, dword [ebp + 8]
mov edx, dword [eax]
mov dword [ebp - 4], edx 
mov edx, dword [eax + 8]
mov dword [ebp - 8], edx 
lea edx, dword [eax + 12]
mov dword [ebp - 12], edx
mov edx, dword [eax + 4]
mov dword [ebp - 20], edx 
mov eax, dword [ebp - 4]
mov dword [ebp - 16], 0
cmp dword [ebp - 8], 0
je .leaf
push dword [ebp + 12]
push dword [ebp - 4]
call tag_to_str
add esp, 8
push eax 
call print_string
add esp, 4
push right_arrow
call print_string
add esp, 4

.loop1:
mov ecx, dword [ebp - 16]
cmp dword [ebp - 8], ecx 
je .reset
mov eax, dword [ebp - 12]
mov eax, dword [eax + ecx * 4]
cmp eax, 0
je .skip
push dword [ebp + 12]
push dword [eax]
call tag_to_str
add esp, 8
push eax 
call print_string
add esp, 4
push space 
call print_string
add esp, 4
.skip:
inc dword [ebp - 16]
jmp .loop1
.reset:
mov dword [ebp - 16], 0
push nl 
call print_string
add esp, 4
.loop2:
mov ecx, dword [ebp - 16]
cmp dword [ebp - 8], ecx 
je .exit
push dword [ebp + 12]
mov eax, dword [ebp - 12]
push dword [eax + ecx * 4]
call print_tree
add esp, 8
inc dword [ebp - 16]
jmp .loop2
.leaf:
cmp dword [ebp - 20], 0
je .exit
mov eax, dword [ebp - 4]
push dword [ebp + 12]
push eax 
call tag_to_str
add esp, 8
push eax 
call print_string
add esp, 4
push right_arrow
call print_string
add esp, 4
mov eax, dword [ebp - 20]
cmp dword [eax], NUM 
je .print_num
; print string
push dword [eax + 4]
call print_string
add esp, 4
push nl 
call print_string
add esp, 4
jmp .exit 
.print_num:
push 10 
push itoa_buffer
push dword [eax + 4]
call itoa 
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push nl
call print_string
add esp, 4
.exit:
leave
ret 

; char* tag_to_str(int tag, char* word_map)
tag_to_str:
push ebp 
mov ebp, esp
cmp dword [ebp + 8], NAME 
jl .ret_char
cmp dword [ebp + 8], FALSE
jl .ret_num

.ret_nonterminal:
mov eax, dword [ebp + 12]
mov edx, dword [ebp + 8]
mov eax, dword [eax + (edx - TYNAME) * 4]
jmp .exit

.ret_char:
push 4
call heap_alloc
add esp, 4
mov edx, dword [ebp + 8]
mov dword [eax], edx 
jmp .exit 

.ret_num:
push 10
push itoa_buffer
push dword [ebp + 8]
call itoa 
add esp, 12
mov eax, itoa_buffer
jmp .exit 

.exit:
leave
ret 



TYNAME_k: db 'TyNa', 0
FUNCNAME_k: db 'FuncNa', 0
prog_k: db 'prog', 0 
TyDS_k: db 'TyDS', 0
VaDS_k: db 'VaDS', 0
FuDS_k: db 'FuDS', 0
TyD_k: db 'TyD', 0
TE_k: db 'TE', 0
Ty_k: db 'Ty', 0
TyDeco_k: db 'TyDeco', 0
VaD_k: db 'VaD', 0
FuD_k: db 'FuD', 0
RFuDS_k: db 'RFuDS', 0
PaDS_k: db 'PaDS', 0
PaD_k: db 'PaD', 0
RPaDS_k: db 'RPaDS', 0
body_k: db 'body', 0
StS_k: db 'StS', 0
rSt_k: db 'rSt', 0
St_k: db 'St', 0
GenE_k: db 'GenE', 0
ArgS_k: db 'ArgS', 0
MatchedElse_k: db 'MatchedElse', 0
ID_k: db 'id', 0
Rid_k: db 'Rid', 0
idSel_k: db 'idSel', 0
E_k: db 'E', 0
T_k: db 'T', 0
RE_k: db 'RE', 0
F_k: db 'F', 0
RT_k: db 'RT', 0
JointE_k: db 'JointE', 0
RRelE_k: db 'RRelE', 0
RelOp_k: db 'RelOp', 0
Union_k: db 'Union', 0
UnionT_k: db 'UnionT', 0
Intersect_k: db 'Intersect', 0
RelE_k: db 'RelE', 0
Arg_k: db 'Arg', 0
RArgS_k: db 'RArgS', 0
PaDTyDeco_k: db 'PaDTyDeco', 0
PDeco_k: db 'PDeco', 0
ArrDeco_k: db 'ArrDeco', 0
PaDArrDeco_k: db 'PaDArrDeco', 0


error_general: db 'ERROR: syntax error', 10, 0
error_no_typedef: db 'ERROR: expected "typedef"', 0
error_undefined_type: db 'ERROR: undefined type', 0
error_illegal_decorator: db 'ERROR: illegal decorator, expected "[E]", "*"', 0
error_missing_semicolon: db 'ERROR: expected semicolon at the end of statement', 0
error_illegal_type_name: db 'ERROR: illegal type name', 0
error_unexpected_eof: db "ERROR: unexpected EOF reached while parsing", 10, 0
error_tail: db ' at line ', 0
finish: db 'Finished parsing', 10, 0
error_line: db 'Error on line: ', 0
right_arrow: db ' -> ', 0