/* =====================================================================
* Sub top module of 10GbE data-path used as the bridge between DEOI
* transaction layer and link layer (xgbe MAC)
*
* Author: Yisong Chang (changyisong@ict.ac.cn)
* Date: 04/12/2016
* Version: v0.0.1
*=======================================================================
*/
`timescale 1ps / 1ps

module xgbe_path # (
    parameter RX_FIFO_CNT_WIDTH =  13,
    parameter ADDRESS_FILTER_EN = 1
)(    
    // AXI-Lite master interface
    input                           xgbe_mac_axi_awready,
    output [10:0]					xgbe_mac_axi_awaddr,
    output                          xgbe_mac_axi_awvalid,
    input                           xgbe_mac_axi_wready,
    output [31:0]					xgbe_mac_axi_wdata,
    output                          xgbe_mac_axi_wvalid,
    input                           xgbe_mac_axi_bvalid,
    input [1:0]                     xgbe_mac_axi_bresp,
    output                          xgbe_mac_axi_bready,
    input                           xgbe_mac_axi_arready,
    output                          xgbe_mac_axi_arvalid,
    output [10:0]					xgbe_mac_axi_araddr,
    input [31:0]                    xgbe_mac_axi_rdata,
    input [1:0]                     xgbe_mac_axi_rresp,
    input                           xgbe_mac_axi_rvalid,
    output                          xgbe_mac_axi_rready, 

	// AXI-Stream interface of 10GbE MAC Rx/Tx
    input [63:0]					xgbe_mac_axis_rx_tdata,
    input [7:0]						xgbe_mac_axis_rx_tkeep,
    input                           xgbe_mac_axis_rx_tvalid,
    input                           xgbe_mac_axis_rx_tlast,
	input							xgbe_mac_axis_rx_tuser,
    output [63:0]					xgbe_mac_axis_tx_tdata,
    output [7:0]					xgbe_mac_axis_tx_tkeep,
    output                          xgbe_mac_axis_tx_tvalid,
    output                          xgbe_mac_axis_tx_tlast,
    input                           xgbe_mac_axis_tx_tready,

	// AXI-Stream interface of packet router
    output [63:0]					router_mac_axis_rx_tdata,
    output [7:0]					router_mac_axis_rx_tkeep,
    output                          router_mac_axis_rx_tvalid,
    output                          router_mac_axis_rx_tlast,
	input							router_mac_axis_rx_tready,
    input [63:0]					router_mac_axis_tx_tdata,
    input [7:0]						router_mac_axis_tx_tkeep,
    input							router_mac_axis_tx_tvalid,
    input							router_mac_axis_tx_tlast,
    output                          router_mac_axis_tx_tready,

	// Clock and Reset signals
	input							xgemac_clk_156,
	input							core_reset,
	input							soft_reset,

    // Additional control inputs
    input [47:0]                    host_mac_id,
    input [47:0]					dev_mac_id,
	input [47:0]					doce_mac_id,
    input [2:0]                     mac_id_valid,

	// MAC Rx statitcs
	input [29:0]					rx_statistics_vector,
	input							rx_statistics_valid,
	output							xgbe_mac_ready
);

  //AXI Lite controller reset signal
  //must be delayed after MAC core_reset deasserted
  wire				axi_lite_ctl_reset;
  reg [15:0]		axi_lite_ctl_reset_i = 16'hFFFF;

  // XGEMAC keeps tready asserted for one cycle after tlast
  // Any back-to-back frame provided are dropped in that case by the MAC
  // Avoid providing back-to-back frames till this is resolved by MAC team
  reg router_mac_axis_tx_tlast_reg = 1'b0;

  always @(posedge xgemac_clk_156)
	  router_mac_axis_tx_tlast_reg  <= router_mac_axis_tx_tlast & router_mac_axis_tx_tvalid & router_mac_axis_tx_tready;

  assign xgbe_mac_axis_tx_tvalid = (~router_mac_axis_tx_tlast_reg) & router_mac_axis_tx_tvalid;
  assign xgbe_mac_axis_tx_tdata = router_mac_axis_tx_tdata; 
  assign xgbe_mac_axis_tx_tkeep = router_mac_axis_tx_tkeep; 
  assign xgbe_mac_axis_tx_tlast = router_mac_axis_tx_tlast; 

  assign router_mac_axis_tx_tready = (~router_mac_axis_tx_tlast_reg) & xgbe_mac_axis_tx_tready;

  //XGBE MAC Rx interface
  rx_interface #(
	  .ADDRESS_FILTER_EN			(ADDRESS_FILTER_EN),
	  .FIFO_CNT_WIDTH				(RX_FIFO_CNT_WIDTH)
  ) u_rx_interface (
	  .axi_str_tdata_from_xgmac   	(xgbe_mac_axis_rx_tdata),
	  .axi_str_tkeep_from_xgmac   	(xgbe_mac_axis_rx_tkeep),
	  .axi_str_tvalid_from_xgmac  	(xgbe_mac_axis_rx_tvalid),
	  .axi_str_tlast_from_xgmac   	(xgbe_mac_axis_rx_tlast),
	  .axi_str_tuser_from_xgmac   	(xgbe_mac_axis_rx_tuser),

	  .host_mac_id					(host_mac_id),
	  .dev_mac_id					(dev_mac_id),
	  .doce_mac_id					(doce_mac_id),
	  .mac_id_valid               	(mac_id_valid),
	  .rx_statistics_vector       	(rx_statistics_vector),
	  .rx_statistics_valid        	(rx_statistics_valid),
	  .promiscuous_mode_en        	(1'b0),
	
	  .axi_str_tdata_to_fifo      	(router_mac_axis_rx_tdata),
	  .axi_str_tkeep_to_fifo      	(router_mac_axis_rx_tkeep),
	  .axi_str_tvalid_to_fifo     	(router_mac_axis_rx_tvalid),
	  .axi_str_tlast_to_fifo      	(router_mac_axis_rx_tlast),
	  .axi_str_tready_from_fifo   	(router_mac_axis_rx_tready),

	  .rd_data_count              	(),
	  .rd_pkt_len                 	(),
	  .rx_fifo_overflow           	(),

	  .user_clk                   	(xgemac_clk_156),
	  .soft_reset                 	(soft_reset),
	  .reset                      	(core_reset)
  );

  always @(posedge xgemac_clk_156)
	  axi_lite_ctl_reset_i <= {axi_lite_ctl_reset_i[14:0], core_reset};

  assign axi_lite_ctl_reset = axi_lite_ctl_reset_i[15];

  //AXI-Lite controller
  axi_10g_ethernet_0_axi_lite_sm  u_axi_lite_controller (
      .s_axi_aclk				(xgemac_clk_156),
      .s_axi_reset				(axi_lite_ctl_reset),

      .pcs_loopback				(1'b0),
      .enable_vlan				(1'b0),
	  .enable_custom_preamble	(1'b0),

      .enable_gen				(xgbe_mac_ready),
      .block_lock				(),

      .s_axi_awaddr				(xgbe_mac_axi_awaddr),
      .s_axi_awvalid			(xgbe_mac_axi_awvalid),
      .s_axi_awready			(xgbe_mac_axi_awready),

      .s_axi_wdata				(xgbe_mac_axi_wdata),
      .s_axi_wvalid				(xgbe_mac_axi_wvalid),
      .s_axi_wready				(xgbe_mac_axi_wready),

      .s_axi_bresp				(xgbe_mac_axi_bresp),
      .s_axi_bvalid				(xgbe_mac_axi_bvalid),
      .s_axi_bready				(xgbe_mac_axi_bready),

      .s_axi_araddr				(xgbe_mac_axi_araddr),
      .s_axi_arvalid			(xgbe_mac_axi_arvalid),
      .s_axi_arready			(xgbe_mac_axi_arready),

      .s_axi_rdata				(xgbe_mac_axi_rdata),
      .s_axi_rresp				(xgbe_mac_axi_rresp),
      .s_axi_rvalid				(xgbe_mac_axi_rvalid),
      .s_axi_rready				(xgbe_mac_axi_rready)
  );

endmodule

