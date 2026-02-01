`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2026 02:06:40 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input  wire clk,
    input  wire rst,
    // for testing on fpga
    output wire [31:0] debug_data,
    output wire debug_valid
    );

    // ======================================================================
    // WIRES INTERCONNECTING MODULES
    // ======================================================================
    
    // Instruction Memory Interface
    wire [31:0] pc;
    wire [31:0] instruction;
    
    // Data Memory Interface
    wire [31:0] data_addr;
    wire [31:0] write_data;
    wire [31:0] read_data;
    wire        mem_write;
    // ======================================================================
    // MODULE INSTANTIATIONS
    // ======================================================================

    // 1. THE DATAPATH (The Brain)
    data_path datapath (
        .clk(clk),
        .rst(rst),
        
        // Instruction Interface
        .pc_out(pc),
        .instr_in(instruction),
        
        // Data Memory Interface
        .data_mem_addr(data_addr),
        .data_mem_wdata(write_data),
        .data_mem_rdata(read_data),
        .mem_write(mem_write)
    );

    // 2. INSTRUCTION MEMORY (The ROM)
    instruction_memory instr_mem (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .instruction_code(instruction)
    );

    // 3. DATA MEMORY (The RAM)
    data_memory data_mem (
        .clk(clk),
        .rst(rst),
        .mem_write(mem_write),
        .mem_addr(data_addr),
        .write_data(write_data),
        .read_data(read_data)
    );
    
    assign debug_data = write_data;
    assign debug_valid = mem_write;

endmodule
