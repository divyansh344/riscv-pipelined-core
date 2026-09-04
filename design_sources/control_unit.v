`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/24/2026 11:15:25 PM
// Design Name: 
// Module Name: control_unit
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


module control_unit(
    
    input wire rst,
    
    // Instruction Fields
    input wire [6:0] funct7,    // Instruction [31:25] - Distinguishes ADD/SUB, SRA/SRL
    input wire [2:0] funct3,    // Instruction [14:12] - Distinguishes ADD/SLT/OR etc.
    input wire [6:0] opcode,    // Instruction [6:0]   - Main Opcode
    
    // Control Signals
    output reg [5:0] alu_control,// Internal code for ALU operation
    output reg mem_write,       // Write Enable for Data Memory (1 for Stores)
    output reg [1:0] result_src, // Mux Select: 0=ALU Result, 1=Memory Data (for Loads), 2 = pc_plus_4(for Jump)
    output reg alu_src,         // Mux Select: 0=Register B, 1=Immediate
    output reg reg_write,       // Write Enable for Register File (1 for R-Type, I-Type, Loads)
    output reg branch,          // 1 if this is a Conditional Branch (BEQ, BNE, etc.)
    output reg jump,
    output reg jalr,
    output reg auipc            // 1 for AUIPC: routes PC as ALU src_A instead of register
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
    
    // ----------------------------------------------------------------------
    // 2. MAIN DECODER LOGIC
    // ----------------------------------------------------------------------
    always @ (*) begin
        // Default Assignments (Prevents Latches)
        alu_control = 6'b0;
        mem_write = 0;
        result_src = 2'b00;
        alu_src = 0;
        reg_write = 0;
        branch = 0;
        jump = 0;
        jalr = 0;
        auipc = 0;
                
        if(rst) begin
            alu_control = ALU_NOP;
            reg_write   = 0;
            mem_write   = 0;
            auipc       = 0;
        end
        
        else begin 
        
            // ---------------------------------------------
            // R-TYPE INSTRUCTIONS (ADD, SUB, SLL, etc.)
            // Opcode: 0110011
            // ---------------------------------------------         
            if(opcode == 7'b0110011) begin
                reg_write = 1;
                result_src = 2'b00;
                alu_src = 0; // Use Register B
                case(funct3)
                3'b000: begin
                    if      (funct7 == 7'h00) alu_control = ALU_ADD; // ADD
                    else if (funct7 == 7'h20) alu_control = ALU_SUB; // SUB
                    else                      alu_control = ALU_NOP;      // Illegal -> NOP
                end
                3'b001: alu_control = (funct7 == 7'h00) ? ALU_SLL : ALU_NOP; // SLL
                3'b010: alu_control = (funct7 == 7'h00) ? ALU_SLT : ALU_NOP; // SLT
                3'b011: alu_control = (funct7 == 7'h00) ? ALU_SLTU : ALU_NOP; // SLTU
                3'b100: alu_control = (funct7 == 7'h00) ? ALU_XOR : ALU_NOP; // XOR
                3'b101: begin
                    if      (funct7 == 7'h00) alu_control = ALU_SRL; // SRL
                    else if (funct7 == 7'h20) alu_control = ALU_SRA; // SRA
                    else                      alu_control = ALU_NOP;      // Illegal
                end
                3'b110: alu_control = (funct7 == 7'h00) ? ALU_OR : ALU_NOP; // OR
                3'b111: alu_control = (funct7 == 7'h00) ? ALU_AND : ALU_NOP; // AND
                default: alu_control = ALU_NOP;
                endcase 
            end
            
            // ---------------------------------------------
            // I-TYPE INSTRUCTIONS (ADDI, XORI, etc.)
            // Opcode: 0010011
            // ---------------------------------------------
            else if(opcode == 7'b001_0011) begin     
                reg_write = 1;
                result_src = 2'b00;
                alu_src = 1; // Use Immediate
                case(funct3)
                3'b000: alu_control = ALU_ADD; // ADDI
                3'b001: alu_control = (funct7 == 7'h00) ? ALU_SLL : ALU_NOP; // SLLI
                3'b010: alu_control = ALU_SLT; // SLTI
                3'b011: alu_control = ALU_SLTU; // SLTIU
                3'b100: alu_control = ALU_XOR; // XORI
                3'b101: begin
                    if      (funct7 == 7'h00) alu_control = ALU_SRL; // SRLI
                    else if (funct7 == 7'h20) alu_control = ALU_SRA; // SRAI
                    else                      alu_control = ALU_NOP;      // Illegal
                end
                3'b110: alu_control = ALU_OR; // ORI
                3'b111: alu_control = ALU_AND; // ANDI
                default: alu_control = ALU_NOP;
                endcase 
            end
            
            // ---------------------------------------------
            // LOAD INSTRUCTIONS (LB, LW, etc.)
            // Opcode: 0000011
            // ---------------------------------------------
            else if(opcode == 7'b000_0011) begin  
                reg_write = 1;
                result_src = 2'b01;
                alu_src = 1; // Use Immediate (Offset)
                alu_control = ALU_ADD; // ALU performs ADD for address calculation 
            end
            
            // ---------------------------------------------
            // STORE INSTRUCTIONS (SB, SW, etc.)
            // Opcode: 0100011
            // ---------------------------------------------
            else if(opcode == 7'b0100_011) begin    
                mem_write = 1;
                alu_src = 1; // Use Immediate (Offset)
                reg_write = 0;
                alu_control = ALU_ADD; // ALU performs ADD for address calculation 
            end
            
            // ---------------------------------------------
            // BRANCH INSTRUCTIONS (BEQ, BNE, etc.)
            // Opcode: 1100011
            // ---------------------------------------------
            else if(opcode == 7'b110_0011) begin 
                branch = 1;
                alu_src = 0;    // Compare two registers
                reg_write = 0;
                alu_control = ALU_SUB;     
            end
            
            // ---------------------------------------------
            // LUI (Load Upper Immediate)
            // Opcode: 0110111
            // ---------------------------------------------
            else if(opcode == 7'b011_0111) begin
                reg_write = 1;
                alu_src = 1;
                alu_control = ALU_COPY_B; // Pass Immediate  
            end
            
            // ---------------------------------------------
            // AUIPC (Add Upper Immediate to PC)
            // Opcode: 0010111
            // ---------------------------------------------
            else if(opcode == 7'b001_0111) begin
                reg_write   = 1;
                alu_src     = 1;       // Use immediate as src_B
                alu_control = ALU_ADD; // ALU computes PC + imm
                auipc       = 1;       // Signal datapath to use PC as src_A
            end 
            
            // ---------------------------------------------
            // JAL (Jump and Link)
            // Opcode: 1101111
            // ---------------------------------------------          
            else if(opcode == 7'b110_1111) begin
                jump = 1;
                result_src = 2'b10;
                reg_write = 1;
                alu_control = ALU_NOP;
            end
            
            // ---------------------------------------------
            // JALR (Jump and Link Register)
            // Opcode: 1100111
            // ---------------------------------------------          
            else if(opcode == 7'b110_0111) begin
                jump = 1;
                jalr = 1;
                reg_write = 1;
                result_src = 2'b10;
                alu_src = 1; // Add Immediate to Register
                alu_control = ALU_ADD; // ALU ADD
            end

            // ---------------------------------------------
            // FENCE (opcode 0001111) — treated as NOP
            // In this in-order pipeline, ordering is already
            // guaranteed, so FENCE is a safe no-op.
            // All control signals remain at default (0).
            // ---------------------------------------------
            else if(opcode == 7'b000_1111) begin
                // NOP: reg_write=0, mem_write=0, branch=0, jump=0
                // alu_control=ALU_NOP (default 0)
            end

            // ---------------------------------------------
            // ECALL / EBREAK (opcode 1110011) — treated as NOP
            // funct3=000 for both; funct12 distinguishes them.
            // In a bare-metal core without OS, both are safe NOPs.
            // A future privilege unit can intercept these.
            // All control signals remain at default (0).
            // ---------------------------------------------
            else if(opcode == 7'b111_0011) begin
                // NOP: reg_write=0, mem_write=0, branch=0, jump=0
            end

        end
    end
endmodule
