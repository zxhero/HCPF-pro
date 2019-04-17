`timescale 1ns / 1ps

module doce_transaction_layer (
    input  wire             reset_in,
    input  wire             clk,
   
    output wire [127:0]     trans_axis_txd_tdata,
    output wire [15:0]      trans_axis_txd_tkeep,
    output wire [3:0]       trans_axis_txd_tconnection_id,
    output wire [12:0]      trans_axis_txd_tbyte_num,
    output wire             trans_axis_txd_tlast,
    output wire             trans_axis_txd_tvalid,
    input  wire             trans_axis_txd_tready,
   
   
    input  wire [127:0]     trans_axis_rxd_tdata,
    input  wire [15:0]      trans_axis_rxd_tkeep,
    input  wire [3:0]       trans_axis_rxd_tconnection_id,
    input  wire             trans_axis_rxd_tlast,
    input  wire             trans_axis_rxd_tvalid,
    output wire             trans_axis_rxd_tready,   
   
   
/*********************slave interface**************************/    
    input  wire [43:0]      s_axi_awaddr,
    input  wire [17:0]      s_axi_awid,
    input  wire [7:0]       s_axi_awlen,
    input  wire [2:0]       s_axi_awsize,
    input  wire [1:0]       s_axi_awburst,
    input  wire             s_axi_awlock,
    input  wire             s_axi_awvalid,
    output wire             s_axi_awready,

    input  wire [43:0]      s_axi_araddr,
    input  wire [17:0]      s_axi_arid,
    input  wire [7:0]       s_axi_arlen,
    input  wire [2:0]       s_axi_arsize,
    input  wire [1:0]       s_axi_arburst,
    input  wire             s_axi_arlock,
    input  wire             s_axi_arvalid,
    output wire             s_axi_arready, 
      
    input  wire [127:0]     s_axi_wdata,
    input  wire [15:0]      s_axi_wstrb,
    input  wire             s_axi_wlast,
    input  wire             s_axi_wvalid,
    output wire             s_axi_wready,

    output wire [127:0]     s_axi_rdata,
    output wire [17:0]      s_axi_rid,
    output wire             s_axi_rlast,
    output wire [1:0]       s_axi_rresp,
    output wire             s_axi_rvalid,
    input  wire             s_axi_rready,

    output wire [1:0]       s_axi_bresp,
    output wire [17:0]      s_axi_bid,
    output wire             s_axi_bvalid,
    input  wire             s_axi_bready,
/*********************slave interface**************************/ 


/*********************master interface**************************/   
    output wire [43:0]      m_axi_awaddr,
    output wire [21:0]      m_axi_awid,   //include 4bit connection id
    output wire [7:0]       m_axi_awlen,
    output wire [2:0]       m_axi_awsize,
    output wire [1:0]       m_axi_awburst,
    output wire             m_axi_awlock,
    output wire             m_axi_awvalid,
    input  wire             m_axi_awready,

    output wire [43:0]      m_axi_araddr,
    output wire [21:0]      m_axi_arid, //include 4bit connection id
    output wire [7:0]       m_axi_arlen,
    output wire [2:0]       m_axi_arsize,
    output wire [1:0]       m_axi_arburst,
    output wire             m_axi_arlock,
    output wire             m_axi_arvalid,
    input  wire             m_axi_arready, 
      
    output wire [127:0]     m_axi_wdata,
    output wire [15:0]      m_axi_wstrb,
    output wire             m_axi_wlast,
    output wire             m_axi_wvalid,
    input  wire             m_axi_wready,

    input  wire [127:0]     m_axi_rdata,
    input  wire [21:0]      m_axi_rid,   //include 4bit connection id
    input  wire             m_axi_rlast,
    input  wire [1:0]       m_axi_rresp,
    input  wire             m_axi_rvalid,
    output wire             m_axi_rready,

    input  wire [1:0]       m_axi_bresp,
    input  wire [21:0]      m_axi_bid, //include 4bit connection id
    input  wire             m_axi_bvalid,
    output wire             m_axi_bready,
/*********************master interface**************************/  

/*********************lite interface**************************/  
    input  wire [43:0]      s_axi_lite_awaddr,
    input  wire             s_axi_lite_awvalid,
    output wire             s_axi_lite_awready,
   
    input  wire [43:0]      s_axi_lite_araddr,
    input  wire             s_axi_lite_arvalid,
    output wire             s_axi_lite_arready,
   
    input  wire [31:0]      s_axi_lite_wdata,
    input  wire [3:0]       s_axi_lite_wstrb,
    input  wire             s_axi_lite_wvalid,
    output wire             s_axi_lite_wready,
   
    output wire [31:0]      s_axi_lite_rdata,
    output wire [1:0]       s_axi_lite_rresp,
    output wire             s_axi_lite_rvalid,
    input  wire             s_axi_lite_rready,
   
    output wire [1:0]       s_axi_lite_bresp,
    output wire             s_axi_lite_bvalid,
    input  wire             s_axi_lite_bready,
/*********************lite interface**************************/  

    output wire [43:0]      m_axi_lite_awaddr_1,
    output wire             m_axi_lite_awvalid_1,
    input  wire             m_axi_lite_awready_1,
    
    output wire [43:0]      m_axi_lite_araddr_1,
    output wire             m_axi_lite_arvalid_1,
    input  wire             m_axi_lite_arready_1,
    
    output wire [31:0]      m_axi_lite_wdata_1,
    output wire [3:0]       m_axi_lite_wstrb_1,
    output wire             m_axi_lite_wvalid_1,
    input  wire             m_axi_lite_wready_1,
    
    input  wire [31:0]      m_axi_lite_rdata_1,
    input  wire [1:0]       m_axi_lite_rresp_1,
    input  wire             m_axi_lite_rvalid_1,
    output wire             m_axi_lite_rready_1,
    
    input  wire [1:0]       m_axi_lite_bresp_1,
    input  wire             m_axi_lite_bvalid_1,
    output wire             m_axi_lite_bready_1,

    output wire [43:0]      m_axi_lite_awaddr_2,
    output wire             m_axi_lite_awvalid_2,
    input  wire             m_axi_lite_awready_2,
    
    output wire [43:0]      m_axi_lite_araddr_2,
    output wire             m_axi_lite_arvalid_2,
    input  wire             m_axi_lite_arready_2,
   
    output wire [31:0]      m_axi_lite_wdata_2,
    output wire [3:0]       m_axi_lite_wstrb_2,
    output wire             m_axi_lite_wvalid_2,
    input  wire             m_axi_lite_wready_2,
    
    input  wire [31:0]      m_axi_lite_rdata_2,
    input  wire [1:0]       m_axi_lite_rresp_2,
    input  wire             m_axi_lite_rvalid_2,
    output wire             m_axi_lite_rready_2,
    
    input  wire [1:0]       m_axi_lite_bresp_2,
    input  wire             m_axi_lite_bvalid_2,
    output wire             m_axi_lite_bready_2
);


reg   reset_id_inquire= 1'b 1;
always @ (posedge clk)
    reset_id_inquire   <= reset_in | reset_soft;
    
reg   reset = 1'b 1;
wire  start_soft;
always @ (posedge clk)
    reset   <= reset_in | reset_soft | (~start_soft);


wire   resetn_id_inquire  = ~reset_id_inquire;

wire [43:0]         m_axi_lite_awaddr_0;
wire                m_axi_lite_awvalid_0;
wire                m_axi_lite_awready_0;

wire [43:0]         m_axi_lite_araddr_0;
wire                m_axi_lite_arvalid_0;
wire                m_axi_lite_arready_0;

wire [31:0]         m_axi_lite_wdata_0;
wire [3:0]          m_axi_lite_wstrb_0;
wire                m_axi_lite_wvalid_0;
wire                m_axi_lite_wready_0;

wire [31:0]         m_axi_lite_rdata_0;
wire [1:0]          m_axi_lite_rresp_0;
wire                m_axi_lite_rvalid_0;
wire                m_axi_lite_rready_0;

wire [1:0]          m_axi_lite_bresp_0;
wire                m_axi_lite_bvalid_0;
wire                m_axi_lite_bready_0;

wire [3:0]        barrier_rx_connection_id;
wire [3:0]        barrier_rx_context_id;
wire              barrier_rx_broadcast_answer;   //high stand for broadcast message,low stand for answer message
wire              barrier_rx_valid;
wire              barrier_rx_ready;

wire [48:0]       phy_base_0;   //use for rx
wire [48:0]       phy_base_1;   //use for rx


axi_lite_crossbar axi_lite_crossbar_inst
(
    .aclk                   ( clk ),                    // input wire aclk
    .aresetn                ( resetn_id_inquire ),              // input wire aresetn
    .s_axi_awaddr           ( s_axi_lite_awaddr ),    // input wire [43 : 0] s_axi_awaddr
    .s_axi_awprot           ( 3'b 0 ),    // input wire [2 : 0] s_axi_awprot
    .s_axi_awvalid          ( s_axi_lite_awvalid ),  // input wire [0 : 0] s_axi_awvalid
    .s_axi_awready          ( s_axi_lite_awready ),  // output wire [0 : 0] s_axi_awready
    .s_axi_wdata            ( s_axi_lite_wdata ),      // input wire [31 : 0] s_axi_wdata
    .s_axi_wstrb            ( s_axi_lite_wstrb ),      // input wire [3 : 0] s_axi_wstrb
    .s_axi_wvalid           ( s_axi_lite_wvalid ),    // input wire [0 : 0] s_axi_wvalid
    .s_axi_wready           ( s_axi_lite_wready ),    // output wire [0 : 0] s_axi_wready
    .s_axi_bresp            ( s_axi_lite_bresp ),      // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid           ( s_axi_lite_bvalid ),    // output wire [0 : 0] s_axi_bvalid
    .s_axi_bready           ( s_axi_lite_bready ),    // input wire [0 : 0] s_axi_bready
    .s_axi_araddr           ( s_axi_lite_araddr ),    // input wire [43 : 0] s_axi_araddr
    .s_axi_arprot           ( 3'b 0 ),    // input wire [2 : 0] s_axi_arprot
    .s_axi_arvalid          ( s_axi_lite_arvalid ),  // input wire [0 : 0] s_axi_arvalid
    .s_axi_arready          ( s_axi_lite_arready ),  // output wire [0 : 0] s_axi_arready
    .s_axi_rdata            ( s_axi_lite_rdata ),      // output wire [31 : 0] s_axi_rdata
    .s_axi_rresp            ( s_axi_lite_rresp ),      // output wire [1 : 0] s_axi_rresp
    .s_axi_rvalid           ( s_axi_lite_rvalid ),    // output wire [0 : 0] s_axi_rvalid
    .s_axi_rready           ( s_axi_lite_rready ),    // input wire [0 : 0] s_axi_rready 
    .m_axi_awaddr           ( {m_axi_lite_awaddr_2,m_axi_lite_awaddr_1,m_axi_lite_awaddr_0} ),    // output wire [131 : 0] m_axi_awaddr
    .m_axi_awprot           (  ),    // output wire [8 : 0] m_axi_awprot
    .m_axi_awvalid          ( {m_axi_lite_awvalid_2,m_axi_lite_awvalid_1,m_axi_lite_awvalid_0} ),  // output wire [2 : 0] m_axi_awvalid
    .m_axi_awready          ( {m_axi_lite_awready_2,m_axi_lite_awready_1,m_axi_lite_awready_0} ),  // input wire [2 : 0] m_axi_awready
    .m_axi_wdata            ( {m_axi_lite_wdata_2,m_axi_lite_wdata_1,m_axi_lite_wdata_0} ),      // output wire [95 : 0] m_axi_wdata
    .m_axi_wstrb            ( {m_axi_lite_wstrb_2,m_axi_lite_wstrb_1,m_axi_lite_wstrb_0} ),      // output wire [11 : 0] m_axi_wstrb
    .m_axi_wvalid           ( {m_axi_lite_wvalid_2,m_axi_lite_wvalid_1,m_axi_lite_wvalid_0} ),    // output wire [2 : 0] m_axi_wvalid
    .m_axi_wready           ( {m_axi_lite_wready_2,m_axi_lite_wready_1,m_axi_lite_wready_0} ),    // input wire [2 : 0] m_axi_wready
    .m_axi_bresp            ( {m_axi_lite_bresp_2,m_axi_lite_bresp_1,m_axi_lite_bresp_0} ),      // input wire [5 : 0] m_axi_bresp
    .m_axi_bvalid           ( {m_axi_lite_bvalid_2,m_axi_lite_bvalid_1,m_axi_lite_bvalid_0} ),    // input wire [2 : 0] m_axi_bvalid
    .m_axi_bready           ( {m_axi_lite_bready_2,m_axi_lite_bready_1,m_axi_lite_bready_0} ),    // output wire [2 : 0] m_axi_bready
    .m_axi_araddr           ( {m_axi_lite_araddr_2,m_axi_lite_araddr_1,m_axi_lite_araddr_0} ),    // output wire [131 : 0] m_axi_araddr
    .m_axi_arprot           (  ),    // output wire [8 : 0] m_axi_arprot
    .m_axi_arvalid          ( {m_axi_lite_arvalid_2,m_axi_lite_arvalid_1,m_axi_lite_arvalid_0} ),  // output wire [2 : 0] m_axi_arvalid
    .m_axi_arready          ( {m_axi_lite_arready_2,m_axi_lite_arready_1,m_axi_lite_arready_0} ),  // input wire [2 : 0] m_axi_arready
    .m_axi_rdata            ( {m_axi_lite_rdata_2,m_axi_lite_rdata_1,m_axi_lite_rdata_0} ),      // input wire [95 : 0] m_axi_rdata
    .m_axi_rresp            ( {m_axi_lite_rresp_2,m_axi_lite_rresp_1,m_axi_lite_rresp_0} ),      // input wire [5 : 0] m_axi_rresp
    .m_axi_rvalid           ( {m_axi_lite_rvalid_2,m_axi_lite_rvalid_1,m_axi_lite_rvalid_0} ),    // input wire [2 : 0] m_axi_rvalid
    .m_axi_rready           ( {m_axi_lite_rready_2,m_axi_lite_rready_1,m_axi_lite_rready_0} )    // output wire [2 : 0] m_axi_rready
);


axi_tx axi_tx_inst
(
    .reset               ( reset ),
    .reset_id_inquire    ( reset_id_inquire ),
    .clk                 ( clk ),
    .reset_soft          ( reset_soft ),
    .start_soft          ( start_soft ),
 
    .tx_data             ( trans_axis_txd_tdata ),
    .tx_keep             ( trans_axis_txd_tkeep ),
    .tx_connection_id    ( trans_axis_txd_tconnection_id ),
    .tx_byte_num         ( trans_axis_txd_tbyte_num ),
    .tx_last             ( trans_axis_txd_tlast  ),
    .tx_valid            ( trans_axis_txd_tvalid ),
    .tx_ready            ( trans_axis_txd_tready ),
 
    .barrier_rx_connection_id     ( barrier_rx_connection_id ),
    .barrier_rx_context_id        ( barrier_rx_context_id ),
    .barrier_rx_broadcast_answer  ( barrier_rx_broadcast_answer ),   //high stand for broadcast message,low stand for answer message
    .barrier_rx_valid             ( barrier_rx_valid ),
    .barrier_rx_ready             ( barrier_rx_ready ),

    .phy_base_0                   ( phy_base_0 ),   //use for rx
    .phy_base_1                   ( phy_base_1 ),   //use for rx

    .s_axi_awaddr        ( s_axi_awaddr ),
    .s_axi_awid          ( s_axi_awid ),
    .s_axi_awlen         ( s_axi_awlen ),
    .s_axi_awsize        ( s_axi_awsize ),
    .s_axi_awburst       ( s_axi_awburst ),
    .s_axi_awlock        ( s_axi_awlock ),
    .s_axi_awvalid       ( s_axi_awvalid ),
    .s_axi_awready       ( s_axi_awready ),
 
    .s_axi_araddr        ( s_axi_araddr ),
    .s_axi_arid          ( s_axi_arid ),
    .s_axi_arlen         ( s_axi_arlen ),
    .s_axi_arsize        ( s_axi_arsize ),
    .s_axi_arburst       ( s_axi_arburst ),
    .s_axi_arlock        ( s_axi_arlock ),
    .s_axi_arvalid       ( s_axi_arvalid ),
    .s_axi_arready       ( s_axi_arready ), 
        
    .s_axi_wdata         ( s_axi_wdata ),
    .s_axi_wstrb         ( s_axi_wstrb ),
    .s_axi_wlast         ( s_axi_wlast ),
    .s_axi_wvalid        ( s_axi_wvalid ),
    .s_axi_wready        ( s_axi_wready ),
 
    .m_axi_rdata         ( m_axi_rdata ),
    .m_axi_rid           ( m_axi_rid ),    //include 4bit connection id
    .m_axi_rlast         ( m_axi_rlast ),
    .m_axi_rresp         ( m_axi_rresp ),
    .m_axi_rvalid        ( m_axi_rvalid ),
    .m_axi_rready        ( m_axi_rready ),
 
    .m_axi_bresp         ( m_axi_bresp ),
    .m_axi_bid           ( m_axi_bid ), //include 4bit connection id
    .m_axi_bvalid        ( m_axi_bvalid ),
    .m_axi_bready        ( m_axi_bready ),


/*********************lite interface**************************/  
    .s_axi_lite_awaddr   ( m_axi_lite_awaddr_0 ),
    .s_axi_lite_awvalid  ( m_axi_lite_awvalid_0 ),
    .s_axi_lite_awready  ( m_axi_lite_awready_0 ),
     
    .s_axi_lite_araddr   ( m_axi_lite_araddr_0 ),
    .s_axi_lite_arvalid  ( m_axi_lite_arvalid_0 ),
    .s_axi_lite_arready  ( m_axi_lite_arready_0 ),
     
    .s_axi_lite_wdata    ( m_axi_lite_wdata_0 ),
    .s_axi_lite_wstrb    ( m_axi_lite_wstrb_0 ),
    .s_axi_lite_wvalid   ( m_axi_lite_wvalid_0 ),
    .s_axi_lite_wready   ( m_axi_lite_wready_0 ),
     
    .s_axi_lite_rdata    ( m_axi_lite_rdata_0 ),
    .s_axi_lite_rresp    ( m_axi_lite_rresp_0 ),
    .s_axi_lite_rvalid   ( m_axi_lite_rvalid_0 ),
    .s_axi_lite_rready   ( m_axi_lite_rready_0 ),
     
    .s_axi_lite_bresp    ( m_axi_lite_bresp_0 ),
    .s_axi_lite_bvalid   ( m_axi_lite_bvalid_0 ),
    .s_axi_lite_bready   ( m_axi_lite_bready_0 )
/*********************lite interface**************************/  
);




axi_rx axi_rx_inst
(
    .reset                        ( reset ),
    .clk                          ( clk ),
    
    .rx_data                      ( trans_axis_rxd_tdata ),
    .rx_connection_id             ( trans_axis_rxd_tconnection_id ),
    .rx_last                      ( trans_axis_rxd_tlast ),
    .rx_valid                     ( trans_axis_rxd_tvalid ),
    .rx_ready                     ( trans_axis_rxd_tready ),

    .barrier_rx_connection_id     ( barrier_rx_connection_id ),
    .barrier_rx_context_id        ( barrier_rx_context_id ),
    .barrier_rx_broadcast_answer  ( barrier_rx_broadcast_answer ),   //high stand for broadcast message,low stand for answer message
    .barrier_rx_valid             ( barrier_rx_valid ),
    .barrier_rx_ready             ( barrier_rx_ready ),

    .phy_base_0                   ( phy_base_0 ),  
    .phy_base_1                   ( phy_base_1 ),


/*********************slave interface**************************/    
    .s_axi_rdata    ( s_axi_rdata ),
    .s_axi_rid      ( s_axi_rid ),
    .s_axi_rlast    ( s_axi_rlast ),
    .s_axi_rresp    ( s_axi_rresp ),
    .s_axi_rvalid   ( s_axi_rvalid ),
    .s_axi_rready   ( s_axi_rready ),
 
    .s_axi_bresp    ( s_axi_bresp ),
    .s_axi_bid      ( s_axi_bid ),  
    .s_axi_bvalid   ( s_axi_bvalid ),
    .s_axi_bready   ( s_axi_bready ),
/*********************slave interface**************************/ 


/*********************master interface**************************/   
    .m_axi_awaddr   ( m_axi_awaddr ),
    .m_axi_awid     ( m_axi_awid ),   //include 4bit connection id
    .m_axi_awlen    ( m_axi_awlen ),
    .m_axi_awsize   ( m_axi_awsize ),
    .m_axi_awburst  ( m_axi_awburst ),
    .m_axi_awlock   ( m_axi_awlock ),
    .m_axi_awvalid  ( m_axi_awvalid ),
    .m_axi_awready  ( m_axi_awready ),
 
    .m_axi_araddr   ( m_axi_araddr ),
    .m_axi_arid     ( m_axi_arid ), //include 4bit connection id
    .m_axi_arlen    ( m_axi_arlen ),
    .m_axi_arsize   ( m_axi_arsize ),
    .m_axi_arburst  ( m_axi_arburst ),
    .m_axi_arlock   ( m_axi_arlock ),
    .m_axi_arvalid  ( m_axi_arvalid ),
    .m_axi_arready  ( m_axi_arready ), 
        
    .m_axi_wdata    ( m_axi_wdata ),
    .m_axi_wstrb    ( m_axi_wstrb ),
    .m_axi_wlast    ( m_axi_wlast ),
    .m_axi_wvalid   ( m_axi_wvalid ),
    .m_axi_wready   ( m_axi_wready )
/*********************master interface**************************/  

);

endmodule
