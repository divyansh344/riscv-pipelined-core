# RISC-V Bare-Metal C Workflow Guide

This guide explains how to write C code, compile it into machine code for your custom RV32I FPGA processor, and execute it using the PYNQ Jupyter notebook.

## 1. The Workspace Setup
Your firmware development environment is located at `D:\SoC_Design\pipelined_risc_v\firmware`. It contains:
- `link.ld`: Maps Instruction Memory to `0x00000000` and Data Memory to `0x10000000`.
- `crt0.S`: The assembly startup code that initializes the stack and calls `main()`.
- `make_hex.py`: The build script that runs the GCC compiler and generates the Python array.

> [!IMPORTANT]
> Because your CPU implements the base **RV32I** instruction set (without the M-extension), **you cannot use multiplication (`*`), division (`/`), or modulo (`%`) operators** in your C code. Doing so will cause linker errors. Use bitwise shifts (`>>`, `<<`) and masks (`&`) instead!

## 2. Writing C Code
Create a `.c` file in the `firmware/` folder (e.g., `my_algorithm.c`). 

To access the Data Memory (RAM) on the FPGA, create a pointer to `0x10000000`. This allows you to read the data your Python notebook wrote to memory!

```c
// Example: my_algorithm.c
int main() {
    // 1. Create a pointer to the start of Data Memory
    volatile int* ram = (int*)0x10000000;
    
    // 2. Read input from Python
    int a = ram[0];
    int b = ram[1];
    
    // 3. Do some math
    int sum = a + b;
    
    // 4. Write result back for Python to read
    ram[2] = sum;
    
    return 0; // CPU will hit infinite loop in crt0.S after this
}
```

## 3. Compiling
Open `make_hex.py` and modify the `run_cmd` block to point to your new C file (around line 29):

```python
    run_cmd([
        gcc,
        "-march=rv32i", "-mabi=ilp32",
        "-nostdlib", "-ffreestanding",
        "-O2", 
        "-T", "link.ld",
        "crt0.S", "my_algorithm.c", # <--- CHANGE THIS LINE
        "-o", "firmware.elf"
    ])
```

Then, run the script from your terminal:
```bash
cd D:\SoC_Design\pipelined_risc_v\firmware
python make_hex.py
```

## 4. Execution
The Python script will print out a perfectly formatted Python array called `hex_code`. 

Simply copy that array, paste it into your Jupyter Notebook cell, and pass it to `RISCV_Controller.load_program()`!

```python
hex_code = [
    "10001117", "00010113", ...
]

RISCV_Controller.load_program(hex_code)
RISCV_Controller.run_timed(0.5)

result = RISCV_Controller.read_data(2)
print("Result:", result)
```
