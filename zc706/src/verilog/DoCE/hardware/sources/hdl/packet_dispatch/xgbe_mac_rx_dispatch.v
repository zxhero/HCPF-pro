/* =====================================================================
* XGBE Rx packet dispatch to PCI DMA, AXI DMA and DoCE
*
* Author: Ran Zhao (zhaoran@ict.ac.cn)
* Date: 02/19/2017
* Version: v0.0.1
*=======================================================================
*/

`timescale 1ns / 1ps

module xgbe_mac_rx_dispatch (
	input				xgemac_clk_156,
	input				xgbe_mac_resetn,
	
	input [47:0]		dev_mac_addr,
	input [47:0]		doce_mac_addr,
	input [47:0]		host_mac_addr,
	
	input [63:0]		xgbe_mac_axis_rx_tdata,
	input [7:0]			xgbe_mac_axis_rx_tkeep,
	input				xgbe_mac_axis_rx_tlast,
	input				xgbe_mac_axis_rx_tvalid,
	output				xgbe_mac_axis_rx_tready,
	
	output [63:0]		xgbe_mac_to_axi_dma_tdata,
	output [7:0]		xgbe_mac_to_axi_dma_tkeep,
	output				xgbe_mac_to_axi_dma_tlast,
	output				xgbe_mac_to_axi_dma_tvalid,
	input				xgbe_mac_to_axi_dma_tready,
	output [2:0]		xgbe_mac_to_axi_dma_tdest,
	
	output [63:0]		xgbe_mac_to_doce_tdata,
	output [7:0]		xgbe_mac_to_doce_tkeep,
	output				xgbe_mac_to_doce_tlast,
	output				xgbe_mac_to_doce_tvalid,
	input				xgbe_mac_to_doce_tready,
	
	output [63:0]		xgbe_mac_to_pcie_dma_tdata,
	output [7:0]		xgbe_mac_to_pcie_dma_tkeep,
	output				xgbe_mac_to_pcie_dma_tlast,
	output				xgbe_mac_to_pcie_dma_tvalid,
	input				xgbe_mac_to_pcie_dma_tready,
	output [2:0]		xgbe_mac_to_pcie_dma_tdest
);

  localparam	DEV_TDEST = 3'b011,
				HOST_TDEST = 3'b001;

  reg			pkt_firstbeat;
  
  wire [47:0]	pkt_dest_mac;
  
  wire			pkt_dev;
  reg			pkt_dev_i;
  wire			pkt_dev_sel;
  
  wire			pkt_doce;
  reg			pkt_doce_i;
  wire			pkt_doce_sel;
  
  wire			pkt_host;
  reg			pkt_host_i;
  wire			pkt_host_sel;
  
  wire			pkt_broadcast;
  reg			pkt_broadcast_i;
  wire			pkt_broadcast_sel;
  
  reg			pkt_sel_mux;
  
  always @(posedge xgemac_clk_156)
  begin
	  if(!xgbe_mac_resetn)
		  pkt_firstbeat <= 1;
	  else if(xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_firstbeat <= xgbe_mac_axis_rx_tlast;
	  else
		  pkt_firstbeat <= pkt_firstbeat;
  end
  
  assign pkt_dest_mac = {48{pkt_firstbeat}} & xgbe_mac_axis_rx_tdata[47:0];
  
  assign pkt_dev = ~|(pkt_dest_mac ^ dev_mac_addr);
  assign pkt_doce = ~|(pkt_dest_mac ^ doce_mac_addr);
  assign pkt_host = ~|(pkt_dest_mac ^ host_mac_addr);
  assign pkt_broadcast = ~|(pkt_dest_mac ^ {48{1'b1}});
 
  always @(posedge xgemac_clk_156)
  begin
	  if (xgbe_mac_resetn == 1'b0)
		  pkt_dev_i <= 1'b0;
	  else if(~pkt_dev_i & xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_dev_i <= (~xgbe_mac_axis_rx_tlast) & pkt_dev;
	  else if(pkt_dev_i & xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_dev_i <= ~xgbe_mac_axis_rx_tlast;
	  else
		  pkt_dev_i <= pkt_dev_i;
  end
   
  always @(posedge xgemac_clk_156)
  begin
	  if (xgbe_mac_resetn == 1'b0)
		  pkt_doce_i <= 1'b0;
	  else if(~pkt_doce_i & xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_doce_i <= (~xgbe_mac_axis_rx_tlast) & pkt_doce;
	  else if(pkt_doce_i & xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_doce_i <= ~xgbe_mac_axis_rx_tlast;
	  else
		  pkt_doce_i <= pkt_doce_i;
  end
  
  always @(posedge xgemac_clk_156)
  begin
	  if (xgbe_mac_resetn == 1'b0)
		  pkt_host_i <= 1'b0;
	  else if(~pkt_host_i & xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_host_i <= (~xgbe_mac_axis_rx_tlast) & pkt_host;
	  else if(pkt_host_i & xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_host_i <= ~xgbe_mac_axis_rx_tlast;
	  else
		  pkt_host_i <= pkt_host_i;
  end
  
  always @(posedge xgemac_clk_156)
  begin
	  if (xgbe_mac_resetn == 1'b0)
		  pkt_broadcast_i <= 1'b0;
	  else if(~pkt_broadcast_i & xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_broadcast_i <= (~xgbe_mac_axis_rx_tlast) & pkt_broadcast;
	  else if(pkt_broadcast_i & xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid)
		  pkt_broadcast_i <= ~xgbe_mac_axis_rx_tlast;
	  else
		  pkt_broadcast_i <= pkt_broadcast_i;
  end
  
  assign pkt_broadcast_sel = pkt_broadcast_i | pkt_broadcast;
  
  always @(posedge xgemac_clk_156)
  begin
	  if (xgbe_mac_resetn == 1'b0)
		  pkt_sel_mux <= 1'b0;
	  else if(xgbe_mac_axis_rx_tready & xgbe_mac_axis_rx_tvalid & xgbe_mac_axis_rx_tlast & pkt_broadcast_sel)
		  pkt_sel_mux <= ~pkt_sel_mux;
	  else
		  pkt_sel_mux <= pkt_sel_mux;
  end
  
  assign pkt_dev_sel = pkt_dev_i | pkt_dev | (pkt_broadcast_sel & pkt_sel_mux);
  assign pkt_host_sel = pkt_host_i | pkt_host | (pkt_broadcast_sel & ~pkt_sel_mux);
  assign pkt_doce_sel = pkt_doce_i | pkt_doce;

  assign xgbe_mac_axis_rx_tready = (pkt_dev_sel & xgbe_mac_to_axi_dma_tready) |
									(pkt_host_sel & xgbe_mac_to_pcie_dma_tready) |
									(pkt_doce_sel & xgbe_mac_to_doce_tready);

  assign xgbe_mac_to_axi_dma_tdata = {64{pkt_dev_sel}} & xgbe_mac_axis_rx_tdata;
  assign xgbe_mac_to_axi_dma_tkeep = {8{pkt_dev_sel}} & xgbe_mac_axis_rx_tkeep;
  assign xgbe_mac_to_axi_dma_tlast = pkt_dev_sel & xgbe_mac_axis_rx_tlast;
  assign xgbe_mac_to_axi_dma_tvalid = pkt_dev_sel & xgbe_mac_axis_rx_tvalid;
  assign xgbe_mac_to_axi_dma_tdest = {3{pkt_dev_sel}} & DEV_TDEST;
  
  assign xgbe_mac_to_pcie_dma_tdata = {64{pkt_host_sel}} & xgbe_mac_axis_rx_tdata;
  assign xgbe_mac_to_pcie_dma_tkeep = {8{pkt_host_sel}} & xgbe_mac_axis_rx_tkeep;
  assign xgbe_mac_to_pcie_dma_tlast = pkt_host_sel & xgbe_mac_axis_rx_tlast;
  assign xgbe_mac_to_pcie_dma_tvalid = pkt_host_sel & xgbe_mac_axis_rx_tvalid;
  assign xgbe_mac_to_pcie_dma_tdest = {3{pkt_host_sel}} & HOST_TDEST;

  assign xgbe_mac_to_doce_tdata = {64{pkt_doce_sel}} & xgbe_mac_axis_rx_tdata;
  assign xgbe_mac_to_doce_tkeep = {8{pkt_doce_sel}} & xgbe_mac_axis_rx_tkeep;
  assign xgbe_mac_to_doce_tlast	= pkt_doce_sel & xgbe_mac_axis_rx_tlast;
  assign xgbe_mac_to_doce_tvalid = pkt_doce_sel & xgbe_mac_axis_rx_tvalid;

endmodule

