[bits 16]
[org 0x7C00]
%define SECTORS 67
%define SOURCE_CODE_SECTORS 2
%define boot_drive_ptr 0x0000_0500
%define drive_read_buffer 0x0001_0000

; boot sector and BPB declarations
BS_jumpBoot:        jmp short boot_code
                    nop 
BS_OEMName:         db "MSWIN4.1"
BPB_BytesPerSec:    dw 512 
BPB_SecPerClus:     db 1
BPB_RsvdSecCnt:     dw 1
BPB_NumFATs:        db 2
BPB_RootEntCnt:     dw 512          ; TODO: figure out a better number 
BPB_TotSec16:       dw 2 * 80 * 18  ; 2 sides, 80 tracks per side, 18 sectors per track
BPB_Media:          db 0xF0         ; 1.44MB floppy
BPB_FATSz16:        dw 9            ; 9 sectors for each FAT (2880 sectors, 341 full entries in each sector)
BPB_SecPerTrk:      dw 16
BPB_NumHeads:       dw 2
BPB_HiddSec:        dd 0
BPB_TotSec32:       dd 0
BS_DrvNum:          db 0x00 
BS_Reserved1:       db 0
BS_BootSig:         db 0x29
BS_VolID:           dd 0
BS_VolLab:          db "FLOPPY     "
BS_FileSysType:     db "FAT12   "

boot_code:
; save the boot drive number for later use
mov byte [boot_drive_ptr], dl

; enter video mode 3 (text 80x25 color)
mov ah, 0x00
mov al, 0x03
; mov al, 0x12 ; graphics 640x480
int 0x10

; disable vga cursor
mov ah, 0x01
mov cx, 0x2607
int 0x10


; load the source code for the compiler
; todo : upgrade to a double buffer system with current_lexeme and forward pointers
; ref : dragon pg 138 3.2 input buffering
; es - segment register
; bx - base address of read buffer
; al - sector_count

mov ax, 0x1000
mov es, ax

read_sectors:
mov ah, 0x02    ; function
mov al, 17      ; sector_count
mov ch, 0x00    ; low eight bits of cylinder
mov cl, 0x02    ; sector after boot, upper two bits cylinder hdd only
mov dh, 0x00    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 0
int 0x13

mov ah, 0x02    ; function
mov al, 18      ; sector_count
mov ch, 0x00    ; low eight bits of cylinder
mov cl, 0x01    ; first sector, upper two bits cylinder hdd only
mov dh, 0x01    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 17 * 512
int 0x13

mov ah, 0x02    ; function
mov al, 18       ; sector_count
mov ch, 0x01    ; low eight bits of cylinder
mov cl, 0x01    ; first sector, upper two bits cylinder hdd only
mov dh, 0x00    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 35 * 512
int 0x13


mov ah, 0x02    ; function
mov al, 18       ; sector_count
mov ch, 0x01    ; low eight bits of cylinder
mov cl, 0x01    ; first sector
mov dh, 0x01    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 53 * 512
int 0x13

mov ah, 0x02    ; function
mov al, 18       ; sector_count
mov ch, 0x02    ; low eight bits of cylinder
mov cl, 0x01    ; first sector
mov dh, 0x00    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 71 * 512
int 0x13

mov ah, 0x02    ; function
mov al, 18       ; sector_count
mov ch, 0x02    ; low eight bits of cylinder
mov cl, 0x01    ; first sector
mov dh, 0x01    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 89 * 512
int 0x13

mov ah, 0x02    ; function
mov al, 18       ; sector_count
mov ch, 0x03    ; low eight bits of cylinder
mov cl, 0x01    ; first sector
mov dh, 0x00    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 107 * 512
int 0x13

mov ah, 0x02    ; function
mov al, 3       ; sector_count
mov ch, 0x03    ; low eight bits of cylinder
mov cl, 0x01    ; first sector
mov dh, 0x01    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 125 * 512
int 0x13

mov ax, 0x2000
mov es, ax

mov ah, 0x02    ; function
mov al, 15       ; sector_count
mov ch, 0x03    ; low eight bits of cylinder
mov cl, 0x04    ; first sector
mov dh, 0x01    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 0
int 0x13

mov ah, 0x02    ; function
mov al, 18       ; sector_count
mov ch, 0x04    ; low eight bits of cylinder
mov cl, 0x01    ; first sector
mov dh, 0x00    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 15 * 512
int 0x13

mov ah, 0x02    ; function
mov al, 18       ; sector_count
mov ch, 0x04    ; low eight bits of cylinder
mov cl, 0x01    ; first sector
mov dh, 0x01    ; head
mov dl, byte [boot_drive_ptr]
mov bx, 33 * 512
int 0x13

; mov ah, 0x02    ; function
; mov al, 18       ; sector_count
; mov ch, 0x05    ; low eight bits of cylinder
; mov cl, 0x01    ; first sector
; mov dh, 0x00    ; head
; mov dl, byte [boot_drive_ptr]
; mov bx, 52 * 512
; int 0x13

; activate a20 gate
mov ax, 0x2401   
int 0x15

xor ax, ax
mov ds, ax
mov es, ax

; disable interrupts
cli        

; load gdt in gdtr
lgdt [gdtr]

; reserve and load the idt
mov ax, 0x0
mov es, ax
mov di, 0
mov cx, 2048
rep stosb

; load the idtr
lidt [idtr]

; set pe bit in cr0
mov eax, cr0
or eax, 1
mov cr0, eax

jmp 0x08:protected_mode ; far jump into pm code segment of gdt index 1 + offset

[bits 32]
protected_mode:
mov ax, 0x10
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
mov ebp, 0x0100_0000
mov esp, ebp        ; init stack

; jump to kernel
jmp 0x08:drive_read_buffer


; declare gdt structures
gdt_null:
dd 0
dd 0

gdt_kernel_code:
dw 0xFFFF           ; max limit (in this case 4 gib)
dw 0                ; base addr 0-15
db 0                ; base addr 16-23
db 0b10011010       ; access byte (preset, kernel-level, is code or data, is exec, growing up, readable, access)
db 0b11001111       ; flags (granularit, is 32bit, long mode, intel reserved) + upper 4 bits of the limit
db 0                ; base addr 24-31

gdt_kernel_data:
dw 0xFFFF           ; max limit (in this case 4 gib)
dw 0                ; base addr 0-15
db 0                ; base addr 16-23
db 0b10010010       ; access byte (preset, kernel-level, is code or data, is exec, growing up, readable, access)
db 0b11001111       ; flags (granularize, is 32bit, long mode, intel reserved) + upper 4 bits of the limit
db 0                ; base addr 24-31

gdtr:
dw gdtr - gdt_null - 1
dd gdt_null

idtr:
dw 2047 ; 256 * 8 byte entries - 1
dd 0x0  ; physical address 0

times 510 - ($ - $$) db 0 ; fill remaining bytes with 0s
dw 0xAA55                 ; write 511-512 with boot_loader magic numbers  