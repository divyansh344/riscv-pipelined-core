`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: instruction_memory
// Description: 1024-word (4 KB) instruction store.
//
//   FPGA runtime:  The PS writes instructions via the AXI write port
//                  (imem_we / imem_waddr / imem_wdata) before deasserting rst.
//                  The $readmemh initial block is excluded from synthesis.
//
//   Simulation:    $readmemh("fib_fixed.mem", ...) pre-loads the test program
//                  at elaboration time, exactly as before.
//
//   Read port:     Always combinational — CPU gets its instruction in the same
//                  cycle as PC is presented (no clock needed for read).
//
// Revision:
//   0.01 - File Created
//   0.02 - AXI write port + 1 KB expansion for SoC integration
//////////////////////////////////////////////////////////////////////////////////

module instruction_memory (
    input  wire        clk,               // Required for AXI synchronous write
    input  wire [31:0] pc,                // Current PC from CPU (byte address)
    output wire [31:0] instruction_code,  // Instruction word to CPU

    // ── AXI write port ─────────────────────────────────────────────────────
    // PS loads the program word-by-word before releasing the CPU from reset.
    input  wire        imem_we,           // Write enable from AXI wrapper
    input  wire [9:0]  imem_waddr,        // Word address [0 .. 1023]
    input  wire [31:0] imem_wdata         // 32-bit instruction word
);

    // -----------------------------------------------------------------------
    // 1. MEMORY ARRAY — 1024 words × 32 bits = 4 KB
    // -----------------------------------------------------------------------
    reg [31:0] memory [0:1023];

    // -----------------------------------------------------------------------
    // 2. SIMULATION INITIALISATION — excluded from synthesis
    //    Vivado synthesis defines the SYNTHESIS macro automatically, so this
    //    block is only visible to xsim / ModelSim / Icarus.
    // -----------------------------------------------------------------------
    `ifndef SYNTHESIS
    initial begin
        $readmemh("fib_fixed.mem", memory);
    end
    `endif

    // -----------------------------------------------------------------------
    // 3. AXI WRITE PORT — PS deposits program words one at a time
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (imem_we)
            memory[imem_waddr] <= imem_wdata;
    end

    // -----------------------------------------------------------------------
    // 4. COMBINATIONAL READ — single-cycle, no clock latency
    //    pc[11:2] = word index into 1024-word (4 KB) array
    // -----------------------------------------------------------------------
    assign instruction_code = memory[pc[11:2]];

endmodule
