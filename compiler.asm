[bits 32]
; TAGS
%define EPSILON -1
%define EOF 0
%define NAME  256
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
    ; table* table_ptr
    ; int* line
    ; bool* type_detect
;}
compiler_compile:
push ebp 
mov ebp, esp 
sub esp, 44                                 ; allocate space for the struct
sub esp, 2400                               ; allocate space for the symbol table
mov dword [ebp - 44], 0                     ; func_detect
mov dword [ebp - 40], 0                     ; type_detect
mov dword [ebp - 36], 1                     ; line_counter
mov dword [ebp - 32], 0                     ; char_counter
mov dword [ebp - 28], source_code_start     ; source buffer
lea eax, dword [ebp - 32]
mov dword [ebp - 24], eax                   ; load lexer_state pointer
push 0
call get_string_builder
add esp, 4
mov dword [ebp - 20], eax                   ; string_builder_ptr
lea eax, dword [ebp - 2444]                 
mov dword [ebp - 16], eax                   ; store symbol_table_ptr
lea eax, dword [ebp - 36]
mov dword [ebp - 12], eax                   ; load line pointer
lea eax, dword [ebp - 40]                   
mov dword [ebp - 8], eax                    ; load type_detect
lea eax, dword [ebp - 44]
mov dword [ebp - 4], eax                    ; load func_detect
push 600
push dword [ebp - 16] 
call array_sanitize                  ; clear all entries
add esp, 8
; init table with reserved keywords
push INTEGER
push integer_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push UINTEGER
push uinteger_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push BOOL
push bool_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push CHAR
push char_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push TYPEDEF
push typedef_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push IF
push if_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push ELSE
push else_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push WHILE
push while_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push DO
push do_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push STRUCT
push struct_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push RETURN 
push return_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push FUNC 
push func_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push TRUE 
push true_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12
push FALSE 
push false_k
push dword [ebp - 16]
call symbol_table_init
add esp, 12

; mov dword [destination_addr], 0
; .loop:
; cmp dword [destination_addr], 600
; je .exit 
; mov eax, dword [ebp - 8]
; mov edx, dword [destination_addr]
; mov eax, dword [eax + edx * 4]
; cmp eax, 0 
; je .no_item
; push eax 
; call print_linked_list
; push nl
; call print_string
; .no_item:
; inc dword [destination_addr]
; jmp .loop
; .exit:

lea eax, dword [ebp - 28]
push eax
call parser_parse
add esp, 4

leave 
ret


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