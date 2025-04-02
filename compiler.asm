[bits 32]
; TAGS
%define EPSILON -1
%define EOF 0
%define NAME 256
%define NUM 257
%define INTEGER 258
%define UINTEGER 259
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
%define IF 271
%define ELSE 272
%define WHILE 273
%define DO 274
%define STRUCT 275
%define RETURN 276
%define FUNC 277
%define TYNAME 278
%define FUNCNAME 279
%define TRUE 280
%define FALSE 281

%define prog 300 
%define TyDS 301
%define VaDS 302
%define FuDS 303
%define TyD 304 
%define TE 305
%define Ty 306
%define TyDeco 307
%define VaD 308
%define FuD 310
%define RFuDS 311
%define PaDS 312
%define PaD 313
%define RPaDS 314
%define body 315
%define StS 316 
%define rSt 317
%define St 318
%define GenE 319
%define ArgS 320 
%define MatchedElse 321
%define ID 322
%define Rid 323
%define idSel 324
%define E 325
%define T 326
%define RE 327
%define F 328 
%define RT 329
%define JointE 330
%define RRelE 331
%define RelOp 332
%define Union 333
%define UnionT 334
%define Intersect 335
%define RelE 336
%define Arg 337
%define RArgS 338
%define PaDTyDeco 339
%define PDeco 340
%define ArrDeco 341
%define PaDArrDeco 342

; CONSTANTS
%define destination_addr 0x4000_0000 

; VARIABLES
; buffer_ptr - [ebp - 4]
; pointer - [ebp - 8]
; string_builder_ptr - [ebp - 12]
; symbol_table_ptr - [ebp - 16]
; line - [ebp - 20]
; char_counter - [ebp - 28]
; line_counter  - [ebp - 32]
; type_detect - [ebp - 36]
; func_detect - [ebp - 40]
; compiles the source code at source_addr and stores it into memory

; struct lexer_state 
;{
    ; char* buffer_addr; 
    ; int* pointer;
    ; builder* str_builder_ptr
    ; hash_map* symbol_table
    ; int* line
    ; bool* type_detect
;}
compiler_compile:
push ebp 
mov ebp, esp 
sub esp, 72                                 
; [ebp - 4] - [ebp - 28] = lexer_state struct
; [ebp - 32] = char_counter ? this is probably a very bad idea
; [ebp - 36] = line_counter
; [ebp - 40] = type_detect
; [ebp - 44] = func_detect
; [ebp - 48] = parse_tree root
; [ebp - 52] = symbol_table
; [ebp - 56] = type_table
; [ebp - 60] = var_table
; [ebp - 64] = func_table
mov dword [ebp - 44], 0                     ; func_detect
mov dword [ebp - 40], 0                     ; type_detect
mov dword [ebp - 36], 1                     ; line_counter
mov dword [ebp - 32], 0                     ; char_counter
mov dword [ebp - 28], source_code_start     ; source buffer
lea eax, dword [ebp - 32]
mov dword [ebp - 24], eax                   ; load char_counter pointer
push 0
call get_string_builder
add esp, 4
mov dword [ebp - 20], eax                   ; string_builder_ptr
lea eax, dword [ebp - 36]
mov dword [ebp - 12], eax                   ; load line pointer
lea eax, dword [ebp - 40]                   
mov dword [ebp - 8], eax                    ; load type_detect
lea eax, dword [ebp - 44]
mov dword [ebp - 4], eax                    ; load func_detect

push 16
push 4
call get_hash_map
add esp, 8
mov dword [ebp - 52], eax

mov eax, dword [ebp - 52]                 
mov dword [ebp - 16], eax                   ; store symbol_table_ptr

push 16
push 4
call get_hash_map
add esp, 8
mov dword [ebp - 56], eax                   ; store type_table

push 16
push 4
call get_hash_map
add esp, 8
mov dword [ebp - 60], eax                   ; store var_table

push 16
push 4
call get_hash_map
add esp, 8
mov dword [ebp - 64], eax                   ; store func_table

; init table with reserved keywords
push INTEGER
push integer_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push UINTEGER
push uinteger_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push BOOL
push bool_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push CHAR
push char_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
; push TYPEDEF
; push typedef_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push IF
; push if_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push ELSE
; push else_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push WHILE
; push while_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push DO
; push do_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push STRUCT
; push struct_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push RETURN 
; push return_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push FUNC 
; push func_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push TRUE 
; push true_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12
; push FALSE 
; push false_k
; push dword [ebp - 52]
; call symbol_table_init
; add esp, 12

push TYNAME
push int_t
push dword [ebp - 52]
call symbol_table_init
add esp, 12


; push 0
; push 1
; call get_token
; add esp, 8
; push 0
; push eax 
; call get_linked_list
; add esp, 8
; mov dword [ebp - 72], eax 
; push 0
; push 2
; call get_token
; add esp, 8
; push eax
; push dword [ebp - 72]
; call linked_list_append
; add esp, 8

mov eax, dword [ebp - 52]
mov ecx, dword [eax + 4]
mov eax, dword [eax]
.loop:
cmp ecx, 0
je .exit 
dec ecx
mov dword [ebp - 68], eax
cmp dword [eax], 0
jne .print 
add eax, 4
jmp .loop
.print:
mov eax, dword [eax]
mov [ebp - 72], eax 
.l_loop:
mov eax, dword [ebp - 72]
cmp eax, 0
je .next
mov edx, dword [eax + 4]
mov dword [ebp - 72], edx
mov eax, dword [eax]
mov eax, dword [eax + 4]
push eax 
call print_token
add esp, 4
push space
call print_string
add esp, 4
jmp .l_loop
.next:
push nl 
call print_string
add esp, 4
mov eax, dword [ebp - 68]
add eax, 4
jmp .loop

; init type table with primitives
; push INTEGER
; push integer_k
; push dword [ebp - 56]
; call type_table_init
; add esp, 12
; push UINTEGER
; push uinteger_k
; push dword [ebp - 56]
; call type_table_init
; add esp, 12
; push CHAR
; push char_k
; push dword [ebp - 56]
; call type_table_init
; add esp, 12
; push BOOL
; push bool_k
; push dword [ebp - 56]
; call type_table_init
; add esp, 12


lea eax, dword [ebp - 28]
push eax
call parser_parse
add esp, 4
mov dword [ebp - 48], eax 
cmp dword [ebp - 48], 0
je .exit
; lea eax, dword [ebp - 44 - 4 - 2400 * 4]
; push eax 
; lea eax, dword [ebp - 44 - 4 - 2400 * 3]
; push eax 
; lea eax, dword [ebp - 44 - 4 - 2400 * 2]
; push eax 
; push dword [ebp - 48]
; call analyzer
; add esp, 16

.exit:
mov eax, 0x3000_0145
mov eax, dword [eax + 4]
mov eax, dword [eax]
mov eax, dword [eax + 4]
push eax 
call print_token
add esp, 4
push nl
call print_string
add esp, 4
; push 16
; push itoa_buffer
; push eax 
; call itoa
; add esp, 12
; push itoa_buffer
; call print_string
; add esp, 4
; push nl
; call print_string
; add esp, 4
; push eax 
; call print_linked_list
; add esp, 4
; push nl
; call print_string
; add esp, 4
; mov eax, 0x3000_019d
; mov eax, dword [eax + 4]
leave 
ret

; initializes class token into the symbol table
; void symbol_table_init(hash_map* table_ptr, char* key, int tag)
symbol_table_init:
push ebp 
mov ebp, esp 
push dword [ebp + 12]
push dword [ebp + 16] 
call get_token 
add esp, 8
push eax 
push dword [ebp + 12]
push dword [ebp + 8]
call hash_map_put
add esp, 12
leave
ret 

; initializes the primitive into the type table
; void type_table_init(hash_map* type_table, char* key, int type)
type_table_init:
push ebp
mov ebp, esp 
push dword [ebp + 16]
push dword [ebp + 12]
call get_primitive_entry
add esp, 8
push eax
push dword [ebp + 12]
push dword [ebp + 8]
call hash_map_put
add esp, 12
leave
ret 

leave
ret 

parsing_done: db "PARSING SUCCESSFULL", 10, 0
int_t: db "int_t", 0
int_p: db "int_p", 0
pairs_t: db "pairs_t", 0
pointer_k: db "pointer", 0

; reserved words
char_k: db "char", 0
integer_k: db "int", 0
uinteger_k: db "uint", 0 
if_k: db "if", 0
else_k: db "else", 0
do_k: db "do", 0
while_k: db "while", 0
typedef_k: db "typedef", 0
struct_k: db "struct", 0
return_k: db "return", 0
bool_k: db "bool", 0
func_k: db "func", 0
true_k: db "true", 0
false_k: db "false", 0
%include "io.asm"
%include "utils.asm"
%include "lexer.asm"
%include "parser.asm"
%include "analyzer.asm"