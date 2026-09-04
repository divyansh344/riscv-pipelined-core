`timescale 1 ns / 1 ps

module RV32I_Core_v1_0_S00_AXI #
(
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // CUSTOMIZED: Changed from 4 to 14 to support up to 0x2FFF (16 KB)
    parameter integer C_S_AXI_ADDR_WIDTH	= 14
)
(
    // 1. CPU Reset Control
    output wire        cpu_rst_out,
    
    // 2. Instruction Memory (AXI Write)
    output wire        imem_we_out,
    output wire [9:0]  imem_waddr_out,
    output wire [31:0] imem_wdata_out,
    
    // 3. Data Memory (AXI Read / Write)
    output wire [9:0]  dmem_raddr_out,
    input  wire [31:0] dmem_rdata_in,
    output wire        dmem_we_out,
    output wire [9:0]  dmem_waddr_out,
    output wire [31:0] dmem_wdata_out,

    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY
);

// AXI4LITE signals
reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
reg  	axi_awready;
reg  	axi_wready;
reg [1 : 0] 	axi_bresp;
reg  	axi_bvalid;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
reg  	axi_arready;
reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
reg [1 : 0] 	axi_rresp;
reg  	axi_rvalid;

localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 1;

wire	 slv_reg_wren;
wire	 slv_reg_rden;
reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
reg	 aw_en;

// Single control register for Reset
reg [31:0] cpu_control_reg;
assign cpu_rst_out = cpu_control_reg[0];

// Address Decoding
// axi_awaddr[13:12] == 2'b00 -> 0x0000 (IMEM)
// axi_awaddr[13:12] == 2'b01 -> 0x1000 (DMEM)
// axi_awaddr[13:12] == 2'b10 -> 0x2000 (Control Reg)
wire is_imem_write = (axi_awaddr[13:12] == 2'b00);
wire is_dmem_write = (axi_awaddr[13:12] == 2'b01);
wire is_ctrl_write = (axi_awaddr[13:12] == 2'b10);

wire is_dmem_read  = (axi_araddr[13:12] == 2'b01);
wire is_ctrl_read  = (axi_araddr[13:12] == 2'b10);

assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

// Wire up the custom output ports
assign imem_we_out    = slv_reg_wren && is_imem_write;
assign imem_waddr_out = axi_awaddr[11:2];
assign imem_wdata_out = S_AXI_WDATA;

assign dmem_we_out    = slv_reg_wren && is_dmem_write;
assign dmem_waddr_out = axi_awaddr[11:2];
assign dmem_wdata_out = S_AXI_WDATA;

assign dmem_raddr_out = axi_araddr[11:2];

// I/O Connections assignments
assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	    = axi_wready;
assign S_AXI_BRESP	    = axi_bresp;
assign S_AXI_BVALID	    = axi_bvalid;
assign S_AXI_ARREADY	= axi_arready;
assign S_AXI_RDATA	    = axi_rdata;
assign S_AXI_RRESP	    = axi_rresp;
assign S_AXI_RVALID	    = axi_rvalid;

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_awready <= 1'b0;
      aw_en <= 1'b1;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          axi_awready <= 1'b1;
          aw_en <= 1'b0;
        end
        else if (S_AXI_BREADY && axi_bvalid)
            begin
              aw_en <= 1'b1;
              axi_awready <= 1'b0;
            end
      else           
        begin
          axi_awready <= 1'b0;
        end
    end 
end       

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_awaddr <= 0;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          axi_awaddr <= S_AXI_AWADDR;
        end
    end 
end       

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_wready <= 1'b0;
    end 
  else
    begin    
      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
        begin
          axi_wready <= 1'b1;
        end
      else
        begin
          axi_wready <= 1'b0;
        end
    end 
end       

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      // Hold CPU in reset automatically when AXI powers up
      cpu_control_reg <= 32'd1; 
    end 
  else begin
    if (slv_reg_wren && is_ctrl_write)
      begin
        cpu_control_reg <= S_AXI_WDATA;
      end
  end
end    

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_bvalid  <= 0;
      axi_bresp   <= 2'b0;
    end 
  else
    begin    
      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
        begin
          axi_bvalid <= 1'b1;
          axi_bresp  <= 2'b0; 
        end                   
      else
        begin
          if (S_AXI_BREADY && axi_bvalid) 
            begin
              axi_bvalid <= 1'b0; 
            end  
        end
    end
end   

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_arready <= 1'b0;
      axi_araddr  <= 32'b0;
    end 
  else
    begin    
      if (~axi_arready && S_AXI_ARVALID)
        begin
          axi_arready <= 1'b1;
          axi_araddr  <= S_AXI_ARADDR;
        end
      else
        begin
          axi_arready <= 1'b0;
        end
    end 
end       

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_rvalid <= 0;
      axi_rresp  <= 0;
    end 
  else
    begin    
      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
        begin
          axi_rvalid <= 1'b1;
          axi_rresp  <= 2'b0; 
        end   
      else if (axi_rvalid && S_AXI_RREADY)
        begin
          axi_rvalid <= 1'b0;
        end                
    end
end    

// CUSTOM READ LOGIC (Reads from DMEM or Control Reg) 
always @(*)
begin
    if (is_ctrl_read) begin
        reg_data_out = cpu_control_reg;
    end else if (is_dmem_read) begin
        reg_data_out = dmem_rdata_in;
    end else begin
        reg_data_out = 32'b0;
    end
end

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_rdata  <= 0;
    end 
  else
    begin    
      if (slv_reg_rden)
        begin
          axi_rdata <= reg_data_out;
        end   
    end
end    

endmodule
