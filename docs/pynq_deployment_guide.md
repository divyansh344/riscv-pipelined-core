# PYNQ Deployment Guide for RISC-V Core

## 1. Files to Extract from Vivado
To run your custom SoC on the Kria KR260 using PYNQ, you need exactly **two files** from your Vivado project. They must have the exact same base name when uploaded to the board.

| File | Where to find it | What to rename it to |
|---|---|---|
| **Bitstream** (`.bit`) | `[Vivado_Project_Dir]/[Project_Name].runs/impl_1/riscv_soc_wrapper.bit` | `riscv_soc.bit` |
| **Hardware Handoff** (`.hwh`) | `[Vivado_Project_Dir]/[Project_Name].gen/sources_1/bd/riscv_soc/hw_handoff/riscv_soc.hwh` | `riscv_soc.hwh` |

*Note: You can also generate the `.hwh` file easily by going to **File -> Export -> Export Block Design** in Vivado.*

## 2. Upload to KR260
Open your Jupyter Notebook environment on the KR260 in your browser (usually `http://<kr260_ip>:9090`).
1. Create a new folder (e.g., `riscv_project`).
2. Upload `riscv_soc.bit` and `riscv_soc.hwh` into this folder.
3. Upload your `fib_fixed.mem` (or any hex program you want to run).
4. Create a new **Python 3 (ipykernel)** notebook in that folder.

## 3. Jupyter Notebook Driver Code
Copy and paste the following Python code into your Jupyter Notebook cells. It uses the `MMIO` class mapped to `0xA000_0000` to control the CPU.

## Cell 1: Hardware Setup & Controllers
```python
from pynq import Overlay, MMIO
import time
import random
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# 1. Load the hardware design
overlay = Overlay("riscv_soc.bit")
print("✅ FPGA Bitstream loaded successfully!")

# 2. Setup Memory Mapped I/O
BASE_ADDRESS = 0xA0000000
MAP_SIZE     = 0x4000
IMEM_OFFSET  = 0x0000
DMEM_OFFSET  = 0x1000
CTRL_OFFSET  = 0x2000

riscv_bus = MMIO(BASE_ADDRESS, MAP_SIZE)

class RISCV_Controller:
    @staticmethod
    def halt():
        riscv_bus.write(CTRL_OFFSET, 1)

    @staticmethod
    def run():
        riscv_bus.write(CTRL_OFFSET, 0)

    @staticmethod
    def load_program(hex_array):
        """Loads a list of hex strings into IMEM and returns load time."""
        RISCV_Controller.halt()
        t0 = time.perf_counter()
        for i, hex_str in enumerate(hex_array):
            riscv_bus.write(IMEM_OFFSET + (i * 4), int(hex_str, 16))
        t1 = time.perf_counter()
        print(f"✅ Loaded {len(hex_array)} instructions into FPGA IMEM  "
              f"({(t1-t0)*1000:.2f} ms via AXI)")

    @staticmethod
    def write_data(word_index, value):
        riscv_bus.write(DMEM_OFFSET + (word_index * 4), value & 0xFFFFFFFF)

    @staticmethod
    def read_data(word_index):
        val = riscv_bus.read(DMEM_OFFSET + (word_index * 4))
        return val - 0x100000000 if val > 0x7FFFFFFF else val

    @staticmethod
    def run_timed(wait_s=0.1):
        """Starts the CPU, waits, halts, and returns elapsed ms."""
        RISCV_Controller.run()
        t0 = time.perf_counter()
        time.sleep(wait_s)
        RISCV_Controller.halt()
        return (time.perf_counter() - t0) * 1000

print("🚀 RISC-V Driver initialized. Ready to run programs!")
```

## Cell 2: The Python RISC-V Assembler
```python
class RISCV_Assembler:
    """
    Two-pass RV32I assembler supporting:
      R-type : ADD, SUB
      I-type : ADDI, LW
      S-type : SW
      B-type : BEQ, BNE, BLT, BGE
      J-type : JAL
    Labels are resolved in pass 1; machine code emitted in pass 2.
    """

    @staticmethod
    def _reg(s):
        s = s.replace(',', '').strip()
        if s == 'zero': return 0
        if s.startswith('x'): return int(s[1:])
        raise ValueError(f"Unknown register: {s}")

    @staticmethod
    def compile(code_string):
        lines_raw = code_string.strip().split('\n')

        # ── Pass 1: strip comments, collect labels ──────────────────────────
        lines   = []   # clean instruction strings
        labels  = {}   # label → byte address
        addr    = 0

        for line in lines_raw:
            line = line.split('//')[0].strip()
            if not line:
                continue
            if ':' in line:
                parts = line.split(':', 1)
                labels[parts[0].strip()] = addr
                line = parts[1].strip()
                if not line:
                    continue
            lines.append(line)
            addr += 4

        # ── Pass 2: emit machine code ───────────────────────────────────────
        hex_out = []
        for i, line in enumerate(lines):
            cur_addr = i * 4
            toks = line.replace(',', ' ').split()
            op   = toks[0].upper()
            mc   = 0

            if op in ('ADD', 'SUB'):
                rd, rs1, rs2 = map(RISCV_Assembler._reg, toks[1:4])
                f7 = 0x20 if op == 'SUB' else 0x00
                mc = (f7<<25)|(rs2<<20)|(rs1<<15)|(0<<12)|(rd<<7)|0x33

            elif op == 'ADDI':
                rd, rs1 = map(RISCV_Assembler._reg, toks[1:3])
                imm = int(toks[3]) & 0xFFF
                mc = (imm<<20)|(rs1<<15)|(0<<12)|(rd<<7)|0x13

            elif op == 'LW':
                rd = RISCV_Assembler._reg(toks[1])
                imm_s, rs_s = toks[2].split('(')
                rs1 = RISCV_Assembler._reg(rs_s.rstrip(')'))
                imm = int(imm_s) & 0xFFF
                mc = (imm<<20)|(rs1<<15)|(0b010<<12)|(rd<<7)|0x03

            elif op == 'SW':
                rs2 = RISCV_Assembler._reg(toks[1])
                imm_s, rs_s = toks[2].split('(')
                rs1 = RISCV_Assembler._reg(rs_s.rstrip(')'))
                imm = int(imm_s)
                mc = (((imm>>5)&0x7F)<<25)|(rs2<<20)|(rs1<<15)|(0b010<<12)|((imm&0x1F)<<7)|0x23

            elif op in ('BEQ','BNE','BLT','BGE'):
                rs1, rs2 = map(RISCV_Assembler._reg, toks[1:3])
                tgt = toks[3]
                off = (labels[tgt] - cur_addr) if tgt in labels else int(tgt)
                f3  = {'BEQ':0,'BNE':1,'BLT':4,'BGE':5}[op]
                mc  = (((off>>12)&1)<<31)|(((off>>5)&0x3F)<<25)|(rs2<<20)|(rs1<<15)|\
                      (f3<<12)|(((off>>1)&0xF)<<8)|(((off>>11)&1)<<7)|0x63

            elif op == 'JAL':
                rd  = RISCV_Assembler._reg(toks[1])
                tgt = toks[2]
                off = (labels[tgt] - cur_addr) if tgt in labels else int(tgt)
                mc  = (((off>>20)&1)<<31)|(((off>>1)&0x3FF)<<21)|\
                      (((off>>11)&1)<<20)|(((off>>12)&0xFF)<<12)|(rd<<7)|0x6F

            else:
                raise ValueError(f"Unsupported instruction: {op}")

            hex_out.append(f"{mc & 0xFFFFFFFF:08X}")

        return hex_out

print("✅ RISC-V Assembler ready.")
```

## Cell 3: Demo 1 — Fibonacci Sequence
```python
# ── NOP-FREE Fibonacci ──────────────────────────────────────────────────────
# With the hardware hazard fix, no NOPs are needed.
# The branch_stall + MEM→Branch forwarding handle all data dependencies.
fibonacci_asm = """
    ADDI x1, x0, 20          // Total count = 20
    ADDI x2, x0, 0           // Loop counter = 0
    ADDI x3, x0, 0           // fib[n-2] = 0
    ADDI x4, x0, 1           // fib[n-1] = 1
    SW   x3, 0(x0)           // RAM[0] = 0
    SW   x4, 4(x0)           // RAM[1] = 1
    ADDI x2, x2, 2           // counter = 2
    ADDI x5, x0, 8           // mem_ptr = byte address 8
loop:
    BGE  x2, x1, end         // if counter >= 20, done
    ADD  x6, x3, x4          // fib[n] = fib[n-2] + fib[n-1]
    SW   x6, 0(x5)           // store fib[n]
    ADD  x3, x0, x4          // fib[n-2] = fib[n-1]
    ADD  x4, x0, x6          // fib[n-1] = fib[n]
    ADDI x5, x5, 4           // advance memory pointer
    ADDI x2, x2, 1           // counter++
    JAL  x0, loop
end:
    BEQ  x0, x0, 0           // halt
"""

hex_code = RISCV_Assembler.compile(fibonacci_asm)
RISCV_Controller.load_program(hex_code)

print(f"\n🔵 Running Fibonacci on RISC-V hardware (zero NOPs)...")
exec_ms = RISCV_Controller.run_timed(0.05)

fib = [RISCV_Controller.read_data(i) for i in range(20)]
print(f"⏱  CPU given {exec_ms:.1f} ms wall time  (algorithm takes ~microseconds)")
print(f"\n📊 Fibonacci sequence (first 20 terms):")
print(fib)

# Verify correctness
expected = [0, 1]
for _ in range(18):
    expected.append(expected[-1] + expected[-2])

correct = fib == expected
print(f"\n{'✅ CORRECT' if correct else '❌ MISMATCH'} — Hardware result matches golden reference!")

# Plot
plt.figure(figsize=(10, 4))
plt.plot(range(20), fib, 'o-', color='#4A90D9', linewidth=2, markersize=6)
plt.fill_between(range(20), fib, alpha=0.15, color='#4A90D9')
plt.title("Fibonacci Sequence — Computed by Custom RV32I FPGA CPU", fontsize=13)
plt.xlabel("Index"); plt.ylabel("Value")
plt.xticks(range(20))
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
```

## Cell 4: Demo 2 — Hardware Bubble Sort
```python
# ── NOP-FREE Bubble Sort ────────────────────────────────────────────────────
# Zero NOPs. The fixed hazard unit autonomously handles:
#   • ADD→ADD dependencies   (EX forwarding)
#   • LW→BGE dependencies    (load-use stall + MEM→branch forwarding)
#   • ADD→BGE dependencies   (branch-EX stall)
NUM_ELEMENTS = 50

print(f"📦 Generating {NUM_ELEMENTS} random numbers and writing to FPGA DMEM...")
random_array = [random.randint(10, 999) for _ in range(NUM_ELEMENTS)]
for i, v in enumerate(random_array):
    RISCV_Controller.write_data(i, v)

sort_asm = f"""
    ADDI x1, x0, {NUM_ELEMENTS}
    ADDI x2, x0, 0
outer_loop:
    ADDI x3, x1, -1
    BGE  x2, x3, end
    ADDI x4, x0, 0
    SUB  x5, x3, x2
inner_loop:
    BGE  x4, x5, inner_end
    ADD  x6, x4, x4
    ADD  x6, x6, x6
    LW   x7, 0(x6)
    LW   x8, 4(x6)
    BGE  x8, x7, skip_swap
    SW   x8, 0(x6)
    SW   x7, 4(x6)
skip_swap:
    ADDI x4, x4, 1
    JAL  x0, inner_loop
inner_end:
    ADDI x2, x2, 1
    JAL  x0, outer_loop
end:
    BEQ  x0, x0, 0
"""

hex_code = RISCV_Assembler.compile(sort_asm)
RISCV_Controller.load_program(hex_code)

print(f"\n🔴 Starting Hardware Bubble Sort (zero NOPs)...")
exec_ms = RISCV_Controller.run_timed(0.5)

sorted_array = [RISCV_Controller.read_data(i) for i in range(NUM_ELEMENTS)]

# Verify
is_sorted = all(sorted_array[i] <= sorted_array[i+1] for i in range(NUM_ELEMENTS-1))
py_sorted  = sorted(random_array)
is_correct = sorted_array == py_sorted

print(f"⏱  CPU given {exec_ms:.1f} ms wall time")
print(f"📐 Algorithm complexity: O(n²) = {NUM_ELEMENTS}² = {NUM_ELEMENTS**2:,} comparisons")
print(f"🔢 Instruction count: {len(hex_code)} instructions loaded")
print(f"\n{'✅ SORTED CORRECTLY' if is_correct else '❌ SORT FAILED'}")

# Plot
fig, axes = plt.subplots(1, 2, figsize=(14, 5))
fig.suptitle("Hardware-Accelerated Bubble Sort on Custom RV32I FPGA CPU",
             fontsize=13, fontweight='bold')

axes[0].bar(range(NUM_ELEMENTS), random_array, color='#E74C3C', alpha=0.85)
axes[0].set_title("Unsorted Input (Generated by Python)", fontsize=11)
axes[0].set_xlabel("Array Index"); axes[0].set_ylabel("Value")

axes[1].bar(range(NUM_ELEMENTS), sorted_array, color='#27AE60', alpha=0.85)
axes[1].set_title(f"Sorted Output (Computed by RISC-V CPU in Hardware)", fontsize=11)
axes[1].set_xlabel("Array Index"); axes[1].set_ylabel("Value")

red_patch   = mpatches.Patch(color='#E74C3C', label='Unsorted (Python)')
green_patch = mpatches.Patch(color='#27AE60', label='Sorted (RISC-V FPGA)')
fig.legend(handles=[red_patch, green_patch], loc='lower center',
           ncol=2, fontsize=10, bbox_to_anchor=(0.5, -0.02))

plt.tight_layout()
plt.show()
```
