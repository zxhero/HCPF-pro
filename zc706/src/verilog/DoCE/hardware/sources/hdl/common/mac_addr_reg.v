/*
 * MAC address register module with AXI-Lite slave interface
 * 
 * Module name: mac_addr_reg
 * Author: Yisong Chang (changyisong@ict.ac.cn)
 * Date: 2017.02.09
 *===========================================================================
 */

`timescale 1ns/1ps

  module mac_addr_reg (
	input wire			axi_lite_aclk,
	input wire			axi_lite_aresetn,
	
	//AXI-Lite Interface
	input wire			s_axi_lite_awvalid,
	input wire [31:0]	s_axi_lite_awaddr,
	output reg			s_axi_lite_awready,
	
	input wire			s_axi_lite_wvalid,
	input wire [31:0]	s_axi_lite_wdata,
	input wire [3:0]	s_axi_lite_wstrb,
	output reg			s_axi_lite_wready,

	output reg			s_axi_lite_bvalid,
	output reg [1:0]	s_axi_lite_bresp,
	input wire			s_axi_lite_bready,

	input wire			s_axi_lite_arvalid,
	input wire [31:0]	s_axi_lite_araddr,
	output reg			s_axi_lite_arready,

	output reg			s_axi_lite_rvalid,
	output reg [31:0]	s_axi_lite_rdata,
	output reg [1:0]	s_axi_lite_rresp,
	input wire			s_axi_lite_rready,

	//output MAC address for each DoCE system component
	output wire [47:0]	host_mac_id,
	output wire [47:0]	dev_mac_id,
	output wire [47:0]	doce_mac_id,
	output reg [31:0]	doce_ip_addr
);

//MMIO register selection mask
	localparam [6:0]	REG_NO_SEL				= 7'b0000000,
						HOST_MAC_ADDR_BASE_SEL	= 7'b0000001,
						HOST_MAC_ADDR_HIGH_SEL	= 7'b0000010,
						DEV_MAC_ADDR_BASE_SEL	= 7'b0000100,
						DEV_MAC_ADDR_HIGH_SEL	= 7'b0001000,
						DOCE_MAC_ADDR_BASE_SEL	= 7'b0010000,
						DOCE_MAC_ADDR_HIGH_SEL	= 7'b0100000,
						DOCE_IP_ADDR_SEL		= 7'b1000000;

//Internal signals
	reg [6:0]			mmio_reg_wr_sel;
	wire				mmio_reg_wr_en;

	reg [31:0]			mmio_reg_rd_val;
	wire				mmio_reg_rd_en;

	reg [31:0]			host_mac_addr_base;	
	reg [31:0]			host_mac_addr_high;	
	reg [31:0]			dev_mac_addr_base;	
	reg [31:0]			dev_mac_addr_high;	
	reg [31:0]			doce_mac_addr_base;	
	reg [31:0]			doce_mac_addr_high;	

/* 
 * ======================================================================
 * AXI4-lite Interface basic logic
 * ======================================================================
 */

/* AW channel */
  always @ (posedge axi_lite_aclk)
  begin
	  if( axi_lite_aresetn == 1'b0 )
		  s_axi_lite_awready <= 1'b0;
	 
	  //capturing write address and write data of AXI-Lite IF at the same time
	  //when both channels are valid
	  else if( ~s_axi_lite_awready & s_axi_lite_awvalid & s_axi_lite_wvalid )
		  s_axi_lite_awready <= 1'b1;
	 
	  //maintaining handshake of awvalid and awready for one cycle
	  else
		  s_axi_lite_awready <= 1'b0;
  end

/* W channel */
  always @ (posedge axi_lite_aclk)
  begin
	  if( axi_lite_aresetn == 1'b0 )
		  s_axi_lite_wready <= 1'b0;
	  
	  //capturing write address and write data of AXI-Lite IF at the same time
	  //when both channels are valid
	  else if( ~s_axi_lite_wready & s_axi_lite_awvalid & s_axi_lite_wvalid )
		  s_axi_lite_wready <= 1'b1;
	  
	  else
		  s_axi_lite_wready <= 1'b0;
  end
  
  assign mmio_reg_wr_en = s_axi_lite_awvalid & s_axi_lite_wvalid;

  //write address decoder
  always @ (s_axi_lite_awaddr[4:2])
  begin
	  case (s_axi_lite_awaddr[4:2])
		  3'd0: mmio_reg_wr_sel = HOST_MAC_ADDR_BASE_SEL;
		  3'd1: mmio_reg_wr_sel = HOST_MAC_ADDR_HIGH_SEL;
		  3'd2: mmio_reg_wr_sel = DEV_MAC_ADDR_BASE_SEL;
		  3'd3: mmio_reg_wr_sel = DEV_MAC_ADDR_HIGH_SEL;
		  3'd4: mmio_reg_wr_sel = DOCE_MAC_ADDR_BASE_SEL;
		  3'd5: mmio_reg_wr_sel = DOCE_MAC_ADDR_HIGH_SEL;
		  3'd6: mmio_reg_wr_sel = DOCE_IP_ADDR_SEL;
		  default: mmio_reg_wr_sel = REG_NO_SEL;
	  endcase
  end

/* B channel */
  always @ (posedge axi_lite_aclk)
  begin
	  if (axi_lite_aresetn == 1'b0)
	  begin
		  s_axi_lite_bvalid <= 1'b0;
		  s_axi_lite_bresp <= 2'b0;
	  end
	  
	  else if ( ~s_axi_lite_bvalid & mmio_reg_wr_en & s_axi_lite_awready & s_axi_lite_wready )
	  begin
		  s_axi_lite_bvalid <= 1'b1;
		  s_axi_lite_bresp <= 2'b0;
	  end
	  
	  else if (s_axi_lite_bvalid & s_axi_lite_bready)
	  begin
		  s_axi_lite_bvalid <= 1'b0;
		  s_axi_lite_bresp <= 2'b0;
	  end
	  
	  else
	  begin
		  s_axi_lite_bvalid <= s_axi_lite_bvalid;
		  s_axi_lite_bresp <= s_axi_lite_bresp;
	  end
  end

/* AR channel */
  always @ (posedge axi_lite_aclk)
  begin
	  if (axi_lite_aresetn == 1'b0)
		  s_axi_lite_arready <= 1'b0;
	  
	  //capturing read address and maintaining arready valid for one cycle
	  else if (~s_axi_lite_arready & s_axi_lite_arvalid)
		  s_axi_lite_arready <= 1'b1;
	  
	  else
		  s_axi_lite_arready <= 1'b0;
  end

  //read address decoder
  always @ (s_axi_lite_araddr[4:2])
  begin
	  case (s_axi_lite_araddr[4:2])
		  3'd0: mmio_reg_rd_val = host_mac_addr_base;
		  3'd1: mmio_reg_rd_val = host_mac_addr_high;
		  3'd2: mmio_reg_rd_val = dev_mac_addr_base; 
		  3'd3: mmio_reg_rd_val = dev_mac_addr_high; 
		  3'd4: mmio_reg_rd_val = doce_mac_addr_base;
		  3'd5: mmio_reg_rd_val = doce_mac_addr_high;
		  3'd6: mmio_reg_rd_val = doce_ip_addr;
		  default: mmio_reg_rd_val = 'd0;
	  endcase
  end

/* R channel */
  always @ (posedge axi_lite_aclk)
  begin
	  if ( axi_lite_aresetn == 1'b0 )
	  begin
		  s_axi_lite_rvalid <= 1'b0;
		  s_axi_lite_rresp <= 2'd0;
	  end
	 
	  //validating rvalid immidiately as the AR channel negotiation is finished
	  else if ( ~s_axi_lite_rvalid & s_axi_lite_arready & s_axi_lite_arvalid )
	  begin
		  s_axi_lite_rvalid <= 1'b1;
		  s_axi_lite_rresp <= 2'd0;
	  end
	 
	  //when the master end receiving the read data, invalidating rvalid signal
	  else if (s_axi_lite_rvalid & s_axi_lite_rready)
	  begin
		  s_axi_lite_rvalid <= 1'b0;
		  s_axi_lite_rresp <= 2'b0;
	  end
	  
	  else
	  begin
		  s_axi_lite_rvalid <= s_axi_lite_rvalid;
		  s_axi_lite_rresp <= s_axi_lite_rresp;
	  end
  end

  assign mmio_reg_rd_en = ~s_axi_lite_rvalid & s_axi_lite_arready & s_axi_lite_arvalid;

  always @ (posedge axi_lite_aclk)
  begin
	  if ( axi_lite_aresetn == 1'b0 )
		  s_axi_lite_rdata <= 32'd0;
	  
	  else if (mmio_reg_rd_en)
		  s_axi_lite_rdata <= mmio_reg_rd_val;
	  
	  else
		  s_axi_lite_rdata <= s_axi_lite_rdata;
  end

/* 
 * ======================================================================
 * MMIO registers 
 * ======================================================================
 */
 /*HOST_MAC_ADDR_BASE*/
 always @(posedge axi_lite_aclk)
 begin
	 if (axi_lite_aresetn == 1'b0)
		 host_mac_addr_base <= 'hDDCCBBAA;

	 else if ( mmio_reg_wr_en & mmio_reg_wr_sel[0] )
		 host_mac_addr_base <= s_axi_lite_wdata;

	 else
		 host_mac_addr_base <= host_mac_addr_base;
 end

 /*HOST_MAC_ADDR_HIGH*/
 always @(posedge axi_lite_aclk)
 begin
	 if (axi_lite_aresetn == 1'b0)
		 host_mac_addr_high <= 'h0000A0EE;

	 else if ( mmio_reg_wr_en & mmio_reg_wr_sel[1] )
		 host_mac_addr_high <= s_axi_lite_wdata;

	 else
		 host_mac_addr_high <= host_mac_addr_high;
 end

 /*DEV_MAC_ADDR_BASE*/
 always @(posedge axi_lite_aclk)
 begin
	 if (axi_lite_aresetn == 1'b0)
		 dev_mac_addr_base <= 'hDDCCBBAA;

	 else if ( mmio_reg_wr_en & mmio_reg_wr_sel[2] )
		 dev_mac_addr_base <= s_axi_lite_wdata;

	 else
		 dev_mac_addr_base <= dev_mac_addr_base;
 end

 /*DEV_MAC_ADDR_HIGH*/
 always @(posedge axi_lite_aclk)
 begin
	 if (axi_lite_aresetn == 1'b0)
		 dev_mac_addr_high <= 'h0000B0EE;

	 else if ( mmio_reg_wr_en & mmio_reg_wr_sel[3] )
		 dev_mac_addr_high <= s_axi_lite_wdata;

	 else
		 dev_mac_addr_high <= dev_mac_addr_high;
 end
 
 /*DOCE_MAC_ADDR_BASE*/
 always @(posedge axi_lite_aclk)
 begin
	 if (axi_lite_aresetn == 1'b0)
		 doce_mac_addr_base <= 'hDDCCBBAA;

	 else if ( mmio_reg_wr_en & mmio_reg_wr_sel[4] )
		 doce_mac_addr_base <= s_axi_lite_wdata;

	 else
		 doce_mac_addr_base <= doce_mac_addr_base;
 end

 /*DOCE_MAC_ADDR_HIGH*/
 always @(posedge axi_lite_aclk)
 begin
	 if (axi_lite_aresetn == 1'b0)
		 doce_mac_addr_high <= 'h0000C0EE;

	 else if ( mmio_reg_wr_en & mmio_reg_wr_sel[5] )
		 doce_mac_addr_high <= s_axi_lite_wdata;

	 else
		 doce_mac_addr_high <= doce_mac_addr_high;
 end

 /*DOCE_IP_ADDR*/
 always @(posedge axi_lite_aclk)
 begin
	 if (axi_lite_aresetn == 1'b0)
		 doce_ip_addr <= 32'h01010101;

	 else if ( mmio_reg_wr_en & mmio_reg_wr_sel[6] )
		 doce_ip_addr <= s_axi_lite_wdata;

	 else
		 doce_ip_addr <= doce_ip_addr;
 end

 assign host_mac_id = {host_mac_addr_high[15:0], host_mac_addr_base}; 

 assign dev_mac_id = {dev_mac_addr_high[15:0], dev_mac_addr_base}; 

 assign doce_mac_id = {doce_mac_addr_high[15:0], doce_mac_addr_base}; 

endmodule

