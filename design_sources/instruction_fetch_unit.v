`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/24/2026 09:55:20 PM
// Design Name: 
// Module Name: instruction_fetch_unit
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


module instruction_fetch_unit(
    input wire clk,
    input wire rst,
    
    // Inputs from Datapath / Control
    input  wire  en,
    input  wire  [31:0] pc_target,
    input  wire  pc_src,
    
    // Outputs
    output reg  [31:0] pc,            // Current Program Counter
    output wire [31:0] pc_plus_4      // Return Address (for JAL/JALR writeback)
    );
    
    // Internal Signals
    wire  [31:0] next_pc;
    
    // 1. Calculate Potential Targets (Combinational)
    assign pc_plus_4     = pc + 32'd4;
        
    assign next_pc = (pc_src) ? pc_target: pc_plus_4;
    
    // 3. PC Register Update (Sequential)
    always @ (posedge clk) begin
        if(rst)
            pc <= 32'b0; // Reset Vector (usually 0)
        else if(en)
            pc <= next_pc;
    end
   
endmodule
