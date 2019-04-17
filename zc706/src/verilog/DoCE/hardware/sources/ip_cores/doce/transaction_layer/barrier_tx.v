`timescale 1ns / 1ps

module barrier_tx
(
    input  wire             reset,
    input  wire             clk,

    input  wire [24:0]      context_id_table_0,  //{(context_id_0[4] & start_soft),context_id_0[3:0],connection_id_3,connection_id_2,connection_id_1,connection_id_0}
    input  wire [24:0]      context_id_table_1,  //{(context_id_1[4] & start_soft),context_id_1[3:0],connection_id_7,connection_id_6,connection_id_5,connection_id_4};

    input  wire             valid,    //keep 1 flop  include & start_soft & context_id_0[4]
    input  wire [24:0]      data,    //25bit   broadcase information
   
    output reg              answer_0=1'b0,   //use to be read by lite
    input  wire             clean_0,        //keep 1 flop after read
    output reg              answer_1=1'b0,
    input  wire             clean_1,

    input  wire [3:0]       rx_connection_id,
    input  wire [3:0]       rx_context_id,
    input  wire             rx_broadcast_answer,  //high stand for broadcast message from other,low stand for answer message from other
    input  wire             rx_valid,
    output reg              rx_ready=1'b0,
   
    output reg  [127:0]     channel=128'b0,
    output reg  [3:0]       channel_connection_id=4'b0,
    output wire [12:0]      channel_byte_num,
    output wire [15:0]      channel_keep,
    output wire             channel_last,
    output reg              channel_valid=1'b0,
    input  wire             channel_ready
);


assign        channel_keep = 16'h1;
assign        channel_last = 1'b1;
assign        channel_byte_num = 13'b 1;

reg  [24:0]   data_mid_0 = 25'b0;
reg  [24:0]   data_mid_1 = 25'b0;
reg           valid_mid_0 = 1'b0;
reg           valid_mid_1 = 1'b0;
reg           ready_mid_0 = 1'b0;

always @(posedge clk) //as 2 depth fifo,  data_out of fifo is data_mid_0, valid_out of fifo is valid_mid_0,rden of fifo is ready_mid_0
begin
    if (reset)
    begin
        data_mid_1    <= 25'b0;
        valid_mid_1   <= 1'b0;
        data_mid_0    <= 25'b0;
        valid_mid_0   <= 1'b0;        
    end
    else if (~valid_mid_0)
    begin
        data_mid_1    <= data;
        valid_mid_1   <= valid;
        data_mid_0    <= data_mid_1;
        valid_mid_0   <= valid_mid_1;
    end
    else 
    begin
        if (~valid_mid_1)
        begin
            data_mid_1    <= data;
            valid_mid_1   <= valid;
        end
        
        if (ready_mid_0)
        begin
            data_mid_0    <= data_mid_1;
            valid_mid_0   <= valid_mid_1;
            data_mid_1    <= data;
            valid_mid_1   <= valid;
        end  
    end
end


localparam SW         = 4;
localparam ONE_HOT    = 4'b 1;
localparam st0        = ONE_HOT << 0;
localparam st1        = ONE_HOT << 1;
localparam st2        = ONE_HOT << 2;
localparam st3        = ONE_HOT << 3;
reg  [SW-1:0]    state=st0;
reg  [SW-1:0]    next_state=st0;

reg  [127:0]     next_channel = 128'b0;
reg  [3:0]       next_channel_connection_id = 4'b0;
reg              next_channel_valid = 1'b0;

always @(posedge clk)
begin
    if (reset)
    begin
        channel                <= 128'b0;
        channel_connection_id  <= 4'b0;
        channel_valid          <= 1'b0;
        state                  <= st0;
    end
    else 
    begin
        channel                <= next_channel;
        channel_connection_id  <= next_channel_connection_id;
        channel_valid          <= next_channel_valid;
        state                  <= next_state;
    end
end

always @(reset                    or
         state                    or
         channel                  or
         channel_connection_id    or
         channel_valid            or
         channel_ready            or
         valid_mid_0              or
         rx_valid                 or
         rx_context_id            or
         rx_connection_id         or
         rx_broadcast_answer      or
         data_mid_0[23:0]         
        )
begin
    next_channel                <= channel;
    next_channel_connection_id  <= channel_connection_id;
    next_channel_valid          <= channel_valid;
    next_state                  <= state;
    if (reset)
    begin
        next_channel                <= 128'b0;
        next_channel_connection_id  <= 4'b0;
        next_channel_valid          <= 1'b0;
        next_state                  <= st0;
        rx_ready                    <= 1'b0;
        ready_mid_0                 <= 1'b0;
    end
    else
    begin
        case (state)
        st0:
        begin
            if ((~channel_valid) | channel_ready)
            begin 
                if (valid_mid_0)
                begin
                    rx_ready                      <= 1'b0;
                    ready_mid_0                   <= (~data_mid_0[4]) & (~data_mid_0[9]) & (~data_mid_0[14]);    // ready_mid_0 is high after deal with barrier sending 
                    if (data_mid_0[4])
                    begin
                        next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                        next_channel_connection_id   <= data_mid_0[3:0];
                        next_channel_valid           <= 1'b 1;
                        next_state                   <= st1;
                    end
                    else if (data_mid_0[9])
                    begin
                        next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                        next_channel_connection_id   <= data_mid_0[8:5];
                        next_channel_valid           <= 1'b 1;
                        next_state                   <= st2;
                    end
                    else if (data_mid_0[14])
                    begin
                        next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                        next_channel_connection_id   <= data_mid_0[13:10];
                        next_channel_valid           <= 1'b 1;
                        next_state                   <= st3;
                    end
                    else if (data_mid_0[19])
                    begin
                        next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                        next_channel_connection_id   <= data_mid_0[18:15];
                        next_channel_valid           <= 1'b 1;
                        next_state                   <= st0;
                    end
                    else
                    begin
                        next_channel                 <= 128'b0;
                        next_channel_connection_id   <= 4'b0;
                        next_channel_valid           <= 1'b 0;
                        next_state                   <= st0;
                    end
                end
                else if (rx_valid)
                begin
                    rx_ready                     <= 1'b1;
                    ready_mid_0                  <= 1'b0;
                    next_channel                 <= {120'b0,rx_context_id,4'h6};
                    next_channel_connection_id   <= rx_connection_id;
                    next_channel_valid           <= rx_broadcast_answer;    //high stand for broadcast message from other,low stand for answer message from other
                    next_state                   <= st0;
                end
                else
                begin
                    rx_ready                     <= 1'b0;
                    ready_mid_0                  <= 1'b0;
                    next_channel                 <= 128'b0;
                    next_channel_connection_id   <= 4'b0;
                    next_channel_valid           <= 1'b0;
                    next_state                   <= st0;
                end
            end
            else
            begin
                rx_ready                      <= 1'b0;
                ready_mid_0                   <= 1'b0;
            end
        end
        st1:   //test data_mid[9]
        begin
            rx_ready                     <= 1'b0;
            if (channel_ready)
            begin
                ready_mid_0                   <= (~data_mid_0[9]) & (~data_mid_0[14]);
                if (data_mid_0[9])
                begin
                    next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                    next_channel_connection_id   <= data_mid_0[8:5];
                    next_channel_valid           <= 1'b 1;
                    next_state                   <= st2;
                end
                else if (data_mid_0[14])
                begin
                    next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                    next_channel_connection_id   <= data_mid_0[13:10];
                    next_channel_valid           <= 1'b 1;
                    next_state                   <= st3;
                end
                else if (data_mid_0[19])
                begin
                    next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                    next_channel_connection_id   <= data_mid_0[18:15];
                    next_channel_valid           <= 1'b 1;
                    next_state                   <= st0;
                end
                else
                begin
                    next_channel                 <= 128'b0;
                    next_channel_connection_id   <= 4'b0;
                    next_channel_valid           <= 1'b 0;
                    next_state                   <= st0;
                end
            end
            else
            begin
                ready_mid_0                   <= 1'b0;
            end
        end

        st2:   //test data_mid[14]
        begin
            rx_ready                     <= 1'b0;
            if (channel_ready)
            begin
                ready_mid_0                   <= ~data_mid_0[14];
                if (data_mid_0[14])
                begin
                    next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                    next_channel_connection_id   <= data_mid_0[13:10];
                    next_channel_valid           <= 1'b 1;
                    next_state                   <= st3;
                end
                else if (data_mid_0[19])
                begin
                    next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                    next_channel_connection_id   <= data_mid_0[18:15];
                    next_channel_valid           <= 1'b 1;
                    next_state                   <= st0;
                end
                else
                begin
                    next_channel                 <= 128'b0;
                    next_channel_connection_id   <= 4'b0;
                    next_channel_valid           <= 1'b 0;
                    next_state                   <= st0;
                end
            end
            else
            begin
                ready_mid_0              <= 1'b 0;
            end
        end
        st3:   //test data_mid[19]
        begin
            rx_ready                     <= 1'b0;
            if (channel_ready)
            begin
                ready_mid_0                  <= 1'b 1;
                next_state                   <= st0;
                if (data_mid_0[19])
                begin
                    next_channel                 <= {120'b0,data_mid_0[23:20],4'h5};
                    next_channel_connection_id   <= data_mid_0[18:15];
                    next_channel_valid           <= 1'b 1;
                end
                else
                begin
                    next_channel                 <= 128'b0;
                    next_channel_connection_id   <= 4'b0;
                    next_channel_valid           <= 1'b 0;
                end
            end
            else
            begin
                ready_mid_0                  <= 1'b 0;
            end
        end 
        default:
        begin
            next_channel                <= 128'b0;
            next_channel_connection_id  <= 4'b0;
            next_channel_valid          <= 1'b0;
            next_state                  <= st0;
            rx_ready                    <= 1'b0;
            ready_mid_0                 <= 1'b0;
        end
        endcase
    end
end



reg         context_valid_0= 1'b0;
reg         context_valid_1= 1'b0;
        
reg [3:0]   context_broadcast_0= 4'b0;   //record received broadcase package
reg [3:0]   context_broadcast_1= 4'b0;

reg [3:0]   context_answer_0= 4'b0;    //record received answer package
reg [3:0]   context_answer_1= 4'b0;
        


always @(posedge clk)
begin
    if (reset)
    begin
        context_valid_0       <= 1'b0;
        context_valid_1       <= 1'b0;
        
        context_broadcast_0    <= 4'b0;
        context_broadcast_1    <= 4'b0;
        
        context_answer_0       <= 4'b0;
        context_answer_1       <= 4'b0;
        
        answer_0               <= 1'b0;
        answer_1               <= 1'b0;
    end
    else
    begin
        if (clean_0)
            context_valid_0       <= 1'b0;
        else if (valid_mid_0 & ready_mid_0  & (~data_mid_0[24]))
            context_valid_0       <= 1'b1;   
                        
        if (clean_1)
            context_valid_1       <= 1'b0;
        else if (valid_mid_0 & ready_mid_0 & data_mid_0[24])
            context_valid_1       <= 1'b1;
        
        if (clean_0)
            context_broadcast_0    <= 4'b0;
        else if (rx_valid & rx_ready & rx_broadcast_answer & (rx_context_id==context_id_table_0[23:20]) & context_id_table_0[24])
        begin
            if ((rx_connection_id==context_id_table_0[18:15]) & (~context_broadcast_0[3]) & context_id_table_0[19])
                context_broadcast_0[3]   <= 1'b1;
            else if ((rx_connection_id==context_id_table_0[13:10]) & (~context_broadcast_0[2]) & context_id_table_0[14])
                context_broadcast_0[2]   <= 1'b1;
            else if ((rx_connection_id==context_id_table_0[8:5]) & (~context_broadcast_0[1]) & context_id_table_0[9])
                context_broadcast_0[1]   <= 1'b1;        
            else if ((rx_connection_id==context_id_table_0[3:0]) & (~context_broadcast_0[0]) & context_id_table_0[4])
                context_broadcast_0[0]   <= 1'b1;        
        end

        if (clean_1)
            context_broadcast_1    <= 4'b0;
        else if (rx_valid & rx_ready & rx_broadcast_answer & (rx_context_id==context_id_table_1[23:20]) & context_id_table_1[24])
        begin
            if ((rx_connection_id==context_id_table_1[18:15]) & (~context_broadcast_1[3]) & context_id_table_1[19])
                context_broadcast_1[3]   <= 1'b1;
            else if ((rx_connection_id==context_id_table_1[13:10]) & (~context_broadcast_1[2]) & context_id_table_1[14])
                context_broadcast_1[2]   <= 1'b1;
            else if ((rx_connection_id==context_id_table_1[8:5]) & (~context_broadcast_1[1]) & context_id_table_1[9])
                context_broadcast_1[1]   <= 1'b1;        
            else if ((rx_connection_id==context_id_table_1[3:0]) & (~context_broadcast_1[0]) & context_id_table_1[4])
                context_broadcast_1[0]   <= 1'b1;        
        end



        if (clean_0)
            context_answer_0    <= 4'b0;
        else if (rx_valid & rx_ready & (~rx_broadcast_answer) & (rx_context_id==context_id_table_0[23:20]) & context_id_table_0[24])
        begin
            if ((rx_connection_id==context_id_table_0[18:15]) & (~context_answer_0[3]) & context_id_table_0[19])
                context_answer_0[3]   <= 1'b1;
            else if ((rx_connection_id==context_id_table_0[13:10]) & (~context_answer_0[2]) & context_id_table_0[14])
                context_answer_0[2]   <= 1'b1;
            else if ((rx_connection_id==context_id_table_0[8:5]) & (~context_answer_0[1]) & context_id_table_0[9])
                context_answer_0[1]   <= 1'b1;        
            else if ((rx_connection_id==context_id_table_0[3:0]) & (~context_answer_0[0]) & context_id_table_0[4])
                context_answer_0[0]   <= 1'b1;        
        end

        if (clean_1)
            context_answer_1    <= 4'b0;
        else if (rx_valid & rx_ready & (~rx_broadcast_answer) & (rx_context_id==context_id_table_1[23:20]) & context_id_table_1[24])
        begin
            if ((rx_connection_id==context_id_table_1[18:15]) & (~context_answer_1[3]) & context_id_table_1[19])
                context_answer_1[3]   <= 1'b1;
            else if ((rx_connection_id==context_id_table_1[13:10]) & (~context_answer_1[2]) & context_id_table_1[14])
                context_answer_1[2]   <= 1'b1;
            else if ((rx_connection_id==context_id_table_1[8:5]) & (~context_answer_1[1]) & context_id_table_1[9])
                context_answer_1[1]   <= 1'b1;        
            else if ((rx_connection_id==context_id_table_1[3:0]) & (~context_answer_1[0]) & context_id_table_1[4])
                context_answer_1[0]   <= 1'b1;        
        end
        
        if (clean_0)
            answer_0             <= 1'b0;
        else
            answer_0             <= context_valid_0 & ((context_broadcast_0 & context_answer_0 & {context_id_table_0[19],context_id_table_0[14],context_id_table_0[9],context_id_table_0[4]}) == {context_id_table_0[19],context_id_table_0[14],context_id_table_0[9],context_id_table_0[4]});

        if (clean_1)
            answer_1             <= 1'b0;
        else
            answer_1             <= context_valid_1 & ((context_broadcast_1 & context_answer_1 & {context_id_table_1[19],context_id_table_1[14],context_id_table_1[9],context_id_table_1[4]}) == {context_id_table_1[19],context_id_table_1[14],context_id_table_1[9],context_id_table_1[4]});
    end
end
endmodule
