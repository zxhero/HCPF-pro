`timescale 1ns / 1ps


module axi_rx
(
    input  wire                   reset,
    input  wire                   clk,
   
    input  wire [127:0]           rx_data,
    input  wire [3:0]             rx_connection_id,
    input  wire                   rx_last,
    input  wire                   rx_valid,
    output wire                   rx_ready,

    output wire [3:0]             barrier_rx_connection_id,
    output wire [3:0]             barrier_rx_context_id,
    output wire                   barrier_rx_broadcast_answer,   //high stand for broadcast message from other,low stand for answer message from other
    output wire                   barrier_rx_valid,
    input  wire                   barrier_rx_ready,

    
    input  wire [48:0]            phy_base_0,    //{(context_id_0[4] & start_soft),context_id_0[3:0],pa_base_0}
    input  wire [48:0]            phy_base_1,


/*********************slave interface**************************/    
    output wire [127:0]           s_axi_rdata,
    output wire [17:0]            s_axi_rid,
    output wire                   s_axi_rlast,
    output wire [1:0]             s_axi_rresp,
    output wire                   s_axi_rvalid,
    input  wire                   s_axi_rready,

    output wire [1:0]             s_axi_bresp,
    output wire [17:0]            s_axi_bid,  
    output wire                   s_axi_bvalid,
    input  wire                   s_axi_bready,
/*********************slave interface**************************/ 

/*********************master interface**************************/   
    output wire [43:0]            m_axi_awaddr,
    output wire [21:0]            m_axi_awid,
    output wire [7:0]             m_axi_awlen,
    output wire [2:0]             m_axi_awsize,
    output wire [1:0]             m_axi_awburst,
    output wire                   m_axi_awlock,
    output wire                   m_axi_awvalid,
    input  wire                   m_axi_awready,

    output wire [43:0]            m_axi_araddr,
    output wire [21:0]            m_axi_arid,
    output wire [7:0]             m_axi_arlen,
    output wire [2:0]             m_axi_arsize,
    output wire [1:0]             m_axi_arburst,
    output wire                   m_axi_arlock,
    output wire                   m_axi_arvalid,
    input  wire                   m_axi_arready, 
       
    output wire [127:0]           m_axi_wdata,
    output wire [15:0]            m_axi_wstrb,
    output wire                   m_axi_wlast,
    output wire                   m_axi_wvalid,
    input  wire                   m_axi_wready
/*********************master interface**************************/  

);


wire   [127:0]      rx_user;
wire                rx_user_last;
wire                rx_aw_valid;
wire                rx_ar_valid;
wire                rx_r_valid;
wire                rx_b_valid;
wire                rx_barrier_valid;
wire                rx_aw_ready;
wire                rx_ar_ready;
wire                rx_w_ready;
wire                rx_r_ready;
wire                rx_b_ready;
wire                rx_barrier_ready;

wire [79:0]         aw_decode_fifo;
wire                aw_decode_fifo_valid;
wire                aw_decode_fifo_ready;

wire [143:0]        w_decode_fifo;     //144bit
wire                w_decode_fifo_last;
wire                w_decode_fifo_valid;
wire                w_decode_fifo_ready;


wire [127:0]        r_fifo_decode;  //128bit
wire                r_fifo_decode_last;
wire                r_fifo_decode_valid;
wire                r_fifo_decode_ready;


wire [79:0]        aw_data;   //m_axi_awlock,m_axi_awburst,m_axi_awsize,m_axi_awlen,m_axi_awid,m_axi_awaddr,connect_id, 1+2+3+8+18+44+4=80
wire [79:0]        ar_data;   //m_axi_arlock,m_axi_arburst,m_axi_arsize,m_axi_arlen,m_axi_arid,m_axi_araddr,connect_id, 1+2+3+8+18+44+4=80
wire [144:0]       w_data;   //m_axi_last,m_axi_wstrb,m_axi_wdata


assign {m_axi_awlock,m_axi_awburst,m_axi_awsize,m_axi_awlen,m_axi_awid[17:0],m_axi_awaddr,m_axi_awid[21:18]} = aw_data;
assign {m_axi_arlock,m_axi_arburst,m_axi_arsize,m_axi_arlen,m_axi_arid[17:0],m_axi_araddr,m_axi_arid[21:18]} = ar_data;
assign {m_axi_wlast,m_axi_wstrb,m_axi_wdata} = w_data;

wire [79:0]        ar_decode_fifo;   //80bit   include 4bit connection id
wire               ar_decode_fifo_valid;
wire               ar_decode_fifo_ready;

rx_switch rx_switch_inst
(
    .reset               ( reset ),
    .clk                 ( clk ),
    
    .rx_data             ( rx_data ),
    .rx_connection_id    ( rx_connection_id ),
    .rx_last             ( rx_last ),
    .rx_valid            ( rx_valid ),
    .rx_ready            ( rx_ready ),
    
    .dout                ( rx_user ),  //128bit
    .dout_last           ( rx_user_last ),
    .aw_valid            ( rx_aw_valid ),
    .ar_valid            ( rx_ar_valid ),
    .r_valid             ( rx_r_valid ),
    .b_valid             ( rx_b_valid ),
    .barrier_valid       ( rx_barrier_valid),
    
    .aw_ready            ( rx_aw_ready ),
    .ar_ready            ( rx_ar_ready ),
    .r_ready             ( rx_r_ready ),
    .b_ready             ( rx_b_ready ),
    .barrier_ready       ( rx_barrier_ready)
);




aw_decode aw_decode_inst
(
    .reset            ( reset ),
    .clk              ( clk ),

    .phy_base_0       ( phy_base_0 ),   //49bit
    .phy_base_1       ( phy_base_1 ),
    
    .aw_w             ( rx_user ),
    .aw_w_last        ( rx_user_last ),
    .aw_w_valid       ( rx_aw_valid ),
    .aw_w_ready       ( rx_aw_ready ),
    
    .aw               ( aw_decode_fifo ),   //80bit   include 4bit connection id
    .aw_valid         ( aw_decode_fifo_valid ),
    .aw_ready         ( aw_decode_fifo_ready ),
    
    .w                ( w_decode_fifo ),      //144bit
    .w_last           ( w_decode_fifo_last ),
    .w_valid          ( w_decode_fifo_valid ),
    .w_ready          ( w_decode_fifo_ready )
);

wire    aw_etp;
assign  m_axi_awvalid = ~aw_etp;
wire    aw_ful;
assign  aw_decode_fifo_ready = ~(aw_ful | reset);

m_aw_fifo m_aw_fifo_inst     //width is 80,depth is 64
(
   .clk               ( clk ),
   .srst              ( reset),
   
   .din               ( aw_decode_fifo ),
   .wr_en             ( aw_decode_fifo_valid ),
   .full              ( aw_ful ),

   .dout              ( aw_data ),
   .rd_en             ( m_axi_awready ),
   .empty             ( aw_etp )
);

wire    w_ept;
assign  m_axi_wvalid = ~w_ept;
wire    w_ful;
assign  w_decode_fifo_ready = ~(w_ful | reset);


m_w_fifo m_w_fifo_inst     //width is 145,depth is 256
(
   .clk               ( clk ), 
   .srst              ( reset),
   
   .din               ( {w_decode_fifo_last,w_decode_fifo} ),
   .wr_en             ( w_decode_fifo_valid ),
   .full              ( w_ful ),

   .dout              ( w_data ),
   .rd_en             ( m_axi_wready ),
   .empty             ( w_ept )
);




ar_decode ar_decode_inst
(
    .reset            ( reset ),
    .clk              ( clk ),

    .phy_base_0       ( phy_base_0 ),
    .phy_base_1       ( phy_base_1 ),
    
    .ar_user          ( rx_user[83:0] ),
    .ar_user_valid    ( rx_ar_valid ),
    .ar_user_ready    ( rx_ar_ready ),
    
    .ar               ( ar_decode_fifo ),   //80bit   include 4bit connection id
    .ar_valid         ( ar_decode_fifo_valid ),
    .ar_ready         ( ar_decode_fifo_ready )
);


wire    ar_ept;
assign  m_axi_arvalid = ~ar_ept;
wire    ar_ful;
assign  ar_decode_fifo_ready = ~(ar_ful | reset);

m_ar_fifo m_ar_fifo_inst  //width is 80,depth is 64
(
   .clk               ( clk ),
   .srst              ( reset),
   
   .din               ( ar_decode_fifo ),
   .wr_en             ( ar_decode_fifo_valid ),
   .full              ( ar_ful ), 

   .dout              ( ar_data ),
   .rd_en             ( m_axi_arready ),
   .empty             ( ar_ept )
);


wire [148:0]        r_data;
assign {s_axi_rlast,s_axi_rid,s_axi_rresp,s_axi_rdata} = r_data;


wire      r_ept;
assign    r_fifo_decode_valid = ~r_ept;
wire      r_ful;
assign    rx_r_ready = ~(r_ful | reset);

s_r_fifo s_r_fifo_inst     //width is 129,depth is 256
(
   .clk               ( clk ),
   .srst              ( reset),
   
   .din               ( {rx_user_last,rx_user} ), 
   .wr_en             ( rx_r_valid ), 
   .full              ( r_ful ),  

   .dout              ( {r_fifo_decode_last,r_fifo_decode} ),
   .rd_en             ( r_fifo_decode_ready ),
   .empty             ( r_ept )
);

r_decode r_decode_inst
(
    .reset            ( reset ),
    .clk              ( clk ),

    
    .r_decode         ( r_fifo_decode),  //128bit
    .r_decode_last    ( r_fifo_decode_last ),
    .r_decode_valid   ( r_fifo_decode_valid ),
    .r_decode_ready   ( r_fifo_decode_ready ),
    
    
    .r                ( r_data ),      //149bit
    .r_valid          ( s_axi_rvalid ),
    .r_ready          ( s_axi_rready )
);




wire [19:0]   b_data;    //s_axi_bid,s_axi_bresp
assign  {s_axi_bid,s_axi_bresp}   = b_data;


wire             b_ept;
assign   s_axi_bvalid   = ~b_ept;
wire    b_ful;
assign  rx_b_ready = ~(b_ful | reset);

s_b_fifo s_b_fifo_inst     //width is 20 depth is 64
(
   .clk               ( clk ),
   .srst              ( reset),
   
   .din               ( rx_user[23:4] ),
   .wr_en             ( rx_b_valid ),
   .full              ( b_ful ),

   .dout              ( b_data ),
   .rd_en             ( s_axi_bready ),
   .empty             ( b_ept )
);


wire    barrier_ept;
assign  barrier_rx_valid  = ~barrier_ept;
wire    barrier_ful;
assign  rx_barrier_ready = ~(barrier_ful | reset);

rx_barrier_fifo rx_barrier_fifo_inst    //width is 9 ,depth is 16
(
    .clk          ( clk ),                  // input wire clk
    .srst         ( reset ),                // input wire srst
    
    .din          ( rx_user[8:0] ),                  // input wire [8 : 0] din
    .wr_en        ( rx_barrier_valid ),              // input wire wr_en
    .full         ( barrier_ful ),                // output wire full 

    .dout         ( {barrier_rx_broadcast_answer,barrier_rx_context_id,barrier_rx_connection_id} ), // output wire [8 : 0] dout    
    .rd_en        ( barrier_rx_ready ),              // input wire rd_en
    .empty        ( barrier_ept )             // output wire empty    
);


endmodule
