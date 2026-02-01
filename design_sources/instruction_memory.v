`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/24/2026 10:11:53 PM
// Design Name: 
// Module Name: instruction_memory
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

module instruction_memory(
    input wire clk,     // Present but unused (for compatibility)
    input wire rst,     // Present but unused
    input wire [31:0] pc,
    output wire [31:0] instruction_code
    );

    reg [31:0] memory [0:127]; 
    
    integer i;

    initial begin
        // 1. Fill everything with Zeros (NOPs) first!
        for (i = 0; i < 128; i = i + 1) begin
            memory[i] = 32'h00000000;
        end
        
        // 2. Then load your program
        $readmemh("fib_fixed.mem", memory);
    end

    // Combinational Read (No Clock needed for ROM)
    assign instruction_code = memory[pc[8:2]];

endmodule
