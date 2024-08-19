# Version 1.1

import sys

if len(sys.argv) == 1:
    subcommand = input("Select an operation from [asm, disasm]: ")
    f = input("File path: ")
else:
    subcommand = sys.argv[1]
    f = sys.argv[2]
    
if subcommand == "asm":
    with open(f,"r") as file:
        for line in file.readlines():
            if len(line) <= 1:
                continue
            jmps = ["jz", "jnz", "js", "jns"]
            line = line.lower()
            if line[0] == "@" or line[0:2] == "//":
                print(line[:-1])
                continue
            args = line.split()
            op = args[0]
            if op == "sub":
                t = int(args[1][1:-1], 16)
                a = int(args[2][1:-1], 16)
                b = int(args[3][1:], 16)
                instr = 0b0000 << 12 | a << 8 | b << 4 | t
            elif op == "movl":
                if args[2][0] != "#":
                    print("Missing #:", line)
                    continue
                t = int(args[1][1:-1], 16)
                i = int(args[2][1:])
                if i > 0xFF:
                    print("Literal too large:",i)
                    continue
                instr = 0b1000 << 12 | i << 4 | t
            elif op == "movh":
                if args[2][0] != "#":
                    print("Missing #:", line)
                    continue
                t = int(args[1][1:-1], 16)
                i = int(args[2][1:])
                if i & 0xFF != 0:
                    print("Literal not a multiple of 256:", i)
                    continue
                elif i > 0xFF00:
                    print("Literal too large:", i << 8)
                    continue
                instr = 0b1001 << 12 | (i >> 8) << 4 | t
            elif op in jmps:
                t = int(args[1][1:-1], 16)
                a = int(args[2][1:], 16)
                instr = 0b1110 << 12 | a << 8 | jmps.index(op) << 4 | t
            elif op == "ld" or op == "st":
                t = int(args[1][1:-1], 16)
                a = int(args[2][1:], 16)
                instr = 0b1111 << 12 | a << 8 | (0 if op == "ld" else 1) << 4 | t
            elif op == "halt":
                instr = 0xFFFF
            else:
                print("Unknown instruction:", op)
                continue
            
            print("%0.4x    // %s" % (instr, line[:-1]))



elif subcommand == "disasm":
    with open(f,"r") as file:
        for line in file.readlines():
            if line[0] == "@" or line[0:2] == "//":
                print(line)
                continue
            instr = int(line[:4], 16)
            code = instr >> 12
            a = (instr >> 8) & 0xF
            b = (instr >> 4) & 0xF
            t = instr & 0xF
            im = (instr >> 4) & 0xFF
            if code == 0b0000:
                print(f"sub r{t}, r{a}, r{b}")
            elif code == 0b1000:
                print(f"movl r{t}, #{im}")
            elif code == 0b1001:
                print(f"movh r{t}, #{im << 8}")
            elif code == 0b1110 and b == 0b0000:
                print(f"jz r{t}, r{a}")
            elif code == 0b1110 and b == 0b0001:
                print(f"jnz r{t}, r{a}")
            elif code == 0b1110 and b == 0b0010:
                print(f"js r{t}, r{a}")
            elif code == 0b1110 and b == 0b0011:
                print(f"jns r{t}, r{a}")
            elif code == 0b1111 and b == 0b0000:
                print(f"ld r{t}, r{a}")
            elif code == 0b1111 and b == 0b0001:
                print(f"st r{t}, r{a}")
            else:
                print("halt")
else:
    print("Bad subcommand option:", subcommand)
