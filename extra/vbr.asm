; MBR 
[bits 16]
[org 0x0600]


relocation:
cli ; disable interrupts
; clear segments and init stack
xor ax, ax 
mov ds, ax 
mov es, ax 
mov ss, ax 
mov sp, 0x7C00

mov cx, 0x100   ; 256 * 2 = 512 bytes
mov si, 0x7C00  ; source address 
mov di, 0x0600  ; relocation start
rep movsw     

jmp 0:vbr_start

vbr_start:
sti                                 
; boot sector and BPB declarations
BS_jumpBoot:        jmp short 0x3E
                    nop 
BS_OEMName:         db "MSWIN4.1"
BPB_BytesPerSec:    dw 512 
BPB_SecPerClus:     db 1
BPB_RsvdSecCnt:     dw 1
BPB_NumFATs:        db 2
BPB_RootEntCnt:     dw 512          ; TODO: figure out a better number 
BPB_TotSec16:       dw 2 * 80 * 16  ; 2 sides, 80 tracks per side, 16 sectors per track
BPB_Media:          db 0xF0         ; 1.44MB floppy
BPB_FATSz16:        dw 0            ; TODO: 
BPB_SecPerTrk:      dw 16
BPB_NumHeads:       dw 2
BPB_HiddSec:        dd 0
BPB_TotSec32:       dd 0
BS_DrvNum:          db 0x00 
BS_Reserved1:       db 0
BS_BootSig:         db 0x29
BS_VolID:           dd 0
BS_VolLab:          db "FLOPPY 1   "
BS_FileSysType:     db "FAT12   "

boot_code:
.load_second_boot:
mov ah, 0x02            ; function
mov al, 1               ; sector_count
mov ch, 0x00            ; low eight bits of cylinder
mov cl, 0x02            ; sector after vbr, upper two bits cylinder hdd only
mov dh, 0x00            ; head
mov dl, 0x00            ; drive number  
mov bx, 0x7C00          ; mem location to load the second boot sector
int 0x13

.jump_to_second_boot:
cmp word [0x7DFE], 0xAA55   ; check for boot signature
jne .error
mov dl, byte 0x00
jmp 0:0x7C00

.error:
jmp $

times 510 - ($ - $$) db 0
dw 0xAA55
