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
    input  wire [31:0] src_a,       // Register source A
    input  wire [31:0] src_b,       // Register source B
    
    output reg        branch_taken  // Output to Fetch Unit (1 = Take Branch)
    );

    always @(*) begin
        branch_taken = 0; // Default: Don't branch

        if (branch) begin
            case(funct3)
                // BEQ (Branch if Equal)
                3'b000: branch_taken = (src_a == src_b);

                // BNE (Branch if Not Equal)
                3'b001: branch_taken = (src_a != src_b);

                // BLT (Branch Less Than - Signed)
                3'b100: branch_taken = ($signed(src_a) < $signed(src_b));

                // BGE (Branch Greater/Equal - Signed)
                3'b101: branch_taken = ($signed(src_a) >= $signed(src_b));

                // BLTU (Branch Less Than - Unsigned)
                3'b110: branch_taken = (src_a < src_b);

                // BGEU (Branch Greater/Equal - Unsigned)
                3'b111: branch_taken = (src_a >= src_b);

                default: branch_taken = 0;
            endcase
        end
    end
endmodule
