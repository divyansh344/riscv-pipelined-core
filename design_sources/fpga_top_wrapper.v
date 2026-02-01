`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2026 06:16:41 PM
// Design Name: 
// Module Name: fpga_top_wrapper
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


module fpga_top_wrapper(
    input  wire clk,      // 100 MHz Board Clock
    input  wire rst,      // Reset Button
    output wire [7:0] led // 8 LEDs
    );
    
    localparam TOGGLE_LIMIT = 25_00_000;
    
    reg [26:0] counter = 0;
    reg clk_divider_reg = 0; // Internal register
    wire clk_slow;
    
    // Xilinx Primitive: Global Clock Buffer
    // This tells Vivado: "Treat this logic signal as a real high-quality Clock"
    BUFG clk_buf (.I(clk_divider_reg), .O(clk_slow));

    always @(posedge clk) begin
        // Toggle every 50 million cycles (0.5 seconds ON, 0.5 seconds OFF)
        if (counter == TOGGLE_LIMIT-1) begin
            counter <= 0;
            clk_divider_reg <= ~clk_divider_reg;
        end else begin
            counter <= counter + 1;
        end
    end
    
    wire [31:0] cpu_data_out; // The data on the bus
    wire        cpu_write_en; // The 'mem_write' trigger

    top my_processor (
        .clk(clk_slow),        
        .rst(rst),
        .debug_data(cpu_data_out),
        .debug_valid(cpu_write_en)
    );
    
    reg [7:0] led_register;
    reg prev_value;

    // Use clk_slow to stay in sync with the processor
    always @(posedge clk_slow or posedge rst) begin
        if (rst) begin
            led_register <= 8'b0;
            prev_value <= 0;
        end
        else begin
            prev_value <= cpu_write_en;
            if (~cpu_write_en & prev_value) begin  
                led_register <= cpu_data_out[7:0]; 
            end
        end
    end

    assign led = led_register;
endmodule
