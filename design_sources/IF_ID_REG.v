`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2026 01:27:56 AM
// Design Name: 
// Module Name: IF_ID_REG
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


module IF_ID_REG(
    input wire clk,
    input wire rst,
    input wire en,
    input wire clr,
    
    input wire [31:0] instruction_in,
    input wire [31:0] pcF,
    input wire [31:0] pc_plus_4F,
    
    output reg [31:0] instrD,
    output reg [31:0] pcD,
    output reg [31:0] pc_plus_4D
    );
    
    always @(posedge clk) begin
        if(rst || clr) begin
            instrD <= 0;
            pcD <= 0;
            pc_plus_4D <= 0;
        end
        else if(en) begin
            instrD <= instruction_in;
            pcD <= pcF;
            pc_plus_4D <= pc_plus_4F;
        end
    end
endmodule
