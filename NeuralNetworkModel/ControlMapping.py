# DMEM[0:80] = W
# DMEM[81:728] = A
# DMEM[729:809] = C for W
# DMEM[810] = C for A
    
if __name__ == "__main__":
    with open("./Contorl.txt", 'w') as f:
        # DMEM[729:809] = C for W
        for i in range(0, 81):
            control = (i<<1) & 0xFF
            f.write(f"{control:04x}\n")
        # DMEM[810] = C for A
        f.write(f"0001")