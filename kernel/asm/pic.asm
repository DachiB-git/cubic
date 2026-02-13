%define PIC_MASTER_COM_PORT  0x20
%define PIC_MASTER_DATA_PORT 0x21
%define PIC_SLAVE_COM_PORT   0xA0
%define PIC_SLAVE_DATA_PORT  0xA1
%define PIC_EOI              0x20
%define ICW1                 0x11
%define PIC_REMAP            0x20
init_PIC:
push ebp
mov ebp, esp
; send ICW1 to MASTER and SLAVE
push ICW1
push PIC_MASTER_COM_PORT
call outb
add esp, 8
call io_wait
push ICW1
push PIC_SLAVE_COM_PORT
call outb
add esp, 8
call io_wait
; send ICW2 to MASTER and SLAVE
push PIC_REMAP
push PIC_MASTER_DATA_PORT
call outb
add esp, 8
call io_wait
push PIC_REMAP+8
push PIC_SLAVE_DATA_PORT
call outb
add esp, 8
call io_wait
; send ICW3 to MASTER and SLAVE
push 0x4
push PIC_MASTER_DATA_PORT
call outb
add esp, 8
call io_wait
push 0x2
push PIC_SLAVE_DATA_PORT
call outb
add esp, 8
call io_wait
; send ICW4 to MASTER and SLAVE
push 0x1
push PIC_MASTER_DATA_PORT
call outb
add esp, 8
call io_wait
push 0x1
push PIC_SLAVE_DATA_PORT
call outb
add esp, 8
call io_wait
; clear data registers
push 0
push PIC_MASTER_DATA_PORT
call outb
add esp, 8
call io_wait
push 0
push PIC_SLAVE_DATA_PORT
call outb
add esp, 8
leave
ret


; void PIC_sendEOI(char irq)
PIC_sendEOI:
push ebp
mov ebp, esp
cmp byte [ebp + 8], 8
jb .send_to_master
.send_to_slave:
push PIC_EOI
push PIC_SLAVE_COM_PORT
call outb
add esp, 8
.send_to_master:
push PIC_EOI
push PIC_MASTER_COM_PORT
call outb
add esp, 8
.exit:
leave
ret