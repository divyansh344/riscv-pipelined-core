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
    // Forwarding (EX and MEM stage forwarding to ALU)
    input wire [4:0] rs1E,
    input wire [4:0] rs2E,
    input wire [4:0] rdM,
    input wire reg_writeM,
    input wire [4:0] rdW,
    input wire reg_writeW,
    
    output reg [1:0] forward_AE,
    output reg [1:0] forward_BE,
    
    // Stalling (Load-Use + Branch-RAW)
    input wire [4:0] rs1D,
    input wire [4:0] rs2D,
    input wire [4:0] rdE,
    input wire [1:0] result_srcE,
    // Branch stall inputs: detect when branch in ID depends on EX-stage result
    input wire        branchD,       // Is the instruction in ID a branch?
    input wire        reg_writeE,    // Does the instruction in EX write a register?
  
    output wire stall_F,
    output wire stall_D,
    output wire Flush_E,
    
    // Control Hazards
    input wire pc_srcE,
    output wire Flush_D
    );
    
    always @(*) begin
        if ((rs1E != 0) && reg_writeM && (rs1E == rdM))
            forward_AE = 2'b10;
        else if ((rs1E != 0) && reg_writeW && (rs1E == rdW))
            forward_AE = 2'b01;
        else
            forward_AE = 2'b00;
    end
    
    always @(*) begin
        if ((rs2E != 0) && reg_writeM && (rs2E == rdM))
            forward_BE = 2'b10;
        else if ((rs2E != 0) && reg_writeW && (rs2E == rdW))
            forward_BE = 2'b01;
        else
            forward_BE = 2'b00;
    end
    
    wire lw_stall;
    wire branch_stall;
    
    // Load-Use stall: LW result not available until end of MEM stage.
    // Stall 1 cycle so the load-use forwarding (MEM→EX, forward_AE/BE = 2'b01) can work.
    assign lw_stall = result_srcE[0] && (rdE != 0) && ((rs1D == rdE) || (rs2D == rdE));
    
    // Branch-EX stall: Branch is in ID, and the instruction currently in EX
    // will write to one of the branch's source registers.
    // The EX result is not yet available (still being computed), so we must stall
    // 1 cycle. After the stall, the result will be in MEM and can be forwarded
    // via the branch_src MEM→ID forwarding mux in datapath.v.
    assign branch_stall = branchD && reg_writeE && (rdE != 0) &&
                          ((rs1D == rdE) || (rs2D == rdE));
    
    assign {stall_F, stall_D} = {2{lw_stall | branch_stall}};
    assign Flush_E = lw_stall | branch_stall | pc_srcE;
    assign Flush_D = pc_srcE;
    
endmodule
