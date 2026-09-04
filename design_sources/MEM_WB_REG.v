`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2026 01:29:25 AM
// Design Name: 
// Module Name: MEM_WB_REG
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


module MEM_WB_REG(
    input wire clk,
    input wire rst,
    
    input wire reg_writeM,
    input wire [1:0] result_srcM,
    input wire [31:0] alu_resultM,
    input wire [31:0] rd,
    input wire [4:0] rdM,
    input wire [31:0] pc_plus_4M,
    input wire [2:0] funct3M,
    
    output reg reg_writeW,
    output reg [1:0] result_srcW,
    output reg [31:0] alu_result_out,
    output reg [31:0] read_dataW,
    output reg [4:0] rdW,
    output reg [31:0] pc_plus_4W,
    output reg [2:0] funct3W
    );
    
    always @(posedge clk) begin
        if(rst) begin
            reg_writeW <= 0;
            result_srcW <= 0;
            alu_result_out <= 0;
            read_dataW      <= 0;
            rdW             <= 0;
            pc_plus_4W      <= 0;
            funct3W         <= 0;
        end
        else begin
            reg_writeW <= reg_writeM;
            result_srcW <= result_srcM;
            alu_result_out <= alu_resultM;
            read_dataW      <= rd;
            rdW             <= rdM;
            pc_plus_4W      <= pc_plus_4M;
            funct3W         <= funct3M;
        end
    end
endmodule
