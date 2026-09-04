`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: data_memory
// Description: 1024-word (4 KB) byte-addressable data store.
//
//   CPU interface:  Unchanged from Phase 1 — SB/SH/SW writes with byte-enable,
//                   full-word combinational read (LB/LH/LW extension in WB).
//
//   AXI read port:  PS reads any word independently after the CPU finishes.
//   AXI write port: PS pre-loads input arrays (e.g. Fibonacci seeds, matrices)
//                   before deasserting rst to start the CPU.
//
//   Reset removed:  The rst-triggered 1024-word clear loop was the primary
//                   contributor to rst fan-out (32 768 FF resets). Removing it:
//                     • Eliminates the fan-out pressure on the timing paths.
//                     • Allows the PS to pre-load DMEM while rst is asserted
//                       on the CPU (writes would have been overwritten before).
//                   FPGA BRAM powers up as all-zero. Simulation uses an initial
//                   block (excluded from synthesis) to match this behaviour.
//
// Revision:
//   0.01 - File Created
//   0.02 - Byte-enable write support (SB/SH/SW)
//   0.03 - AXI read/write ports + 1 KB expansion + rst loop removed
//////////////////////////////////////////////////////////////////////////////////

module data_memory (
    input  wire        clk,

    // ── CPU interface (unchanged) ───────────────────────────────────────────
    input  wire        mem_write,    // 1 = CPU store (SB / SH / SW)
    input  wire [2:0]  funct3,       // Store size: 000=SB  001=SH  010=SW
    input  wire [31:0] mem_addr,     // ALU-computed byte address
    input  wire [31:0] write_data,   // CPU rs2 value to store
    output wire [31:0] read_data,    // Full 32-bit word → WB stage sign-extends

    // ── AXI read port (PS reads results) ───────────────────────────────────
    input  wire [9:0]  dmem_raddr_axi,    // Word address [0 .. 1023]
    output wire [31:0] dmem_rdata_axi,    // Result word to PS (combinational)

    // ── AXI write port (PS pre-loads input data) ───────────────────────────
    // Full-word writes only; byte-granular writes not needed from PS side.
    // Priority: CPU write > AXI write (safety net; both should not occur
    // simultaneously in normal operation — PS holds rst while writing).
    input  wire        dmem_we_axi,       // AXI write enable
    input  wire [9:0]  dmem_waddr_axi,    // AXI write word address
    input  wire [31:0] dmem_wdata_axi     // AXI write data (full word)
);

    // -----------------------------------------------------------------------
    // 1. MEMORY ARRAY — 1024 words × 32 bits = 4 KB
    // -----------------------------------------------------------------------
    reg [31:0] ram [0:1023];

    // -----------------------------------------------------------------------
    // 2. SIMULATION INITIALISATION — excluded from synthesis
    //    FPGA BRAM powers up as all-zero. Mirror that in simulation so that
    //    unwritten locations read 0x00000000 (not X).
    // -----------------------------------------------------------------------
    `ifndef SYNTHESIS
    integer sim_i;
    initial begin
        for (sim_i = 0; sim_i < 1024; sim_i = sim_i + 1)
            ram[sim_i] = 32'b0;
    end
    `endif

    // Word index and byte-lane within that word
    wire [9:0] word_idx    = mem_addr[11:2];   // 10-bit: 1024-word range
    wire [1:0] byte_offset = mem_addr[1:0];

    // -----------------------------------------------------------------------
    // 3. WRITE LOGIC (synchronous)
    //    CPU has priority; AXI write fires only when CPU is not storing.
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (mem_write) begin
            // ── CPU store ──────────────────────────────────────────────────
            case (funct3[1:0])
                // SW — write full 32-bit word
                2'b10: ram[word_idx] <= write_data;

                // SH — write 16-bit half-word into lower or upper half
                2'b01: begin
                    if (byte_offset[1] == 1'b0)
                        ram[word_idx][15:0]  <= write_data[15:0];
                    else
                        ram[word_idx][31:16] <= write_data[15:0];
                end

                // SB — write 8-bit byte into one of four byte lanes
                2'b00: begin
                    case (byte_offset)
                        2'b00: ram[word_idx][7:0]   <= write_data[7:0];
                        2'b01: ram[word_idx][15:8]  <= write_data[7:0];
                        2'b10: ram[word_idx][23:16] <= write_data[7:0];
                        2'b11: ram[word_idx][31:24] <= write_data[7:0];
                    endcase
                end

                default: ;   // Unused encoding — no write
            endcase

        end else if (dmem_we_axi) begin
            // ── AXI store (full word, lower priority) ─────────────────────
            ram[dmem_waddr_axi] <= dmem_wdata_axi;
        end
    end

    // -----------------------------------------------------------------------
    // 4. READ LOGIC (combinational — both ports always valid)
    // -----------------------------------------------------------------------
    assign read_data      = ram[word_idx];         // CPU read
    assign dmem_rdata_axi = ram[dmem_raddr_axi];   // AXI read

endmodule
