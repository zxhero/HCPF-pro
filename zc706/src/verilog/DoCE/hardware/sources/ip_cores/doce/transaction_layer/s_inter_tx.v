`timescale 1ns / 1ps

module s_inter_tx
(
    input  wire             reset,
    input  wire             reset_id_inquire,
    input  wire             clk,
    output wire             reset_soft,
    output wire             start_soft,
   
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


    output wire [127:0]     aw_channel,
    output wire [15:0]      aw_channel_keep,
    output wire             aw_channel_last,
    output wire [3:0]       aw_channel_connection_id,
    output wire [12:0]      aw_channel_byte_num,
    output wire             aw_channel_valid,
    input  wire             aw_channel_ready,
   
    output wire [127:0]     ar_channel,
    output wire [15:0]      ar_channel_keep,
    output wire             ar_channel_last,
    output wire [3:0]       ar_channel_connection_id,
    output wire [12:0]      ar_channel_byte_num,
    output wire             ar_channel_valid,
    input  wire             ar_channel_ready,

    output wire [24:0]      context_id_table_0,   //{(context_id_0[4] & start_soft),context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0}
    output wire [24:0]      context_id_table_1,  //{(context_id_1[4] & start_soft),context_id_1[3:0],connection_id_7,connection_id_6,connection_id_5,connection_id_4};

    output wire             barrier_valid ,  //keep 1 flop   include & start_soft & context_id_0[4]
    output wire [24:0]      barrier_data,     //{1'b0,context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0}
    
    input wire              barrier_answer_0,
    output wire             barrier_clean_0,   //keep 1 flop
    input wire              barrier_answer_1,
    output wire             barrier_clean_1,   //keep 1 flop

    output wire [48:0]      phy_base_0,   //use for rx
    output wire [48:0]      phy_base_1,   //use for rx

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
    input  wire             s_axi_lite_bready
/*********************lite interface**************************/  

);

wire [75:0]            s_aw_data   = {s_axi_awlock,s_axi_awburst,s_axi_awsize,s_axi_awlen,s_axi_awid,s_axi_awaddr};  //1+2+3+8+18+44
wire [75:0]            s_ar_data   = {s_axi_arlock,s_axi_arburst,s_axi_arsize,s_axi_arlen,s_axi_arid,s_axi_araddr};  //1+2+3+8+18+44
wire [143:0]           s_w_data    = {s_axi_wstrb,s_axi_wdata}; //16+128



wire                  resetn  = ~reset;


wire [75:0]           aw_fifo_inq;
wire                  aw_fifo_inq_valid;
wire                  aw_fifo_inq_ready;

wire [75:0]           aw_inq_packet;  
wire [3:0]            aw_inq_packet_connection_id;
wire [3:0]            aw_inq_packet_context_id;
wire                  aw_inq_packet_valid;
wire                  aw_inq_packet_ready;

wire [143:0]          w_fifo_packet;
wire                  w_fifo_packet_last;
wire                  w_fifo_packet_valid;
wire                  w_fifo_packet_ready;


wire [75:0]           ar_fifo_inq;
wire                  ar_fifo_inq_valid;
wire                  ar_fifo_inq_ready;

assign ar_channel[127:84]  = 44'b 0;
assign ar_channel[3:0]     = 4'b 0010;
assign ar_channel_keep     = 16'h07ff; 
assign ar_channel_last     = 1'b 1;
assign ar_channel_byte_num = 13'h b;

wire    aw_etp;
assign  aw_fifo_inq_valid = ~aw_etp;
wire    aw_ful;
assign  s_axi_awready = ~(aw_ful | reset);

s_aw_fifo s_aw_fifo_inst    //width is 76,depth is 64
(
    .clk            ( clk ),                
    .srst           ( reset ), 
  
    .din            ( s_aw_data ),
    .wr_en          ( s_axi_awvalid ),
    .full           ( aw_ful ),
  
    .rd_en          ( aw_fifo_inq_ready ),
    .dout           ( aw_fifo_inq ),
    .empty          ( aw_etp )  
);



s_w_stream_data_fifo s_w_stream_data_fifo_inst   //width is 18Byte, depth is 256
(
  .s_axis_aresetn         ( resetn ), 
  .s_axis_aclk            ( clk ),
  .s_axis_tvalid          ( s_axi_wvalid ),
  .s_axis_tready          ( s_axi_wready ),
  .s_axis_tdata           ( s_w_data ),
  .s_axis_tlast           ( s_axi_wlast ),
  
  .m_axis_tvalid          ( w_fifo_packet_valid ),
  .m_axis_tready          ( w_fifo_packet_ready ),
  .m_axis_tdata           ( w_fifo_packet ),
  .m_axis_tlast           ( w_fifo_packet_last ),
  
  .axis_data_count        (  ),
  .axis_wr_data_count     (  ),
  .axis_rd_data_count     (  )
);

aw_width_converter aw_width_converter_inst
(
    .reset               ( reset ),
    .clk                 ( clk ),
    
    .aw                  ( {aw_inq_packet,aw_inq_packet_context_id,4'b0001} ), //84bit  include context id and channel num 
    .aw_connection_id    ( aw_inq_packet_connection_id ),
    .aw_valid            ( aw_inq_packet_valid ),
    .aw_ready            ( aw_inq_packet_ready ),

    .w                   ( w_fifo_packet ),  //144bit
    .w_last              ( w_fifo_packet_last ),
    .w_valid             ( w_fifo_packet_valid ),
    .w_ready             ( w_fifo_packet_ready ),
    
    .dout                ( aw_channel ),   //128
    .dout_keep           ( aw_channel_keep ),   //16
    .dout_last           ( aw_channel_last ),
    .dout_connection_id  ( aw_channel_connection_id ),
    .dout_byte_num       ( aw_channel_byte_num ),
    .dout_valid          ( aw_channel_valid ),
    .dout_ready          ( aw_channel_ready )
);



id_inquire  id_inquire_inst
(
    .reset_id_inquire         ( reset_id_inquire ),
    .clk                      ( clk ),
    .reset_soft               ( reset_soft ),
    .start_soft               ( start_soft ),

    .data_in_0                ( aw_fifo_inq ),     //76bit
    .data_valid_in_0          ( aw_fifo_inq_valid ),
    .data_ready_out_0         ( aw_fifo_inq_ready ),
   
    .data_out_0               ( aw_inq_packet ),  //76bit
    .data_connection_id_out_0 ( aw_inq_packet_connection_id ),
    .data_context_id_out_0    ( aw_inq_packet_context_id ),
    .data_valid_out_0         ( aw_inq_packet_valid ),
    .data_ready_in_0          ( aw_inq_packet_ready ),
    .context_id_error_0       (  ),    //high indicate addr is not include context_id table
    .connection_id_error_0    (  ),    //high indicate addr is not include connection_id table
    
    
   
    .data_in_1                ( ar_fifo_inq ),  //76bit
    .data_valid_in_1          ( ar_fifo_inq_valid ),
    .data_ready_out_1         ( ar_fifo_inq_ready ),

    .data_out_1               ( ar_channel[83:8] ),   //76bit
    .data_connection_id_out_1 ( ar_channel_connection_id ),
    .data_context_id_out_1    ( ar_channel[7:4] ),
    .data_valid_out_1         ( ar_channel_valid ),
    .data_ready_in_1          ( ar_channel_ready ),
    .context_id_error_1       (  ),     //high indicate addr is not include context_id table
    .connection_id_error_1    (  ),    //high indicate addr is not include connection_id table


    .context_id_table_0       ( context_id_table_0 ),   //{(context_id_0[4] & start_soft),context_id_0[3:0]}  used for barrier trans
    .context_id_table_1       ( context_id_table_1 ),

    .barrier_valid            ( barrier_valid ),  //keep 1 flop
    .barrier_data             ( barrier_data ),  //25bit
    
    .barrier_answer_0         ( barrier_answer_0 ),
    .barrier_clean_0          ( barrier_clean_0 ),   //keep 1 flop
    .barrier_answer_1         ( barrier_answer_1 ),
    .barrier_clean_1          ( barrier_clean_1 ),   //keep 1 flop

    .phy_base_0               ( phy_base_0 ),
    .phy_base_1               ( phy_base_1 ),

    .s_axi_lite_awaddr        ( s_axi_lite_awaddr ),
    .s_axi_lite_awvalid       ( s_axi_lite_awvalid ),
    .s_axi_lite_awready       ( s_axi_lite_awready ),
    .s_axi_lite_araddr        ( s_axi_lite_araddr ),
    .s_axi_lite_arvalid       ( s_axi_lite_arvalid ),
    .s_axi_lite_arready       ( s_axi_lite_arready ),
    .s_axi_lite_wdata         ( s_axi_lite_wdata ),
    .s_axi_lite_wstrb         ( s_axi_lite_wstrb ),
    .s_axi_lite_wvalid        ( s_axi_lite_wvalid ),
    .s_axi_lite_wready        ( s_axi_lite_wready ),
    .s_axi_lite_rdata         ( s_axi_lite_rdata ),
    .s_axi_lite_rresp         ( s_axi_lite_rresp ),
    .s_axi_lite_rvalid        ( s_axi_lite_rvalid ),
    .s_axi_lite_rready        ( s_axi_lite_rready ),
    .s_axi_lite_bresp         ( s_axi_lite_bresp ),
    .s_axi_lite_bvalid        ( s_axi_lite_bvalid ),
    .s_axi_lite_bready        ( s_axi_lite_bready )
);

wire    ar_ept;
assign  ar_fifo_inq_valid = ~ar_ept;
wire    ar_ful;
assign  s_axi_arready = ~(ar_ful | reset);

s_ar_fifo s_ar_fifo_inst    //width is 76,depth is 64
(
    .clk            ( clk ), 
    .srst           ( reset ),
    
    .din            ( s_ar_data ), 
    .wr_en          ( s_axi_arvalid ),
    .full           ( ar_ful ),
    
    .rd_en          ( ar_fifo_inq_ready ),
    .dout           ( ar_fifo_inq ),
    .empty          ( ar_ept )
);

endmodule
