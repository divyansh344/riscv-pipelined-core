`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2026 01:28:23 AM
// Design Name: 
// Module Name: ID_EX_REG
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


module ID_EX_REG(
    input wire clk,
    input wire rst,
    input wire clr,
    
    
    input wire [5:0] alu_controlD,
    input wire mem_writeD,       
    input wire [1:0] result_srcD,
    input wire alu_src,        
    input wire reg_writeD,      
    input wire branchD,         
    input wire jumpD,
    input wire jalrD,           
    input wire [4:0] rdD,
    input wire [31:0] imm_extD,
    input wire [31:0] pcD,
    input wire [31:0] pc_plus_4D,
    input wire [31:0] rd1,
    input wire [31:0] rd2,
    input wire [4:0] rs1D,
    input wire [4:0] rs2D,
    input wire [2:0] funct3D,
    
    output reg [5:0] alu_controlE,
    output reg mem_writeE,       
    output reg [1:0] result_srcE, 
    output reg alu_srcE,  
    output reg reg_writeE,      
    output reg branchE,          
    output reg jumpE,
    output reg jalrE,            
    output reg [4:0] rdE,
    output reg [31:0] imm_extE,
    output reg [31:0] pcE,
    output reg [31:0] pc_plus_4E,
    output reg [31:0] rd1E,
    output reg [31:0] rd2E,
    output reg [4:0] rs1E,
    output reg [4:0] rs2E,
    output reg [2:0] funct3E
    );
    
    always @(posedge clk) begin
        if(rst || clr) begin
            alu_controlE <= 0;
            mem_writeE <= 0;       
            result_srcE <= 0; 
            alu_srcE <= 0;  
            reg_writeE <= 0;      
            branchE <= 0;          
            jumpE <= 0;
            jalrE <= 0;            
            rdE <= 0;
            imm_extE <= 0;
            pcE <= 0;
            pc_plus_4E <= 0;
            rd1E <= 0;
            rd2E <= 0; 
            rs1E <= 0;
            rs2E <= 0;
            funct3E <= 0;  
        end
        else begin
            alu_controlE <= alu_controlD;
            mem_writeE <= mem_writeD;       
            result_srcE <= result_srcD; 
            alu_srcE <= alu_src;  
            reg_writeE <= reg_writeD;      
            branchE <= branchD;          
            jumpE <= jumpD;
            jalrE <= jalrD;            
            rdE <= rdD;
            imm_extE <= imm_extD;
            pcE <= pcD;
            pc_plus_4E <= pc_plus_4D;
            rd1E <= rd1;
            rd2E <= rd2;
            rs1E <= rs1D;
            rs2E <= rs2D;
            funct3E <= funct3D;
        end
    end
endmodule
