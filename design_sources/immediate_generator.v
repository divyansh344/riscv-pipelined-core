`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/25/2026 08:38:28 PM
// Design Name: 
// Module Name: immediate_generator
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

module immediate_generator(
    input  wire [31:0] instruction, // The full instruction code
    output reg  [31:0] imm_val      // The clean 32-bit immediate
    );

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case(opcode)
            // -----------------------------------------------------
            // I-TYPE (ADDI, LW, JALR, Shifts)
            // -----------------------------------------------------
            // Opcode 0010011 (Arith), 0000011 (Load), 1100111 (JALR)
            7'b0010011, 7'b0000011, 7'b1100111: begin 
                // Sign-extend bits [31:20]
                imm_val = {{20{instruction[31]}}, instruction[31:20]};
            end

            // -----------------------------------------------------
            // S-TYPE (Store Word/Byte/Half)
            // -----------------------------------------------------
            // Opcode 0100011
            7'b0100011: begin
                // Split: [31:25] and [11:7]
                imm_val = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            // -----------------------------------------------------
            // B-TYPE (Branches: BEQ, BNE, etc.)
            // -----------------------------------------------------
            // Opcode 1100011
            // Note: The LSB [0] is always 0 because addresses are multiples of 2.
            7'b1100011: begin
                imm_val = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end

            // -----------------------------------------------------
            // J-TYPE (JAL)
            // -----------------------------------------------------
            // Opcode 1101111
            7'b1101111: begin
                imm_val = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end

            // -----------------------------------------------------
            // U-TYPE (LUI, AUIPC)
            // -----------------------------------------------------
            // Opcode 0110111 (LUI), 0010111 (AUIPC)
            7'b0110111, 7'b0010111: begin
                // Shifts immediate to top 20 bits
                imm_val = {instruction[31:12], 12'b0};
            end

            default: imm_val = 32'b0;
        endcase
    end
endmodule
