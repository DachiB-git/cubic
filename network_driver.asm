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