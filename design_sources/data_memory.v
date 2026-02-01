`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2026 01:31:06 AM
// Design Name: 
// Module Name: data_memory
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


module data_memory(
    input  wire        clk,
    input  wire        rst,
    
    // Control Signals
    input  wire        mem_write,  // 1 = Write Data (Store)    
    // Data Paths
    input  wire [31:0] mem_addr,   // Calculated by ALU (e.g., Base + Offset)
    input  wire [31:0] write_data, // Data to be stored (from Register File rs2)
    
    output wire [31:0] read_data    // Output Data
    );

    // 1. MEMORY ARRAY
    // 128 words (addressable range 0 to 511 bytes)
    reg [31:0] ram [0:127];
    
    integer i;

    // 2. WRITE LOGIC (Synchronous)
    always @(posedge clk) begin
        if (rst) begin
            // Clear memory
            for(i=0; i<128; i=i+1) ram[i] <= 32'b0;
        end
        else if (mem_write) begin
            // Only write on clock edge if Write Enable is High
            // Indexing: Drop bottom 2 bits to convert Byte Addr -> Word Index
            ram[mem_addr[8:2]] <= write_data;
        end
    end

    // 3. READ LOGIC (Combinational / Asynchronous)
    assign read_data = ram[mem_addr[8:2]];

endmodule
