`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2026 03:39:02 AM
// Design Name: 
// Module Name: Hazard_unit
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


module Hazard_unit(
    // Forwarding
    input wire [4:0] rs1E,
    input wire [4:0] rs2E,
    input wire [4:0] rdM,
    input wire reg_writeM,
    input wire [4:0] rdW,
    input wire reg_writeW,
    
    output reg [1:0] forward_AE,
    output reg [1:0] forward_BE,
    
    // Stalling
    input wire [4:0] rs1D,
    input wire [4:0] rs2D,
    input wire [4:0] rdE,
    input wire [1:0] result_srcE,
  
    output wire stall_F,
    output wire stall_D,
    output wire Flush_E,
    
    // Control Hazards
    input wire pc_srcE,
    output wire Flush_D
    );
    
    always @(*) begin
        if((rs1E == rdM)&& reg_writeM && (rs1E != 0))
            forward_AE = 2'b10;
        else if((rs1E == rdW) && reg_writeW && (rs1E != 0))
            forward_AE = 2'b01;
        else
            forward_AE = 2'b00;    
    end
    
    always @(*) begin
        if((rs2E == rdM)&& reg_writeM && (rs2E != 0))
            forward_BE = 2'b10;
        else if((rs2E == rdW) && reg_writeW && (rs2E != 0))
            forward_BE = 2'b01;
        else
            forward_BE = 2'b00;    
    end
    
    wire lw_stall;
    
    assign lw_stall = result_srcE[0] && ((rs1D == rdE) || (rs2D == rdE));
    assign {stall_F, stall_D} = {2{lw_stall}}; 
    assign Flush_E = lw_stall || pc_srcE;
    assign Flush_D = pc_srcE;
    
endmodule
