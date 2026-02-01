`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/25/2026 07:11:17 PM
// Design Name: 
// Module Name: alu
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


module alu(
    input  wire [31:0] src_a,      // Operand A
    input  wire [31:0] src_b,      // Operand B
    input  wire [5:0]  alu_control,// Control Signal
    output reg  [31:0] result,     // ALU Output
    output wire        zero_flag,  // For BEQ/BNE
    output wire        sign_flag   // For BLT/BGE
    );
    
    // ----------------------------------------------------------------------
    // 1. LOCAL PARAMETERS
    // ----------------------------------------------------------------------
    localparam ALU_ADD  = 6'b000001;
    localparam ALU_SUB  = 6'b000010;
    localparam ALU_AND  = 6'b001010;
    localparam ALU_OR   = 6'b001001;
    localparam ALU_XOR  = 6'b000110;
    localparam ALU_SLL  = 6'b000011;
    localparam ALU_SRL  = 6'b000111;
    localparam ALU_SRA  = 6'b001000;
    localparam ALU_SLT  = 6'b000100;
    localparam ALU_SLTU = 6'b000101;
    localparam ALU_COPY_B = 6'b010000;
    // Error Code (NOP)
    localparam ALU_NOP  = 6'b000000;
    
    // Internal signal for signed operations
    reg signed [31:0] signed_a;
    
    always @ (*) begin
        result = 32'b0; // Default
        signed_a = $signed(src_a); // Cast for SRA and SLT
        
        case(alu_control)
            // Arithmetic
            ALU_ADD: result = src_a + src_b;
            ALU_SUB: result = src_a - src_b;

            // Logic
            ALU_AND: result = src_a & src_b;
            ALU_OR:  result = src_a | src_b;
            ALU_XOR: result = src_a ^ src_b;

            // Shifts (Using bottom 5 bits of B)
            ALU_SLL: result = src_a << src_b[4:0];
            ALU_SRL: result = src_a >> src_b[4:0];
            ALU_SRA: result = signed_a >>> src_b[4:0]; // Arithmetic Shift

            // Comparisons
            // SLT: Checks signed comparison
            ALU_SLT: result = (signed_a < $signed(src_b)) ? 32'd1 : 32'd0;
            // SLTU: Checks unsigned comparison
            ALU_SLTU: result = (src_a < src_b) ? 32'd1 : 32'd0;

            // LUI Support (Pass Through)
            ALU_COPY_B: result = src_b;

            default: result = 32'b0;
        endcase    
    end
    
    // Flags for Branch Unit
    assign zero_flag = (result == 32'b0);
    assign sign_flag = result[31];  
    
    
endmodule
