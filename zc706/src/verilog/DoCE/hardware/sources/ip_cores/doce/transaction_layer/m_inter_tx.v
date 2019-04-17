`timescale 1ns / 1ps

module m_inter_tx
(
   input wire                               reset,
   input wire                               clk,
   

   input  wire [127:0]                      m_axi_rdata,
   input  wire [21:0]                       m_axi_rid,    //include 4bit connection id
   input  wire                              m_axi_rlast,
   input  wire [1:0]                        m_axi_rresp,
   input  wire                              m_axi_rvalid,
   output wire                              m_axi_rready,

   input  wire [1:0]                        m_axi_bresp,
   input  wire [21:0]                       m_axi_bid,   //include 4bit connection id
   input  wire                              m_axi_bvalid,
   output wire                              m_axi_bready,

   output wire [127:0]                      r_channel,
   output wire [15:0]                       r_channel_keep,
   output wire                              r_channel_last,
   output wire [3:0]                        r_channel_connection_id,
   output wire [12:0]                       r_channel_byte_num,
   output wire                              r_channel_valid,
   input  wire                              r_channel_ready,
   
   output wire [127:0]                      b_channel,
   output wire [15:0]                       b_channel_keep,
   output wire                              b_channel_last,
   output wire [3:0]                        b_channel_connection_id,
   output wire [12:0]                       b_channel_byte_num,
   output wire                              b_channel_valid,
   input  wire                              b_channel_ready

);

assign   b_channel_byte_num = 13'h3;



wire [23:0]   m_r_data      = {m_axi_rid,m_axi_rresp};
wire [23:0]   m_b_data      = {m_axi_bid,m_axi_rresp};


wire           resetn  = ~reset;


wire [127:0]    r_packet_fifo;
wire            r_packet_fifo_last;
wire            r_packet_fifo_valid;
wire            r_packet_fifo_ready;

wire            r_fifo_gen_valid;
wire            r_fifo_gen_ready;       // input wire m_axis_tready
wire [127:0]    r_fifo_gen;             // output wire [127 : 0] m_axis_tdata
wire            r_fifo_gen_last;            // output wire m_axis_tlast

wire            r_num_fifo_full;
wire [8:0]      r_packet_fifo_num;
wire            r_packet_fifo_num_valid;
wire            r_packet_fifo_num_ready = ~(r_num_fifo_full | reset);

wire           r_num_fifo_ept;
wire [8:0]     r_fifo_gen_num;
wire           r_fifo_gen_num_valid = ~r_num_fifo_ept;
wire           r_fifo_gen_num_ready;

r_width_converter r_width_converter_inst    //only store useful data
(
   .reset                 ( reset ),
   .clk                   ( clk ),

   .rdata_in              ( m_axi_rdata ),
   .rlast_in              ( m_axi_rlast ),
   .config_in             ( m_r_data ),   //24bit
   .valid_in              ( m_axi_rvalid ),
   .ready_out             ( m_axi_rready ),


   .rlast_out             ( r_packet_fifo_last ),
   .rdata_out             ( r_packet_fifo ),
   .valid_out             ( r_packet_fifo_valid ),
   .ready_in              ( r_packet_fifo_ready ),
   
   .num                   ( r_packet_fifo_num ),
   .num_valid             ( r_packet_fifo_num_valid ),
   .num_ready             ( r_packet_fifo_num_ready )
);



m_r_stream_data_fifo m_r_stream_data_fifo_inst   //width is 16Byte, depth is 256
(
  .s_axis_aresetn         ( resetn ),                // input wire s_axis_aresetn
  .s_axis_aclk            ( clk ),                // input wire s_axis_aclk
  
  .s_axis_tvalid          ( r_packet_fifo_valid ),  // input wire s_axis_tvalid
  .s_axis_tready          ( r_packet_fifo_ready ),  // output wire s_axis_tready
  .s_axis_tdata           ( r_packet_fifo ),   // input wire [127 : 0] s_axis_tdata
  .s_axis_tlast           ( r_packet_fifo_last ),  // input wire s_axis_tlast
  
  .m_axis_tvalid          ( r_fifo_gen_valid ),            // output wire m_axis_tvalid
  .m_axis_tready          ( r_fifo_gen_ready ),            // input wire m_axis_tready
  .m_axis_tdata           ( r_fifo_gen ),              // output wire [127 : 0] m_axis_tdata
  .m_axis_tlast           ( r_fifo_gen_last ),              // output wire m_axis_tlast
  
  .axis_data_count        (  ),  // output wire [31 : 0] axis_data_count
  .axis_wr_data_count     (  ),  // output wire [31 : 0] axis_wr_data_count
  .axis_rd_data_count     (  )  // output wire [31 : 0] axis_rd_data_count
);





r_num_fifo r_num_fifo_inst
(
    .srst     ( reset ),    // input wire srst
    .clk      ( clk ),      // input wire clk

    .din      ( r_packet_fifo_num ),      // input wire [8 : 0] din
    .wr_en    ( r_packet_fifo_num_valid ),  // input wire wr_en
    .full     ( r_num_fifo_full ),    // output wire full    

    .dout     ( r_fifo_gen_num ),    // output wire [8 : 0] dout    
    .rd_en    ( r_fifo_gen_num_ready ),  // input wire rd_en
    .empty    ( r_num_fifo_ept )  // output wire empty
);



r_connection_id_gene r_connection_id_gene_inst  //delete connection id ,add channel num
(
   .reset                    ( reset ),
   .clk                      ( clk ),
   
   .data                     ( r_fifo_gen ),
   .last                     ( r_fifo_gen_last ),
   .valid                    ( r_fifo_gen_valid ),
   .ready                    ( r_fifo_gen_ready ),
   
   .num                      ( r_fifo_gen_num ),
   .num_valid                ( r_fifo_gen_num_valid ),
   .num_ready                ( r_fifo_gen_num_ready ),
   
   .r_channel                ( r_channel ),
   .r_channel_connection_id  ( r_channel_connection_id ),
   .r_channel_byte_num       ( r_channel_byte_num ),
   .r_channel_keep           ( r_channel_keep ),
   .r_channel_last           ( r_channel_last ),
   .r_channel_valid          ( r_channel_valid ),
   .r_channel_ready          ( r_channel_ready )

);


wire    b_ept;
assign  b_channel_valid =~b_ept;
wire    b_ful;
assign  m_axi_bready = ~(b_ful | reset);

m_b_fifo m_b_fifo_inst    //width is 24,depth is 64
 (
    .clk            ( clk ),
    .srst           ( reset ),
    
    .din            ( m_b_data ),
    .wr_en          ( m_axi_bvalid ),
    .full           ( b_ful ),
    
    .rd_en          ( b_channel_ready ),
    .dout           ( {b_channel_connection_id,b_channel[23:4]} ),
    .empty          ( b_ept )
 ); 


assign b_channel[127:24] = 104'b 0; 
assign b_channel[3:0]    = 4'b 0100;
assign b_channel_keep    = 16'h 0007;
assign b_channel_last    = 1'b 1;
 


endmodule
