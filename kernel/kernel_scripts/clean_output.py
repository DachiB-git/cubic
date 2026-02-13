import sys

rows = []

with open(sys.argv[1]) as f:
    for row in f:
        clean_row = ""
        for c in row:
            if c != "\x1f" and c != "\x00":
                clean_row += c
        if len(clean_row) > 1:
            rows.append(clean_row)

with open("./output/main.asm", "w") as f:
    f.writelines(rows)