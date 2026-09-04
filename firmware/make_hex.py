import os
import subprocess
import sys

# Update this path if GCC is installed elsewhere
GCC_PATH = r"C:\Tools\xPack\xpack-riscv-none-elf-gcc-13.2.0-2\bin"
PREFIX = "riscv-none-elf-"
# Note: we will need to know exactly what folder the zip extracts to.
# We'll adjust this script if needed after extracting.

def run_cmd(cmd):
    print(" ".join(cmd))
    res = subprocess.run(cmd)
    if res.returncode != 0:
        print("Error executing command.")
        sys.exit(1)

def main():
    if not os.path.exists("main.c"):
        print("main.c not found.")
        return

    # 1. Compile and Link
    gcc = os.path.join(GCC_PATH, PREFIX + "gcc.exe")
    run_cmd([
        gcc,
        "-march=rv32i", "-mabi=ilp32",
        "-nostdlib", "-ffreestanding",
        "-O2", # Optimization helps a lot with Bubble Sort!
        "-T", "link.ld",
        "crt0.S", "star_pyramid.c",
        "-o", "firmware.elf"
    ])

    # 2. Extract raw binary (machine code)
    objcopy = os.path.join(GCC_PATH, PREFIX + "objcopy.exe")
    run_cmd([
        objcopy,
        "-O", "binary",
        "-j", ".text",
        "firmware.elf",
        "firmware.bin"
    ])

    # 3. Convert to Hex Array
    with open("firmware.bin", "rb") as f:
        data = f.read()

    hex_array = []
    # Read 4 bytes at a time
    for i in range(0, len(data), 4):
        chunk = data[i:i+4]
        # Pad with 0 if not 4 bytes
        while len(chunk) < 4:
            chunk += b'\x00'
        
        # RISC-V is little-endian, so we read as little-endian 32-bit integer
        val = int.from_bytes(chunk, byteorder='little')
        hex_array.append(f'"{val:08X}"')

    print("\nCompilation successful!")
    print("\nCopy this array into your Jupyter Notebook:\n")
    print("hex_code = [")
    for i in range(0, len(hex_array), 8):
        line = ", ".join(hex_array[i:i+8])
        if i + 8 < len(hex_array):
            line += ","
        print(f"    {line}")
    print("]")

if __name__ == "__main__":
    main()
