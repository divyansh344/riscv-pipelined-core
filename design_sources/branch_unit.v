`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2026 01:46:20 AM
// Design Name: 
// Module Name: branch_unit
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


module branch_unit(
    input  wire       branch,       // From Control Unit (Is this a Branch instruction?)
    input  wire [2:0] funct3,       // From Instruction [14:12] (BEQ vs BNE vs BLT)
    input  wire       zero_flag,    // From ALU (True if A - B == 0)
    input  wire       sign_flag,    // From ALU (True if Result is Negative)
    
    output reg        branch_taken  // Output to Fetch Unit (1 = Take Branch)
    );

    always @(*) begin
        branch_taken = 0; // Default: Don't branch

        if (branch) begin
            case(funct3)
                // BEQ (Branch if Equal) -> ALU zero_flag is High
                3'b000: branch_taken = zero_flag; 
                
                // BNE (Branch if Not Equal) -> ALU zero_flag is Low
                3'b001: branch_taken = ~zero_flag;
                
                // BLT (Branch Less Than) -> Result is Negative (sign_flag is High)
                3'b100: branch_taken = sign_flag;
                
                // BGE (Branch Greater/Equal) -> Result is Positive (sign_flag is Low)
                3'b101: branch_taken = ~sign_flag;

                // BLTU/BGEU (Unsigned) would need a Carry Flag, 
                // but for this version, we default to 0.
                default: branch_taken = 0;
            endcase
        end
    end
endmodule
