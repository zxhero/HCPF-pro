`timescale 1ns / 1ps

module doce_top #(
    parameter AXI_ADDR_WIDTH       = 44,
    parameter AXI_DATA_WIDTH       = 16,   //Byte
    parameter AXI_ID_WIDTH         = 18,
    parameter AXI_SIZE_WIDTH       = 3,
    parameter AXI_BASE_ADDR        = 44'h00040000000,
    parameter AXI_LITE_BASE_ADDR   = 44'h00080000000
)(
    input  wire                             reset,
    input  wire                             clk,

	/*DoCE Tx interface*/
    output wire [63:0]						doce_axis_txd_tdata,
    output wire [7:0]						doce_axis_txd_tkeep,
    output wire                             doce_axis_txd_tlast,
    output wire                             doce_axis_txd_tvalid,
    input  wire                             doce_axis_txd_tready,
  
	/*DoCE Rx interface*/
    input  wire [63:0]						doce_axis_rxd_tdata,
    input  wire [7:0]						doce_axis_rxd_tkeep,
    input  wire                             doce_axis_rxd_tlast,
    input  wire                             doce_axis_rxd_tvalid,
    output wire                             doce_axis_rxd_tready,   
   
	/*AXI Slave interface*/
    input  wire [AXI_ADDR_WIDTH-1:0]        doce_axi_slave_awaddr,
    input  wire [AXI_ID_WIDTH-1:0]          doce_axi_slave_awid,
    input  wire [7:0]                       doce_axi_slave_awlen,
    input  wire [AXI_SIZE_WIDTH-1:0]        doce_axi_slave_awsize,
    input  wire [1:0]                       doce_axi_slave_awburst,
    input  wire                             doce_axi_slave_awlock,
    input  wire                             doce_axi_slave_awvalid,
    output wire                             doce_axi_slave_awready,

    input  wire [AXI_ADDR_WIDTH-1:0]        doce_axi_slave_araddr,
    input  wire [AXI_ID_WIDTH-1:0]          doce_axi_slave_arid,
    input  wire [7:0]                       doce_axi_slave_arlen,
    input  wire [AXI_SIZE_WIDTH-1:0]        doce_axi_slave_arsize,
    input  wire [1:0]                       doce_axi_slave_arburst,
    input  wire                             doce_axi_slave_arlock,
    input  wire                             doce_axi_slave_arvalid,
    output wire                             doce_axi_slave_arready, 
       
    input  wire [AXI_DATA_WIDTH*8-1:0]      doce_axi_slave_wdata,
    input  wire [AXI_DATA_WIDTH-1:0]        doce_axi_slave_wstrb,
    input  wire                             doce_axi_slave_wlast,
    input  wire                             doce_axi_slave_wvalid,
    output wire                             doce_axi_slave_wready,

    output wire [AXI_DATA_WIDTH*8-1:0]      doce_axi_slave_rdata,
    output wire [AXI_ID_WIDTH-1:0]          doce_axi_slave_rid,
    output wire                             doce_axi_slave_rlast,
    output wire [1:0]                       doce_axi_slave_rresp,
    output wire                             doce_axi_slave_rvalid,
    input  wire                             doce_axi_slave_rready,

    output wire [1:0]                       doce_axi_slave_bresp,
    output wire [AXI_ID_WIDTH-1:0]          doce_axi_slave_bid,
    output wire                             doce_axi_slave_bvalid,
    input  wire                             doce_axi_slave_bready,

	/*AXI Master interface*/
    output wire [AXI_ADDR_WIDTH-1:0]        doce_axi_master_awaddr,
    output wire [AXI_ID_WIDTH+3:0]          doce_axi_master_awid,   //include 4bit connection_id
    output wire [7:0]                       doce_axi_master_awlen,
    output wire [AXI_SIZE_WIDTH-1:0]        doce_axi_master_awsize,
    output wire [1:0]                       doce_axi_master_awburst,
    output wire [3:0]                       doce_axi_master_awcache,
    output wire                             doce_axi_master_awlock,
    output wire                             doce_axi_master_awvalid,
    input  wire                             doce_axi_master_awready,

    output wire [AXI_ADDR_WIDTH-1:0]        doce_axi_master_araddr,
    output wire [AXI_ID_WIDTH+3:0]          doce_axi_master_arid,	//include 4bit connection_id
    output wire [7:0]                       doce_axi_master_arlen,
    output wire [AXI_SIZE_WIDTH-1:0]        doce_axi_master_arsize,
    output wire [3:0]                       doce_axi_master_arcache,
    output wire [1:0]                       doce_axi_master_arburst,
    output wire                             doce_axi_master_arlock,
    output wire                             doce_axi_master_arvalid,
    input  wire                             doce_axi_master_arready, 
       
    output wire [AXI_DATA_WIDTH*8-1:0]      doce_axi_master_wdata,
    output wire [AXI_DATA_WIDTH-1:0]        doce_axi_master_wstrb,
    output wire                             doce_axi_master_wlast,
    output wire                             doce_axi_master_wvalid,
    input  wire                             doce_axi_master_wready,

    input  wire [AXI_DATA_WIDTH*8-1:0]      doce_axi_master_rdata,
    input  wire [AXI_ID_WIDTH+3:0]          doce_axi_master_rid,    //include 4bit connection_id
    input  wire                             doce_axi_master_rlast,
    input  wire [1:0]                       doce_axi_master_rresp,
    input  wire                             doce_axi_master_rvalid,
    output wire                             doce_axi_master_rready,

    input  wire [1:0]                       doce_axi_master_bresp,
    input  wire [AXI_ID_WIDTH+3:0]          doce_axi_master_bid, ////include 4bit connection_id
    input  wire                             doce_axi_master_bvalid,
    output wire                             doce_axi_master_bready,
 
	/*AXI-Lite slave interface*/
    input  wire [AXI_ADDR_WIDTH-1:0]        doce_axi_lite_slave_awaddr,
    input  wire                             doce_axi_lite_slave_awvalid,
    output wire                             doce_axi_lite_slave_awready,
    
    input  wire [AXI_ADDR_WIDTH-1:0]        doce_axi_lite_slave_araddr,
    input  wire                             doce_axi_lite_slave_arvalid,
    output wire                             doce_axi_lite_slave_arready,
    
    input  wire [31:0]                      doce_axi_lite_slave_wdata,
    input  wire [3:0]                       doce_axi_lite_slave_wstrb,
    input  wire                             doce_axi_lite_slave_wvalid,
    output wire                             doce_axi_lite_slave_wready,
    
    output wire [31:0]                      doce_axi_lite_slave_rdata,
    output wire [1:0]                       doce_axi_lite_slave_rresp,
    output wire                             doce_axi_lite_slave_rvalid,
    input  wire                             doce_axi_lite_slave_rready,
    
    output wire [1:0]                       doce_axi_lite_slave_bresp,
    output wire                             doce_axi_lite_slave_bvalid,
    input  wire                             doce_axi_lite_slave_bready,

	/*AXI-Lite master interface to DoCE MAC/IP address register*/
    output wire [AXI_ADDR_WIDTH-1:0]        m_axi_doce_mac_awaddr,
    output wire                             m_axi_doce_mac_awvalid,
    input  wire                             m_axi_doce_mac_awready,
     
    output wire [AXI_ADDR_WIDTH-1:0]        m_axi_doce_mac_araddr,
    output wire                             m_axi_doce_mac_arvalid,
    input  wire                             m_axi_doce_mac_arready,
    
    output wire [31:0]                      m_axi_doce_mac_wdata,
    output wire [3:0]                       m_axi_doce_mac_wstrb,
    output wire                             m_axi_doce_mac_wvalid,
    input  wire                             m_axi_doce_mac_wready,
     
    input  wire [31:0]                      m_axi_doce_mac_rdata,
    input  wire [1:0]                       m_axi_doce_mac_rresp,
    input  wire                             m_axi_doce_mac_rvalid,
    output wire                             m_axi_doce_mac_rready,
     
    input  wire [1:0]                       m_axi_doce_mac_bresp,
    input  wire                             m_axi_doce_mac_bvalid,
    output wire                             m_axi_doce_mac_bready,

	/*DoCE MAC address */
	input wire [47:0]						doce_mac_addr,
	input wire [31:0]						doce_ip_addr
    
    
    
);


assign doce_axi_master_awcache = 4'b1111;
assign doce_axi_master_arcache = 4'b1111;

wire [44:0]	s_axi_awaddr_f = {{(45-AXI_ADDR_WIDTH){1'b0}}, (doce_axi_slave_awaddr ^ AXI_BASE_ADDR[AXI_ADDR_WIDTH-1:0])};
wire [18:0] s_axi_awid_f = {{(19-AXI_ID_WIDTH){1'b0}}, doce_axi_slave_awid};
wire [3:0] s_axi_awsize_f = {{(4-AXI_SIZE_WIDTH){1'b0}}, doce_axi_slave_awsize};

wire [44:0] s_axi_araddr_f = {{(45-AXI_ADDR_WIDTH){1'b0}}, (doce_axi_slave_araddr ^ AXI_BASE_ADDR[AXI_ADDR_WIDTH-1:0])};
wire [18:0] s_axi_arid_f = {{(19-AXI_ID_WIDTH){1'b0}}, doce_axi_slave_arid};
wire [3:0] s_axi_arsize_f = {{(4-AXI_SIZE_WIDTH){1'b0}}, doce_axi_slave_arsize};

wire [128:0] s_axi_wdata_f = {{(129-AXI_DATA_WIDTH*8){1'b0}}, doce_axi_slave_wdata};
wire [16:0] s_axi_wstrb_f = {{(17-AXI_DATA_WIDTH){1'b0}}, doce_axi_slave_wstrb};

wire [127:0] s_axi_rdata_f;  
wire [17:0] s_axi_rid_f;
assign doce_axi_slave_rdata = s_axi_rdata_f[AXI_DATA_WIDTH*8-1:0];
assign doce_axi_slave_rid = s_axi_rid_f[AXI_ID_WIDTH-1:0];

wire [17:0] s_axi_bid_f;
assign doce_axi_slave_bid = s_axi_bid_f[AXI_ID_WIDTH-1:0];

wire [43:0] m_axi_awaddr_f;
wire [21:0] m_axi_awid_f;
wire [2:0] m_axi_awsize_f;
assign doce_axi_master_awaddr = m_axi_awaddr_f[AXI_ADDR_WIDTH-1:0];
assign doce_axi_master_awid = {m_axi_awid_f[21:18], m_axi_awid_f[AXI_ID_WIDTH-1:0]};
assign doce_axi_master_awsize = m_axi_awsize_f[AXI_SIZE_WIDTH-1:0];

wire [43:0] m_axi_araddr_f;
wire [21:0] m_axi_arid_f;
wire [2:0] m_axi_arsize_f;
assign doce_axi_master_araddr = m_axi_araddr_f[AXI_ADDR_WIDTH-1:0];
assign doce_axi_master_arid = {m_axi_arid_f[21:18], m_axi_arid_f[AXI_ID_WIDTH-1:0]};
assign doce_axi_master_arsize = m_axi_arsize_f[AXI_SIZE_WIDTH-1:0];

wire [127:0] m_axi_wdata_f;
wire [15:0] m_axi_wstrb_f;
assign doce_axi_master_wdata = m_axi_wdata_f[AXI_DATA_WIDTH*8-1:0];
assign doce_axi_master_wstrb = m_axi_wstrb_f[AXI_DATA_WIDTH-1:0];

wire [128:0] m_axi_rdata_f = {{(129-AXI_DATA_WIDTH*8){1'b0}}, doce_axi_master_rdata};  

wire [18:0] m_axi_rid_f_mid = {{(19-AXI_ID_WIDTH){1'b0}}, doce_axi_master_rid[AXI_ID_WIDTH-1:0]};
wire [21:0] m_axi_rid_f = {doce_axi_master_rid[AXI_ID_WIDTH+3:AXI_ID_WIDTH], m_axi_rid_f_mid[17:0]};

wire [18:0] m_axi_bid_f_mid = {{(19-AXI_ID_WIDTH){1'b0}}, doce_axi_master_bid[AXI_ID_WIDTH-1:0]};
wire [21:0] m_axi_bid_f = {doce_axi_master_bid[AXI_ID_WIDTH+3:AXI_ID_WIDTH],m_axi_bid_f_mid[17:0]};

wire [44:0] s_axi_lite_awaddr_f = {{(45-AXI_ADDR_WIDTH){1'b0}}, (doce_axi_lite_slave_awaddr ^ AXI_LITE_BASE_ADDR[AXI_ADDR_WIDTH-1:0])};
wire [44:0] s_axi_lite_araddr_f = {{(45-AXI_ADDR_WIDTH){1'b0}}, (doce_axi_lite_slave_araddr ^ AXI_LITE_BASE_ADDR[AXI_ADDR_WIDTH-1:0])};

wire [43:0] m_axi_doce_mac_awaddr_f;
wire [43:0] m_axi_doce_mac_araddr_f;
assign m_axi_doce_mac_awaddr = m_axi_doce_mac_awaddr_f[AXI_ADDR_WIDTH-1:0];
assign m_axi_doce_mac_araddr = m_axi_doce_mac_araddr_f[AXI_ADDR_WIDTH-1:0];

wire [AXI_ADDR_WIDTH-1:0] m_axi_doce_trp_layer_awaddr;
wire                      m_axi_doce_trp_layer_awvalid;
wire                      m_axi_doce_trp_layer_awready;

wire [AXI_ADDR_WIDTH-1:0] m_axi_doce_trp_layer_araddr;
wire                      m_axi_doce_trp_layer_arvalid;
wire                      m_axi_doce_trp_layer_arready;

wire [31:0]               m_axi_doce_trp_layer_wdata;
wire [3:0]                m_axi_doce_trp_layer_wstrb;
wire                      m_axi_doce_trp_layer_wvalid;
wire                      m_axi_doce_trp_layer_wready;

wire [31:0]               m_axi_doce_trp_layer_rdata;
wire [1:0]                m_axi_doce_trp_layer_rresp;
wire                      m_axi_doce_trp_layer_rvalid;
wire                      m_axi_doce_trp_layer_rready;

wire [1:0]                m_axi_doce_trp_layer_bresp;
wire                      m_axi_doce_trp_layer_bvalid;
wire                      m_axi_doce_trp_layer_bready;

wire [43:0] m_axi_doce_trp_layer_awaddr_f;
wire [43:0] m_axi_doce_trp_layer_araddr_f;
assign m_axi_doce_trp_layer_awaddr = m_axi_doce_trp_layer_awaddr_f[AXI_ADDR_WIDTH-1:0];
assign m_axi_doce_trp_layer_araddr = m_axi_doce_trp_layer_araddr_f[AXI_ADDR_WIDTH-1:0];

//AXI Stream interface
wire [127:0]    axis_txd_trans_layer_tdata;
wire [15:0]     axis_txd_trans_layer_tkeep;
wire [16:0]     axis_txd_trans_layer_tuser;
wire            axis_txd_trans_layer_tlast;
wire            axis_txd_trans_layer_tvalid;
wire            axis_txd_trans_layer_tready;

wire [127:0]    axis_rxd_trans_layer_tdata;
wire [15:0]     axis_rxd_trans_layer_tkeep;
wire [3:0]      axis_rxd_trans_layer_tuser;
wire            axis_rxd_trans_layer_tlast;
wire            axis_rxd_trans_layer_tvalid;
wire            axis_rxd_trans_layer_tready;   




doce_transaction_layer		u_deoi_transaction_layer (
   .reset_in                        (reset),
   .clk                             (clk),
   
   .trans_axis_txd_tdata            (axis_txd_trans_layer_tdata),
   .trans_axis_txd_tkeep            (axis_txd_trans_layer_tkeep),
   .trans_axis_txd_tconnection_id   (axis_txd_trans_layer_tuser[3:0]),
   .trans_axis_txd_tbyte_num        (axis_txd_trans_layer_tuser[16:4]),
   .trans_axis_txd_tlast            (axis_txd_trans_layer_tlast),
   .trans_axis_txd_tvalid           (axis_txd_trans_layer_tvalid),
   .trans_axis_txd_tready           (axis_txd_trans_layer_tready),
   
   .trans_axis_rxd_tdata            (axis_rxd_trans_layer_tdata),
   .trans_axis_rxd_tkeep            (axis_rxd_trans_layer_tkeep),
   .trans_axis_rxd_tconnection_id   (axis_rxd_trans_layer_tuser),
   .trans_axis_rxd_tlast            (axis_rxd_trans_layer_tlast),
   .trans_axis_rxd_tvalid           (axis_rxd_trans_layer_tvalid),
   .trans_axis_rxd_tready           (axis_rxd_trans_layer_tready),   
   
   //AXI slave interface
   .s_axi_awaddr       (s_axi_awaddr_f[43:0]),
   .s_axi_awid         (s_axi_awid_f[17:0]),
   .s_axi_awlen        (doce_axi_slave_awlen),
   .s_axi_awsize       (s_axi_awsize_f[2:0]),
   .s_axi_awburst      (doce_axi_slave_awburst),
   .s_axi_awlock       (doce_axi_slave_awlock),
   .s_axi_awvalid      (doce_axi_slave_awvalid),
   .s_axi_awready      (doce_axi_slave_awready),

   .s_axi_araddr       (s_axi_araddr_f[43:0]),
   .s_axi_arid         (s_axi_arid_f[17:0]),
   .s_axi_arlen        (doce_axi_slave_arlen),
   .s_axi_arsize       (s_axi_arsize_f[2:0]),
   .s_axi_arburst      (doce_axi_slave_arburst),
   .s_axi_arlock       (doce_axi_slave_arlock),
   .s_axi_arvalid      (doce_axi_slave_arvalid),
   .s_axi_arready      (doce_axi_slave_arready), 
       
   .s_axi_wdata        (s_axi_wdata_f[127:0]),
   .s_axi_wstrb        (s_axi_wstrb_f[15:0]),
   .s_axi_wlast        (doce_axi_slave_wlast),
   .s_axi_wvalid       (doce_axi_slave_wvalid),
   .s_axi_wready       (doce_axi_slave_wready),

   .s_axi_rdata        (s_axi_rdata_f),
   .s_axi_rid          (s_axi_rid_f),
   .s_axi_rlast        (doce_axi_slave_rlast),
   .s_axi_rresp        (doce_axi_slave_rresp),
   .s_axi_rvalid       (doce_axi_slave_rvalid),
   .s_axi_rready       (doce_axi_slave_rready),

   .s_axi_bresp        (doce_axi_slave_bresp),
   .s_axi_bid          (s_axi_bid_f),
   .s_axi_bvalid       (doce_axi_slave_bvalid),
   .s_axi_bready       (doce_axi_slave_bready),

   //AXI master interface
   .m_axi_awaddr       (m_axi_awaddr_f),
   .m_axi_awid         (m_axi_awid_f),
   .m_axi_awlen        (doce_axi_master_awlen),
   .m_axi_awsize       (m_axi_awsize_f),
   .m_axi_awburst      (doce_axi_master_awburst),
   .m_axi_awlock       (doce_axi_master_awlock),
   .m_axi_awvalid      (doce_axi_master_awvalid),
   .m_axi_awready      (doce_axi_master_awready),

   .m_axi_araddr       (m_axi_araddr_f),
   .m_axi_arid         (m_axi_arid_f),
   .m_axi_arlen        (doce_axi_master_arlen),
   .m_axi_arsize       (m_axi_arsize_f),
   .m_axi_arburst      (doce_axi_master_arburst),
   .m_axi_arlock       (doce_axi_master_arlock),
   .m_axi_arvalid      (doce_axi_master_arvalid),
   .m_axi_arready      (doce_axi_master_arready), 
       
   .m_axi_wdata        (m_axi_wdata_f),
   .m_axi_wstrb        (m_axi_wstrb_f),
   .m_axi_wlast        (doce_axi_master_wlast),
   .m_axi_wvalid       (doce_axi_master_wvalid),
   .m_axi_wready       (doce_axi_master_wready),

   .m_axi_rdata        (m_axi_rdata_f[127:0]),
   .m_axi_rid          (m_axi_rid_f),
   .m_axi_rlast        (doce_axi_master_rlast),
   .m_axi_rresp        (doce_axi_master_rresp),
   .m_axi_rvalid       (doce_axi_master_rvalid),
   .m_axi_rready       (doce_axi_master_rready),

   .m_axi_bresp        (doce_axi_master_bresp),
   .m_axi_bid          (m_axi_bid_f),
   .m_axi_bvalid       (doce_axi_master_bvalid),
   .m_axi_bready       (doce_axi_master_bready),

   //AXI-Lite slave
   .s_axi_lite_awaddr  (s_axi_lite_awaddr_f[43:0]),
   .s_axi_lite_awvalid (doce_axi_lite_slave_awvalid),
   .s_axi_lite_awready (doce_axi_lite_slave_awready),
    
   .s_axi_lite_araddr  (s_axi_lite_araddr_f[43:0]),
   .s_axi_lite_arvalid (doce_axi_lite_slave_arvalid),
   .s_axi_lite_arready (doce_axi_lite_slave_arready),
    
   .s_axi_lite_wdata   (doce_axi_lite_slave_wdata),
   .s_axi_lite_wstrb   (doce_axi_lite_slave_wstrb),
   .s_axi_lite_wvalid  (doce_axi_lite_slave_wvalid),
   .s_axi_lite_wready  (doce_axi_lite_slave_wready),
    
   .s_axi_lite_rdata   (doce_axi_lite_slave_rdata),
   .s_axi_lite_rresp   (doce_axi_lite_slave_rresp),
   .s_axi_lite_rvalid  (doce_axi_lite_slave_rvalid),
   .s_axi_lite_rready  (doce_axi_lite_slave_rready),
    
   .s_axi_lite_bresp   (doce_axi_lite_slave_bresp),
   .s_axi_lite_bvalid  (doce_axi_lite_slave_bvalid),
   .s_axi_lite_bready  (doce_axi_lite_slave_bready),
  
   //AXI-Lite master interface to DoCE transportation layer
   .m_axi_lite_awaddr_1     (m_axi_doce_trp_layer_awaddr_f),
   .m_axi_lite_awvalid_1    (m_axi_doce_trp_layer_awvalid),
   .m_axi_lite_awready_1    (m_axi_doce_trp_layer_awready),
   
   .m_axi_lite_araddr_1     (m_axi_doce_trp_layer_araddr_f),
   .m_axi_lite_arvalid_1    (m_axi_doce_trp_layer_arvalid),
   .m_axi_lite_arready_1    (m_axi_doce_trp_layer_arready),
   
   .m_axi_lite_wdata_1      (m_axi_doce_trp_layer_wdata),
   .m_axi_lite_wstrb_1      (m_axi_doce_trp_layer_wstrb),
   .m_axi_lite_wvalid_1     (m_axi_doce_trp_layer_wvalid),
   .m_axi_lite_wready_1     (m_axi_doce_trp_layer_wready),
   
   .m_axi_lite_rdata_1      (m_axi_doce_trp_layer_rdata),
   .m_axi_lite_rresp_1      (m_axi_doce_trp_layer_rresp),
   .m_axi_lite_rvalid_1     (m_axi_doce_trp_layer_rvalid),
   .m_axi_lite_rready_1     (m_axi_doce_trp_layer_rready),
   
   .m_axi_lite_bresp_1      (m_axi_doce_trp_layer_bresp),
   .m_axi_lite_bvalid_1     (m_axi_doce_trp_layer_bvalid),
   .m_axi_lite_bready_1     (m_axi_doce_trp_layer_bready),
  
   //AXI-Lite master interface to DoCE MAC/IP address register
   .m_axi_lite_awaddr_2    (m_axi_doce_mac_awaddr_f),
   .m_axi_lite_awvalid_2   (m_axi_doce_mac_awvalid),
   .m_axi_lite_awready_2   (m_axi_doce_mac_awready),
   
   .m_axi_lite_araddr_2    (m_axi_doce_mac_araddr_f),
   .m_axi_lite_arvalid_2   (m_axi_doce_mac_arvalid),
   .m_axi_lite_arready_2   (m_axi_doce_mac_arready),
   
   .m_axi_lite_wdata_2     (m_axi_doce_mac_wdata),
   .m_axi_lite_wstrb_2     (m_axi_doce_mac_wstrb),
   .m_axi_lite_wvalid_2    (m_axi_doce_mac_wvalid),
   .m_axi_lite_wready_2    (m_axi_doce_mac_wready),
   
   .m_axi_lite_rdata_2     (m_axi_doce_mac_rdata),
   .m_axi_lite_rresp_2     (m_axi_doce_mac_rresp),
   .m_axi_lite_rvalid_2    (m_axi_doce_mac_rvalid),
   .m_axi_lite_rready_2    (m_axi_doce_mac_rready),
   
   .m_axi_lite_bresp_2     (m_axi_doce_mac_bresp),
   .m_axi_lite_bvalid_2    (m_axi_doce_mac_bvalid),
   .m_axi_lite_bready_2    (m_axi_doce_mac_bready)
);

doce_transport_layer	u_doce_transport_layer (
	//clock and reset
	.clk					(clk),
	.reset					(reset),
	
	//AXI-Lite slave connected to transaction layer
    .s_axi_trp_awaddr    	(m_axi_doce_trp_layer_awaddr),
    .s_axi_trp_awvalid   	(m_axi_doce_trp_layer_awvalid),
    .s_axi_trp_awready   	(m_axi_doce_trp_layer_awready),
		
    .s_axi_trp_araddr    	(m_axi_doce_trp_layer_araddr),
    .s_axi_trp_arvalid   	(m_axi_doce_trp_layer_arvalid),
    .s_axi_trp_arready   	(m_axi_doce_trp_layer_arready),
		
    .s_axi_trp_wdata     	(m_axi_doce_trp_layer_wdata),
    .s_axi_trp_wstrb     	(m_axi_doce_trp_layer_wstrb),
    .s_axi_trp_wvalid    	(m_axi_doce_trp_layer_wvalid),
    .s_axi_trp_wready    	(m_axi_doce_trp_layer_wready),
		
    .s_axi_trp_rdata     	(m_axi_doce_trp_layer_rdata),
    .s_axi_trp_rresp     	(m_axi_doce_trp_layer_rresp),
    .s_axi_trp_rvalid    	(m_axi_doce_trp_layer_rvalid),
    .s_axi_trp_rready    	(m_axi_doce_trp_layer_rready),
		
    .s_axi_trp_bresp     	(m_axi_doce_trp_layer_bresp),
    .s_axi_trp_bvalid    	(m_axi_doce_trp_layer_bvalid),
    .s_axi_trp_bready    	(m_axi_doce_trp_layer_bready),	
	
	//AXIS from transaction layer Tx
    .trans_axis_txd_tdata   (axis_txd_trans_layer_tdata),
    .trans_axis_txd_tkeep   (axis_txd_trans_layer_tkeep),
    .trans_axis_txd_tuser   (axis_txd_trans_layer_tuser),
    .trans_axis_txd_tlast   (axis_txd_trans_layer_tlast),
    .trans_axis_txd_tvalid  (axis_txd_trans_layer_tvalid),
    .trans_axis_txd_tready  (axis_txd_trans_layer_tready),
	
	//AXIS to transaction layer Rx
    .trans_axis_rxd_tdata   (axis_rxd_trans_layer_tdata),
    .trans_axis_rxd_tkeep   (axis_rxd_trans_layer_tkeep),
    .trans_axis_rxd_tuser   (axis_rxd_trans_layer_tuser),
    .trans_axis_rxd_tlast   (axis_rxd_trans_layer_tlast),
    .trans_axis_rxd_tvalid  (axis_rxd_trans_layer_tvalid),
    .trans_axis_rxd_tready  (axis_rxd_trans_layer_tready),    
	
	//DoCE Tx interface
	.doce_axis_txd_tdata	(doce_axis_txd_tdata),
	.doce_axis_txd_tkeep	(doce_axis_txd_tkeep),
	.doce_axis_txd_tlast	(doce_axis_txd_tlast),
	.doce_axis_txd_tready	(doce_axis_txd_tready),
	.doce_axis_txd_tvalid	(doce_axis_txd_tvalid),	
	
	//DoCE Rx interface
	.doce_axis_rxd_tdata	(doce_axis_rxd_tdata),
	.doce_axis_rxd_tkeep	(doce_axis_rxd_tkeep),
	.doce_axis_rxd_tlast	(doce_axis_rxd_tlast),
	.doce_axis_rxd_tready	(doce_axis_rxd_tready),
	.doce_axis_rxd_tvalid	(doce_axis_rxd_tvalid),
	
	//DoCE MAC/IP address
	.doce_mac_addr			(doce_mac_addr),
	.doce_ip_addr			(doce_ip_addr)
);

endmodule

