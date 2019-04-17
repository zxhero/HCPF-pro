`timescale 1ns / 1ps

module axi_tx
(
    input  wire              reset,
    input  wire              reset_id_inquire,
    input  wire              clk,
    output wire              reset_soft,
    output wire              start_soft,

    output wire [127:0]      tx_data,
    output wire [15:0]       tx_keep,
    output wire [3:0]        tx_connection_id,
    output wire [12:0]       tx_byte_num,
    output wire              tx_last,
    output wire              tx_valid,
    input  wire              tx_ready,

    input  wire [3:0]        barrier_rx_connection_id,
    input  wire [3:0]        barrier_rx_context_id,
    input  wire              barrier_rx_broadcast_answer,   //high stand for broadcast message,low stand for answer message
    input  wire              barrier_rx_valid,
    output wire              barrier_rx_ready,

    output wire [48:0]       phy_base_0,   //use for rx   {(context_id_0[4] & start_soft),context_id_0[3:0],pa_base_0}
    output wire [48:0]       phy_base_1,   //use for rx   {(context_id_1[4] & start_soft),context_id_1[3:0],pa_base_1} 

/*********************axi interface**************************/     
    input  wire [43:0]       s_axi_awaddr,
    input  wire [17:0]       s_axi_awid,
    input  wire [7:0]        s_axi_awlen,
    input  wire [2:0]        s_axi_awsize,
    input  wire [1:0]        s_axi_awburst,
    input  wire              s_axi_awlock,
    input  wire              s_axi_awvalid,
    output wire              s_axi_awready,

    input  wire [43:0]       s_axi_araddr,
    input  wire [17:0]       s_axi_arid,
    input  wire [7:0]        s_axi_arlen,
    input  wire [2:0]        s_axi_arsize,
    input  wire [1:0]        s_axi_arburst,
    input  wire              s_axi_arlock,
    input  wire              s_axi_arvalid,
    output wire              s_axi_arready, 
       
    input  wire [127:0]      s_axi_wdata,
    input  wire [15:0]       s_axi_wstrb,
    input  wire              s_axi_wlast,
    input  wire              s_axi_wvalid,
    output wire              s_axi_wready,

    input  wire [127:0]      m_axi_rdata,
    input  wire [21:0]       m_axi_rid,    //include 4bit connection id
    input  wire              m_axi_rlast,
    input  wire [1:0]        m_axi_rresp,
    input  wire              m_axi_rvalid,
    output wire              m_axi_rready,

    input  wire [1:0]        m_axi_bresp,
    input  wire [21:0]       m_axi_bid, //include 4bit connection id
    input  wire              m_axi_bvalid,
    output wire              m_axi_bready,
/*********************axi interface**************************/  


/*********************lite interface**************************/  
    input  wire [43:0]       s_axi_lite_awaddr,
    input  wire              s_axi_lite_awvalid,
    output wire              s_axi_lite_awready,
    
    input  wire [43:0]       s_axi_lite_araddr,
    input  wire              s_axi_lite_arvalid,
    output wire              s_axi_lite_arready,
    
    input  wire [31:0]       s_axi_lite_wdata,
    input  wire [3:0]        s_axi_lite_wstrb,
    input  wire              s_axi_lite_wvalid,
    output wire              s_axi_lite_wready,
    
    output wire [31:0]       s_axi_lite_rdata,
    output wire [1:0]        s_axi_lite_rresp,
    output wire              s_axi_lite_rvalid,
    input  wire              s_axi_lite_rready,
    
    output wire [1:0]        s_axi_lite_bresp,
    output wire              s_axi_lite_bvalid,
    input  wire              s_axi_lite_bready
/*********************lite interface**************************/  


);





wire [24:0]        context_id_table_0;
wire [24:0]        context_id_table_1;

wire               barrier_valid;  //keep 1 flop
wire [24:0]        barrier_data;   //25bit   //{1'b0,context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0}  used to send broadcase package

wire               barrier_answer_0;   //used to read by lite
wire               barrier_clean_0;   //keep 1 flop  after read by lite
wire               barrier_answer_1;
wire               barrier_clean_1;   //keep 1 flop



wire  [127:0]      aw_channel;
wire  [15:0]       aw_channel_keep;
wire               aw_channel_last;
wire  [3:0]        aw_channel_connection_id;
wire  [12:0]       aw_channel_byte_num;
wire               aw_channel_valid;
wire               aw_channel_ready;

wire  [127:0]      ar_channel;
wire  [15:0]       ar_channel_keep;
wire               ar_channel_last;
wire  [3:0]        ar_channel_connection_id;
wire  [12:0]       ar_channel_byte_num;
wire               ar_channel_valid;
wire               ar_channel_ready;


wire  [127:0]      r_channel;
wire               r_channel_last;
wire  [15:0]       r_channel_keep;
wire  [3:0]        r_channel_connection_id;
wire  [12:0]       r_channel_byte_num;
wire               r_channel_valid;
wire               r_channel_ready;

wire  [127:0]      b_channel;
wire               b_channel_last;
wire  [15:0]       b_channel_keep;
wire  [3:0]        b_channel_connection_id;
wire  [12:0]       b_channel_byte_num;
wire               b_channel_valid;
wire               b_channel_ready;



wire [127:0]       barrier_channel;
wire [3:0]         barrier_channel_connection_id;
wire [12:0]        barrier_channel_byte_num;
wire [15:0]        barrier_channel_keep;
wire               barrier_channel_last;
wire               barrier_channel_valid;
wire               barrier_channel_ready;


s_inter_tx s_inter_tx_inst
(  
    .reset                     ( reset ),
    .reset_id_inquire          ( reset_id_inquire ),
    .clk                       ( clk ),
    .reset_soft                ( reset_soft ),
    .start_soft                ( start_soft ),
   
    .s_axi_awaddr              ( s_axi_awaddr ),
    .s_axi_awid                ( s_axi_awid ),
    .s_axi_awlen               ( s_axi_awlen ),
    .s_axi_awsize              ( s_axi_awsize ),
    .s_axi_awburst             ( s_axi_awburst ),
    .s_axi_awlock              ( s_axi_awlock ),
    .s_axi_awvalid             ( s_axi_awvalid ),
    .s_axi_awready             ( s_axi_awready ),

    .s_axi_araddr              ( s_axi_araddr ),
    .s_axi_arid                ( s_axi_arid ),
    .s_axi_arlen               ( s_axi_arlen ),
    .s_axi_arsize              ( s_axi_arsize ),
    .s_axi_arburst             ( s_axi_arburst ),
    .s_axi_arlock              ( s_axi_arlock ),
    .s_axi_arvalid             ( s_axi_arvalid ),
    .s_axi_arready             ( s_axi_arready ),
       
    .s_axi_wdata               ( s_axi_wdata ),
    .s_axi_wstrb               ( s_axi_wstrb ),
    .s_axi_wlast               ( s_axi_wlast ),
    .s_axi_wvalid              ( s_axi_wvalid ),
    .s_axi_wready              ( s_axi_wready ),

    .context_id_table_0        ( context_id_table_0 ),
    .context_id_table_1        ( context_id_table_1 ),

    .barrier_valid             ( barrier_valid ),  //keep 1 flop   include & start_soft
    .barrier_data              ( barrier_data ),   //25bit  {1'b0,context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0}
                                                   //       {1'b1,(context_id_1[4] & start_soft),context_id_1[3:0],connection_id_7,connection_id_6,connection_id_5,connection_id_4}
    .barrier_answer_0          ( barrier_answer_0 ),
    .barrier_clean_0           ( barrier_clean_0 ),   //keep 1 flop
    .barrier_answer_1          ( barrier_answer_1 ),
    .barrier_clean_1           ( barrier_clean_1 ),   //keep 1 flop

    .phy_base_0                ( phy_base_0 ),   //used by rx
    .phy_base_1                ( phy_base_1 ),

    .aw_channel                ( aw_channel ),
    .aw_channel_keep           ( aw_channel_keep ),
    .aw_channel_last           ( aw_channel_last ),
    .aw_channel_connection_id  ( aw_channel_connection_id ),
    .aw_channel_byte_num       ( aw_channel_byte_num ),
    .aw_channel_valid          ( aw_channel_valid ),
    .aw_channel_ready          ( aw_channel_ready ),
   
    .ar_channel                ( ar_channel ),
    .ar_channel_keep           ( ar_channel_keep ),
    .ar_channel_last           ( ar_channel_last ),
    .ar_channel_connection_id  ( ar_channel_connection_id ),
    .ar_channel_byte_num       ( ar_channel_byte_num ),
    .ar_channel_valid          ( ar_channel_valid ),
    .ar_channel_ready          ( ar_channel_ready ),

/*********************lite interface**************************/  
    .s_axi_lite_awaddr         ( s_axi_lite_awaddr ),
    .s_axi_lite_awvalid        ( s_axi_lite_awvalid ),
    .s_axi_lite_awready        ( s_axi_lite_awready ),
    .s_axi_lite_araddr         ( s_axi_lite_araddr ),
    .s_axi_lite_arvalid        ( s_axi_lite_arvalid ),
    .s_axi_lite_arready        ( s_axi_lite_arready ),
    .s_axi_lite_wdata          ( s_axi_lite_wdata ),
    .s_axi_lite_wstrb          ( s_axi_lite_wstrb ),
    .s_axi_lite_wvalid         ( s_axi_lite_wvalid ),
    .s_axi_lite_wready         ( s_axi_lite_wready ),
    .s_axi_lite_rdata          ( s_axi_lite_rdata ),
    .s_axi_lite_rresp          ( s_axi_lite_rresp ),
    .s_axi_lite_rvalid         ( s_axi_lite_rvalid ),
    .s_axi_lite_rready         ( s_axi_lite_rready ),
    .s_axi_lite_bresp          ( s_axi_lite_bresp ),
    .s_axi_lite_bvalid         ( s_axi_lite_bvalid ),
    .s_axi_lite_bready         ( s_axi_lite_bready )
/*********************lite interface**************************/  
);

m_inter_tx m_inter_tx_inst
(
    .reset                     ( reset ),
    .clk                       ( clk ),
   
    .m_axi_rdata               ( m_axi_rdata ),
    .m_axi_rid                 ( m_axi_rid ),    //include 4bit connection id
    .m_axi_rlast               ( m_axi_rlast ),
    .m_axi_rresp               ( m_axi_rresp ),
    .m_axi_rvalid              ( m_axi_rvalid ),
    .m_axi_rready              ( m_axi_rready ),

    .m_axi_bresp               ( m_axi_bresp ),
    .m_axi_bid                 ( m_axi_bid ),   //include 4bit connection id
    .m_axi_bvalid              ( m_axi_bvalid ),
    .m_axi_bready              ( m_axi_bready ),

    .r_channel                 ( r_channel ),
    .r_channel_keep            ( r_channel_keep ),
    .r_channel_last            ( r_channel_last ),
    .r_channel_connection_id   ( r_channel_connection_id ),
    .r_channel_byte_num        ( r_channel_byte_num ),
    .r_channel_valid           ( r_channel_valid ),
    .r_channel_ready           ( r_channel_ready ),
   
    .b_channel                 ( b_channel ),
    .b_channel_keep            ( b_channel_keep ),
    .b_channel_last            ( b_channel_last ),
    .b_channel_connection_id   ( b_channel_connection_id ),
    .b_channel_byte_num        ( b_channel_byte_num ),
    .b_channel_valid           ( b_channel_valid ),
    .b_channel_ready           ( b_channel_ready )
);



barrier_tx barrier_tx_inst
(
    .reset                   ( reset ),
    .clk                     ( clk ),

    .context_id_table_0      ( context_id_table_0 ),  
    .context_id_table_1      ( context_id_table_1 ),
    
    .valid                   ( barrier_valid ),   //keep 1 flop   //keep 1 flop   include & start_soft
    .data                    ( barrier_data ),   //25bit  //{1'b0,context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0}

    .answer_0                ( barrier_answer_0 ),
    .clean_0                 ( barrier_clean_0 ),   //keep 1 flop
    .answer_1                ( barrier_answer_1 ),
    .clean_1                 ( barrier_clean_1 ),   //keep 1 flop

    .rx_connection_id        ( barrier_rx_connection_id ),
    .rx_context_id           ( barrier_rx_context_id ),
    .rx_broadcast_answer     ( barrier_rx_broadcast_answer ),  //high stand for broadcast message,low stand for answer message
    .rx_valid                ( barrier_rx_valid ),   .rx_ready                ( barrier_rx_ready ),

    .channel                 ( barrier_channel ),
    .channel_connection_id   ( barrier_channel_connection_id ),
    .channel_byte_num        ( barrier_channel_byte_num ),
    .channel_keep            ( barrier_channel_keep ),
    .channel_last            ( barrier_channel_last ),
    .channel_valid           ( barrier_channel_valid ),
    .channel_ready           ( barrier_channel_ready )
 
);



assign   resetn   = ~reset;

tx_stream_switch tx_stream_switch_inst 
(
  .aclk                      ( clk ),     // input wire aclk
  .aresetn                   ( resetn ),    // input wire aresetn
  .s_axis_tvalid             ( {aw_channel_valid,ar_channel_valid,r_channel_valid,b_channel_valid,barrier_channel_valid} ),    // input wire [5 : 0] s_axis_tvalid
  .s_axis_tready             ( {aw_channel_ready,ar_channel_ready,r_channel_ready,b_channel_ready,barrier_channel_ready} ),    // output wire [5 : 0] s_axis_tready
  .s_axis_tdata              ( {aw_channel,ar_channel,r_channel,b_channel,barrier_channel} ),      // input wire [767 : 0] s_axis_tdata
  .s_axis_tkeep              ( {aw_channel_keep,ar_channel_keep,r_channel_keep,b_channel_keep,barrier_channel_keep} ),      // input wire [95 : 0] s_axis_tkeep
  .s_axis_tlast              ( {aw_channel_last,ar_channel_last,r_channel_last,b_channel_last,barrier_channel_last} ),      // input wire [5 : 0] s_axis_tlast
  .s_axis_tuser              ( {aw_channel_byte_num,aw_channel_connection_id,ar_channel_byte_num,ar_channel_connection_id,r_channel_byte_num,r_channel_connection_id,b_channel_byte_num,b_channel_connection_id,barrier_channel_byte_num,barrier_channel_connection_id} ),      // input wire [23 : 0] s_axis_tuser
  .m_axis_tvalid             ( tx_valid ),    // output wire [0 : 0] m_axis_tvalid
  .m_axis_tready             ( tx_ready ),    // input wire [0 : 0] m_axis_tready
  .m_axis_tdata              ( tx_data ),      // output wire [127 : 0] m_axis_tdata
  .m_axis_tkeep              ( tx_keep ),      // output wire [15 : 0] m_axis_tkeep
  .m_axis_tlast              ( tx_last ),      // output wire [0 : 0] m_axis_tlast
  .m_axis_tuser              ( {tx_byte_num,tx_connection_id} ),      // output wire [3 : 0] m_axis_tuser
  .s_req_suppress            ( {{4{barrier_channel_valid}},1'b 0} ),  // input wire [5 : 0] s_req_suppress
  .s_decode_err              (  )      // output wire [5 : 0] s_decode_err
);


endmodule
