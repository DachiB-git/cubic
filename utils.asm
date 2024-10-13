; the symbol table
; implements a basic hash map interface with FNV32_1 hashing algorithm 
; with separate chaining

; puts the key, val pair into the symbol table
; EAX - symbol_table_ptr
; EBX - key
; ECX - val
symbol_table_put_entry:

; retrieves the value for the supplied key from the symbol_table if present, 
; otherwise returns null
; RETURN : EAX - value
; EBX - symbol_table_ptr
; ECX - key
symbol_table_get_entry:


; returns a linked_list node pointer into EAX, with optional initial values
; STRUCTURE : Node <val, next_ptr>
; EBX - val
; ECX - next_ptr
get_linked_list:
PUSH EDX 
PUSH EBX
MOV EBX, 8
CALL heap_alloc
MOV EDX, EAX 
POP EBX
MOV DWORD [EDX], EBX 
ADD EDX, 4
MOV DWORD [EDX], ECX  
POP EDX 
RET 

; appends value in EAX to a linked list pointer in EBX 
linked_list_append:
PUSH EBX 
PUSH EAX 
.loop:
ADD EBX, 4
MOV EDX, EBX 
MOV DWORD EDX, [EDX]
CMP EDX, 0x00 
JE .tail_found
MOV DWORD EDX, [EDX]
MOV EBX, EDX
JMP .loop
.tail_found:
CALL get_linked_list
MOV EDX, EAX 
MOV DWORD [EBX], EDX 
POP EAX 
MOV DWORD [EDX], EAX 
POP EBX 
RET 

; prints linked_list elements 
; EAX - linked_list pointer 
; EBX - buffer_ptr
print_linked_list:
PUSH EAX 
PUSH EBX
PUSH EDX
MOV ESI, left_bracket
CALL print_string
CMP EAX, 0x00 
JE .end
.loop:
MOV DWORD ECX, [EAX]
CALL int_to_string_base_10
MOV ESI, EBX 
CALL print_string
ADD EAX, 4
MOV DWORD EAX, [EAX]
CMP EAX, 0x00 
JE .end 
MOV ESI, comma_sep
CALL print_string
JMP .loop
.end:
MOV ESI, right_bracket
CALL print_string
POP EDX
POP EBX 
POP EAX 
RET 

left_bracket: db '[', 0
right_bracket: db ']', 0
comma_sep: db ',', 0

; returns a token_ptr into EAX, with initialized values 
; STRUCTURE : Num Token => <tag, val>, Basic Token => <tag, null_ptr>, Id Token => <tag, symbol_table_ptr>
; EBX - token tag
; ECX - optional second argument, could be null | nullptr
get_token:
PUSH EDX 
PUSH EBX 
MOV EBX, 8
CALL heap_alloc
POP EBX
MOV EDX, EAX 
MOV DWORD [EDX], EBX 
ADD EDX, 4
MOV DWORD [EDX], ECX
POP EDX
RET

; returns a string_builder_ptr into EAX
get_string_builder:
PUSH EBX 
MOV EBX, 5
CALL heap_alloc
MOV EBX, EAX
MOV BYTE [EBX], 0x00
INC EBX 
MOV DWORD [EBX], 0x00 
POP EBX 
RET

; appends the char in AL to builder_ptr in EBX
string_builder_append:
PUSHF
PUSH EBX 
PUSH ECX 
PUSH EDX
; EAX - char to append
; EBX - base builder_ptr
; ECX - string_builder_size pointer
.check_head: 
CLC 
MOV EDX, EBX 
MOV BYTE BL, [EBX]
CMP BL, 0x00 
JNE .load_next_node
MOV BYTE [EDX], AL 
JMP .end
.load_next_node:
CLC 
MOV EBX, EDX
INC EBX,
MOV DWORD EBX, [EBX]
CMP EBX, 0x00 
JNE .check_head
PUSH EAX 
CALL get_string_builder
INC EDX
MOV DWORD [EDX], EAX
MOV EDX, EAX
POP EAX
MOV BYTE [EDX], AL 
.end:
INC DWORD [ECX]
POP EDX
POP ECX
POP EBX 
POPF
RET

; emptyes all nodes of the builter_ptr in EBX
; builder_size_value pointer in ECX
; preserving the allocated memory for new use
; space and time complexity of O(n), where n is the max(len(s)) of all strings in source
; lmao deffo need a better heap implementation 
string_builder_clear:
PUSHF
PUSH EBX
PUSH ECX
PUSH EDX
.check_head: 
MOV EDX, EBX 
MOV BYTE BL, [EBX]
CMP BL, 0x00 
JE .load_next_node
MOV BYTE [EDX], 0x00            ; zero the char 
DEC DWORD [ECX]                 ; size--
.load_next_node:
MOV EBX, EDX
INC EBX,
MOV DWORD EBX, [EBX]
CMP EBX, 0x00 
JNE .check_head
.end:
POP EDX
POP ECX 
POP EBX
POPF
RET

; returns a pointer to the constructed string into EAX
; input: string_builder_ptr in EBX, size in ECX 
string_builder_to_string:
PUSHF
CMP ECX, 0              ; check if size > 0
JNE .not_zero
MOV EAX, 0x00           ; return null pointer
POPF
RET
.not_zero:
PUSH EBX
PUSH ECX
PUSH EDX
PUSH EBX
MOV EBX, ECX 
INC EBX                 ; alloc size + 1 for null termination
CALL heap_alloc
POP EBX
MOV EDX, EAX 
PUSH EAX
XOR EAX, EAX
.loop:
CMP EAX, ECX 
JE .end       
; node -> char, next -> node -> char, next -> 
; new_str_base[0] = node0.char, new_str_base[1] = node1.char, ...
PUSH EBX 
MOV BYTE BL, [EBX]
MOV BYTE [EDX], BL
POP EBX 
INC EBX 
MOV DWORD EBX, [EBX]
INC EDX  
INC EAX 
JMP .loop
.end:
MOV BYTE [EDX], 0x00    ; add null terminator
POP EAX
POP EDX 
POP ECX 
POP EBX
POPF
RET

; converts the given integer value into a null terminated string
; and stores into the buffer location
; EBX - string buffer addr
; ECX - value to be converted 
int_to_string_base_10:
PUSHF
PUSH EAX
PUSH ECX
PUSH EDX
PUSH EBX
MOV EDI, EBX
MOV EAX, ECX
MOV EBX, 10 
.loop:
CMP EAX, 0x00 
JE .exit_loop
CDQ 
IDIV EBX
; remainder in EDX
PUSH EAX 
MOV EAX, EDX
ADD EAX, 0x30           ; convert to ASCII
STOSB
POP EAX 
; quotient in EAX 
JMP .loop
.exit_loop:
MOV BYTE [EDI], 0x00    ; add null terminator
; reverse the string
DEC DWORD EDI           ; pointer--
POP EBX 
PUSH EBX 
STD         ; set DF to decrement EDI
.rev_loop:
CMP EBX, EDI 
JG .exit_rev_loop
MOV BYTE DL, [EBX]    ; temp = buffer[bp]
MOV BYTE DH, [EDI]
MOV BYTE [EBX], DH 
MOV BYTE [EDI], DL 
DEC DWORD EDI 
INC DWORd EBX 
JMP .rev_loop
.exit_rev_loop:
POP EBX
POP EDX 
POP ECX
POP EAX
POPF
RET 