# 5-Stage Pipelined RISC-V Core (RV32I)

**5-stage pipelined RISC-V (RV32I) core in Verilog implementing data forwarding, stalling, and flushing, validated on the Zynq-7000 ZedBoard.**

## 📌 Introduction
This repository contains the RTL implementation of a 32-bit RISC-V processor designed from scratch. The core implements the standard **RV32I Instruction Set** and features a classic 5-stage pipelined architecture with hazard handling.

Key architectural features include a **Hazard Detection Unit** for stalling and a **Forwarding Unit** to solve data hazards without unnecessary bubbles, ensuring high throughput. The design has been synthesized and validated on the **Digilent ZedBoard (Zynq-7000)**.

## 🚀 Key Features
- **ISA:** RISC-V 32-bit Integer (RV32I)
- **Pipeline:** 5-Stage (IF, ID, EX, MEM, WB)
- **Hazard Handling:** - **Data Hazards:** Solved via Forwarding (EX-to-EX, MEM-to-EX).
  - **Load-Use Hazards:** Solved via Stalling (Bubble insertion).
  - **Control Hazards:** Solved via Flushing (Branch misprediction handling).
- **Platform:** Zynq-7000 (ZedBoard).
- **Verification:** Validated via infinite loop Fibonacci sequence generation.

## 📂 Repository Structure
| Folder | Description |
| :--- | :--- |
| `design_sources/` | Verilog source code for the processor core and pipeline stages. |
| `simulation_source/` | Testbench files (`tb_top.v`) for verifying logic in Vivado/ModelSim. |
| `constraint_file/` | Xilinx XDC constraints for ZedBoard pin mapping (LEDs, Clock). |
| `hexcode/` | Machine code (`.mem`) files for loading into Instruction Memory. |
| `simulation_image/` | Waveform screenshots proving functional correctness. |
| `block_diagram/` | High-level architecture diagrams of the datapath. |

## 📊 Architecture
The processor uses a Harvard Architecture with separate Instruction and Data memories.
*(Note: View the `block_diagram` folder for the detailed datapath visual).*

## 🧪 Simulation & Testing
The core was verified by running an **Infinite Fibonacci Sequence** program.

### **Waveform Output**
![Simulation Waveform](simulation_image/Screenshot%202026-01-29%20052156.png)

### **Test Program (Fibonacci)**
The processor executes the following assembly code to generate the sequence `0, 1, 1, 2, 3, 5, 8...` on the LEDs:

```assembly
00000093  // ADDI x1, x0, 0    -> Init 'a' = 0
00100113  // ADDI x2, x0, 1    -> Init 'b' = 1
002081b3  // ADD  x3, x1, x2   -> Loop Start: c = a + b
00302023  // SW   x3, 0(x0)    -> Store 'c' to Mem[0] (Update LEDs)
002000b3  // ADD  x1, x0, x2   -> Shift: a = b
00300133  // ADD  x2, x0, x3   -> Shift: b = c
fe0008e3  // BEQ  x0, x0, -16  -> Jump back 4 instructions (Infinite Loop)
```

### 🛠️ How to Run

### **1. Simulation (Vivado)**
To verify the logic before deployment:
1.  Open **Vivado** and create a new project.
2.  Add all Verilog files from the `design_sources/` folder.
3.  Add the testbench file (`tb_top.v`) from the `simulation_source/` folder.
4.  **Important:** Copy the `hexcode/fib_fixed.mem` file into your project's simulation directory (or ensure the path in `instruction_memory.v` is correct).
5.  Run **Behavioral Simulation**.
6.  Observe `cpu_data_out` to see the Fibonacci sequence generated.

### **2. FPGA Implementation (ZedBoard)**
To run the processor on hardware:
1.  Create a project targeting the **Zynq-7000 (xc7z020clg484-1)**.
2.  Add `fpga_wrapper.v` as the **Top Module**.
3.  Add the constraints file from `constraint_file/`.
4.  Run **Synthesis** and **Implementation**.
5.  Click **Generate Bitstream**.
6.  Open **Hardware Manager** -> **Auto Connect** -> **Program Device**.
7.  Press the **Reset Button** on the board and watch the LEDs count!

## 🔮 Future Roadmap
- [ ] Add support for **RV32M Extension** (Hardware Multiplication/Division).
- [ ] Interface with external **DDR Memory** controller.

## 👤 Author
**Divyansh**
- **GitHub:** [@divyansh344](https://github.com/divyansh344)

## 📜 License
This project is open-source and available under the **MIT License**.
