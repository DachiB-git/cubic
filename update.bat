nasm -f bin -o boot.bin ./boot.asm
fsutil file setEOF "./source.txt" 1024
@REM fsutil file setEOF "./source.txt" 1474560 
type boot.bin source.txt > boot.img
dd if=/dev/zero of=floppy.img bs=1024 count=1440
dd if=boot.img of=floppy.img seek=0
del boot.bin 
del boot.img