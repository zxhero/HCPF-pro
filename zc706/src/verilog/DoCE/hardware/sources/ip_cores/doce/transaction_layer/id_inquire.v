


`timescale 1ns / 1ps



module id_inquire
(
    input  wire                   reset_id_inquire,
    input  wire                   clk,
    output reg                    reset_soft = 1'b 0,
    output reg                    start_soft = 1'b 0,
    
    input  wire [75:0]            data_in_0,
    input  wire                   data_valid_in_0,
    output wire                   data_ready_out_0,
    
    output reg  [75:0]            data_out_0=76'b0,
    output reg  [3:0]             data_context_id_out_0=4'b0,
    output reg  [3:0]             data_connection_id_out_0=4'b0,
    output reg                    data_valid_out_0=1'b0,
    input  wire                   data_ready_in_0,
    output reg                    context_id_error_0 = 1'b0,      //high indicate addr is not include context_id table
    output reg                    connection_id_error_0 = 1'b0,  //high indicate addr is not include connection_id table
    

    input  wire [75:0]            data_in_1,
    input  wire                   data_valid_in_1,
    output wire                   data_ready_out_1,
    
    output reg  [75:0]            data_out_1=76'b0,
    output reg [3:0]              data_context_id_out_1=4'b0,
    output reg [3:0]              data_connection_id_out_1=4'b0,
    output reg                    data_valid_out_1=1'b0,
    input  wire                   data_ready_in_1,    
    output reg                    context_id_error_1 = 1'b0,
    output reg                    connection_id_error_1 = 1'b0,
        

    output wire [24:0]            context_id_table_0,   //{(context_id_0[4] & start_soft),context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0}
    output wire [24:0]            context_id_table_1,   //{(context_id_1[4] & start_soft),context_id_1[3:0],connection_id_7,connection_id_6,connection_id_5,connection_id_4};

    output reg                    barrier_valid=1'b0,  //keep 1 flop  include & start_soft & context_id_0[4]
    output reg  [24:0]            barrier_data=25'b0,  //{1'b0,context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0}
    
    input  wire                   barrier_answer_0,
    output reg                    barrier_clean_0=1'b0,   //keep 1 flop
    input  wire                   barrier_answer_1,
    output reg                    barrier_clean_1=1'b0,   //keep 1 flop

    output wire [48:0]            phy_base_0,   //use for rx    {(context_id_0[4] & start_soft),context_id_0[3:0],pa_base_0}
    output wire [48:0]            phy_base_1,   //use for rx


    input  wire [43:0]            s_axi_lite_awaddr,
    input  wire                   s_axi_lite_awvalid,
    output wire                   s_axi_lite_awready,
    
    input  wire [43:0]            s_axi_lite_araddr,
    input  wire                   s_axi_lite_arvalid,
    output wire                   s_axi_lite_arready,
    
    input  wire [31:0]            s_axi_lite_wdata,
    input  wire [3:0]             s_axi_lite_wstrb,
    input  wire                   s_axi_lite_wvalid,
    output wire                   s_axi_lite_wready,
    
    output reg  [31:0]            s_axi_lite_rdata =32'b 0 ,
    output wire [1:0]             s_axi_lite_rresp,
    output reg                    s_axi_lite_rvalid = 1'b 0,
    input  wire                   s_axi_lite_rready,
    
    output wire [1:0]             s_axi_lite_bresp,
    output reg                    s_axi_lite_bvalid = 1'b 0,
    input  wire                   s_axi_lite_bready
);


reg [4:0]     context_id_0     = 5'b0;
reg [4:0]     context_id_1     = 5'b0;
reg [43:0]    shadow_base_0    = 44'b0;
reg [43:0]    shadow_high_0    = 44'b0;
reg [43:0]    shadow_base_1    = 44'b0;
reg [43:0]    shadow_high_1    = 44'b0;

reg [4:0]     connection_id_0  = 5'b0;
reg [4:0]     connection_id_1  = 5'b0;
reg [4:0]     connection_id_2  = 5'b0;
reg [4:0]     connection_id_3  = 5'b0;
reg [43:0]    start_offset_0   = 44'b0;
reg [43:0]    end_offset_0     = 44'b0;
reg [43:0]    start_offset_1   = 44'b0;
reg [43:0]    end_offset_1     = 44'b0;
reg [43:0]    start_offset_2   = 44'b0;
reg [43:0]    end_offset_2     = 44'b0;
reg [43:0]    start_offset_3   = 44'b0;
reg [43:0]    end_offset_3     = 44'b0;

reg [4:0]     connection_id_4  = 5'b0;
reg [4:0]     connection_id_5  = 5'b0;
reg [4:0]     connection_id_6  = 5'b0;
reg [4:0]     connection_id_7  = 5'b0;
reg [43:0]    start_offset_4   = 44'b0;
reg [43:0]    end_offset_4     = 44'b0;
reg [43:0]    start_offset_5   = 44'b0;
reg [43:0]    end_offset_5     = 44'b0;
reg [43:0]    start_offset_6   = 44'b0;
reg [43:0]    end_offset_6     = 44'b0;
reg [43:0]    start_offset_7   = 44'b0;
reg [43:0]    end_offset_7     = 44'b0;

reg [43:0]    pa_base_0        = 44'b0;
reg [43:0]    pa_base_1        = 44'b0;


reg           aw_valid = 1'b 0;
reg           ar_valid = 1'b 0;
reg           w_valid = 1'b 0;


assign   context_id_table_0  = {(context_id_0[4] & start_soft),context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0};
assign   context_id_table_1  = {(context_id_1[4] & start_soft),context_id_1[3:0],connection_id_7,connection_id_6,connection_id_5,connection_id_4};



assign   phy_base_0            = {(context_id_0[4] & start_soft),context_id_0[3:0],pa_base_0};
assign   phy_base_1            = {(context_id_1[4] & start_soft),context_id_1[3:0],pa_base_1};

assign   s_axi_lite_awready    = ~(reset_id_inquire | aw_valid | s_axi_lite_bvalid);
assign   s_axi_lite_arready    = ~(reset_id_inquire | ar_valid | s_axi_lite_rvalid);
assign   s_axi_lite_wready     = ~(reset_id_inquire | w_valid | s_axi_lite_bvalid);
assign   s_axi_lite_bresp      = 2'b 0;
assign   s_axi_lite_rresp      = 2'b 0;


reg  [6:0]    aw_addr       = 7'b 0;
reg  [6:0]    ar_addr       = 7'b 0;
reg  [31:0]   w_data        = 32'b 0;
reg  [3:0]    w_strb        = 4'b 0;

always @(posedge clk)
begin
    if (reset_id_inquire)
    begin
        aw_valid            <= 1'b 0;
        ar_valid            <= 1'b 0;
        w_valid             <= 1'b 0;

        s_axi_lite_rvalid   <= 1'b 0;
        s_axi_lite_bvalid   <= 1'b 0;
        
        reset_soft          <= 1'b0;
        
        context_id_0        <= 5'b0;
        shadow_base_0       <= 44'b0;
        shadow_high_0       <= 44'b0;
        connection_id_0     <= 5'b0;
        start_offset_0      <= 44'b0;
        end_offset_0        <= 44'b0;
        connection_id_1     <= 5'b0;
        start_offset_1      <= 44'b0;
        end_offset_1        <= 44'b0;
        connection_id_2     <= 5'b0;
        start_offset_2      <= 44'b0;
        end_offset_2        <= 44'b0;
        connection_id_3     <= 5'b0;
        start_offset_3      <= 44'b0;
        end_offset_3        <= 44'b0;
        pa_base_0           <= 44'b0;

        context_id_1        <= 5'b0;
        shadow_base_1       <= 44'b0;
        shadow_high_1       <= 44'b0;
        connection_id_4     <= 5'b0;
        start_offset_4      <= 44'b0;
        end_offset_4        <= 44'b0;
        connection_id_5     <= 5'b0;
        start_offset_5      <= 44'b0;
        end_offset_5        <= 44'b0;
        connection_id_6     <= 5'b0;
        start_offset_6      <= 44'b0;
        end_offset_6        <= 44'b0;
        connection_id_7     <= 5'b0;
        start_offset_7      <= 44'b0;
        end_offset_7        <= 44'b0;
        pa_base_1           <= 44'b0;

        start_soft          <= 1'b0;
        
        barrier_valid       <=1'b0;
        barrier_data        <=25'b0;
        barrier_clean_0     <=1'b0;
        barrier_clean_1     <=1'b0; 
    end
    else
    begin
        if (s_axi_lite_awready & s_axi_lite_awvalid)
        begin
            aw_addr            <= s_axi_lite_awaddr[8:2];
            aw_valid           <= 1'b 1;
        end

        if (s_axi_lite_arready & s_axi_lite_arvalid)
        begin
            ar_addr            <= s_axi_lite_araddr[8:2];
            ar_valid           <= 1'b 1;
        end

        if (s_axi_lite_wready & s_axi_lite_wvalid)
        begin
            w_data             <= s_axi_lite_wdata;
            w_strb             <= s_axi_lite_wstrb;
            w_valid            <= 1'b 1;
        end
      
      
        if (s_axi_lite_bvalid & s_axi_lite_bready)
            s_axi_lite_bvalid  <= 1'b 0;


        if (aw_valid & w_valid & (~s_axi_lite_bvalid))
        begin
            aw_valid           <= 1'b 0;
            w_valid            <= 1'b 0;
            s_axi_lite_bvalid  <= 1'b 1;
            
            if (aw_addr == 0)
                context_id_0           <= (context_id_0 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 1)
                context_id_1           <= (context_id_1 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 2)
                shadow_base_0[31:0]    <= (shadow_base_0[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 3)
                shadow_base_0[43:32]   <= (shadow_base_0[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 4)
                shadow_high_0[31:0]    <= (shadow_high_0[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 5)
                shadow_high_0[43:32]   <= (shadow_high_0[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 6)
                shadow_base_1[31:0]    <= (shadow_base_1[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 7)
                shadow_base_1[43:32]   <= (shadow_base_1[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 8)
                shadow_high_1[31:0]    <= (shadow_high_1[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 9)
                shadow_high_1[43:32]   <= (shadow_high_1[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});

            else if (aw_addr == 12)
                connection_id_0        <= (connection_id_0 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 13)
                connection_id_1        <= (connection_id_1 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 14)
                connection_id_2        <= (connection_id_2 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 15)
                connection_id_3        <= (connection_id_3 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 16)
                start_offset_0[31:0]   <= (start_offset_0[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 17)
                start_offset_0[43:32]  <= (start_offset_0[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 18)
                end_offset_0[31:0]     <= (end_offset_0[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 19)
                end_offset_0[43:32]    <= (end_offset_0[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 20)
                start_offset_1[31:0]   <= (start_offset_1[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 21)
                start_offset_1[43:32]  <= (start_offset_1[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 22)
                end_offset_1[31:0]     <= (end_offset_1[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 23)
                end_offset_1[43:32]    <= (end_offset_1[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 24)
                start_offset_2[31:0]   <= (start_offset_2[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 25)
                start_offset_2[43:32]  <= (start_offset_2[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 26)
                end_offset_2[31:0]     <= (end_offset_2[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 27)
                end_offset_2[43:32]    <= (end_offset_2[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 28)
                start_offset_3[31:0]   <= (start_offset_3[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 29)
                start_offset_3[43:32]  <= (start_offset_3[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 30)
                end_offset_3[31:0]     <= (end_offset_3[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 31)
                end_offset_3[43:32]    <= (end_offset_3[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});



            else if (aw_addr == 32)
                connection_id_4        <= (connection_id_4 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 33)
                connection_id_5        <= (connection_id_5 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 34)
                connection_id_6        <= (connection_id_6 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 35)
                connection_id_7        <= (connection_id_7 & {5{~w_strb[0]}}) | (w_data[4:0] & {5{w_strb[0]}});
            else if (aw_addr == 36)
                start_offset_4[31:0]   <= (start_offset_4[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 37)
                start_offset_4[43:32]  <= (start_offset_4[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 38)
                end_offset_4[31:0]     <= (end_offset_4[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 39)
                end_offset_4[43:32]    <= (end_offset_4[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 40)
                start_offset_5[31:0]   <= (start_offset_5[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 41)
                start_offset_5[43:32]  <= (start_offset_5[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 42)
                end_offset_5[31:0]     <= (end_offset_5[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 43)
                end_offset_5[43:32]    <= (end_offset_5[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 44)
                start_offset_6[31:0]   <= (start_offset_6[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 45)
                start_offset_6[43:32]  <= (start_offset_6[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 46)
                end_offset_6[31:0]     <= (end_offset_6[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 47)
                end_offset_6[43:32]    <= (end_offset_6[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 48)
                start_offset_7[31:0]   <= (start_offset_7[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 49)
                start_offset_7[43:32]  <= (start_offset_7[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 50)
                end_offset_7[31:0]     <= (end_offset_7[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 51)
                end_offset_7[43:32]    <= (end_offset_7[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});

            else if (aw_addr == 52)
                pa_base_0[31:0]        <= (pa_base_0[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 53)
                pa_base_0[43:32]       <= (pa_base_0[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 54)
                pa_base_1[31:0]        <= (pa_base_1[31:0] & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 55)
                pa_base_1[43:32]       <= (pa_base_1[43:32] & {{4{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data[11:0] & {{4{w_strb[1]}},{8{w_strb[0]}}});

            else if (aw_addr == 56)
            begin
                barrier_valid               <= w_data[0] & w_strb[0] & start_soft & context_id_0[4];
                barrier_data                <= {1'b0,context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0};
            end
            else if (aw_addr == 57)
            begin
                barrier_valid               <= w_data[0] & w_strb[0] & start_soft & context_id_1[4];
                barrier_data                <= {1'b1,context_id_1[3:0],connection_id_7,connection_id_6,connection_id_5,connection_id_4};
            end

            else if (aw_addr == 64)
            begin
                reset_soft             <= w_data[0] & w_strb[0];
                start_soft             <= w_data[1] & w_strb[0];
            end
        end
        
        if (barrier_valid)
        begin
            barrier_valid      <= 1'b0;
            barrier_data       <= 25'b0;
        end


         
        if (s_axi_lite_rvalid & s_axi_lite_rready)
            s_axi_lite_rvalid    <= 1'b 0;
         
        if (ar_valid & (~s_axi_lite_rvalid))
        begin
            ar_valid             <= 1'b 0;
            s_axi_lite_rvalid    <= 1'b 1;
            if (ar_addr == 0)
                s_axi_lite_rdata   <= {27'b0,context_id_0};
            else if (ar_addr == 1)
                s_axi_lite_rdata   <= {27'b0,context_id_1};
            else if (ar_addr == 2)
                s_axi_lite_rdata   <= shadow_base_0[31:0];
            else if (ar_addr == 3)
                s_axi_lite_rdata   <= {20'b0,shadow_base_0[43:32]};
            else if (ar_addr == 4)
                s_axi_lite_rdata   <= shadow_high_0[31:0];
            else if (ar_addr == 5)
                s_axi_lite_rdata   <= {20'b0,shadow_high_0[43:32]};                    
            else if (ar_addr == 6)
                s_axi_lite_rdata   <= shadow_base_1[31:0];
            else if (ar_addr == 7)
                s_axi_lite_rdata   <= {20'b0,shadow_base_1[43:32]};
            else if (ar_addr == 8)
                s_axi_lite_rdata   <= shadow_high_1[31:0];
            else if (ar_addr == 9)
                s_axi_lite_rdata   <= {20'b0,shadow_high_1[43:32]};  

            else if (ar_addr == 12)
                s_axi_lite_rdata   <= {27'b0,connection_id_0};
            else if (ar_addr == 13)
                s_axi_lite_rdata   <= {27'b0,connection_id_1};
            else if (ar_addr == 14)
                s_axi_lite_rdata   <= {27'b0,connection_id_2};
            else if (ar_addr == 15)
                s_axi_lite_rdata   <= {27'b0,connection_id_3};
            else if (ar_addr == 16)
                s_axi_lite_rdata   <= start_offset_0[31:0];
            else if (ar_addr == 17)
                s_axi_lite_rdata   <= {20'b0,start_offset_0[43:32]};  
            else if (ar_addr == 18)
                s_axi_lite_rdata   <= end_offset_0[31:0];
            else if (ar_addr == 19)
                s_axi_lite_rdata   <= {20'b0,end_offset_0[43:32]};  
            else if (ar_addr == 20)
                s_axi_lite_rdata   <= start_offset_1[31:0];
            else if (ar_addr == 21)
                s_axi_lite_rdata   <= {20'b0,start_offset_1[43:32]};  
            else if (ar_addr == 22)
                s_axi_lite_rdata   <= end_offset_1[31:0];
            else if (ar_addr == 23)
                s_axi_lite_rdata   <= {20'b0,end_offset_1[43:32]};  
            else if (ar_addr == 24)
                s_axi_lite_rdata   <= start_offset_2[31:0];
            else if (ar_addr == 25)
                s_axi_lite_rdata   <= {20'b0,start_offset_2[43:32]};  
            else if (ar_addr == 26)
                s_axi_lite_rdata   <= end_offset_2[31:0];
            else if (ar_addr == 27)
                s_axi_lite_rdata   <= {20'b0,end_offset_2[43:32]}; 
            else if (ar_addr == 28)
                s_axi_lite_rdata   <= start_offset_3[31:0];
            else if (ar_addr == 29)
                s_axi_lite_rdata   <= {20'b0,start_offset_3[43:32]};  
            else if (ar_addr == 30)
                s_axi_lite_rdata   <= end_offset_3[31:0];
            else if (ar_addr == 31)
                s_axi_lite_rdata   <= {20'b0,end_offset_3[43:32]}; 

            else if (ar_addr == 32)
                s_axi_lite_rdata   <= {27'b0,connection_id_4};
            else if (ar_addr == 33)
                s_axi_lite_rdata   <= {27'b0,connection_id_5};
            else if (ar_addr == 34)
                s_axi_lite_rdata   <= {27'b0,connection_id_6};
            else if (ar_addr == 35)
                s_axi_lite_rdata   <= {27'b0,connection_id_7};
            else if (ar_addr == 36)
                s_axi_lite_rdata   <= start_offset_4[31:0];
            else if (ar_addr == 37)
                s_axi_lite_rdata   <= {20'b0,start_offset_4[43:32]};  
            else if (ar_addr == 38)
                s_axi_lite_rdata   <= end_offset_4[31:0];
            else if (ar_addr == 39)
                s_axi_lite_rdata   <= {20'b0,end_offset_4[43:32]};  
            else if (ar_addr == 40)
                s_axi_lite_rdata   <= start_offset_5[31:0];
            else if (ar_addr == 41)
                s_axi_lite_rdata   <= {20'b0,start_offset_5[43:32]};  
            else if (ar_addr == 42)
                s_axi_lite_rdata   <= end_offset_5[31:0];
            else if (ar_addr == 43)
                s_axi_lite_rdata   <= {20'b0,end_offset_5[43:32]};  
            else if (ar_addr == 44)
                s_axi_lite_rdata   <= start_offset_6[31:0];
            else if (ar_addr == 45)
                s_axi_lite_rdata   <= {20'b0,start_offset_6[43:32]};  
            else if (ar_addr == 46)
                s_axi_lite_rdata   <= end_offset_6[31:0];
            else if (ar_addr == 47)
                s_axi_lite_rdata   <= {20'b0,end_offset_6[43:32]}; 
            else if (ar_addr == 48)
                s_axi_lite_rdata   <= start_offset_7[31:0];
            else if (ar_addr == 49)
                s_axi_lite_rdata   <= {20'b0,start_offset_7[43:32]};  
            else if (ar_addr == 50)
                s_axi_lite_rdata   <= end_offset_7[31:0];
            else if (ar_addr == 51)
                s_axi_lite_rdata   <= {20'b0,end_offset_7[43:32]}; 

            else if (ar_addr == 52)
                s_axi_lite_rdata   <= pa_base_0[31:0];
            else if (ar_addr == 53)
                s_axi_lite_rdata   <= {20'b0,pa_base_0[43:32]}; 
            else if (ar_addr == 54)
                s_axi_lite_rdata   <= pa_base_1[31:0];
            else if (ar_addr == 55)
                s_axi_lite_rdata   <= {20'b0,pa_base_1[43:32]}; 
            
            else if (ar_addr == 56)
            begin
                s_axi_lite_rdata    <= {31'b0,barrier_answer_0};
                barrier_clean_0     <= barrier_answer_0;
            end  
            else if (ar_addr == 57)
            begin
                s_axi_lite_rdata    <= {31'b0,barrier_answer_1};
                barrier_clean_1     <= barrier_answer_1;
            end

            else if (ar_addr == 60)
                s_axi_lite_rdata    <= {27'b0,connection_id_3[4],connection_id_2[4],connection_id_1[4],connection_id_0[4]};
            else if (ar_addr == 61)
                s_axi_lite_rdata    <= {27'b0,connection_id_7[4],connection_id_6[4],connection_id_5[4],connection_id_4[4]};

            else if (ar_addr == 64)
               s_axi_lite_rdata    <= {30'b0,start_soft,1'b0};

            else
               s_axi_lite_rdata     <= 32'b0;        
        end
        
        if (barrier_clean_0)
            barrier_clean_0     <= 1'b0;
        if (barrier_clean_1)
            barrier_clean_1     <= 1'b0;
    end
end



reg [75:0]        data_mid_0=76'b0;
reg [3:0]         data_context_id_mid_0=4'b0;
reg               data_valid_mid_0=1'b0;
wire              data_ready_mid_0;

assign   data_ready_out_0  = (~reset_id_inquire) & ((~data_valid_mid_0) | data_ready_mid_0);
assign   data_ready_mid_0  = (~reset_id_inquire) & ((~data_valid_out_0) | data_ready_in_0);

always @(posedge clk)
begin
    if (reset_id_inquire)
    begin
        data_mid_0              <=  76'b0;
        data_context_id_mid_0   <= 4'b0;
        data_valid_mid_0        <= 1'b0;
        context_id_error_0      <= 1'b 0;
    end
    else if (data_valid_in_0 & data_ready_out_0)
    begin
        if ((data_in_0[43:0]>=shadow_base_0) & (data_in_0[43:0]<=shadow_high_0) & context_id_0[4] & start_soft)
        begin
            data_mid_0             <= data_in_0;
            data_context_id_mid_0  <= context_id_0[3:0];
            data_valid_mid_0       <= 1'b1;
         end
         else if ((data_in_0[43:0]>=shadow_base_1) & (data_in_0[43:0]<=shadow_high_1) & context_id_1[4] & start_soft)
         begin
             data_mid_0             <= data_in_0;
             data_context_id_mid_0  <= context_id_1[3:0];
             data_valid_mid_0       <= 1'b1;
         end
         else
         begin        
             data_mid_0             <= 76'b0;
             data_context_id_mid_0  <= 4'b0;
             data_valid_mid_0       <= 1'b 0;
             context_id_error_0     <= 1'b 1;
         end
    end
    else
    begin
        data_mid_0             <= data_mid_0;
        data_context_id_mid_0  <= data_context_id_mid_0;
        data_valid_mid_0       <= data_valid_mid_0 & (~data_ready_mid_0);
    end

    
    if (reset_id_inquire)
    begin
        data_out_0                <= 76'b0;
        data_context_id_out_0     <= 4'b0;
        data_connection_id_out_0  <= 4'b0;
        data_valid_out_0          <= 1'b0;
        connection_id_error_0     <= 1'b0;
    end
    else if (data_valid_mid_0 & data_ready_mid_0 & (data_context_id_mid_0==context_id_0[3:0]))
    begin
        if ((data_mid_0[43:0]>=start_offset_0) & (data_mid_0[43:0]<=end_offset_0) & connection_id_0[4])
        begin
            data_out_0                <= data_mid_0;
            data_context_id_out_0     <= data_context_id_mid_0;
            data_connection_id_out_0  <= connection_id_0[3:0];
            data_valid_out_0          <= 1'b1;
        end
        else if ((data_mid_0[43:0]>=start_offset_1) & (data_mid_0[43:0]<=end_offset_1) & connection_id_1[4])
        begin
            data_out_0                <= data_mid_0;
            data_context_id_out_0     <= data_context_id_mid_0;
            data_connection_id_out_0  <= connection_id_1[3:0];
            data_valid_out_0          <= 1'b1;
        end
        else if ((data_mid_0[43:0]>=start_offset_2) & (data_mid_0[43:0]<=end_offset_2) & connection_id_2[4])
        begin
            data_out_0                <= data_mid_0;
            data_context_id_out_0     <= data_context_id_mid_0;
            data_connection_id_out_0  <= connection_id_2[3:0];
            data_valid_out_0          <= 1'b1;
        end        
        else if ((data_mid_0[43:0]>=start_offset_3) & (data_mid_0[43:0]<=end_offset_3) & connection_id_3[4])
        begin
            data_out_0                <= data_mid_0;
            data_context_id_out_0     <= data_context_id_mid_0;
            data_connection_id_out_0  <= connection_id_3[3:0];
            data_valid_out_0          <= 1'b1;
        end
        else
        begin
            data_out_0                <= 76'b0;
            data_context_id_out_0     <= 4'b0;
            data_connection_id_out_0  <= 4'b0;
            data_valid_out_0          <= 1'b0;
            connection_id_error_0     <= 1'b1;
        end                
    end

    else if (data_valid_mid_0 & data_ready_mid_0 & (data_context_id_mid_0==context_id_1[3:0]))
    begin
        if ((data_mid_0[43:0]>=start_offset_4) & (data_mid_0[43:0]<=end_offset_4) & connection_id_4[4])
        begin
            data_out_0                <= data_mid_0;
            data_context_id_out_0     <= data_context_id_mid_0;
            data_connection_id_out_0  <= connection_id_4[3:0];
            data_valid_out_0          <= 1'b1;
        end
        else if ((data_mid_0[43:0]>=start_offset_5) & (data_mid_0[43:0]<=end_offset_5) & connection_id_5[4])
        begin
            data_out_0                <= data_mid_0;
            data_context_id_out_0     <= data_context_id_mid_0;
            data_connection_id_out_0  <= connection_id_5[3:0];
            data_valid_out_0          <= 1'b1;
        end
        else if ((data_mid_0[43:0]>=start_offset_6) & (data_mid_0[43:0]<=end_offset_6) & connection_id_6[4])
        begin
            data_out_0                <= data_mid_0;
            data_context_id_out_0     <= data_context_id_mid_0;
            data_connection_id_out_0  <= connection_id_6[3:0];
            data_valid_out_0          <= 1'b1;
        end        
        else if ((data_mid_0[43:0]>=start_offset_7) & (data_mid_0[43:0]<=end_offset_7) & connection_id_7[4])
        begin
            data_out_0                <= data_mid_0;
            data_context_id_out_0     <= data_context_id_mid_0;
            data_connection_id_out_0  <= connection_id_7[3:0];
            data_valid_out_0          <= 1'b1;
        end
        else
        begin
            data_out_0                <= 76'b0;
            data_context_id_out_0     <= 4'b0;
            data_connection_id_out_0  <= 4'b0;
            data_valid_out_0          <= 1'b0;
            connection_id_error_0     <= 1'b1;
        end                
    end
    else
    begin
        data_out_0                <= data_out_0;
        data_context_id_out_0     <= data_context_id_out_0;
        data_connection_id_out_0  <= data_connection_id_out_0;
        data_valid_out_0          <= data_valid_out_0 & (~data_ready_in_0);
    end
end



reg [75:0]        data_mid_1=76'b0;
reg [3:0]         data_context_id_mid_1=4'b0;
reg               data_valid_mid_1=1'b0;
wire              data_ready_mid_1;

assign   data_ready_out_1  = (~(reset_id_inquire)) & ((~data_valid_mid_1) | data_ready_mid_1);
assign   data_ready_mid_1  = (~(reset_id_inquire)) & ((~data_valid_out_1) | data_ready_in_1);
always @(posedge clk)
begin
    if (reset_id_inquire)
    begin
        data_mid_1              <=  76'b0;
        data_context_id_mid_1   <= 4'b0;
        data_valid_mid_1        <= 1'b0;
        context_id_error_1      <= 1'b0;
    end
    else if (data_valid_in_1 & data_ready_out_1)
    begin
        if ((data_in_1[43:0]>=shadow_base_0) & (data_in_1[43:0]<=shadow_high_0) & context_id_0[4] & start_soft)
        begin
            data_mid_1             <= data_in_1;
            data_context_id_mid_1  <= context_id_0[3:0];
            data_valid_mid_1       <= 1'b1;
         end
         else if ((data_in_1[43:0]>=shadow_base_1) & (data_in_1[43:0]<=shadow_high_1) & context_id_1[4] & start_soft)
         begin
             data_mid_1             <= data_in_1;
             data_context_id_mid_1  <= context_id_1[3:0];
             data_valid_mid_1       <= 1'b1;
         end
         else
         begin        
             data_mid_1             <= 76'b0;
             data_context_id_mid_1  <= 4'b0;
             data_valid_mid_1       <= 1'b0;
             context_id_error_1     <= 1'b1;
         end
    end
    else
    begin
        data_mid_1             <= data_mid_1;
        data_context_id_mid_1  <= data_context_id_mid_1;
        data_valid_mid_1       <= data_valid_mid_1 & (~data_ready_mid_1);
    end

    
    if (reset_id_inquire)
    begin
        data_out_1               <= 76'b0;
        data_context_id_out_1    <= 4'b0;
        data_connection_id_out_1 <= 4'b0;
        data_valid_out_1         <= 1'b0;
        connection_id_error_1    <= 1'b0;
    end
    else if (data_valid_mid_1 & data_ready_mid_1 & (data_context_id_mid_1==context_id_0[3:0]))
    begin
        if ((data_mid_1[43:0]>=start_offset_0) & (data_mid_1[43:0]<=end_offset_0) & connection_id_0[4])
        begin
            data_out_1                <= data_mid_1;
            data_context_id_out_1     <= data_context_id_mid_1;
            data_connection_id_out_1  <= connection_id_0[3:0];
            data_valid_out_1          <= 1'b1;
        end
        else if ((data_mid_1[43:0]>=start_offset_1) & (data_mid_1[43:0]<=end_offset_1) & connection_id_1[4])
        begin
            data_out_1                <= data_mid_1;
            data_context_id_out_1     <= data_context_id_mid_1;
            data_connection_id_out_1  <= connection_id_1[3:0];
            data_valid_out_1          <= 1'b1;
        end
        else if ((data_mid_1[43:0]>=start_offset_2) & (data_mid_1[43:0]<=end_offset_2) & connection_id_2[4])
        begin
            data_out_1                <= data_mid_1;
            data_context_id_out_1     <= data_context_id_mid_1;
            data_connection_id_out_1  <= connection_id_2[3:0];
            data_valid_out_1          <= 1'b1;
        end        
        else if ((data_mid_1[43:0]>=start_offset_3) & (data_mid_1[43:0]<=end_offset_3) & connection_id_3[4])
        begin
            data_out_1                <= data_mid_1;
            data_context_id_out_1     <= data_context_id_mid_1;
            data_connection_id_out_1  <= connection_id_3[3:0];
            data_valid_out_1          <= 1'b1;
        end
        else
        begin
            data_out_1                <= 76'b0;
            data_context_id_out_1     <= 4'b0;
            data_connection_id_out_1  <= 4'b0;
            data_valid_out_1          <= 1'b0;
            connection_id_error_1     <= 1'b1;
        end                
    end

    else if (data_valid_mid_1 & data_ready_mid_1 & (data_context_id_mid_1==context_id_1[3:0]))
    begin
        if ((data_mid_1[43:0]>=start_offset_4) & (data_mid_1[43:0]<=end_offset_4) & connection_id_4[4])
        begin
            data_out_1                <= data_mid_1;
            data_context_id_out_1     <= data_context_id_mid_1;
            data_connection_id_out_1  <= connection_id_4[3:0];
            data_valid_out_1          <= 1'b1;
        end
        else if ((data_mid_1[43:0]>=start_offset_5) & (data_mid_1[43:0]<=end_offset_5) & connection_id_5[4])
        begin
            data_out_1                <= data_mid_1;
            data_context_id_out_1     <= data_context_id_mid_1;
            data_connection_id_out_1  <= connection_id_5[3:0];
            data_valid_out_1          <= 1'b1;
        end
        else if ((data_mid_1[43:0]>=start_offset_6) & (data_mid_1[43:0]<=end_offset_6) & connection_id_6[4])
        begin
            data_out_1                <= data_mid_1;
            data_context_id_out_1     <= data_context_id_mid_1;
            data_connection_id_out_1  <= connection_id_6[3:0];
            data_valid_out_1          <= 1'b1;
        end        
        else if ((data_mid_1[43:0]>=start_offset_7) & (data_mid_1[43:0]<=end_offset_7) & connection_id_7[4])
        begin
            data_out_1                <= data_mid_1;
            data_context_id_out_1     <= data_context_id_mid_1;
            data_connection_id_out_1  <= connection_id_7[3:0];
            data_valid_out_1          <= 1'b1;
        end
        else
        begin
            data_out_1                <= 76'b0;
            data_context_id_out_1     <= 4'b0;
            data_connection_id_out_1  <= 4'b0;
            data_valid_out_1          <= 1'b0;
            connection_id_error_1     <= 1'b1;
        end                
    end
    else
    begin
        data_out_1                <= data_out_1;
        data_context_id_out_1     <= data_context_id_out_1;
        data_connection_id_out_1  <= data_connection_id_out_1;
        data_valid_out_1          <= data_valid_out_1 & (~data_ready_in_1);
    end
end

endmodule
