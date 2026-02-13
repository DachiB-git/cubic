nasm -f bin -o boot.bin ./boot.asm
nasm -f bin -o kernel.bin ./kernel.asm
copy %1 "./source.txt"
fsutil file setEOF "./source.txt" 40960
type "./source.txt" >> kernel.bin
type kernel.bin >> boot.bin
dd if=/dev/zero of=floppy.img bs=1024 count=1440
dd if=boot.bin of=floppy.img bs=512 seek=0
del boot.bin
del kernel.bin
del source.txt