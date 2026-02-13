

with open ("isr_GEN.asm", "w") as f:
    for i in range(32, 256):
        f.write(f"ISR_NOERROR {i}\n")
