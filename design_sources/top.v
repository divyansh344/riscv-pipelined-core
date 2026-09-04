`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: top
// Description: RV32I pipelined RISC-V core — SoC integration top-level.
//
//   Typical Jupyter / PYNQ usage sequence
//   ──────────────────────────────────────
//   1. Assert   rst = 1        (holds CPU in reset; pipeline + regfile cleared)
//   2. Write    IMEM via imem_we/waddr/wdata   (load program word by word)
//   3. Write    DMEM via dmem_we_axi/waddr/wdata  (pre-load input arrays)
//   4. Deassert rst = 0        (CPU starts executing from PC = 0)
//   5. Wait for CPU to reach the halt BEQ or a known cycle count
//   6. Read     DMEM via dmem_raddr_axi/rdata   (inspect results)
//
//   Internal modules unchanged: data_path, branch_unit, alu, control_unit,
//   register_file, hazard_unit, all pipeline registers, imm_gen, IFU.
//
// Revision:
//   0.01 - File Created
//   0.02 - AXI memory ports added; debug_data/debug_valid removed
//////////////////////////////////////////////////////////////////////////////////

module top (
    input  wire clk,
    input  wire rst,    // Active-high; PS drives this as a "program load / run" flag

    // ── Instruction Memory — AXI write port ─────────────────────────────────
    // PS writes the program before deasserting rst.
    input  wire        imem_we,           // Write enable from AXI wrapper
    input  wire [9:0]  imem_waddr,        // Word address [0 .. 1023]
    input  wire [31:0] imem_wdata,        // Instruction word

    // ── Data Memory — AXI read port ──────────────────────────────────────────
    // PS reads computation results after the CPU has finished.
    input  wire [9:0]  dmem_raddr_axi,    // Word address [0 .. 1023]
    output wire [31:0] dmem_rdata_axi,    // Result word (combinational)

    // ── Data Memory — AXI write port ─────────────────────────────────────────
    // PS pre-loads input data arrays before deasserting rst.
    input  wire        dmem_we_axi,       // Write enable from AXI wrapper
    input  wire [9:0]  dmem_waddr_axi,    // Word address [0 .. 1023]
    input  wire [31:0] dmem_wdata_axi     // Data word
);

    // =========================================================================
    // INTERNAL WIRES
    // =========================================================================

    // Instruction Memory Interface
    wire [31:0] pc;
    wire [31:0] instruction;

    // Data Memory Interface
    wire [31:0] data_addr;
    wire [31:0] write_data;
    wire [31:0] read_data;
    wire        mem_write;
    wire [2:0]  data_funct3;

    // =========================================================================
    // MODULE INSTANTIATIONS
    // =========================================================================

    // 1. THE DATAPATH
    data_path datapath (
        .clk             (clk),
        .rst             (rst),

        // Instruction interface
        .pc_out          (pc),
        .instr_in        (instruction),

        // Data memory interface
        .data_mem_addr   (data_addr),
        .data_mem_wdata  (write_data),
        .data_mem_rdata  (read_data),
        .mem_write       (mem_write),
        .data_mem_funct3 (data_funct3)
    );

    // 2. INSTRUCTION MEMORY — 1024 words, AXI-writable
    instruction_memory instr_mem (
        .clk              (clk),
        .pc               (pc),
        .instruction_code (instruction),
        // AXI write port
        .imem_we          (imem_we),
        .imem_waddr       (imem_waddr),
        .imem_wdata       (imem_wdata)
    );

    // 3. DATA MEMORY — 1024 words, AXI-readable and AXI-writable
    data_memory data_mem (
        .clk            (clk),
        // CPU interface
        .mem_write      (mem_write),
        .funct3         (data_funct3),
        .mem_addr       (data_addr),
        .write_data     (write_data),
        .read_data      (read_data),
        // AXI read port
        .dmem_raddr_axi (dmem_raddr_axi),
        .dmem_rdata_axi (dmem_rdata_axi),
        // AXI write port
        .dmem_we_axi    (dmem_we_axi),
        .dmem_waddr_axi (dmem_waddr_axi),
        .dmem_wdata_axi (dmem_wdata_axi)
    );

endmodule
