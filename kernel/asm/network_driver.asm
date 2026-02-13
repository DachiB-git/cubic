[bits 32]


; config constants for Am79C973 AMD pci network card
%define VENDOR_ID 1022
%define DEVICE_ID 2625

; pci port constants
%define CONFIG_ADDRESS 0xcf8
%define CONFIG_DATA 0xcfc


; function to access pci device configuration space
; returns the full 32 bit word from 0 offset into the header file
; address structure
; bits | limit
; enable - 31 | 0-1
; reserved 30-24
; bus - 24-16 | 0-255
; device - 15-11 | 0-31
; func - 10-8 | 0-7
; offset - 7-2 | 0-63 (first two bits reserved as 0x00) 
; int pci_config_read(char bus, char slot, char func, char offset)
pci_config_read:
push ebp 
mov ebp, esp 
mov eax, 0x8000_0000
shl dword [ebp + 8], 16
or eax, dword [ebp + 8]
shl dword [ebp + 12], 11
or eax, dword [ebp + 12]
shl dword [ebp + 16], 8
or eax, dword [ebp + 16]
mov dx, CONFIG_ADDRESS
out dx, eax 
mov dx, CONFIG_DATA
in eax, dx
leave
ret 

lspci: 
push ebp
mov ebp, esp 
sub esp, 16
mov dword [ebp - 4], 0  ; bus number
; bus loop
.bus_loop:
cmp dword [ebp - 4], 256
je .bus_loop_end
mov dword [ebp - 8], 0  ; device number
.device_loop:
cmp dword [ebp - 8], 32
je .device_loop_end
mov dword [ebp - 12], 0 ; function number
.function_loop:
cmp dword [ebp - 12], 8
je .function_loop_end
push dword [ebp - 12]
push dword [ebp - 8]
push dword [ebp - 4]
call pci_config_read
add esp, 12
cmp eax, 0xffff_ffff
je .function_loop_end
mov dword [ebp - 16], eax
; print vendor id
mov eax, dword [ebp - 16]
and eax, 0xffff
push 16
push itoa_buffer
push eax 
call itoa
add esp, 12
push itoa_buffer
call print_string
add esp, 4
push space
call print_string
add esp, 4
; print device id
mov eax, dword [ebp - 16]
shr eax, 16
push 16 
push itoa_buffer
push eax 
call itoa 
add esp, 12 
push itoa_buffer
call print_string
add esp, 4
push nl
call print_string
add esp, 4
inc dword [ebp - 12]
jmp .function_loop
.function_loop_end:
inc dword [ebp - 8]
jmp .device_loop
.device_loop_end:
inc dword [ebp - 4]
jmp .bus_loop
.bus_loop_end:
leave 
ret