# 5-Stage Pipelined RISC-V SoC (RV32I + AXI4-Lite)

**A complete full-stack RISC-V SoC: custom 5-stage pipelined RV32I core in Verilog,
wrapped with an AXI4-Lite interface, integrated on the Kria KR260 (Zynq UltraScale+ MPSoC),
and driven by a bare-metal C toolchain with a Python/Jupyter software driver.**

---

## 📌 What This Is

This project goes beyond a textbook CPU. It is a complete hardware/software co-design:

1. **RTL Layer** — A 5-stage pipelined RV32I core with complete hazard resolution
2. **SoC Layer** — AXI4-Lite memory-mapped interface so the ARM PS can load programs and read results
3. **Software Layer** — Bare-metal C programs compiled with GCC cross-compiler and executed on custom silicon

---

## 🚀 Key Features

### Hardware (RTL)
- **Full RV32I ISA**: All 40 base integer instructions — arithmetic, logic, all shifts (SLL/SRL/SRA), all comparisons (SLT/SLTU), all 6 branch types (BEQ/BNE/BLT/BGE/BLTU/BGEU), all 5 load variants (LB/LH/LW/LBU/LHU), all 3 store variants (SB/SH/SW), LUI, AUIPC, JAL, JALR
- **5-Stage Pipeline**: IF → ID → EX → MEM → WB

### Hazard Resolution (6 mechanisms)
| Hazard | Resolution |
|--------|-----------|
| R-type data hazard (1 cycle) | MEM→EX forwarding |
| R-type data hazard (2 cycle) | WB→EX forwarding |
| Load-use | 1-cycle stall + MEM→EX forward |
| Branch source in EX | 1-cycle branch-EX stall |
| Branch source in MEM/WB | MEM→ID / WB→ID forwarding |
| posedge register file read-write race | WB→ID general forwarding |

### SoC Integration
- **AXI4-Lite interface** on Instruction and Data memories
- **PS→PL workflow**: ARM processor loads program into IMEM, pre-loads data into DMEM, releases CPU from reset, waits, reads results
- Validated on **Kria KR260 (Zynq UltraScale+ MPSoC)** via Vivado + PYNQ

### Software Stack
- **Bare-metal C programs** compiled with `riscv-none-elf-gcc`
- **Custom linker script** (`link.ld`) mapping Harvard architecture: IMEM@`0x00000000`, DMEM@`0x10000000`
- **Build script** (`make_hex.py`): GCC → ELF → binary → hex array for Python injection
- **Python/Jupyter driver** using PYNQ MMIO for AXI control

---

## 📂 Repository Structure

| Folder | Description |
|--------|-------------|
| `design_sources/` | All 15 Verilog RTL files — CPU core + pipeline registers + memories |
| `firmware/` | Bare-metal C programs, startup code, linker script, build script |
| `hexcodes/` | Pre-compiled `.mem` files for simulation and FPGA loading |
| `simulation_source/` | Vivado/xsim testbench |
| `docs/` | RTL architecture deep-dive + C workflow guide |
| `block_diagram/` | Datapath architecture diagram |
| `simulation_image/` | Waveform screenshots |
| `constraint_file/` | ZedBoard XDC pin constraints (legacy reference) |


## 🧪 Demo Programs

All programs are compiled C code running on the custom CPU:

| Program | What it demonstrates |
|---------|---------------------|
| `bubble_sort.c` | Nested loops, LW/SW, all branch types, sorting 50 integers on silicon |
| `fibonacci.c` | Classic sequence — continuity test from original design |
| `radix_sort.c` | Base-256 bitwise radix (avoids MUL/DIV — hardware-aware algorithm design) |
| `star_pyramid.c` | Nested loops with SB (byte stores) — printf-style output on silicon |

---

## 🛠️ How to Run

### Simulation (Vivado/xsim)
1. Create new Vivado project
2. Add all `.v` files from `design_sources/`
3. Add `simulation_source/tb_top.v` as testbench
4. Copy `hexcodes/fib_fixed.mem` to your simulation run directory
5. Run Behavioral Simulation

### C Firmware Compilation
```bash
cd firmware/
# Edit make_hex.py to point to your .c file
python make_hex.py
# Copy the printed hex_code array into your Jupyter Notebook

```
Requires: [xPack RISC-V GCC](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack)

### FPGA (Kria KR260 via PYNQ)
1. Synthesize + implement in Vivado targeting `xck26-sfvc784-2LV-c`
2. Generate bitstream
3. Load onto KR260 with PYNQ
4. Use the Python/Jupyter driver to load programs and read results

## 🔮 Future Roadmap

- [ ] AXI4-Lite wrapper RTL (expose IMEM/DMEM as memory-mapped AXI slave registers)
- [ ] RV32M Extension (Hardware Multiplication/Division)
- [ ] Interrupt / Exception support (CSR registers)
- [ ] Cache layer

---

## 👤 Author

**Divyansh** — [GitHub @divyansh344](https://github.com/divyansh344)

## 📜 License

MIT License
