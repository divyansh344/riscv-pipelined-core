`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2026 01:41:53 AM
// Design Name: 
// Module Name: data_path
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


module data_path(
    input  wire        clk,
    input  wire        rst,
    
    // ----------------------------------------------------------------------
    // Interface to Instruction Memory
    // ----------------------------------------------------------------------
    output wire [31:0] pc_out,          // Current PC -> Goes to Instruction Memory
    input  wire [31:0] instr_in,        // Instruction <- Comes from Instruction Memory
    
    // ----------------------------------------------------------------------
    // Interface to Data Memory
    // ----------------------------------------------------------------------
    output wire [31:0] data_mem_addr,   // Address -> Goes to Data Memory
    output wire [31:0] data_mem_wdata,  // Write Data -> Goes to Data Memory
    input  wire [31:0] data_mem_rdata,  // Read Data <- Comes from Data Memory
    output wire        mem_write       // Control Signal -> Goes to Data Memory
    );

    // ======================================================================
    // INTERNAL WIRES
    // ======================================================================
    
    // Control Unit Signals
    wire [5:0] alu_control;
    wire       reg_write;
    wire       alu_src;
    wire       [1:0] result_src;
    wire       branch;
    wire       jump;
    wire       jalr;
    
    // Datapath Wires
    wire [31:0] pc_plus_4;
    wire [31:0] imm_val;
    wire [31:0] reg_rdata1;
    wire [31:0] reg_rdata2;
    wire [31:0] alu_result;
    wire [31:0] src_AE, src_BE;
    wire pc_srcE;
    wire [31:0] pc_targetE;
    reg  [31:0] write_back_data;// Data to be written to Register File

    
    // Branch Unit Signals
    wire        zero_flag;
    wire        sign_flag;
    wire        branch_taken;
       
    // Pipeline Wires
    // 1. Fetch->Decode
    wire [31:0] instrD, pc_plus_4D, pcD;
    // 2. Decode->Execute
    wire reg_writeE, mem_writeE, jumpE, jalrE, branchE, alu_srcE;
    wire [1:0] result_srcE;
    wire [5:0] alu_controlE;
    wire [31:0] rd1E, rd2E, pcE, imm_extE, pc_plus_4E;
    wire [4:0] rs1E, rs2E, rdE;
    wire [2:0] funct3E;
    // 3. Execute->Memory
    wire reg_writeM, mem_writeM;
    wire [1:0] result_srcM;
    wire [31:0] write_dataE, alu_resultM, write_dataM, pc_plus_4M;
    wire [4:0] rdM;
    // 4. Memory->Writeback
    wire reg_writeW;
    wire [1:0] result_srcW;
    wire [31:0] alu_result_out, read_dataW, pc_plus_4W;
    wire [4:0] rdW;
    // Hazard Unit
    wire stall_F, stall_D, Flush_D, Flush_E;
    wire [1:0] forward_AE, forward_BE;
  
    // ======================================================================
    // MODULE INSTANTIATIONS
    // ======================================================================
    
    // Datapath Units
    
    // 1. CONTROL UNIT
    control_unit ctrl_unit (
        .rst(rst),
        .opcode(instrD[6:0]),
        .funct3(instrD[14:12]),
        .funct7(instrD[31:25]),
        .alu_control(alu_control),
        .mem_write(mem_write),
        .result_src(result_src),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .branch(branch),
        .jump(jump),
        .jalr(jalr)
    );

    // 2. IMMEDIATE GENERATOR
    immediate_generator imm_gen (
        .instruction(instrD),
        .imm_val(imm_val)
    );

    // 3. REGISTER FILE
    register_file reg_file (
        .clk(clk),
        .rst(rst),
        .reg_write_en(reg_writeW),
        .read_addr1(instrD[19:15]), // rs1
        .read_addr2(instrD[24:20]), // rs2
        .write_addr(rdW),  // rd
        .write_data(write_back_data), // From Writeback Mux
        .read_data1(reg_rdata1),
        .read_data2(reg_rdata2)
    );

    // 4. ALU SOURCE MUX (Selects between Register B and Immediate)
    assign src_BE = (alu_srcE) ? imm_extE : write_dataE;
    
    // 5. ALU
    alu my_alu (
        .src_a(src_AE),
        .src_b(src_BE),
        .alu_control(alu_controlE),
        .result(alu_result),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag)
    );

    // 6. BRANCH UNIT
    branch_unit br_unit (
        .branch(branchE),
        .funct3(funct3E),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag),
        .branch_taken(branch_taken)
    );

    // 7. INSTRUCTION FETCH UNIT
    instruction_fetch_unit fetch_unit (
        .clk(clk),
        .rst(rst),
        .en(~stall_F),
        .pc_target(pc_targetE),
        .pc_src(pc_srcE),
        .pc(pc_out),
        .pc_plus_4(pc_plus_4)
    );
    
    // Pipeline Registers
    
    // 1. Fetch->Decode
    IF_ID_REG R1(
    .clk(clk),
    .rst(rst),
    .en(~stall_D),
    .clr(Flush_D),
    
    .instruction_in(instr_in),
    .pcF(pc_out),
    .pc_plus_4F(pc_plus_4),
    
    .instrD(instrD),
    .pcD(pcD),
    .pc_plus_4D(pc_plus_4D)
    );
    
    // 2. Decode->Execute
    ID_EX_REG R2(
    .clk(clk),
    .rst(rst),
    .clr(Flush_E),
    
    
    .alu_controlD(alu_control),
    .mem_writeD(mem_write),       
    .result_srcD(result_src),
    .alu_src(alu_src),        
    .reg_writeD(reg_write),      
    .branchD(branch),         
    .jumpD(jump),
    .jalrD(jalr),           
    .rdD(instrD[11:7]),
    .imm_extD(imm_val),
    .pcD(pcD),
    .pc_plus_4D(pc_plus_4D),
    .rd1(reg_rdata1),
    .rd2(reg_rdata2),
    .rs1D(instrD[19:15]),
    .rs2D(instrD[24:20]),
    .funct3D(instrD[14:12]),
    
    .alu_controlE(alu_controlE),
    .mem_writeE(mem_writeE),       
    .result_srcE(result_srcE), 
    .alu_srcE(alu_srcE),  
    .reg_writeE(reg_writeE),      
    .branchE(branchE),          
    .jumpE(jumpE),
    .jalrE(jalrE),            
    .rdE(rdE),
    .imm_extE(imm_extE),
    .pcE(pcE),
    .pc_plus_4E(pc_plus_4E),
    .rd1E(rd1E),
    .rd2E(rd2E),
    .rs1E(rs1E),
    .rs2E(rs2E),
    .funct3E(funct3E)
    );
    
    // 3. Execute->Memory
    EX_MEM_REG R3(
    .clk(clk),
    .rst(rst),
    
    .reg_writeE(reg_writeE),
    .result_srcE(result_srcE),
    .mem_writeE(mem_writeE),
    .alu_result(alu_result),
    .write_dataE(write_dataE),
    .rdE(rdE),
    .pc_plus_4E(pc_plus_4E),
    
    .reg_writeM(reg_writeM),
    .result_srcM(result_srcM),
    .mem_writeM(mem_writeM),
    .alu_resultM(alu_resultM),
    .write_dataM(write_dataM),
    .rdM(rdM),
    .pc_plus_4M(pc_plus_4M)
    );
    
    // 4. Memory->Writeback
    MEM_WB_REG R4(
    .clk(clk),
    .rst(rst),
    
    .reg_writeM(reg_writeM),
    .result_srcM(result_srcM),
    .alu_resultM(alu_resultM),
    .rd(data_mem_rdata),
    .rdM(rdM),
    .pc_plus_4M(pc_plus_4M),
    
    .reg_writeW(reg_writeW),
    .result_srcW(result_srcW),
    .alu_result_out(alu_result_out),
    .read_dataW(read_dataW),
    .rdW(rdW),
    .pc_plus_4W(pc_plus_4W)
    );
    
    // Hazard Unit
    Hazard_unit H1(
    // Forwarding
    .rs1E(rs1E),
    .rs2E(rs2E),
    .rdM(rdM),
    .reg_writeM(reg_writeM),
    .rdW(rdW),
    .reg_writeW(reg_writeW),
    
    .forward_AE(forward_AE),
    .forward_BE(forward_BE),
    
    // Stalling
    .rs1D(instrD[19:15]),
    .rs2D(instrD[24:20]),
    .rdE(rdE),
    .result_srcE(result_srcE),
  
    .stall_F(stall_F),
    .stall_D(stall_D),
    .Flush_E(Flush_E),
    
    // Control Hazards
    .pc_srcE(pc_srcE),
    .Flush_D(Flush_D)
    );
    
    // ======================================================================
    // Internal Units
    // ======================================================================
  
    assign pc_srcE = jumpE || branch_taken;
    assign pc_targetE = (jalrE) ? (src_AE + imm_extE):(pcE + imm_extE);
    assign src_AE =     (forward_AE == 2'b00)? rd1E:
                        (forward_AE == 2'b01)? write_back_data:
                        (forward_AE == 2'b10)? alu_resultM: 32'b0;
    
    assign write_dataE =(forward_BE == 2'b00)? rd2E:
                        (forward_BE == 2'b01)? write_back_data:
                        (forward_BE == 2'b10)? alu_resultM: 32'b0;
                                           
    // ======================================================================
    // OUTPUT ASSIGNMENTS & WRITEBACK LOGIC
    // ======================================================================
    
    // Data Memory Connections
    assign data_mem_addr  = alu_resultM;
    assign data_mem_wdata = write_dataM;
    
    // Writeback Mux (The 3-way Mux for Jumps, Loads, and ALU Ops)
    always @(*) begin
        case(result_srcW)
            2'b00: write_back_data = alu_result_out;
            2'b01: write_back_data = read_dataW;
            2'b10: write_back_data = pc_plus_4W;
            default: write_back_data = 32'b0;
        endcase   
    end
endmodule
