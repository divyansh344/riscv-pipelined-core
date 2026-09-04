`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2026 01:28:46 AM
// Design Name: 
// Module Name: EX_MEM_REG
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


module EX_MEM_REG(
    input wire clk,
    input wire rst,
    
    input wire reg_writeE,
    input wire [1:0] result_srcE,
    input wire mem_writeE,
    input wire [31:0] alu_result,
    input wire [31:0] write_dataE,
    input wire [4:0] rdE,
    input wire [31:0] pc_plus_4E,
    input wire [2:0] funct3E,
    
    output reg reg_writeM,
    output reg [1:0] result_srcM,
    output reg mem_writeM,
    output reg [31:0] alu_resultM,
    output reg [31:0] write_dataM,
    output reg [4:0] rdM,
    output reg [31:0] pc_plus_4M,
    output reg [2:0] funct3M
    );
    
    always @(posedge clk) begin
        if(rst) begin
            reg_writeM <= 0;
            result_srcM <= 0;
            mem_writeM <= 0;
            alu_resultM <= 0;
            write_dataM <= 0;
            rdM         <= 0;
            pc_plus_4M  <= 0;
            funct3M     <= 0;
        end
        else begin
            reg_writeM <= reg_writeE;
            result_srcM <= result_srcE;
            mem_writeM <= mem_writeE;
            alu_resultM <= alu_result;
            write_dataM <= write_dataE;
            rdM         <= rdE;
            pc_plus_4M  <= pc_plus_4E;
            funct3M     <= funct3E;
        end
    end
endmodule
