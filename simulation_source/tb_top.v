`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2026 08:55:09 PM
// Design Name: 
// Module Name: tb_top
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


module tb_top;

    reg clk;
    reg rst;

    wire [31:0] cpu_data_out;
    wire cpu_write_en;

    top uut (
        .clk(clk),
        .rst(rst),
        .debug_data(cpu_data_out),
        .debug_valid(cpu_write_en)
    );

    always #5 clk = ~clk;

    initial begin
        // Initialize Signals
        clk = 0;
        rst = 1;  // Assert Reset initially

        // Wait for 100ns and release reset
        #100;
        rst = 0;
        // Run simulation for enough time to see the Fibonacci sequence grow
        #5000;
        $stop; // Pauses simulation so you can check waveforms
    end

endmodule
