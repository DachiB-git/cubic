[bits 32]
%define itoa_buffer 0x1000_0064
; cursors positions
%define cursor_x_ptr 0x1000_0050
%define cursor_y_ptr 0x1000_005c
%define frame_buffer_ptr 0x000B_8000
; screen constants
%define vga_width 80
%define vga_height 25

; linked_list* get_linked_list(int val, linked_list* next);
; returns a linked_list node pointer into eax, with preset initial values
; STRUCTURE : node <val, next_ptr>
get_linked_list:
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

; appends value to the supplied list 
; void linked_list_append(linked_list* list_ptr, auto val)
linked_list_append:
push ebp
mov ebp, esp 
sub esp, 4
mov eax, dword [ebp + 8]        ; load list_ptr
.loop:
add eax, 4                      ; get to next_ptr
mov dword [ebp - 4], eax        ; save next_ptr addr
mov eax, dword [eax]            ; load next_ptr
cmp eax, 0 
je .tail_found
jmp .loop
.tail_found:
; vacant next_ptr in ebx
push 0 
push dword [ebp + 12]
call get_linked_list
add esp, 8
mov edx, eax 
mov eax, dword [ebp - 4]
mov dword [eax], edx  ; bind new tail node
leave
ret 

; returns a reversed copy of the original list 
; linked_list* linked_list_reverse(linked_list* list)
linked_list_reverse:
push ebp 
mov ebp, esp 
sub esp, 4
mov dword [ebp - 4], 0
.loop: 
cmp dword [ebp + 8], 0
je .exit
mov eax, dword [ebp + 8]
push dword [ebp - 4]
push dword [eax]            ; get val 
call get_linked_list
add esp, 8
mov dword [ebp - 4], eax    ; save last node
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov dword [ebp + 8], eax
jmp .loop
.exit:
mov eax, dword [ebp - 4]
leave
ret 

; linked_list* linked_list_get(linked_list* list, int index)
linked_list_get:
push ebp
mov ebp, esp
cmp dword [ebp + 8], 0
je .error_exit
cmp dword [ebp + 12], 0
jl .error_exit
.loop:
mov eax, dword [ebp + 8]
cmp eax, 0
je .error_exit
mov eax, dword [ebp + 12]
cmp eax, 0
je .exit
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov dword [ebp + 8], eax
dec dword [ebp + 12]
jmp .loop
.exit:
mov eax, dword [ebp + 8]
leave
ret

.error_exit:
xor eax, eax
leave
ret

; uint linked_list_size(linked_list* list)
linked_list_size:
push ebp
mov ebp, esp
sub esp, 4
mov dword [ebp - 4], 0  ; size counter
.loop:
cmp dword [ebp + 8], 0
je .exit
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov dword [ebp + 8], eax
inc dword [ebp - 4]
jmp .loop
.exit:
mov eax, dword [ebp - 4]
leave
ret

; prints linked_list elements 
print_linked_list:
push ebp 
mov ebp, esp 
cmp dword [ebp + 8], 0 
jne .not_null
leave 
ret
.not_null:
push left_bracket
call print_string
add esp, 4
.loop:
mov eax, dword [ebp + 8]
push 16
push itoa_buffer
push dword [eax] 
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov dword [ebp + 8], eax
cmp dword [ebp + 8], 0 
je .end 
push comma_sep
call print_string
add esp, 4
jmp .loop
.end:
push right_bracket
call print_string
add esp, 4
leave 
ret 

left_bracket: db '[', 0
right_bracket: db ']', 0
comma_sep: db ',', 0

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


; builder* get_string_builder()
get_string_builder:
push ebp
mov ebp, esp
sub esp, 4
push 5
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax 
mov dl, byte [ebp + 8]
mov eax, dword [ebp - 4]
mov byte [eax], dl   
; mov edx, dword [ebp + 12]
mov dword [eax + 1], 0x00
mov eax, dword [ebp - 4]
leave
ret 

; appends the char to builder_ptr and increments the size
; void string_builder_append(char c, builder* builder_ptr, int* size_ptr)
string_builder_append:
push ebp
mov ebp, esp 
.check_head:  
mov eax, dword [ebp + 12]
cmp byte [eax], 0
jne .load_next_node
mov dl, byte [ebp + 8]
mov byte [eax], dl
jmp .end
.load_next_node:
mov eax, dword [ebp + 12]
cmp dword [eax + 1], 0 
; jne .check_head
je .append 
mov eax, dword [eax + 1]
mov dword [ebp + 12], eax 
jmp .check_head
.append:
movsx eax, byte [ebp + 8]
; movsx eax, al
push eax 
call get_string_builder
add esp, 4
mov edx, dword [ebp + 12]
mov dword [edx + 1], eax
.end:
mov eax, dword [ebp + 16]
inc dword [eax]
leave
ret

; emptyes all nodes of the builter_ptr
; preserving the allocated memory for new use
; space and time complexity of o(n), where n is the max(len(s)) of all strings in source
; lmao deffo need a better heap implementation
; void string_builder_clear(builder* builder_ptr, int* size_ptr) 
string_builder_clear:
push ebp 
mov ebp, esp
.check_head: 
mov eax, dword [ebp + 8]
cmp byte [eax], 0x00 
je .load_next_node
mov eax, dword [ebp + 8]
mov byte [eax], 0x00            ; zero the char 
mov eax, dword [ebp + 12]       ; load size_ptr
dec dword [eax]                 ; size--
.load_next_node:
mov eax, dword [ebp + 8]
mov eax, dword [eax + 1]
mov dword [ebp + 8], eax
cmp eax, 0x00 
jne .check_head
.end:
leave
ret

; returns a pointer to the constructed string into eax
; char* string_builder_to_string(builder* builder_ptr, int size)
string_builder_to_string:
push ebp 
mov ebp, esp
sub esp, 4
cmp dword [ebp + 12], 0         ; check if size > 0
jne .not_zero
mov eax, 0                      ; return null pointer
leave
ret
.not_zero: 
mov eax, dword [ebp + 12]
inc eax 
push eax                        ; alloc size + 1 for null termination
call heap_alloc
add esp, 4
mov dword [ebp - 4], eax
mov ecx, 0
.loop:
cmp ecx, dword [ebp + 12] 
je .end       
; node -> char, next -> node -> char, next -> 
; new_str_base[0] = node0.char, new_str_base[1] = node1.char, ... 
mov eax, dword [ebp + 8]
mov dl, byte [eax]           ; load char
mov eax, dword [ebp - 4]
mov byte [eax + ecx], dl
mov eax, dword [ebp + 8]
mov eax, dword [eax + 1]
mov dword [ebp + 8], eax
inc ecx 
jmp .loop
.end:
mov eax, dword [ebp - 4]
mov byte [eax + ecx], 0    ; add null terminator
leave
ret

; converts the given integer value into a null terminated string
; and stores into the buffer location
; void itoa(int value, char* str, int base) 
itoa:
push ebp
mov ebp, esp
sub esp, 4
push edi 
mov edi, dword [ebp + 12]
mov dword [ebp - 4], edi 
; if (base < 2 || base > 36) return null
cmp dword [ebp + 16], 2
jl .exit 
cmp dword [ebp + 16], 36 
jg .exit
; if (value < 0 && base == 10) add '-'
cmp dword [ebp + 8], 0
jns .loop 
cmp dword [ebp + 16], 10
jne .loop
mov byte [edi], '-'
inc edi 
; update offset
mov dword [ebp - 4], edi
.loop:
mov eax, dword [ebp + 8]
xor edx, edx
cdq 
idiv dword [ebp + 16]
; remainder in edx
mov dword [ebp + 8], eax 
mov eax, dword itoa_chars[35 + edx]
stosb
cmp dword [ebp + 8], 0      ; if value != 0 repeat 
je .exit_loop 
jmp .loop
.exit_loop:
mov byte [edi], 0           ; add null terminator
; reverse the string
dec dword edi               ; pointer--
mov eax, dword [ebp - 4]
.rev_loop:
cmp eax, edi 
jg .exit_rev_loop
mov dl, byte [eax]          ; temp = buffer[bp]
mov dh, byte [edi]
mov byte [eax], dh 
mov byte [edi], dl 
dec dword edi 
inc dword eax 
jmp .rev_loop
.exit_rev_loop:
pop edi 
leave 
ret 
.exit:
mov byte [edi], 0
pop edi 
leave
ret 

itoa_chars: db "zyxwvutsrqponmlkjihgfedcba9876543210123456789abcdefghijklmnopqrstuvwxyz", 0

; hashing constants
%define fnv_prime 0x0100_0193
%define fnv_offset_basis 0x811c_9dc5

; the input string must be null terminated
; returns a hashed value of the provided string in EAX
; int fnv32_1(char * str)
fnv32_1:
push ebp 
mov ebp, esp 
sub esp, 8
push esi
mov esi, dword [ebp + 8]
mov dword [ebp - 4], fnv_offset_basis
.hash_loop:
lodsb 
cmp al, 0
je .hash_end
mov byte [ebp - 8], al
mov eax, dword [ebp - 4]
mov edx, fnv_prime
mul edx
mov dword [ebp - 4], eax 
movsx eax, byte [ebp - 8]
xor dword [ebp - 4], eax
jmp .hash_loop
.hash_end:
mov eax, dword [ebp - 4]
pop esi 
leave
ret

; void string_copy(char* dest, char* src)
string_copy:
push ebp
mov ebp, esp
sub esp, 12
push edi
push esi
mov esi, dword [ebp + 12]
mov edi, dword [ebp + 8]
.loop:
cmp byte [esi], 0
je .exit
stosb
jmp .loop
.exit:
mov byte [edi], 0   ; add null terminator
pop esi
pop edi
leave
ret

; bool string_equals(char* a, char* b)
; check if two given strings are equal 
; for a = a1, a2, a3 and b = b1, b2, b3
; return true if a1 = b1, a2 = b2, a3 = b3
; both strings have to be null terminated
; RETURN: eax - boolean, true if equal else false
string_equals:
push ebp 
mov ebp, esp
.loop:
mov edx, dword [ebp + 8]      ; load char from a
movsx edx, byte [edx]
mov eax, dword [ebp + 12]
movsx eax, byte [eax]     ; load char from b
cmp eax, edx 
jnz .not_equal
cmp eax, 0               ; both chars are equal only in two cases
je .equal               ; if an = bn or an = bn = \0
inc dword [ebp + 8]     ; increment pointers
inc dword [ebp + 12]
jmp .loop               ; check next chars if nesessary
.equal:
mov eax, 1 
leave
ret 
.not_equal:
xor eax, eax 
leave
ret

; check if char is a digit
; returns 1 if true else 0 in al
is_a_digit:
push ebp 
mov ebp, esp 
cmp byte [ebp + 8], 0x30
js .not_a_digit
cmp byte [ebp + 8], 0x39
jg .not_a_digit
mov eax, 1
leave
ret
.not_a_digit:
mov eax, 0
leave
ret
; check if char in peek is a letter c >= 'A' && c <= 'z' || c >= 'a' && c <= 'z' || c == '_'
; returns 1 if true else 0 in al
is_a_letter:
push ebp 
mov ebp, esp 
cmp byte [ebp + 8], 0x41   ; 'A'
jl .check_lower 
cmp byte [ebp + 8], 0x5A   ; 'Z'
jg .check_lower 
mov eax, 1
jmp .exit
.check_lower:
cmp byte [ebp + 8], 0x61   ; 'a'
jl .check_underscore
cmp byte [ebp + 8], 0x7A   ; 'z'
jg .check_underscore
mov eax, 1
jmp .exit
.check_underscore:
cmp byte [ebp + 8], 0x5F   ; '_'
jnz .not_a_letter
mov eax, 1 
jmp .exit
.not_a_letter:
mov eax, 0
.exit:
leave
ret

; zeroes all entries for the supplied array
; void array_sanitize(auto arr[], int size)
array_sanitize:
push ebp 
mov ebp, esp 
push edi 
mov ecx, dword [ebp + 12] 
mov eax, 0
mov edi, dword [ebp + 8]
rep stosd
pop edi 
leave
ret

; the symbol table
; implements a basic hash map interface with fnv32_1 hashing algorithm 
; with separate chaining
; INVARIANT: returned value is a null_ptr iff the given key has appeared for the first time
; otherwise the returned value is a pointer to a linked list of all cohashed items on the index

; Doesn't currently implement a load factor setter since the optimum for separate chaining falls close to one
; (any official source on this would be nice)
; STRUCTURE: hash_map <(sizeof(value_size)*)[capacity] bucket, uint capacity, uint item_count, uint bucket_size_b> 
; hash_map* get_hash_map(uint value_size, uint initial_capacity)
get_hash_map:
push ebp
mov ebp, esp 
sub esp, 16
mov dword [ebp - 4], 1          ; size power of two
mov eax, dword [ebp + 8]
mov dword [ebp - 8], eax        ; bucket_size in bytes
mov dword [ebp - 12], 0         ; hash_map pointer
mov dword [ebp - 16], 0         ; bucket pointer
; calculate the bucket size
.size_calc:
mov eax, dword [ebp - 4]        ; load size
cmp eax, dword [ebp + 12]
jge .end_size_calc
shl eax, 1
mov dword [ebp - 4], eax
mov eax, dword [ebp - 8]
add eax, eax 
mov dword [ebp - 8], eax
jmp .size_calc
.end_size_calc:
; get empty hash_map*
push 16
call heap_alloc
add esp, 4
mov dword [ebp - 12], eax 
; alloc the bucket and clean it
push dword [ebp - 8]
call heap_alloc
add esp, 4
mov dword [ebp - 16], eax 
push dword [ebp - 4]
push dword [ebp - 16]
call array_sanitize
add esp, 8
mov eax, dword [ebp - 12]
mov edx, dword [ebp - 16]
mov dword [eax], edx 
mov edx, dword [ebp - 4]
mov dword [eax + 4], edx 
mov dword [eax + 8], 0
mov edx, dword [ebp - 8]
mov dword [eax + 12], edx
leave
ret 

; puts the key, val pair into the hash_map
; void hash_map_put(hash_map* table_ptr, char* key, auto val)
hash_map_put:
push ebp 
mov ebp, esp 
sub esp, 24
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov dword [ebp - 4], eax    ; load hash_map capacity
; [ebp - 4] = size
; [ebp - 8] = index 
; [ebp - 12] = list_node_ptr
; [ebp - 16] = table_entry_ptr 
; [ebp - 20] = bucket pointer
; [ebp - 24] = counter
; calculate index
push dword [ebp + 12]
call fnv32_1                ; get hash
add esp, 4
push eax 
push dword [ebp - 4]
call get_index
add esp, 8
shl eax, 2
mov dword [ebp - 8], eax

.load_list:
; load list_node_ptr at table[index]
mov eax, dword [ebp + 8]
mov eax, dword [eax]
add eax, dword [ebp - 8]
mov eax, dword [eax]
mov dword [ebp - 12], eax   ; save list_node_ptr
cmp dword [ebp - 12], 0
je .free_index 
.list_loop:
mov eax, dword [ebp - 12]   ; load current node
mov eax, dword [eax]        ; load list val, i.e. a table entry pointer
mov dword [ebp - 16], eax   ; save table_entry_ptr
mov eax, dword [eax]
push eax 
push dword [ebp + 12]
call string_equals
add esp, 8
cmp eax, 1 
je .entry_found
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]    ; load next_ptr
cmp eax, 0
je .resolve_collision
mov dword [ebp - 12], eax   ; save list_node_ptr
jmp .list_loop

.resolve_collision:
push dword [ebp + 16]
push dword [ebp + 12]
call get_entry
add esp, 8
push eax 
push dword [ebp - 12]
call linked_list_append
add esp, 8
leave 
ret 

.free_index:
push dword [ebp + 16]
push dword [ebp + 12]
call get_entry
add esp, 8
push 0
push eax
call get_linked_list
add esp, 8
mov edx, dword [ebp + 8]
mov edx, dword [edx]
add edx, dword [ebp - 8]
mov dword [edx], eax 
; update hash_map item count
mov eax, dword [ebp + 8]
inc dword [eax + 8]
; check for resize
mov edx, dword [ebp - 4]
cmp edx, dword [eax + 8]
jne .exit 
.resize:
mov eax, dword [ebp + 8]
mov eax, dword [eax]
mov dword [ebp - 20], eax   ; save old bucket baddr
mov eax, dword [ebp + 8]
shl dword [eax + 12], 1     ; double byte count
push dword [eax + 12]
call heap_alloc
add esp, 4
mov edx, dword [ebp + 8]
mov dword [edx], eax
mov eax, dword [ebp + 8]
shl dword [eax + 4], 1      ; double capacity
mov dword [eax + 8], 0      ; item_count = 0
; rehash old items into the new bucket
mov eax, dword [ebp - 4]
mov dword [ebp - 24], eax   ; load counter
.rehash_loop:
mov eax, dword [ebp - 20]
cmp dword [ebp - 24], 0
je .exit
dec dword [ebp - 24] 
cmp dword [eax], 0
je .get_next_addr
mov eax, dword [eax]
mov dword [ebp - 12], eax   ; load list_node
.rehash_list_loop:
mov eax, dword [ebp - 12]
cmp eax, 0
je .get_next_addr
mov eax, dword [eax]        ; load entry
push dword [eax + 4]
push dword [eax]
push dword [ebp + 8]
call hash_map_put
add esp, 12
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]
mov dword [ebp - 12], eax
jmp .rehash_list_loop
.get_next_addr:
mov eax, dword [ebp - 20]
add eax, 4
mov dword [ebp - 20], eax
jmp .rehash_loop
.exit:
leave
ret 

.entry_found:
; update the value of the entry
mov eax, dword [ebp - 16]
mov edx, dword [ebp + 16]
mov dword [eax + 4], edx 
leave 
ret

; retrieves the value (token_ptr) for the supplied key from the hash_map if present, 
; otherwise returns null
; token* hash_map_get(hash_map* table_ptr, char* key)
hash_map_get:
push ebp 
mov ebp, esp 
sub esp, 16                 ; reserve 16 bytes (4 pointer variables)
mov eax, dword [ebp + 8]
mov eax, dword [eax + 4]
mov dword [ebp - 4], eax
; [ebp - 4] = size
; [ebp - 8] = index 
; [ebp - 12] = list_node_ptr
; [ebp - 16] = table_entry_ptr 
; calculate index
push dword [ebp + 12]
call fnv32_1                ; get hash
add esp, 4
push eax
push dword [ebp - 4]
call get_index
add esp, 8
shl eax, 2
mov dword [ebp - 8], eax

.load_list:
; load list_node_ptr at table[index]
mov eax, dword [ebp + 8]
mov eax, dword [eax]
add eax, dword [ebp - 8]
mov eax, dword [eax]
mov dword [ebp - 12], eax   ; save list_node_ptr
cmp dword [ebp - 12], 0
je .free_index 
.list_loop:
mov eax, dword [ebp - 12]   ; load current node
mov eax, dword [eax]        ; load list val, i.e. a table entry pointer
mov dword [ebp - 16], eax   ; save table_entry_ptr
mov eax, dword [eax]
push eax 
push dword [ebp + 12]
call string_equals
add esp, 8
cmp eax, 1 
je .entry_found
mov eax, dword [ebp - 12]
mov eax, dword [eax + 4]    ; load next_ptr
cmp eax, 0
je .entry_not_found
mov dword [ebp - 12], eax   ; save list_node_ptr
jmp .list_loop

.entry_not_found:
.free_index:
xor eax, eax
leave
ret 

.entry_found:
; return the value of the entry
mov eax, dword [ebp - 16]
mov eax, dword [eax + 4]
leave 
ret

; returns a new table entry object, with optional initial values

; STRUCTURE: table_entry < char* prehash_key,  auto* value >
; RETURN: entry_ptr
get_entry:
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

; uint get_index(uint size, uint hash)
get_index:
push ebp 
mov ebp, esp 
sub esp, 4
mov dword [ebp - 4], 0      ; bit_count
mov eax, dword [ebp + 8]
.get_bit_count:
shr eax, 1
jc .got_count
inc dword [ebp - 4]
jmp .get_bit_count
.got_count:
; get index through xor folding 
mov cl, byte [ebp - 4]
mov eax, dword [ebp + 12]
shr eax, cl                 ; hash >> bit_count
cmp dword [ebp - 4], 16     ; 16-bit word
jge .mask
.tiny_mask:
xor eax, dword [ebp + 12]   ; (hash >> bit_count) ^ hash
mov edx, dword [ebp + 8]
dec edx                     ; get mask
and eax, edx                ; ((hash >> bit_count) ^ hash) & mask
leave
ret
.mask:
cmp dword [ebp - 4], 32 ; 32-bit word
je .exit
mov edx, dword [ebp + 8]
dec edx                     ; get mask
and edx, dword [ebp + 12]   ; hash & mask
xor eax, edx                ; (hash >> bit_count) ^ (hash & mask)
leave
ret
.exit:
mov eax, dword [ebp + 12]
leave
ret 