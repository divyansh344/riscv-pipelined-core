`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/25/2026 08:19:12 PM
// Design Name: 
// Module Name: register_file
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


module register_file( 
    input  wire        clk,
    input  wire        rst,
    
    // Control Signals
    input  wire        reg_write_en,  // "reg_write" from Control Unit
    
    // Address Inputs (5 bits for 32 registers)
    input  wire [4:0]  read_addr1,    // rs1 (Source Register 1)
    input  wire [4:0]  read_addr2,    // rs2 (Source Register 2)
    input  wire [4:0]  write_addr,    // rd  (Destination Register)
    
    // Data I/O
    input  wire [31:0] write_data,    // Result from ALU or Memory
    output wire [31:0] read_data1,    // Value of rs1
    output wire [31:0] read_data2     // Value of rs2
    );
    
    // ----------------------------------------------------------------------
    // 1. MEMORY ARRAY DECLARATION
    // ----------------------------------------------------------------------
    // 32 registers, each 32 bits wide.
    reg [31:0] registers [31:0]; 
    
    integer i; // Used for looping in Reset
    
    // ----------------------------------------------------------------------
    // 2. WRITE LOGIC (Synchronous)
    // ----------------------------------------------------------------------
    // Writes only happen on the Falling Edge of the Clock.
    always @(negedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end
        else if (reg_write_en && (write_addr != 5'b00000)) begin
            registers[write_addr] <= write_data;
        end
    end
    
    // ----------------------------------------------------------------------
    // 3. READ LOGIC (Asynchronous / Combinational)
    // ----------------------------------------------------------------------
    // Reads happen immediately (no clock wait).
    // This allows the ALU to get data in the same cycle.
    
    // Read Port 1
    assign read_data1 = (read_addr1 == 5'b00000) ? 32'b0 : registers[read_addr1];

    // Read Port 2
    assign read_data2 = (read_addr2 == 5'b00000) ? 32'b0 : registers[read_addr2];
    
endmodule
