nasm -f bin -o boot.bin ./boot.asm
fsutil file setEOF "./source.txt" 1024
type boot.bin source.txt > boot.img
del boot.bin