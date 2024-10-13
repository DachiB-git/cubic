
%define COM_BUFFER_PTR 0x7E00
%define EXEC_FLAG_PTR 0x7E80

MOV DH, 0x00

CALL getRegisterData
CALL moveCursor

.loop:
CALL getCommand
CALL moveCursor
CALL getRegisterData
CALL moveCursor
JMP .loop

getChar:
MOV AH, 0x00    ; load get keystroke BIOS func code
INT 0x16        ; call BIOS keyboard service int
RET

checkNewLine:
MOV AH, 0x0D    ; move '\r' into AH
CMP AH, AL      ; compare entered key to carriage return
JNE .noNewLine  ; if a newline is requested exec moveCursor
CALL moveCursor  
.noNewLine:
RET

moveCursor:
MOV BYTE [EXEC_FLAG_PTR], 0x01  ; update exec command flag
MOV AH, 0x02                    ; load set cursor BIOS func code
MOV BH, 0x00                    ; set page to 0
ADD DH, 0x01                    ; set row to (last_row + 1)
MOV DL, 0x00                    ; set col to 0
INT 0x10                        ; call BIOS video service int
RET

getCommand:
CALL getChar
CALL checkNewLine
CALL printChar
RET

execCommand:
MOV BYTE AL, [EXEC_FLAG_PTR]
CMP AL, 0
JE .no_exec
MOV AL, 'e'
CALL printChar
MOV AL, 'x'
CALL printChar
MOV AL, 'c'
CALL printChar
MOV BYTE [EXEC_FLAG_PTR], 0x00
CALL moveCursor
.no_exec:
RET

get_register_data:
; get register name and fetch data
; print format => [regName]: [data]
; move address into DX
MOV CL, 16   ; bit length
MOV CH, 0   

.get_bits:
CMP CH, CL      ; check if all bits displayed
JE .exit_loop   ;
SHL DX, 1       ; shift out the MSB to set CF
SETC AL         ; set AL to CF & 1
ADD AL, 0x30    ; add 0x30 to get ASCII value
CALL print_char  ; print the character
SUB CL, 1       ; decrement counter
CLC             ; clear CF
JMP .get_bits
.exit_loop:
CALL move_cursor
RET

expr:
CALL term 
; match for a '+' or a '-' and look for the next term; print the op
; if no op do nothing
.tail:
MOV BYTE AL, [lookahead]
CMP AL, '+'
JE .plus 
CMP AL, '-'
JE .minus
RET

.plus:
MOV AH, '+'
CALL match
CALL term
MOV AL, '+'
CALL print_char
JMP .tail

.minus:
MOV AH, '-'
CALL match
CALL term
MOV AL, '-'
CALL print_char
JMP .tail

term:
MOV BYTE AL, [lookahead]
SUB AL, 0x30
JL error
CMP AL, 9
JG error
ADD AL, 0x30
PUSH BX
MOV BL, AL
MOV BYTE AH, [lookahead]
CALL match
MOV AL, BL
CALL print_char
POP BX
RET

match:
MOV AL, [lookahead]
CMP AH, AL       ; compare with lookahead char
JNE error
CALL get_char
RET

error:
error_msg db "Syntax error!", 0
MOV SI, error_msg
CALL print_string
JMP terminate

MOV AX, 0
MOV DS, AX
MOV ES, AX

; init stack
MOV AX, STACK_SEGMENT
MOV SS, AX
MOV BP, STACK_BASE_OFFSET
MOV SP, STACK_BASE_OFFSET

; ; load hash prime and basis
; MOV DWORd [FNV_prime_ptr], FNV_prime
; MOV DWORD [FNV_basis_ptr], FNV_offset_basis

; MOV BYTE [DRIVE_READ_BUFFER], 'h'
; MOV BYTE [DRIVE_READ_BUFFER + 1], 'e'
; MOV BYTE [DRIVE_READ_BUFFER + 2], 'l'
; MOV BYTE [DRIVE_READ_BUFFER + 3], 'l'
; MOV BYTE [DRIVE_READ_BUFFER + 4], 'o'
; MOV BYTE [DRIVE_READ_BUFFER + 5], 0x00


get_register_data:
; get register name and fetch data
; print format => [regName]: [data]
; move address into DX
MOV CL, 16   ; bit length
MOV CH, 0   
XOR AL, AL

.get_bits:
CMP CH, CL      ; check if all bits displayed
JE .exit_loop   
CMP CL, 0
SHL DX, 1      ; shift out the MSB to set CF
SETC AL         ; set AL to shifted out bit
CLC             ; clear CF 
ADD AL, 0x30
CALL print_char
SUB CL, 1
JMP .get_bits
.exit_loop:
CALL move_cursor
RET

get_register_data_hex:
; get register name and fetch data
; print format => [regName]: [data]
; move address into DX
MOV CL, 32   ; bit length 

.get_bits:
CMP CL, 0      ; check if all bits displayed
JE .exit_loop   
PUSH CX
MOV CL, 4
XOR BL, BL
.get_hex:
CMP CL, 0
JE .exit_hex
CLC
SHL BL, 1       ; shift left for next bit
CLC
SHL EDX, 1      ; shift out the MSB to set CF
SETC AL         ; set AL to shifted out bit
CLC             ; clear CF 
OR BL, AL       ; load bit into BL
SUB CL, 1
JMP .get_hex
.exit_hex:
POP CX
SUB CL, 4
MOV AL, BL
CMP AL, 9
JG .alpha
ADD AL, 0x30
JMP .post_alpha_check
.alpha:
ADD AL, 0x37
.post_alpha_check:
CALL print_char
JMP .get_bits
.exit_loop:
CALL move_cursor
RET


; move string pointer into SI
; void print_string(char* string)
print_string:
CLD
.loop:
LODSB
CMP AL, 0x00
JE .end_of_string
CLC
CALL print_char
JMP .loop
.end_of_string:
RET

; char get_char()
; returns a single character from the read buffer
; using the AX register
get_char:
PUSH BX
MOV BX, [index]
MOV BYTE AL, [DRIVE_READ_BUFFER + BX]
MOV BYTE [lookahead], AL
INC BX
MOV WORD [index], BX
POP BX
RET

; move c into AL
; void print_char(char c)
print_char:
PUSH BX
MOV AH, 0x0E    ; write char teletype mode
MOV BH, 0x00	; set page to 0
MOV BL, 0x07    ; set font color to gray
INT 0x10        ; call BIOS video service int
POP BX
RET

move_cursor:
MOV AH, 0x02                    ; load set cursor BIOS func code
MOV BH, 0x00                    ; set page to 0
ADD DH, 0x01                    ; set row to (last_row + 1)
MOV DL, 0x00                    ; set col to 0
INT 0x10                        ; call BIOS video service int
RET

write_sector:
MOV AH, 0x03
MOV AL, 1
MOV CH, 0
MOV CL, 3
MOV DH, 0
MOV BYTE DL, [DRIVE_NUMBER_PTR]
INT 0x13
RET 