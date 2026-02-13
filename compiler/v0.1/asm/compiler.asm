[bits 32]
; TAGS
%define EPSILON -1
%define EOF 0
%define NAME 256
%define NUM 257
%define TYPEDEF 258
%define LT 259
%define LE 260
%define GT 261
%define GE 262
%define EQ 263
%define NE 264
%define AND_OP 265
%define OR_OP 266
%define IF 267
%define ELSE 268
%define WHILE 269
%define DO 270
%define STRUCT 271
%define RETURN 272
%define FUNC 273
%define TYNAME 274
%define FUNCNAME 275
%define TRUE 276
%define FALSE 277
%define STRLIT 278
%define UNTERMINATEDLIT 279
; define signed types smallest to largest
%define CHAR 280
%define SHORT 281
%define INT 282
; define unsigned types smallest to largest and bool
%define UCHAR 283
%define USHORT 284
%define UINT 285
%define BOOL 286
%define ASM 287
%define ELIF 288

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
%define id 322
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

; INCLUDES
%include "io.asm"
%include "utils.asm"
%include "lexer.asm"
%include "parser.asm"
%include "analyzer.asm"
%include "generator.asm"
; %include "parser copy.asm"
; %include "analyzer copy.asm"
; %include "generator copy.asm"
; colon_k: db ":", 0
; comma_k: db ",", 0
; label_k: db ".L", 0


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
; [ebp - 68], [ebp - 72] = misc
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
push ELIF
push elif_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push ASM
push asm_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push CHAR
push char_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push SHORT
push short_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push INT
push integer_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push UCHAR
push uchar_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push USHORT
push ushort_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push UINT
push uinteger_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push BOOL
push bool_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push TYPEDEF
push typedef_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push IF
push if_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push ELSE
push else_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push WHILE
push while_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push DO
push do_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push STRUCT
push struct_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push RETURN 
push return_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push FUNC 
push func_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push TRUE 
push true_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12
push FALSE 
push false_k
push dword [ebp - 52]
call symbol_table_init
add esp, 12

; init type table with primitives
push 1
push CHAR
push char_k
push dword [ebp - 56]
call type_table_init
add esp, 16

push 2
push SHORT
push short_k
push dword [ebp - 56]
call type_table_init
add esp, 16

push 4
push INT
push integer_k
push dword [ebp - 56]
call type_table_init
add esp, 16

push 1
push UCHAR
push uchar_k
push dword [ebp - 56]
call type_table_init
add esp, 16

push 2
push USHORT
push ushort_k
push dword [ebp - 56]
call type_table_init
add esp, 16

push 4
push UINT
push uinteger_k
push dword [ebp - 56]
call type_table_init
add esp, 16
push 1
push BOOL
push bool_k
push dword [ebp - 56]
call type_table_init
add esp, 16

lea eax, dword [ebp - 28]
push eax
call parser_parse
add esp, 4
mov dword [ebp - 48], eax 
cmp dword [ebp - 48], 0
je .exit

push dword [ebp - 64]       ; func_table
push dword [ebp - 60]       ; var_table
push dword [ebp - 56]       ; type_table
push dword [ebp - 48]       ; parse_tree root
call analyzer
add esp, 16
cmp eax, 0                  ; semantic error detected
je .exit

; start code_gen
push dword [ebp - 56]
push dword [ebp - 64]
push dword [ebp - 60]
push dword [ebp - 48]
call generator
add esp, 16

.exit:
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
; void type_table_init(hash_map* type_table, char* key, int type, uint size)
type_table_init:
push ebp
mov ebp, esp
push dword [ebp + 20] 
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

; returns a token_ptr into eax, with initialized values 
; STRUCTURE : num token => <tag, val>, basic token => <tag, null_ptr>, id token => <tag, hash_map_ptr>
; token* get_token(int tag, auto value)
get_token:
push ebp
mov ebp, esp
sub esp, 4
push 8
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax 
mov edx, dword [ebp + 8]
mov eax, dword [ebp - 4]
mov dword [eax], edx 
mov edx, dword [ebp + 12]
mov dword [eax + 4], edx 
leave
ret 

; void print_token(token* token_ptr)
print_token:
push ebp
mov ebp, esp
sub esp, 4
push left_caret
call print_string
add esp, 4
mov eax, dword [ebp + 8]
mov dword [ebp - 4], eax    ; save the tag
push 10
push itoa_buffer
push dword [eax]
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push comma_sep
call print_string
add esp, 4
mov eax, dword [ebp + 8]
cmp dword [ebp - 4], NAME 
je .print_addr
push 10 
jmp .print_int
.print_addr:
push 16
.print_int:
push itoa_buffer
push dword [eax + 4]
call itoa 
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push right_caret
call print_string
add esp, 4
leave
ret


left_caret: db '<', 0
right_caret: db '>', 0

parsing_done: db "PARSING SUCCESSFULL", 10, 0
int_t: db "int_t", 0
int_p: db "int_p", 0
pairs_t: db "pairs_t", 0
pointer_k: db "pointer", 0
my_var: db "my_var", 0

; reserved words
elif_k: db "elif", 0
asm_k: db "asm", 0
uchar_k: db "uchar", 0
ushort_k: db "ushort", 0
uinteger_k: db "uint", 0 
char_k: db "char", 0
short_k: db "short", 0
integer_k: db "int", 0
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
EOF_k: db "EOF", 0
int_t_k: db "int_t", 0
int_arr_k: db "int_arr", 0
struct_test: db "SLL", 0
test_str: db "str", 0
test_str_a: db "a", 0
test_str_b: db "b", 0
test_str_c: db "c", 0
test_str_d: db "d", 0
equals: db "=", 0
lt_op: db "<", 0
le_op: db "<=", 0
gt_op: db ">", 0
ge_op: db ">=", 0
eq_op: db "==", 0
ne_op: db "!=", 0
or_op: db "||", 0
and_op: db "&&", 0
left_parenthesis: db "(", 0
right_parenthesis: db ")", 0
