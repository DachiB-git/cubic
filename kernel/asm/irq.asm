%define KEYBOARD_CONTROLLER_PORT 0x60


irq_handlers: times 16 dd 0

irq_handler:
push ebp
mov ebp, esp
sub esp, 4
mov eax, dword [ebp + 8]
mov eax, dword [eax + 36]
sub eax, PIC_REMAP
mov dword [ebp - 4], eax
cmp dword [irq_handlers + eax * 4], 0
je .unhandled_hardware_interrupt_error
push dword [ebp + 8]
mov eax, dword [irq_handlers + eax * 4]
call eax
jmp .eio
.unhandled_hardware_interrupt_error:
push unhandled_hardware_interrupt
call print_string
add esp, 4
push space
call print_string
add esp, 4
push dword [ebp - 4]
call print_number
add esp, 4
push nl
call print_string
add esp, 4
.eio:
push dword [ebp - 4]
call PIC_sendEOI
add esp, 4
leave
ret


init_IRQs:
push ebp
mov ebp, esp
sub esp, 4
mov dword [ebp - 4], 0
call init_PIC
.irq_loop:
cmp dword [ebp - 4], 16
je .end_loop 
mov eax, dword [ebp - 4]
add eax, PIC_REMAP
push irq_handler
push eax 
call register_isr_handler
add esp, 8
inc dword [ebp - 4]
jmp .irq_loop
.end_loop:
; set up hardware handlers
push handler_TIMER
push 0
call register_irq_handler
add esp, 8
push handler_KEYBOARD
push 1
call register_irq_handler
add esp, 8
sti
leave
ret


handler_TIMER:
push ebp
mov ebp, esp
; TODO: add timer handling
nop
leave
ret

handler_KEYBOARD:
push ebp
mov ebp, esp
sub esp, 4
mov dword [ebp - 4], 0
push KEYBOARD_CONTROLLER_PORT
call inb
add esp, 4
mov byte [ebp - 4], al
; push scan_code
; call print_string
; add esp, 4
push dword [ebp - 4]
call print_hex
add esp, 4
push space
call print_string
add esp, 4
leave
ret

; void register_irq_handler(int irq, void* handler)
register_irq_handler:
push ebp
mov ebp, esp
mov eax, dword [ebp + 8]
mov edx, dword [ebp + 12]
mov dword [irq_handlers + eax * 4], edx
leave
ret

unhandled_hardware_interrupt: db "Unhandled Hardware Interrupt", 0
scan_code: db "Scan code received: ", 0