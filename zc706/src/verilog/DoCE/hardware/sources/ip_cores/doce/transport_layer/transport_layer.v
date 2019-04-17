/* =====================================================================
* DoCE Transport Layer Wrapper
*
* Author: Ran Zhao (zhaoran@ict.ac.cn)
* Date: 03/02/2017
* Version: v0.0.1
*=======================================================================
*/

`timescale 1ns / 1ps

module doce_transport_layer(
	// Clock and Reset signals
	input								clk,
	input								reset,
	
	// AXI-Stream interface to transaction layer Rx
	output  [127:0]                     trans_axis_rxd_tdata,
	output  [15:0]                      trans_axis_rxd_tkeep,
	output  [3:0]                       trans_axis_rxd_tuser,
	output                              trans_axis_rxd_tlast,
	output                              trans_axis_rxd_tvalid,
	input                               trans_axis_rxd_tready,
	
	// AXI-Stream interface from transaction layer Tx
	input   [127:0]                     trans_axis_txd_tdata,
	input   [15:0]                      trans_axis_txd_tkeep,
	input   [16:0]                      trans_axis_txd_tuser,
	input                               trans_axis_txd_tlast,
	input                               trans_axis_txd_tvalid,
	output                              trans_axis_txd_tready,
	
	// AXI-Lite slave connected to transaction layer
	input  	[31:0]       				s_axi_trp_awaddr,
	input                              	s_axi_trp_awvalid,
	output                              s_axi_trp_awready,
	                                    	
	input  	[31:0]        				s_axi_trp_araddr,
	input                              	s_axi_trp_arvalid,
	output                              s_axi_trp_arready,
	                                    	
	input  	[31:0]                      s_axi_trp_wdata,
	input  	[3:0]                       s_axi_trp_wstrb,
	input                              	s_axi_trp_wvalid,
	output                              s_axi_trp_wready,
	                                    	
	output 	[31:0]                     	s_axi_trp_rdata,
	output 	[1:0]                      	s_axi_trp_rresp,
	output                              s_axi_trp_rvalid,
	input                              	s_axi_trp_rready,
	                                    	
	output 	[1:0]                      	s_axi_trp_bresp,
	output                              s_axi_trp_bvalid,
	input                              	s_axi_trp_bready,
			
	// DoCE MAC/IP address
	input	[47:0]						doce_mac_addr,
	input	[31:0]						doce_ip_addr,
		
	// DoCE Rx interface
	input  	[63:0]						doce_axis_rxd_tdata,
	input 	[7:0]						doce_axis_rxd_tkeep,
	input 								doce_axis_rxd_tlast,
	output								doce_axis_rxd_tready,
	input 								doce_axis_rxd_tvalid,
	
	// DoCE Tx interface
	output	[63:0]						doce_axis_txd_tdata,
	output	[7:0]						doce_axis_txd_tkeep,
	output								doce_axis_txd_tlast,
	input 								doce_axis_txd_tready,
	output								doce_axis_txd_tvalid
    );
    
	wire 				axi_str_tvalid_to_router;
	wire 				axi_str_tready_from_router;
	wire [127:0]		axi_str_tdata_to_router;
	wire [15:0]			axi_str_tkeep_to_router;
	wire 				axi_str_tlast_to_router;
	
	wire 				axi_str_tvalid_from_router;
	wire 				axi_str_tready_to_router;
	wire [127:0]		axi_str_tdata_from_router;
	wire [15:0]			axi_str_tkeep_from_router;
	wire 				axi_str_tlast_from_router;
	
	wire [3:0]			look_up_tx_tuser;
	wire [3:0]			look_up_rx_tuser;
	wire [47:0]			tx_dst_mac_addr;
	wire [47:0]			rx_dst_mac_addr;
	
	reg	[47:0]			doce_mac_addr_r;
	reg [31:0]   		doce_ip_addr_r;
	
	always @(posedge clk)
	begin
		doce_mac_addr_r   	<= doce_mac_addr;
		doce_ip_addr_r   	<= doce_ip_addr;
	end
	
	//DEOI Tx MAC framing 64-bit packets
	axis_dc_128_to_64	u_axis_dc_deoi_slave_tx (
	  .aclk					(clk),
	  .aresetn				(~reset),

	  .s_axis_tvalid		(axi_str_tvalid_to_router),
	  .s_axis_tready		(axi_str_tready_from_router),
	  .s_axis_tdata			(axi_str_tdata_to_router),
	  .s_axis_tkeep			(axi_str_tkeep_to_router),
	  .s_axis_tlast			(axi_str_tlast_to_router),

	  .m_axis_tvalid		(doce_axis_txd_tvalid),
	  .m_axis_tready		(doce_axis_txd_tready),
	  .m_axis_tdata			(doce_axis_txd_tdata),
	  .m_axis_tkeep			(doce_axis_txd_tkeep),
	  .m_axis_tlast			(doce_axis_txd_tlast)
  );
  
	axis_dc_64_to_128	u_axis_dc_deoi_slave_rx (
	  .aclk					(clk),
	  .aresetn				(~reset),

	  .s_axis_tvalid		(doce_axis_rxd_tvalid),
	  .s_axis_tready		(doce_axis_rxd_tready),
	  .s_axis_tdata			(doce_axis_rxd_tdata),
	  .s_axis_tkeep			(doce_axis_rxd_tkeep),
	  .s_axis_tlast			(doce_axis_rxd_tlast),

	  .m_axis_tvalid		(axi_str_tvalid_from_router),
	  .m_axis_tready		(axi_str_tready_to_router),
	  .m_axis_tdata			(axi_str_tdata_from_router),
	  .m_axis_tkeep			(axi_str_tkeep_from_router),
	  .m_axis_tlast			(axi_str_tlast_from_router)
  );	
  
	mac_id_table u_mac_id_table (
		.clk					(clk),
		.reset					(reset),
		
		.trans_axis_txd_tuser	(look_up_tx_tuser),
		.tx_dst_mac_addr		(tx_dst_mac_addr),
		
		.trans_axis_rxd_tuser_i	(look_up_rx_tuser),
		.rx_dst_mac_addr		(rx_dst_mac_addr),
	
		.s_axi_lite_awaddr   	(s_axi_trp_awaddr),
		.s_axi_lite_awvalid  	(s_axi_trp_awvalid),
		.s_axi_lite_awready  	(s_axi_trp_awready),
		.s_axi_lite_araddr   	(s_axi_trp_araddr),
		.s_axi_lite_arvalid  	(s_axi_trp_arvalid),
		.s_axi_lite_arready  	(s_axi_trp_arready),
		.s_axi_lite_wdata    	(s_axi_trp_wdata),
		.s_axi_lite_wstrb    	(s_axi_trp_wstrb),
		.s_axi_lite_wvalid   	(s_axi_trp_wvalid),
		.s_axi_lite_wready   	(s_axi_trp_wready),
		.s_axi_lite_rdata    	(s_axi_trp_rdata),
		.s_axi_lite_rresp    	(s_axi_trp_rresp),
		.s_axi_lite_rvalid   	(s_axi_trp_rvalid),
		.s_axi_lite_rready   	(s_axi_trp_rready),
		.s_axi_lite_bresp    	(s_axi_trp_bresp),
		.s_axi_lite_bvalid   	(s_axi_trp_bvalid),
		.s_axi_lite_bready   	(s_axi_trp_bready)
	
	);
	
    tx_fsm u_tx_fsm(
		.user_clk					(clk),
		.reset						(reset),
		
		.axi_str_tdata_from_trans	(trans_axis_txd_tdata),
		.axi_str_tkeep_from_trans	(trans_axis_txd_tkeep),
		.axi_str_tvalid_from_trans	(trans_axis_txd_tvalid),
		.axi_str_tlast_from_trans	(trans_axis_txd_tlast),
		.axi_str_tuser_from_trans	(trans_axis_txd_tuser),
		.axi_str_tready_to_trans	(trans_axis_txd_tready),
		
		.axi_str_tready_from_router	(axi_str_tready_from_router),
		.axi_str_tdata_to_router	(axi_str_tdata_to_router),   
		.axi_str_tkeep_to_router	(axi_str_tkeep_to_router),   
		.axi_str_tvalid_to_router	(axi_str_tvalid_to_router),
		.axi_str_tlast_to_router	(axi_str_tlast_to_router),
		
		.trans_axis_txd_tuser		(look_up_tx_tuser),
		.tx_dst_mac_addr			(tx_dst_mac_addr),
		.doce_mac_addr				(doce_mac_addr_r),
		.doce_ip_addr				(doce_ip_addr_r)
	);
	
	rx_fsm u_rx_fsm(
		.user_clk					(clk),
		.reset						(reset),
		
		.axi_str_tdata_to_trans		(trans_axis_rxd_tdata),
		.axi_str_tkeep_to_trans		(trans_axis_rxd_tkeep),
		.axi_str_tvalid_to_trans	(trans_axis_rxd_tvalid),
		.axi_str_tlast_to_trans		(trans_axis_rxd_tlast),
		.axi_str_tuser_to_trans		(trans_axis_rxd_tuser),
		.axi_str_tready_from_trans	(trans_axis_rxd_tready),
		
		.axi_str_tready_to_router	(axi_str_tready_to_router),
		.axi_str_tdata_from_router	(axi_str_tdata_from_router),   
		.axi_str_tkeep_from_router	(axi_str_tkeep_from_router),   
		.axi_str_tvalid_from_router	(axi_str_tvalid_from_router),
		.axi_str_tlast_from_router	(axi_str_tlast_from_router),
		
		.trans_axis_rxd_tuser		(look_up_rx_tuser),
		.rx_dst_mac_addr			(rx_dst_mac_addr)
	);
    
    
endmodule
