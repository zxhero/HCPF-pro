`timescale 1 ps / 1 ps

module rocketchip_DoCE_wrapper(
	inout [14:0]DDR_addr,
	inout [2:0]DDR_ba,
	inout DDR_cas_n,
	inout DDR_ck_n,
	inout DDR_ck_p,
	inout DDR_cke,
	inout DDR_cs_n,
	inout [3:0]DDR_dm,
	inout [31:0]DDR_dq,
	inout [3:0]DDR_dqs_n,
	inout [3:0]DDR_dqs_p,
	inout DDR_odt,
	inout DDR_ras_n,
	inout DDR_reset_n,
	inout DDR_we_n,

	inout FIXED_IO_ddr_vrn,
	inout FIXED_IO_ddr_vrp,
	inout [53:0]FIXED_IO_mio,
	inout FIXED_IO_ps_clk,
	inout FIXED_IO_ps_porb,
	inout FIXED_IO_ps_srstb,
		/*1GB DDR3 SODIMM in Programmable Logic*/
    output [13:0]				PL_DDR3_addr,             
    output [2:0]				PL_DDR3_ba,               
    output						PL_DDR3_cas_n,            
    output                      PL_DDR3_ck_p,               
    output                      PL_DDR3_ck_n,             
    output						PL_DDR3_cke,              
    output                      PL_DDR3_cs_n,             
    output [7:0]                PL_DDR3_dm,               
    inout  [63:0]               PL_DDR3_dq,               
    inout  [7:0]                PL_DDR3_dqs_p,              
    inout  [7:0]                PL_DDR3_dqs_n,            
    output                      PL_DDR3_odt,              
    output                      PL_DDR3_ras_n,            
    output                      PL_DDR3_reset_n,          
    output                      PL_DDR3_we_n,
		/*XGBE GT channel*/
	output						xgbe_phy_txp,
	output						xgbe_phy_txn,

	input						xgbe_phy_rxp,
	input						xgbe_phy_rxn,

	/*LED for debug*/
	output						xgbe_phy_up,
	output						xgbe_mac_config_done,
	output                      debug_inf,
	//output                      debug_inf_1,
	//output                      debug_inf_2,
	output                      pl_ddr3_calib_done,

    /*200MHz reference clock input*/
	input						clk_ref_p,
	input						clk_ref_n,

	/*GT reference clock for XGBE PHY*/
	input						gt_xgbe_ref_clk_p,
	input						gt_xgbe_ref_clk_n,

	/*Si5324 I2C programming interface*/
    inout                       i2c_clk,
    inout                       i2c_data,
    output                      si5324_rst_n
	
);

/* clock signals */
  //init system clock signals
  wire				clk_ref_200;
  wire				clk_ref_200_i;

  //XGBE user clock generated from xgbe PCS-PMA PHY
  wire				xgemac_clk_156;

  //user clock generated from memory controller block
  wire				mcb_clk;
  
  //Si5324 related clock signal
  wire				clk50;
  reg [1:0]			clk_divide = 2'b00;

  //Positive XGBE PHY reset signal (assosiated with xgemac_clk_156)
  reg [1:0]			xgbe_phy_reset_i = 2'b11;
  wire				xgbe_phy_reset;

  //Positive XGBE MAC reset signal (assosiated with xgemac_clk_156)
  reg				xgbe_core_reset_i;
  reg				xgbe_core_reset;
  
  //Asynchrounous PL user logic init negative reset signal
  //generated from PS
  wire				ps_user_reset_n;
  
/* AXI-Stream channel reset signals */
  //DoCE module reset signal (assosiated with mcb_clk)
  wire				mig_ic_resetn;
  
  wire				tile_aresetn;
  wire				tile_clock;
  //system DCM 
  reg	[1:0]			dcm_locked;
/* AXI and AXI4 channel */
  // XGBE MAC AXI-Lite slave interface 
  wire              xgbe_mac_axi_awready;
  wire [10:0]		xgbe_mac_axi_awaddr;
  wire              xgbe_mac_axi_awvalid;
  wire              xgbe_mac_axi_wready;
  wire [31:0]		xgbe_mac_axi_wdata;
  wire              xgbe_mac_axi_wvalid;
  wire              xgbe_mac_axi_bvalid;
  wire [1:0]        xgbe_mac_axi_bresp;
  wire              xgbe_mac_axi_bready;
  wire              xgbe_mac_axi_arready;
  wire              xgbe_mac_axi_arvalid;
  wire [10:0]		xgbe_mac_axi_araddr;
  wire [31:0]       xgbe_mac_axi_rdata;
  wire [1:0]        xgbe_mac_axi_rresp;
  wire              xgbe_mac_axi_rvalid;
  wire              xgbe_mac_axi_rready; 

  //AXI-Lite to DoCE
  wire [31:0]		doce_axi_lite_slave_araddr;
  wire [0:0]		doce_axi_lite_slave_arready;
  wire [0:0]		doce_axi_lite_slave_arvalid;
  wire [31:0]		doce_axi_lite_slave_awaddr;
  wire [0:0]		doce_axi_lite_slave_awready;
  wire [0:0]		doce_axi_lite_slave_awvalid;
  wire [0:0]		doce_axi_lite_slave_bready;
  wire [1:0]		doce_axi_lite_slave_bresp;
  wire [0:0]		doce_axi_lite_slave_bvalid;
  wire [31:0]		doce_axi_lite_slave_rdata;
  wire [0:0]		doce_axi_lite_slave_rready;
  wire [1:0]		doce_axi_lite_slave_rresp;
  wire [0:0]		doce_axi_lite_slave_rvalid;
  wire [31:0]		doce_axi_lite_slave_wdata;
  wire [0:0]		doce_axi_lite_slave_wready;
  wire [3:0]		doce_axi_lite_slave_wstrb;
  wire [0:0]		doce_axi_lite_slave_wvalid;

  //AXI4 master from DoCE
  wire [31:0]		doce_axi_master_araddr;
  wire [1:0]		doce_axi_master_arburst;
  wire [3:0]		doce_axi_master_arcache;
  wire [9:0]		doce_axi_master_arid;
  wire [7:0]		doce_axi_master_arlen;
  wire [0:0]		doce_axi_master_arlock;
  wire [2:0]		doce_axi_master_arprot;
  wire [3:0]		doce_axi_master_arqos;
  wire				doce_axi_master_arready;
  wire [2:0]		doce_axi_master_arsize;
  wire				doce_axi_master_arvalid;
  wire [31:0]		doce_axi_master_awaddr;
  wire [1:0]		doce_axi_master_awburst;
  wire [3:0]		doce_axi_master_awcache;
  wire [9:0]		doce_axi_master_awid;
  wire [7:0]		doce_axi_master_awlen;
  wire [0:0]		doce_axi_master_awlock;
  wire [2:0]		doce_axi_master_awprot;
  wire [3:0]		doce_axi_master_awqos;
  wire				doce_axi_master_awready;
  wire [2:0]		doce_axi_master_awsize;
  wire				doce_axi_master_awvalid;
  wire [9:0]		doce_axi_master_bid;
  wire				doce_axi_master_bready;
  wire [1:0]		doce_axi_master_bresp;
  wire				doce_axi_master_bvalid;
  wire [31:0]		doce_axi_master_rdata;
  wire [9:0]		doce_axi_master_rid;
  wire				doce_axi_master_rlast;
  wire				doce_axi_master_rready;
  wire [1:0]		doce_axi_master_rresp;
  wire				doce_axi_master_rvalid;
  wire [31:0]		doce_axi_master_wdata;
  wire				doce_axi_master_wlast;
  wire				doce_axi_master_wready;
  wire [3:0]		doce_axi_master_wstrb;
  wire				doce_axi_master_wvalid;
  
  //AXI4 slave to DoCE
  wire [31:0]		doce_axi_slave_araddr;
  wire [1:0]		doce_axi_slave_arburst;
  wire [3:0]		doce_axi_slave_arcache;
  wire [5:0]		doce_axi_slave_arid;
  wire [7:0]		doce_axi_slave_arlen;
  wire [0:0]		doce_axi_slave_arlock;
  wire [2:0]		doce_axi_slave_arprot;
  wire [3:0]		doce_axi_slave_arqos;
  wire				doce_axi_slave_arready;
  wire [3:0]		doce_axi_slave_arregion;
  wire [2:0]		doce_axi_slave_arsize;
  wire				doce_axi_slave_arvalid;
  wire [31:0]		doce_axi_slave_awaddr;
  wire [1:0]		doce_axi_slave_awburst;
  wire [3:0]		doce_axi_slave_awcache;
  wire [5:0]		doce_axi_slave_awid;
  wire [7:0]		doce_axi_slave_awlen;
  wire [0:0]		doce_axi_slave_awlock;
  wire [2:0]		doce_axi_slave_awprot;
  wire [3:0]		doce_axi_slave_awqos;
  wire				doce_axi_slave_awready;
  wire [3:0]		doce_axi_slave_awregion;
  wire [2:0]		doce_axi_slave_awsize;
  wire				doce_axi_slave_awvalid;
  wire [5:0]		doce_axi_slave_bid;
  wire				doce_axi_slave_bready;
  wire [1:0]		doce_axi_slave_bresp;
  wire				doce_axi_slave_bvalid;
  wire [31:0]		doce_axi_slave_rdata;
  wire [5:0]		doce_axi_slave_rid;
  wire				doce_axi_slave_rlast;
  wire				doce_axi_slave_rready;
  wire [1:0]		doce_axi_slave_rresp;
  wire				doce_axi_slave_rvalid;
  wire [31:0]		doce_axi_slave_wdata;
  wire				doce_axi_slave_wlast;
  wire				doce_axi_slave_wready;
  wire [3:0]		doce_axi_slave_wstrb;
  wire				doce_axi_slave_wvalid;

  //AXI-Lite to MAC address register from DoCE
  wire [31:0]		m_axi_doce_mac_araddr;
  wire [2:0]		m_axi_doce_mac_arprot;
  wire				m_axi_doce_mac_arready;
  wire				m_axi_doce_mac_arvalid;
  wire [31:0]		m_axi_doce_mac_awaddr;
  wire [2:0]		m_axi_doce_mac_awprot;
  wire				m_axi_doce_mac_awready;
  wire				m_axi_doce_mac_awvalid;
  wire				m_axi_doce_mac_bready;
  wire [1:0]		m_axi_doce_mac_bresp;
  wire				m_axi_doce_mac_bvalid;
  wire [31:0]		m_axi_doce_mac_rdata;
  wire				m_axi_doce_mac_rready;
  wire [1:0]		m_axi_doce_mac_rresp;
  wire				m_axi_doce_mac_rvalid;
  wire [31:0]		m_axi_doce_mac_wdata;
  wire				m_axi_doce_mac_wready;
  wire [3:0]		m_axi_doce_mac_wstrb;
  wire				m_axi_doce_mac_wvalid;

/* AXI-Stream Interface */
  //XGBE MAC Tx
  wire [63:0]		xgbe_mac_axis_tx_tdata;
  wire [7:0]		xgbe_mac_axis_tx_tkeep;
  wire              xgbe_mac_axis_tx_tvalid;
  wire              xgbe_mac_axis_tx_tlast;
  wire              xgbe_mac_axis_tx_tready;

  //XGBE MAC Rx
  wire [63:0]		xgbe_mac_axis_rx_tdata;
  wire [7:0]		xgbe_mac_axis_rx_tkeep;
  wire              xgbe_mac_axis_rx_tvalid;
  wire              xgbe_mac_axis_rx_tlast;
  wire              xgbe_mac_axis_rx_tuser;

  //DoCE Rx
  wire [63:0]		doce_axis_rxd_tdata;
  wire [7:0]		doce_axis_rxd_tkeep;
  wire				doce_axis_rxd_tlast;
  wire				doce_axis_rxd_tready;
  wire				doce_axis_rxd_tvalid;
 
  //DoCE Tx
  wire [63:0]		doce_axis_txd_tdata;
  wire [7:0]		doce_axis_txd_tkeep;
  wire				doce_axis_txd_tlast;
  wire				doce_axis_txd_tready;
  wire				doce_axis_txd_tvalid;

  //XGBE Rx/Tx channel for xgbe_path
  wire [63:0]		router_mac_axis_rx_tdata;
  wire [7:0]		router_mac_axis_rx_tkeep;
  wire              router_mac_axis_rx_tvalid;
  wire              router_mac_axis_rx_tlast;
  wire				router_mac_axis_rx_tready;

  wire [63:0]		router_mac_axis_tx_tdata;
  wire [7:0]		router_mac_axis_tx_tkeep;
  wire [0:0]		router_mac_axis_tx_tvalid;
  wire [0:0]		router_mac_axis_tx_tlast;
  wire [0:0]        router_mac_axis_tx_tready;
  wire [2:0]		router_mac_axis_tx_tdest;

  //XGBE MAC Rx channel to packet router
  wire [63:0]		xgbe_mac_to_doce_tdata;
  wire [7:0]		xgbe_mac_to_doce_tkeep;
  wire				xgbe_mac_to_doce_tlast;
  wire				xgbe_mac_to_doce_tready;
  wire				xgbe_mac_to_doce_tvalid;

/* MISC signals */
  //PL DDR3 MIG calibration done
  //wire				pl_ddr3_calib_done;

  //XGBE PHY & MAC status
  wire [7:0]		xgbe_phy_core_status;
  wire				xgbe_phy_resetdone;
  
  wire [29:0]		xgbe_mac_rx_statistics_vector;
  wire				xgbe_mac_rx_statistics_valid;
	
  //Host, Device and DoCE MAC Address
  wire [47:0]		host_mac_id;
  wire [47:0]		dev_mac_id;
  wire [47:0]		doce_mac_id;
  wire [31:0]		doce_ip_addr;

  //VFIFO overflow control signals (assosiated to mcb_clk)
  wire [5:0]		vfifo_s2mm_channel_full;
  reg [5:0]			vfifo_s2mm_channel_full_reg;

  //pacekt FIFO data count for VFIFO arbitration
  wire [11:0]		pkt_m00_data_cnt;
  wire [11:0]		pkt_m01_data_cnt;
  wire [11:0]		pkt_m02_data_cnt;
  
  //rocket to PL DDR3
  	wire [31:0]hcpf_M_AXI_araddr;
	wire [1:0]hcpf_M_AXI_arburst;
	wire [3:0]hcpf_M_AXI_arcache;
	wire [5:0]hcpf_M_AXI_arid;
	wire [7:0]hcpf_M_AXI_arlen;
	wire [0:0]hcpf_M_AXI_arlock;
	wire [2:0]hcpf_M_AXI_arprot;
	wire [3:0]hcpf_M_AXI_arqos;
	wire [0:0]hcpf_M_AXI_arready;
	wire [3:0]hcpf_M_AXI_arregion;
	wire [2:0]hcpf_M_AXI_arsize;
	wire [0:0]hcpf_M_AXI_arvalid;
	wire [31:0]hcpf_M_AXI_awaddr;
	wire [1:0]hcpf_M_AXI_awburst;
	wire [3:0]hcpf_M_AXI_awcache;
	wire [5:0]hcpf_M_AXI_awid;
	wire [7:0]hcpf_M_AXI_awlen;
	wire [0:0]hcpf_M_AXI_awlock;
	wire [2:0]hcpf_M_AXI_awprot;
	wire [3:0]hcpf_M_AXI_awqos;
	wire [0:0]hcpf_M_AXI_awready;
	wire [3:0]hcpf_M_AXI_awregion;
	wire [2:0]hcpf_M_AXI_awsize;
	wire [0:0]hcpf_M_AXI_awvalid;
	wire [5:0]hcpf_M_AXI_bid;
	wire [0:0]hcpf_M_AXI_bready;
	wire [1:0]hcpf_M_AXI_bresp;
	wire [0:0]hcpf_M_AXI_bvalid;
	wire [63:0]hcpf_M_AXI_rdata;
	wire [5:0]hcpf_M_AXI_rid;
	wire [0:0]hcpf_M_AXI_rlast;
	wire [0:0]hcpf_M_AXI_rready;
	wire [1:0]hcpf_M_AXI_rresp;
	wire [0:0]hcpf_M_AXI_rvalid;
	wire [63:0]hcpf_M_AXI_wdata;
	wire [0:0]hcpf_M_AXI_wlast;
	wire [0:0]hcpf_M_AXI_wready;
	wire [7:0]hcpf_M_AXI_wstrb;
	wire [0:0]hcpf_M_AXI_wvalid;
	
	wire [31:0]mbus_M_AXI_araddr;
	wire [1:0]mbus_M_AXI_arburst;
	wire [3:0]mbus_M_AXI_arcache;
	wire [5:0]mbus_M_AXI_arid;
	wire [7:0]mbus_M_AXI_arlen;
	wire [0:0]mbus_M_AXI_arlock;
	wire [2:0]mbus_M_AXI_arprot;
	wire [3:0]mbus_M_AXI_arqos;
	wire [0:0]mbus_M_AXI_arready;
	wire [3:0]mbus_M_AXI_arregion;
	wire [2:0]mbus_M_AXI_arsize;
	wire [0:0]mbus_M_AXI_arvalid;
	wire [31:0]mbus_M_AXI_awaddr;
	wire [1:0]mbus_M_AXI_awburst;
	wire [3:0]mbus_M_AXI_awcache;
	wire [5:0]mbus_M_AXI_awid;
	wire [7:0]mbus_M_AXI_awlen;
	wire [0:0]mbus_M_AXI_awlock;
	wire [2:0]mbus_M_AXI_awprot;
	wire [3:0]mbus_M_AXI_awqos;
	wire [0:0]mbus_M_AXI_awready;
	wire [3:0]mbus_M_AXI_awregion;
	wire [2:0]mbus_M_AXI_awsize;
	wire [0:0]mbus_M_AXI_awvalid;
	wire [5:0]mbus_M_AXI_bid;
	wire [0:0]mbus_M_AXI_bready;
	wire [1:0]mbus_M_AXI_bresp;
	wire [0:0]mbus_M_AXI_bvalid;
	wire [63:0]mbus_M_AXI_rdata;
	wire [5:0]mbus_M_AXI_rid;
	wire [0:0]mbus_M_AXI_rlast;
	wire [0:0]mbus_M_AXI_rready;
	wire [1:0]mbus_M_AXI_rresp;
	wire [0:0]mbus_M_AXI_rvalid;
	wire [63:0]mbus_M_AXI_wdata;
	wire [0:0]mbus_M_AXI_wlast;
	wire [0:0]mbus_M_AXI_wready;
	wire [7:0]mbus_M_AXI_wstrb;
	wire [0:0]mbus_M_AXI_wvalid;
  //rocket to DoCE
	
	wire         io_mmio_axi_aw_ready; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire        io_mmio_axi_aw_valid;// @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire [30:0] io_mmio_axi_aw_bits_addr; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire         io_mmio_axi_w_ready; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire        io_mmio_axi_w_valid; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire [63:0] io_mmio_axi_w_bits_data; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire [7:0]  io_mmio_axi_w_bits_strb; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire        io_mmio_axi_b_ready; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire         io_mmio_axi_b_valid; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire  [1:0]  io_mmio_axi_b_bits_resp; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire         io_mmio_axi_ar_ready; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire        io_mmio_axi_ar_valid; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire [30:0] io_mmio_axi_ar_bits_addr; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire        io_mmio_axi_r_ready; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire         io_mmio_axi_r_valid; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire  [63:0] io_mmio_axi_r_bits_data; // @[:Top.ZynqFPGAConfig.fir@183370.4]
	wire  [1:0]  io_mmio_axi_r_bits_resp; // @[:Top.ZynqFPGAConfig.fir@183370.4]
//==============================
// Clock and Reset
//==============================

//System and Reference clock input to PL MIG
  IBUFDS u_diff_clk_200(
	  .I					(clk_ref_p),
	  .IB					(clk_ref_n),
	  .O					(clk_ref_200_i)
  );

  BUFG u_bufg_clk_ref(
	  .I					(clk_ref_200_i),
	  .O					(clk_ref_200)
  );

//50MHz clock required by Si5324 clock controller
  always @(posedge clk_ref_200)
	  clk_divide  <= clk_divide + 2'd1;

  BUFG buffer_clk50 (
	  .I					(clk_divide[1]),
	  .O					(clk50)
  );
  
  //XGBE PHY and MAC reset synchronized to xgemac clock region
//the reset signal must be triggered by PCIe perst#
  always @(posedge xgemac_clk_156)
  begin
	  xgbe_phy_reset_i <= {xgbe_phy_reset_i[0], ~ps_user_reset_n}; 
  end

  assign xgbe_phy_reset = xgbe_phy_reset_i[1];

  always @(posedge xgbe_phy_reset or posedge xgemac_clk_156)
  begin
	  if (xgbe_phy_reset)
	  begin
		  xgbe_core_reset_i <= 1'b1;
		  xgbe_core_reset <= 1'b1;
	  end
	  else
	  begin
		  // Hold core in reset until everything else is ready...
		  xgbe_core_reset_i <= (  xgbe_phy_reset || (~xgbe_phy_resetdone));
		  xgbe_core_reset <= xgbe_core_reset_i;
	  end
  end 
  
    localparam			RX_FIFO_CNT_WIDTH   = 13;  
    localparam            ADDRESS_FILTER_EN   = 1; 
	xgbe_path #(
	  .RX_FIFO_CNT_WIDTH			(RX_FIFO_CNT_WIDTH),
	  .ADDRESS_FILTER_EN			(ADDRESS_FILTER_EN)
	) u_xgbe_path(
	  //connected to XGBE MAC AXI-Lite interface
	  .xgbe_mac_axi_awready			(xgbe_mac_axi_awready),
	  .xgbe_mac_axi_awaddr			(xgbe_mac_axi_awaddr),
	  .xgbe_mac_axi_awvalid			(xgbe_mac_axi_awvalid),
	  .xgbe_mac_axi_wready			(xgbe_mac_axi_wready),
	  .xgbe_mac_axi_wdata			(xgbe_mac_axi_wdata),
	  .xgbe_mac_axi_wvalid			(xgbe_mac_axi_wvalid),
	  .xgbe_mac_axi_bvalid			(xgbe_mac_axi_bvalid),
	  .xgbe_mac_axi_bresp			(xgbe_mac_axi_bresp),
	  .xgbe_mac_axi_bready			(xgbe_mac_axi_bready),
	  .xgbe_mac_axi_arready			(xgbe_mac_axi_arready),
	  .xgbe_mac_axi_arvalid			(xgbe_mac_axi_arvalid),
	  .xgbe_mac_axi_araddr			(xgbe_mac_axi_araddr),
	  .xgbe_mac_axi_rdata			(xgbe_mac_axi_rdata),
	  .xgbe_mac_axi_rresp			(xgbe_mac_axi_rresp),
	  .xgbe_mac_axi_rvalid			(xgbe_mac_axi_rvalid),
	  .xgbe_mac_axi_rready			(xgbe_mac_axi_rready),
	  
	  // XGBE MAC Rx/Tx channel connected to packet router
	  .router_mac_axis_rx_tdata		(router_mac_axis_rx_tdata),
      .router_mac_axis_rx_tkeep		(router_mac_axis_rx_tkeep),
      .router_mac_axis_rx_tvalid	(router_mac_axis_rx_tvalid),
      .router_mac_axis_rx_tlast		(router_mac_axis_rx_tlast),
	  .router_mac_axis_rx_tready	(router_mac_axis_rx_tready),
      .router_mac_axis_tx_tdata		(router_mac_axis_tx_tdata),
      .router_mac_axis_tx_tkeep		(router_mac_axis_tx_tkeep),
      .router_mac_axis_tx_tvalid	(router_mac_axis_tx_tvalid),
      .router_mac_axis_tx_tlast		(router_mac_axis_tx_tlast),
      .router_mac_axis_tx_tready	(router_mac_axis_tx_tready),
	  
	  // AXI-Stream interface of 10GbE MAC Tx/Rx channel
 	  .xgbe_mac_axis_rx_tdata		(xgbe_mac_axis_rx_tdata),
 	  .xgbe_mac_axis_rx_tkeep		(xgbe_mac_axis_rx_tkeep),
 	  .xgbe_mac_axis_rx_tvalid		(xgbe_mac_axis_rx_tvalid),
 	  .xgbe_mac_axis_rx_tlast		(xgbe_mac_axis_rx_tlast),
 	  .xgbe_mac_axis_rx_tuser		(xgbe_mac_axis_rx_tuser),
 	  .xgbe_mac_axis_tx_tdata		(xgbe_mac_axis_tx_tdata),
 	  .xgbe_mac_axis_tx_tkeep		(xgbe_mac_axis_tx_tkeep),
 	  .xgbe_mac_axis_tx_tvalid		(xgbe_mac_axis_tx_tvalid),
 	  .xgbe_mac_axis_tx_tlast		(xgbe_mac_axis_tx_tlast),
 	  .xgbe_mac_axis_tx_tready		(xgbe_mac_axis_tx_tready),

	  // Clock and Reset signals
	  .xgemac_clk_156				(xgemac_clk_156),
	  .core_reset					(xgbe_core_reset),
	  .soft_reset					(xgbe_core_reset),
	  
	  // Additional control inputs
	  .host_mac_id					(host_mac_id),
	  .dev_mac_id					(dev_mac_id),
	  .doce_mac_id					(doce_mac_id),
	  .mac_id_valid					(3'b111),
	  
	  // MAC Rx statitcs
	  .rx_statistics_vector			(xgbe_mac_rx_statistics_vector),
	  .rx_statistics_valid			(xgbe_mac_rx_statistics_valid),

	  .xgbe_mac_ready				(xgbe_mac_config_done)
	);
    
    clock_control		u_clock_control_inst(
	.i2c_clk        (i2c_clk),
	.i2c_data       (i2c_data),
	.i2c_mux_rst_n  (),
	.si5324_rst_n   (si5324_rst_n),
	.rst            (~ps_user_reset_n),
	.clk50          (clk50)
    );
    
	packet_router_wrapper		u_packet_router(
		.mcb_clk						(mcb_clk),
		.xgemac_clk_156				(xgemac_clk_156),
	  
	  //Reset and related signals
      .mig_ic_resetn				(mig_ic_resetn),

      .xgbe_mac_resetn				(~xgbe_core_reset),

	  // XGBE MAC Tx
	  .router_mac_axis_tx_tdata		(router_mac_axis_tx_tdata),
      .router_mac_axis_tx_tkeep		(router_mac_axis_tx_tkeep),
      .router_mac_axis_tx_tlast		(router_mac_axis_tx_tlast),
      .router_mac_axis_tx_tready	(router_mac_axis_tx_tready),
      .router_mac_axis_tx_tvalid	(router_mac_axis_tx_tvalid),

	  // XGBE MAC to DoCE Rx
	  .xgbe_mac_to_doce_tdata		(xgbe_mac_to_doce_tdata),
      .xgbe_mac_to_doce_tdest		(3'b000),
      .xgbe_mac_to_doce_tkeep		(xgbe_mac_to_doce_tkeep),
      .xgbe_mac_to_doce_tlast		(xgbe_mac_to_doce_tlast),
      .xgbe_mac_to_doce_tready		(xgbe_mac_to_doce_tready),
      .xgbe_mac_to_doce_tvalid		(xgbe_mac_to_doce_tvalid),

	  // DoCE Rx channel
	  .doce_axis_rxd_tdata			(doce_axis_rxd_tdata),
      .doce_axis_rxd_tdest			(),
      .doce_axis_rxd_tkeep			(doce_axis_rxd_tkeep),
      .doce_axis_rxd_tlast			(doce_axis_rxd_tlast),
      .doce_axis_rxd_tready			(doce_axis_rxd_tready),
      .doce_axis_rxd_tvalid			(doce_axis_rxd_tvalid),
      
	  // DoCE Tx channel
	  .doce_axis_txd_tdata			(doce_axis_txd_tdata),
      .doce_axis_txd_tdest			(3'b110),
      .doce_axis_txd_tkeep			(doce_axis_txd_tkeep),
      .doce_axis_txd_tlast			(doce_axis_txd_tlast),
      .doce_axis_txd_tready			(doce_axis_txd_tready),
      .doce_axis_txd_tvalid			(doce_axis_txd_tvalid)
	);

	mac_addr_reg		u_mac_addr_reg(
	  .axi_lite_aclk					(xgemac_clk_156),
	  .axi_lite_aresetn					(~xgbe_core_reset),
	  
	  .s_axi_lite_awvalid				(m_axi_doce_mac_awvalid),
	  .s_axi_lite_awaddr				(m_axi_doce_mac_awaddr),
	  .s_axi_lite_awready				(m_axi_doce_mac_awready),
	  .s_axi_lite_wvalid				(m_axi_doce_mac_wvalid),
	  .s_axi_lite_wdata					(m_axi_doce_mac_wdata),
	  .s_axi_lite_wstrb					(m_axi_doce_mac_wstrb),
	  .s_axi_lite_wready				(m_axi_doce_mac_wready),
	  .s_axi_lite_bvalid				(m_axi_doce_mac_bvalid),
	  .s_axi_lite_bresp					(m_axi_doce_mac_bresp),
	  .s_axi_lite_bready				(m_axi_doce_mac_bready),
	  .s_axi_lite_arvalid				(m_axi_doce_mac_arvalid),
	  .s_axi_lite_araddr				(m_axi_doce_mac_araddr),
	  .s_axi_lite_arready				(m_axi_doce_mac_arready),
	  .s_axi_lite_rvalid				(m_axi_doce_mac_rvalid),
	  .s_axi_lite_rdata					(m_axi_doce_mac_rdata),
	  .s_axi_lite_rresp					(m_axi_doce_mac_rresp),
	  .s_axi_lite_rready				(m_axi_doce_mac_rready),
	  
	  .host_mac_id						(host_mac_id),
	  .dev_mac_id						(dev_mac_id),
	  .doce_mac_id						(doce_mac_id),
	  .doce_ip_addr						(doce_ip_addr)
	  
	);
	
	xgbe_mac_rx_dispatch		u_xgbe_mac_rx_dispatch(
	  .xgemac_clk_156					(xgemac_clk_156),
	  .xgbe_mac_resetn					(~xgbe_core_reset),
	  
	  .dev_mac_addr						(dev_mac_id),
	  .host_mac_addr					(host_mac_id),
	  .doce_mac_addr					(doce_mac_id),
	  
	  .xgbe_mac_axis_rx_tdata			(router_mac_axis_rx_tdata),
	  .xgbe_mac_axis_rx_tkeep			(router_mac_axis_rx_tkeep),
	  .xgbe_mac_axis_rx_tlast			(router_mac_axis_rx_tlast),
	  .xgbe_mac_axis_rx_tvalid			(router_mac_axis_rx_tvalid),
	  .xgbe_mac_axis_rx_tready			(router_mac_axis_rx_tready),

	  .xgbe_mac_to_axi_dma_tready		('d0),

	  .xgbe_mac_to_pcie_dma_tready		('d0),

	  .xgbe_mac_to_doce_tdata			(xgbe_mac_to_doce_tdata),
	  .xgbe_mac_to_doce_tkeep			(xgbe_mac_to_doce_tkeep),
	  .xgbe_mac_to_doce_tlast			(xgbe_mac_to_doce_tlast),
	  .xgbe_mac_to_doce_tvalid			(xgbe_mac_to_doce_tvalid),
	  .xgbe_mac_to_doce_tready			(xgbe_mac_to_doce_tready)
	);
	
	xgbe_component_wrapper		u_xgbe_component(
	  .gt_ref_clk_clk_n				(gt_xgbe_ref_clk_n),
	  .gt_ref_clk_clk_p				(gt_xgbe_ref_clk_p),

      .drp_clk						(clk50),
      .xgemac_clk_156				(xgemac_clk_156),

	  //Reset and related signals
      .xgbe_phy_reset				(xgbe_phy_reset),
	  .xgbe_phy_resetdone			(xgbe_phy_resetdone),
	  .xgbe_phy_core_status			(xgbe_phy_core_status),

      .xgbe_mac_reset				(xgbe_core_reset),
      .xgbe_mac_resetn				(~xgbe_core_reset),
   
	  //XGBE MAC AXI-Lite interface
	  .xgbe_mac_axi_araddr			(xgbe_mac_axi_araddr),
      .xgbe_mac_axi_arready			(xgbe_mac_axi_arready),
      .xgbe_mac_axi_arvalid			(xgbe_mac_axi_arvalid),
      .xgbe_mac_axi_awaddr			(xgbe_mac_axi_awaddr),
      .xgbe_mac_axi_awready			(xgbe_mac_axi_awready),
      .xgbe_mac_axi_awvalid			(xgbe_mac_axi_awvalid),
      .xgbe_mac_axi_bready			(xgbe_mac_axi_bready),
      .xgbe_mac_axi_bresp			(xgbe_mac_axi_bresp),
      .xgbe_mac_axi_bvalid			(xgbe_mac_axi_bvalid),
      .xgbe_mac_axi_rdata			(xgbe_mac_axi_rdata),
      .xgbe_mac_axi_rready			(xgbe_mac_axi_rready),
      .xgbe_mac_axi_rresp			(xgbe_mac_axi_rresp),
      .xgbe_mac_axi_rvalid			(xgbe_mac_axi_rvalid),
      .xgbe_mac_axi_wdata			(xgbe_mac_axi_wdata),
      .xgbe_mac_axi_wready			(xgbe_mac_axi_wready),
      .xgbe_mac_axi_wvalid			(xgbe_mac_axi_wvalid),
     
	  //XGBE MAC Rx/Tx channel
	  .xgbe_mac_axis_rx_tdata		(xgbe_mac_axis_rx_tdata),
      .xgbe_mac_axis_rx_tkeep		(xgbe_mac_axis_rx_tkeep),
      .xgbe_mac_axis_rx_tlast		(xgbe_mac_axis_rx_tlast),
      .xgbe_mac_axis_rx_tuser		(xgbe_mac_axis_rx_tuser),
      .xgbe_mac_axis_rx_tvalid		(xgbe_mac_axis_rx_tvalid),
      
	  .xgbe_mac_axis_tx_tdata		(xgbe_mac_axis_tx_tdata),
      .xgbe_mac_axis_tx_tkeep		(xgbe_mac_axis_tx_tkeep),
      .xgbe_mac_axis_tx_tlast		(xgbe_mac_axis_tx_tlast),
      .xgbe_mac_axis_tx_tready		(xgbe_mac_axis_tx_tready),
      .xgbe_mac_axis_tx_tuser		('d0),
      .xgbe_mac_axis_tx_tvalid		(xgbe_mac_axis_tx_tvalid),
      
	  //XGBE MISC interface
      .xgbe_phy_pma_pmd_type			(3'b101),		//10GBASE-ER
      .xgbe_phy_prtad					('d0),
	  .xgbe_mac_axis_pause_tdata		('d0),
	  .xgbe_mac_axis_pause_tvalid		('d0),
	  .xgbe_mac_rx_statistics_valid		(xgbe_mac_rx_statistics_valid),
	  .xgbe_mac_rx_statistics_vector	(xgbe_mac_rx_statistics_vector),
	  .xgbe_mac_tx_ifg_delay			('d0),

	  //XGBE GT channels
	  .xgbe_phy_rxn					(xgbe_phy_rxn),
      .xgbe_phy_rxp					(xgbe_phy_rxp),
      .xgbe_phy_txn					(xgbe_phy_txn),
      .xgbe_phy_txp					(xgbe_phy_txp)
    );
    assign xgbe_phy_up = xgbe_phy_core_status[0]; 
    rocket_DoCE_SoC_wrapper     u_rocket_DoCE_SoC(
	  //PL DDR3
 	  .PL_DDR3_addr					(PL_DDR3_addr),
 	  .PL_DDR3_ba					(PL_DDR3_ba),
 	  .PL_DDR3_cas_n				(PL_DDR3_cas_n),
 	  .PL_DDR3_ck_n					(PL_DDR3_ck_n),
 	  .PL_DDR3_ck_p					(PL_DDR3_ck_p),
 	  .PL_DDR3_cke					(PL_DDR3_cke),
 	  .PL_DDR3_cs_n					(PL_DDR3_cs_n),
 	  .PL_DDR3_dm					(PL_DDR3_dm),
 	  .PL_DDR3_dq					(PL_DDR3_dq),
 	  .PL_DDR3_dqs_n				(PL_DDR3_dqs_n),
 	  .PL_DDR3_dqs_p				(PL_DDR3_dqs_p),
 	  .PL_DDR3_odt					(PL_DDR3_odt),
 	  .PL_DDR3_ras_n				(PL_DDR3_ras_n),
 	  .PL_DDR3_reset_n				(PL_DDR3_reset_n),
 	  .PL_DDR3_we_n					(PL_DDR3_we_n),
	  //DoCE AXI-Lite
	  .doce_axi_lite_master_araddr	(doce_axi_lite_slave_araddr),    
	  .doce_axi_lite_master_arready	(doce_axi_lite_slave_arready),  
	  .doce_axi_lite_master_arvalid	(doce_axi_lite_slave_arvalid),  
	  .doce_axi_lite_master_awaddr	(doce_axi_lite_slave_awaddr),    
	  .doce_axi_lite_master_awready	(doce_axi_lite_slave_awready),  
	  .doce_axi_lite_master_awvalid	(doce_axi_lite_slave_awvalid),  
	  .doce_axi_lite_master_bready	(doce_axi_lite_slave_bready),    
	  .doce_axi_lite_master_bresp	(doce_axi_lite_slave_bresp),      
	  .doce_axi_lite_master_bvalid	(doce_axi_lite_slave_bvalid),    
	  .doce_axi_lite_master_rdata	(doce_axi_lite_slave_rdata),      
	  .doce_axi_lite_master_rready	(doce_axi_lite_slave_rready),    
	  .doce_axi_lite_master_rresp	(doce_axi_lite_slave_rresp),      
	  .doce_axi_lite_master_rvalid	(doce_axi_lite_slave_rvalid),    
	  .doce_axi_lite_master_wdata	(doce_axi_lite_slave_wdata),      
	  .doce_axi_lite_master_wready	(doce_axi_lite_slave_wready),    
	  .doce_axi_lite_master_wstrb	(doce_axi_lite_slave_wstrb),      
	  .doce_axi_lite_master_wvalid	(doce_axi_lite_slave_wvalid),  
	  //DoCE AXI Master
	  .doce_axi_master_araddr		({4'd2,doce_axi_master_araddr[27:0]}),            
	  .doce_axi_master_arburst		(doce_axi_master_arburst),          
	  .doce_axi_master_arcache		(doce_axi_master_arcache),          
	  .doce_axi_master_arid			(doce_axi_master_arid),
	  .doce_axi_master_arlen		(doce_axi_master_arlen),
	  .doce_axi_master_arlock		(doce_axi_master_arlock),            
	  .doce_axi_master_arprot		(doce_axi_master_arprot),            
	  .doce_axi_master_arqos		(doce_axi_master_arqos),
	  .doce_axi_master_arready		(doce_axi_master_arready),          
	  .doce_axi_master_arsize		(doce_axi_master_arsize),            
	  .doce_axi_master_arvalid		(doce_axi_master_arvalid),          
	  .doce_axi_master_awaddr		({4'd2,doce_axi_master_awaddr[27:0]}),            
	  .doce_axi_master_awburst		(doce_axi_master_awburst),          
	  .doce_axi_master_awcache		(doce_axi_master_awcache),          
	  .doce_axi_master_awid			(doce_axi_master_awid),
	  .doce_axi_master_awlen		(doce_axi_master_awlen),
	  .doce_axi_master_awlock		(doce_axi_master_awlock),            
	  .doce_axi_master_awprot		(doce_axi_master_awprot),            
	  .doce_axi_master_awqos		(doce_axi_master_awqos),
	  .doce_axi_master_awready		(doce_axi_master_awready),          
	  .doce_axi_master_awsize		(doce_axi_master_awsize),            
	  .doce_axi_master_awvalid		(doce_axi_master_awvalid),          
	  .doce_axi_master_bid			(doce_axi_master_bid),
	  .doce_axi_master_bready		(doce_axi_master_bready),            
	  .doce_axi_master_bresp		(doce_axi_master_bresp),
	  .doce_axi_master_bvalid		(doce_axi_master_bvalid),            
	  .doce_axi_master_rdata		(doce_axi_master_rdata),
	  .doce_axi_master_rid			(doce_axi_master_rid),
	  .doce_axi_master_rlast		(doce_axi_master_rlast),
	  .doce_axi_master_rready		(doce_axi_master_rready),            
	  .doce_axi_master_rresp		(doce_axi_master_rresp),
	  .doce_axi_master_rvalid		(doce_axi_master_rvalid),            
	  .doce_axi_master_wdata		(doce_axi_master_wdata),
	  .doce_axi_master_wlast		(doce_axi_master_wlast),
	  .doce_axi_master_wready		(doce_axi_master_wready),            
	  .doce_axi_master_wstrb		(doce_axi_master_wstrb),
	  .doce_axi_master_wvalid		(doce_axi_master_wvalid), 

	  .hcpf_master_araddr			(hcpf_M_AXI_araddr),
      .hcpf_master_arburst			(hcpf_M_AXI_arburst),
      .hcpf_master_arcache			(hcpf_M_AXI_arcache),
      .hcpf_master_arid				(hcpf_M_AXI_arid),
      .hcpf_master_arlen			(hcpf_M_AXI_arlen),
      .hcpf_master_arlock			(hcpf_M_AXI_arlock),
      .hcpf_master_arprot			(hcpf_M_AXI_arprot),
      .hcpf_master_arqos			(hcpf_M_AXI_arqos),
      .hcpf_master_arready			(hcpf_M_AXI_arready),
      .hcpf_master_arsize			(hcpf_M_AXI_arsize),
      .hcpf_master_arvalid			(hcpf_M_AXI_arvalid),
      .hcpf_master_awaddr			(hcpf_M_AXI_awaddr),
      .hcpf_master_awburst			(hcpf_M_AXI_awburst),
      .hcpf_master_awcache			(hcpf_M_AXI_awcache),
      .hcpf_master_awid				(hcpf_M_AXI_awid),
      .hcpf_master_awlen			(hcpf_M_AXI_awlen),
      .hcpf_master_awlock			(hcpf_M_AXI_awlock),
      .hcpf_master_awprot			(hcpf_M_AXI_awprot),
      .hcpf_master_awqos			(hcpf_M_AXI_awqos),
      .hcpf_master_awready			(hcpf_M_AXI_awready),
      .hcpf_master_awsize			(hcpf_M_AXI_awsize),
      .hcpf_master_awvalid			(hcpf_M_AXI_awvalid),
      .hcpf_master_bid				(hcpf_M_AXI_bid),
      .hcpf_master_bready			(hcpf_M_AXI_bready),
      .hcpf_master_bresp			(hcpf_M_AXI_bresp),
      .hcpf_master_bvalid			(hcpf_M_AXI_bvalid),
      .hcpf_master_rdata			(hcpf_M_AXI_rdata),
      .hcpf_master_rid				(hcpf_M_AXI_rid),
      .hcpf_master_rlast			(hcpf_M_AXI_rlast),
      .hcpf_master_rready			(hcpf_M_AXI_rready),
      .hcpf_master_rresp			(hcpf_M_AXI_rresp),
      .hcpf_master_rvalid			(hcpf_M_AXI_rvalid),
      .hcpf_master_wdata			(hcpf_M_AXI_wdata),
      .hcpf_master_wlast			(hcpf_M_AXI_wlast),
      .hcpf_master_wready			(hcpf_M_AXI_wready),
      .hcpf_master_wstrb			(hcpf_M_AXI_wstrb),
      .hcpf_master_wvalid			(hcpf_M_AXI_wvalid),
      .io_mmio_axi_araddr			(io_mmio_axi_ar_bits_addr),
      .io_mmio_axi_arprot			(),
      .io_mmio_axi_arready			(io_mmio_axi_ar_ready),
      .io_mmio_axi_arvalid			(io_mmio_axi_ar_valid),
      .io_mmio_axi_awaddr			(io_mmio_axi_aw_bits_addr),
      .io_mmio_axi_awprot			(),
      .io_mmio_axi_awready			(io_mmio_axi_aw_ready),
      .io_mmio_axi_awvalid			(io_mmio_axi_aw_valid),
      .io_mmio_axi_bready			(io_mmio_axi_b_ready),
      .io_mmio_axi_bresp			(io_mmio_axi_b_bits_resp),
      .io_mmio_axi_bvalid			(io_mmio_axi_b_valid),
      .io_mmio_axi_rdata			(io_mmio_axi_r_bits_data),
      .io_mmio_axi_rready			(io_mmio_axi_r_ready),
      .io_mmio_axi_rresp			(io_mmio_axi_r_bits_resp),
      .io_mmio_axi_rvalid			(io_mmio_axi_r_valid),
      .io_mmio_axi_wdata			(io_mmio_axi_w_bits_data),
      .io_mmio_axi_wready			(io_mmio_axi_w_ready),
      .io_mmio_axi_wstrb			(io_mmio_axi_w_bits_strb),
      .io_mmio_axi_wvalid			(io_mmio_axi_w_valid),	
      .mbus_master_araddr			(mbus_M_AXI_araddr),
      .mbus_master_arburst			(mbus_M_AXI_arburst),
      .mbus_master_arcache			(mbus_M_AXI_arcache),
      .mbus_master_arid				(mbus_M_AXI_arid),
      .mbus_master_arlen			(mbus_M_AXI_arlen),
      .mbus_master_arlock			(mbus_M_AXI_arlock),
      .mbus_master_arprot			(mbus_M_AXI_arprot),	
      .mbus_master_arqos			(mbus_M_AXI_arqos),
      .mbus_master_arready			(mbus_M_AXI_arready),
      .mbus_master_arsize			(mbus_M_AXI_arsize),
      .mbus_master_arvalid			(mbus_M_AXI_arvalid),
      .mbus_master_awaddr			(mbus_M_AXI_awaddr),
      .mbus_master_awburst			(mbus_M_AXI_awburst),
      .mbus_master_awcache			(mbus_M_AXI_awcache),
      .mbus_master_awid				(mbus_M_AXI_awid),
      .mbus_master_awlen			(mbus_M_AXI_awlen),
      .mbus_master_awlock			(mbus_M_AXI_awlock),
      .mbus_master_awprot			(mbus_M_AXI_awprot),
      .mbus_master_awqos			(mbus_M_AXI_awqos),
      .mbus_master_awready			(mbus_M_AXI_awready),
      .mbus_master_awsize			(mbus_M_AXI_awsize),
      .mbus_master_awvalid			(mbus_M_AXI_awvalid),
      .mbus_master_bid				(mbus_M_AXI_bid),
      .mbus_master_bready			(mbus_M_AXI_bready),
      .mbus_master_bresp			(mbus_M_AXI_bresp),
      .mbus_master_bvalid			(mbus_M_AXI_bvalid),
      .mbus_master_rdata			(mbus_M_AXI_rdata),
      .mbus_master_rid				(mbus_M_AXI_rid),
      .mbus_master_rlast			(mbus_M_AXI_rlast),
      .mbus_master_rready			(mbus_M_AXI_rready),
      .mbus_master_rresp			(mbus_M_AXI_rresp),
      .mbus_master_rvalid			(mbus_M_AXI_rvalid),
      .mbus_master_wdata			(mbus_M_AXI_wdata),
      .mbus_master_wlast			(mbus_M_AXI_wlast),
      .mbus_master_wready			(mbus_M_AXI_wready),
      .mbus_master_wstrb			(mbus_M_AXI_wstrb),
      .mbus_master_wvalid			(mbus_M_AXI_wvalid),

	  .tile_clock						(tile_clock),
      .tile_resetn						(tile_aresetn),
	  .ref_clk						(clk_ref_200),
	  .mcb_clk						(mcb_clk),
	  .mig_calib_done				(pl_ddr3_calib_done),
	  .mig_ic_resetn				(mig_ic_resetn),
	  .mig_pl_ddr3_reset			(~ps_user_reset_n)
	);
    
	doce_top #(
	.AXI_ADDR_WIDTH			(32),
	.AXI_DATA_WIDTH			(8),			//64-bit
    .AXI_ID_WIDTH			(6),
	.AXI_SIZE_WIDTH			(3),
    .AXI_BASE_ADDR			(32'h30000000),
    .AXI_LITE_BASE_ADDR		(32'h60000000)
	)u_doce_top(
    .clk					(mcb_clk),
    .reset					(~mig_ic_resetn),

	/*DoCE Tx interface*/
    .doce_axis_txd_tdata	(doce_axis_txd_tdata),
    .doce_axis_txd_tkeep	(doce_axis_txd_tkeep),
    .doce_axis_txd_tlast	(doce_axis_txd_tlast),
    .doce_axis_txd_tvalid	(doce_axis_txd_tvalid),
    .doce_axis_txd_tready	(doce_axis_txd_tready),
  
	/*DoCE Rx interface*/
    .doce_axis_rxd_tdata	(doce_axis_rxd_tdata),
    .doce_axis_rxd_tkeep	(doce_axis_rxd_tkeep),
    .doce_axis_rxd_tlast	(doce_axis_rxd_tlast),
    .doce_axis_rxd_tvalid	(doce_axis_rxd_tvalid),
    .doce_axis_rxd_tready	(doce_axis_rxd_tready),   
   
	/*AXI Slave interface*/
    .doce_axi_slave_awaddr	(doce_axi_slave_awaddr),
    .doce_axi_slave_awid	(doce_axi_slave_awid),
    .doce_axi_slave_awlen	(doce_axi_slave_awlen),
    .doce_axi_slave_awsize	(doce_axi_slave_awsize),
    .doce_axi_slave_awburst	(doce_axi_slave_awburst),
    .doce_axi_slave_awlock	(doce_axi_slave_awlock),
    .doce_axi_slave_awvalid	(doce_axi_slave_awvalid),
    .doce_axi_slave_awready	(doce_axi_slave_awready),

    .doce_axi_slave_araddr	(doce_axi_slave_araddr),
    .doce_axi_slave_arid	(doce_axi_slave_arid),
    .doce_axi_slave_arlen	(doce_axi_slave_arlen),
    .doce_axi_slave_arsize	(doce_axi_slave_arsize),
    .doce_axi_slave_arburst	(doce_axi_slave_arburst),
    .doce_axi_slave_arlock	(doce_axi_slave_arlock),
    .doce_axi_slave_arvalid	(doce_axi_slave_arvalid),
    .doce_axi_slave_arready	(doce_axi_slave_arready), 
       
    .doce_axi_slave_wdata	(doce_axi_slave_wdata),
    .doce_axi_slave_wstrb	(doce_axi_slave_wstrb),
    .doce_axi_slave_wlast	(doce_axi_slave_wlast),
    .doce_axi_slave_wvalid	(doce_axi_slave_wvalid),
    .doce_axi_slave_wready	(doce_axi_slave_wready),

    .doce_axi_slave_rdata	(doce_axi_slave_rdata),
    .doce_axi_slave_rid		(doce_axi_slave_rid),
    .doce_axi_slave_rlast	(doce_axi_slave_rlast),
    .doce_axi_slave_rresp	(doce_axi_slave_rresp),
    .doce_axi_slave_rvalid	(doce_axi_slave_rvalid),
    .doce_axi_slave_rready	(doce_axi_slave_rready),

    .doce_axi_slave_bresp	(doce_axi_slave_bresp),
    .doce_axi_slave_bid		(doce_axi_slave_bid),
    .doce_axi_slave_bvalid	(doce_axi_slave_bvalid),
    .doce_axi_slave_bready	(doce_axi_slave_bready),

	/*AXI Master interface*/
    .doce_axi_master_awaddr		(doce_axi_master_awaddr),
    .doce_axi_master_awid		(doce_axi_master_awid),   //include 4bit connection_id
    .doce_axi_master_awlen		(doce_axi_master_awlen),
    .doce_axi_master_awsize		(doce_axi_master_awsize),
    .doce_axi_master_awburst	(doce_axi_master_awburst),
    .doce_axi_master_awcache	(doce_axi_master_awcache),
    .doce_axi_master_awlock		(doce_axi_master_awlock),
    .doce_axi_master_awvalid	(doce_axi_master_awvalid),
    .doce_axi_master_awready	(doce_axi_master_awready),

    .doce_axi_master_araddr		(doce_axi_master_araddr),
    .doce_axi_master_arid		(doce_axi_master_arid),	//include 4bit connection_id
    .doce_axi_master_arlen		(doce_axi_master_arlen),
    .doce_axi_master_arsize		(doce_axi_master_arsize),
    .doce_axi_master_arcache	(doce_axi_master_arcache),
    .doce_axi_master_arburst	(doce_axi_master_arburst),
    .doce_axi_master_arlock		(doce_axi_master_arlock),
    .doce_axi_master_arvalid	(doce_axi_master_arvalid),
    .doce_axi_master_arready	(doce_axi_master_arready), 
       
    .doce_axi_master_wdata		(doce_axi_master_wdata),
    .doce_axi_master_wstrb		(doce_axi_master_wstrb),
    .doce_axi_master_wlast		(doce_axi_master_wlast),
    .doce_axi_master_wvalid		(doce_axi_master_wvalid),
    .doce_axi_master_wready		(doce_axi_master_wready),

    .doce_axi_master_rdata		(doce_axi_master_rdata),
    .doce_axi_master_rid		(doce_axi_master_rid),    //include 4bit connection_id
    .doce_axi_master_rlast		(doce_axi_master_rlast),
    .doce_axi_master_rresp		(doce_axi_master_rresp),
    .doce_axi_master_rvalid		(doce_axi_master_rvalid),
    .doce_axi_master_rready		(doce_axi_master_rready),

    .doce_axi_master_bresp		(doce_axi_master_bresp),
    .doce_axi_master_bid		(doce_axi_master_bid), //include 4bit connection_id
    .doce_axi_master_bvalid		(doce_axi_master_bvalid),
    .doce_axi_master_bready		(doce_axi_master_bready),
 
	/*AXI-Lite slave interface*/
    .doce_axi_lite_slave_awaddr		(doce_axi_lite_slave_awaddr),
    .doce_axi_lite_slave_awvalid	(doce_axi_lite_slave_awvalid),
    .doce_axi_lite_slave_awready	(doce_axi_lite_slave_awready),
    
    .doce_axi_lite_slave_araddr		(doce_axi_lite_slave_araddr),
    .doce_axi_lite_slave_arvalid	(doce_axi_lite_slave_arvalid),
    .doce_axi_lite_slave_arready	(doce_axi_lite_slave_arready),
    
    .doce_axi_lite_slave_wdata		(doce_axi_lite_slave_wdata),
    .doce_axi_lite_slave_wstrb		(doce_axi_lite_slave_wstrb),
    .doce_axi_lite_slave_wvalid		(doce_axi_lite_slave_wvalid),
    .doce_axi_lite_slave_wready		(doce_axi_lite_slave_wready),
    
    .doce_axi_lite_slave_rdata		(doce_axi_lite_slave_rdata),
    .doce_axi_lite_slave_rresp		(doce_axi_lite_slave_rresp),
    .doce_axi_lite_slave_rvalid		(doce_axi_lite_slave_rvalid),
    .doce_axi_lite_slave_rready		(doce_axi_lite_slave_rready),
    
    .doce_axi_lite_slave_bresp		(doce_axi_lite_slave_bresp),
    .doce_axi_lite_slave_bvalid		(doce_axi_lite_slave_bvalid),
    .doce_axi_lite_slave_bready		(doce_axi_lite_slave_bready),

	/*AXI-Lite master interface to DoCE MAC/IP address register*/
    .m_axi_doce_mac_awaddr		(m_axi_doce_mac_awaddr),
    .m_axi_doce_mac_awvalid		(m_axi_doce_mac_awvalid),
    .m_axi_doce_mac_awready		(m_axi_doce_mac_awready),
    
    .m_axi_doce_mac_araddr		(m_axi_doce_mac_araddr),
    .m_axi_doce_mac_arvalid		(m_axi_doce_mac_arvalid),
    .m_axi_doce_mac_arready		(m_axi_doce_mac_arready),
    
    .m_axi_doce_mac_wdata		(m_axi_doce_mac_wdata),
    .m_axi_doce_mac_wstrb		(m_axi_doce_mac_wstrb),
    .m_axi_doce_mac_wvalid		(m_axi_doce_mac_wvalid),
    .m_axi_doce_mac_wready		(m_axi_doce_mac_wready),
    
    .m_axi_doce_mac_rdata		(m_axi_doce_mac_rdata),
    .m_axi_doce_mac_rresp		(m_axi_doce_mac_rresp),
    .m_axi_doce_mac_rvalid		(m_axi_doce_mac_rvalid),
    .m_axi_doce_mac_rready		(m_axi_doce_mac_rready),
    
    .m_axi_doce_mac_bresp		(m_axi_doce_mac_bresp),
    .m_axi_doce_mac_bvalid		(m_axi_doce_mac_bvalid),
    .m_axi_doce_mac_bready		(m_axi_doce_mac_bready),

	/*DoCE MAC address */
	.doce_mac_addr				(doce_mac_id),
	.doce_ip_addr				()
	);
	
	always @(posedge tile_clock)
	begin
		dcm_locked <= {dcm_locked[0],pl_ddr3_calib_done};
	end
	rocketchip_wrapper u_rocket_chip(
	.DDR_addr				(DDR_addr),
    .DDR_ba					(DDR_ba),
    .DDR_cas_n				(DDR_cas_n),
    .DDR_ck_n				(DDR_ck_n),
    .DDR_ck_p				(DDR_ck_p),
    .DDR_cke				(DDR_cke),
    .DDR_cs_n				(DDR_cs_n),
    .DDR_dm					(DDR_dm),
    .DDR_dq					(DDR_dq),
    .DDR_dqs_n				(DDR_dqs_n),
    .DDR_dqs_p				(DDR_dqs_p),
    .DDR_odt				(DDR_odt),
    .DDR_ras_n				(DDR_ras_n),
    .DDR_reset_n			(DDR_reset_n),
    .DDR_we_n				(DDR_we_n),
    .FIXED_IO_ddr_vrn		(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp		(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio			(FIXED_IO_mio),
    .FIXED_IO_ps_clk		(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb		(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb		(FIXED_IO_ps_srstb),
	
	.hcpf_M_AXI_araddr		(hcpf_M_AXI_araddr),
	.hcpf_M_AXI_arburst		(hcpf_M_AXI_arburst),
	.hcpf_M_AXI_arcache		(hcpf_M_AXI_arcache),
	.hcpf_M_AXI_arid		(hcpf_M_AXI_arid),
	.hcpf_M_AXI_arlen		(hcpf_M_AXI_arlen),
	.hcpf_M_AXI_arlock		(hcpf_M_AXI_arlock),
	.hcpf_M_AXI_arprot		(hcpf_M_AXI_arprot),
	.hcpf_M_AXI_arqos		(hcpf_M_AXI_arqos),
	.hcpf_M_AXI_arready		(hcpf_M_AXI_arready),
	.hcpf_M_AXI_arregion	(hcpf_M_AXI_arregion),
	.hcpf_M_AXI_arsize		(hcpf_M_AXI_arsize),
	.hcpf_M_AXI_arvalid		(hcpf_M_AXI_arvalid),
	.hcpf_M_AXI_awaddr		(hcpf_M_AXI_awaddr),
	.hcpf_M_AXI_awburst		(hcpf_M_AXI_awburst),
	.hcpf_M_AXI_awcache		(hcpf_M_AXI_awcache),
	.hcpf_M_AXI_awid		(hcpf_M_AXI_awid),
	.hcpf_M_AXI_awlen		(hcpf_M_AXI_awlen),
	.hcpf_M_AXI_awlock		(hcpf_M_AXI_awlock),
	.hcpf_M_AXI_awprot		(hcpf_M_AXI_awprot),
	.hcpf_M_AXI_awqos		(hcpf_M_AXI_awqos),
	.hcpf_M_AXI_awready		(hcpf_M_AXI_awready),
	.hcpf_M_AXI_awregion	(hcpf_M_AXI_awregion),
	.hcpf_M_AXI_awsize		(hcpf_M_AXI_awsize),
	.hcpf_M_AXI_awvalid		(hcpf_M_AXI_awvalid),
	.hcpf_M_AXI_bid			(hcpf_M_AXI_bid),
	.hcpf_M_AXI_bready		(hcpf_M_AXI_bready),
	.hcpf_M_AXI_bresp		(hcpf_M_AXI_bresp),
	.hcpf_M_AXI_bvalid		(hcpf_M_AXI_bvalid),
	.hcpf_M_AXI_rdata		(hcpf_M_AXI_rdata),
	.hcpf_M_AXI_rid			(hcpf_M_AXI_rid),
	.hcpf_M_AXI_rlast		(hcpf_M_AXI_rlast),
	.hcpf_M_AXI_rready		(hcpf_M_AXI_rready),
	.hcpf_M_AXI_rresp		(hcpf_M_AXI_rresp),
	.hcpf_M_AXI_rvalid		(hcpf_M_AXI_rvalid),
	.hcpf_M_AXI_wdata		(hcpf_M_AXI_wdata),
	.hcpf_M_AXI_wlast		(hcpf_M_AXI_wlast),
	.hcpf_M_AXI_wready		(hcpf_M_AXI_wready),
	.hcpf_M_AXI_wstrb		(hcpf_M_AXI_wstrb),
	.hcpf_M_AXI_wvalid		(hcpf_M_AXI_wvalid),
	
	.mbus_M_AXI_araddr		(mbus_M_AXI_araddr),
	.mbus_M_AXI_arburst		(mbus_M_AXI_arburst),
	.mbus_M_AXI_arcache		(mbus_M_AXI_arcache),
	.mbus_M_AXI_arid		(mbus_M_AXI_arid),
	.mbus_M_AXI_arlen		(mbus_M_AXI_arlen),
	.mbus_M_AXI_arlock		(mbus_M_AXI_arlock),
	.mbus_M_AXI_arprot		(mbus_M_AXI_arprot),
	.mbus_M_AXI_arqos		(mbus_M_AXI_arqos),
	.mbus_M_AXI_arready		(mbus_M_AXI_arready),
	.mbus_M_AXI_arregion	(mbus_M_AXI_arregion),
	.mbus_M_AXI_arsize		(mbus_M_AXI_arsize),
	.mbus_M_AXI_arvalid		(mbus_M_AXI_arvalid),
	.mbus_M_AXI_awaddr		(mbus_M_AXI_awaddr),
	.mbus_M_AXI_awburst		(mbus_M_AXI_awburst),
	.mbus_M_AXI_awcache		(mbus_M_AXI_awcache),
	.mbus_M_AXI_awid		(mbus_M_AXI_awid),
	.mbus_M_AXI_awlen		(mbus_M_AXI_awlen),
	.mbus_M_AXI_awlock		(mbus_M_AXI_awlock),
	.mbus_M_AXI_awprot		(mbus_M_AXI_awprot),
	.mbus_M_AXI_awqos		(mbus_M_AXI_awqos),
	.mbus_M_AXI_awready		(mbus_M_AXI_awready),
	.mbus_M_AXI_awregion	(mbus_M_AXI_awregion),
	.mbus_M_AXI_awsize		(mbus_M_AXI_awsize),
	.mbus_M_AXI_awvalid		(mbus_M_AXI_awvalid),
	.mbus_M_AXI_bid			(mbus_M_AXI_bid),
	.mbus_M_AXI_bready		(mbus_M_AXI_bready),
	.mbus_M_AXI_bresp		(mbus_M_AXI_bresp),
	.mbus_M_AXI_bvalid		(mbus_M_AXI_bvalid),
	.mbus_M_AXI_rdata		(mbus_M_AXI_rdata),
	.mbus_M_AXI_rid			(mbus_M_AXI_rid),
	.mbus_M_AXI_rlast		(mbus_M_AXI_rlast),
	.mbus_M_AXI_rready		(mbus_M_AXI_rready),
	.mbus_M_AXI_rresp		(mbus_M_AXI_rresp),
	.mbus_M_AXI_rvalid		(mbus_M_AXI_rvalid),
	.mbus_M_AXI_wdata		(mbus_M_AXI_wdata),
	.mbus_M_AXI_wlast		(mbus_M_AXI_wlast),
	.mbus_M_AXI_wready		(mbus_M_AXI_wready),
	.mbus_M_AXI_wstrb		(mbus_M_AXI_wstrb),
	.mbus_M_AXI_wvalid		(mbus_M_AXI_wvalid),

	.tile_M_AXI_araddr		(doce_axi_slave_araddr),
	.tile_M_AXI_arburst		(doce_axi_slave_arburst),
	.tile_M_AXI_arcache		(),
	.tile_M_AXI_arid		(doce_axi_slave_arid),
	.tile_M_AXI_arlen		(doce_axi_slave_arlen),
	.tile_M_AXI_arlock		(doce_axi_slave_arlock),
	.tile_M_AXI_arprot		(),
	.tile_M_AXI_arqos		(),
	.tile_M_AXI_arready		(doce_axi_slave_arready),
	.tile_M_AXI_arregion		(),
	.tile_M_AXI_arsize		(doce_axi_slave_arsize),
	.tile_M_AXI_arvalid		(doce_axi_slave_arvalid),
	.tile_M_AXI_awaddr		(doce_axi_slave_awaddr),
	.tile_M_AXI_awburst		(doce_axi_slave_awburst),
	.tile_M_AXI_awcache		(),
	.tile_M_AXI_awid		(doce_axi_slave_awid),
	.tile_M_AXI_awlen		(doce_axi_slave_awlen),
	.tile_M_AXI_awlock		(doce_axi_slave_awlock),
	.tile_M_AXI_awprot		(),
	.tile_M_AXI_awqos		(),
	.tile_M_AXI_awready		(doce_axi_slave_awready),
	.tile_M_AXI_awregion		(),
	.tile_M_AXI_awsize		(doce_axi_slave_awsize),
	.tile_M_AXI_awvalid		(doce_axi_slave_awvalid),
	.tile_M_AXI_bid			(doce_axi_slave_bid),
	.tile_M_AXI_bready		(doce_axi_slave_bready),
	.tile_M_AXI_bresp		(doce_axi_slave_bresp),
	.tile_M_AXI_bvalid		(doce_axi_slave_bvalid),
	.tile_M_AXI_rdata		(doce_axi_slave_rdata),
	.tile_M_AXI_rid			(doce_axi_slave_rid),
	.tile_M_AXI_rlast		(doce_axi_slave_rlast),
	.tile_M_AXI_rready		(doce_axi_slave_rready),
	.tile_M_AXI_rresp		(doce_axi_slave_rresp),
	.tile_M_AXI_rvalid		(doce_axi_slave_rvalid),
	.tile_M_AXI_wdata		(doce_axi_slave_wdata),
	.tile_M_AXI_wlast		(doce_axi_slave_wlast),
	.tile_M_AXI_wready		(doce_axi_slave_wready),
	.tile_M_AXI_wstrb		(doce_axi_slave_wstrb),
	.tile_M_AXI_wvalid		(doce_axi_slave_wvalid),
	
	.io_mmio_axi_aw_ready	(io_mmio_axi_aw_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_aw_valid	(io_mmio_axi_aw_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_aw_bits_addr(io_mmio_axi_aw_bits_addr), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_w_ready	(io_mmio_axi_w_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_w_valid	(io_mmio_axi_w_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_w_bits_data(io_mmio_axi_w_bits_data), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_w_bits_strb(io_mmio_axi_w_bits_strb), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_b_ready	(io_mmio_axi_b_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_b_valid	(io_mmio_axi_b_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_b_bits_resp(io_mmio_axi_b_bits_resp), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_ar_ready	(io_mmio_axi_ar_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_ar_valid	(io_mmio_axi_ar_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_ar_bits_addr(io_mmio_axi_ar_bits_addr), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_r_ready	(io_mmio_axi_r_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_r_valid	(io_mmio_axi_r_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_r_bits_data(io_mmio_axi_r_bits_data), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	.io_mmio_axi_r_bits_resp(io_mmio_axi_r_bits_resp), // @[:Top.ZynqFPGAConfig.fir@183370.4]
	
	.mcb_clk				(mcb_clk),
	.mig_ic_resetn			(mig_ic_resetn),
	.tile_aresetn			(tile_aresetn),
	.host_clk				(tile_clock),
	.FCLK_RESET0_N(ps_user_reset_n),
	.debug_inf              (debug_inf),
	.debug_inf_1              (debug_inf_1),
            .debug_inf_2              (debug_inf_2)
	//.dcm_locked()
	);
//`ifndef differential_clock
 //   .clk					());
//`else
   // .SYSCLK_P				(clk_ref_p),
 //   .gclk_i				(clk_ref_200_i));
//`endif

endmodule