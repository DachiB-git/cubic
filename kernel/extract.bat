del .\output\main.asm
set "MEMORY_FILE=C:\Users\dachi\OneDrive\Desktop\boot_loader\memory_dump.elf"
set "RAW_FILE=C:\Users\dachi\OneDrive\Desktop\boot_loader\memory_dump.bin"
call update %1
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "Cubic" --defaultfrontend headless
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm "Cubic"
timeout /t 5
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" debugvm "Cubic" dumpvmcore --filename=%MEMORY_FILE%
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm "Cubic" poweroff
objcopy %MEMORY_FILE% %RAW_FILE%
dd if=%RAW_FILE% of=output.txt bs=256 count=1024 skip=1059
python clean_output.py output.txt
del %MEMORY_FILE%
@REM del %RAW_FILE%
@REM del output.txt