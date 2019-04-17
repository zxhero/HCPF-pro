`timescale 1ns / 1ps

module rx_switch
(
    input  wire           reset,
    input  wire           clk,
   
    input  wire [127:0]   rx_data,
    input  wire [3:0]     rx_connection_id,
    input  wire           rx_last,
    input  wire           rx_valid,
    output wire           rx_ready,
   
    output reg  [127:0]   dout = 129'b 0,
    output reg            dout_last = 1'b 0,
    output reg            aw_valid = 1'b 0,
    output reg            ar_valid = 1'b 0,
    output reg            r_valid = 1'b 0,
    output reg            b_valid = 1'b 0,
    output reg            barrier_valid = 1'b 0,
   
    input  wire           aw_ready,
    input  wire           ar_ready,
    input  wire           r_ready,
    input  wire           b_ready,
    input  wire           barrier_ready
   
);

localparam SW         = 3;
localparam ONE_HOT    = 3'b 1;
localparam st0        = ONE_HOT << 0;
localparam st1        = ONE_HOT << 1;
localparam st2        = ONE_HOT << 2;
reg  [SW-1:0]    state =st0;
reg  [SW-1:0]    next_state =st0;

reg              next_aw_valid = 1'b 0;
reg              next_ar_valid = 1'b 0;
reg              next_r_valid = 1'b 0;
reg              next_b_valid = 1'b 0;
reg              next_barrier_valid = 1'b 0;
reg [127:0]      next_dout = 128'b 0;
reg              next_dout_last = 1'b 0;



assign    rx_ready = ~(reset | (aw_valid & (~aw_ready)) | (ar_valid & (~ar_ready)) | (r_valid & (~r_ready)) | (b_valid & (~b_ready)) | (barrier_valid & (~barrier_ready)));



always @(posedge clk)
begin
    if (reset)
    begin     
        aw_valid            <= 1'b 0;
        ar_valid            <= 1'b 0;
        r_valid             <= 1'b 0;
        b_valid             <= 1'b 0;
        barrier_valid       <= 1'b 0;
        dout                <= 128'b 0;
        dout_last           <= 1'b 0;
        state               <= st0;
    end
    else
    begin
        aw_valid            <= next_aw_valid;
        ar_valid            <= next_ar_valid;
        r_valid             <= next_r_valid;
        b_valid             <= next_b_valid;
        barrier_valid       <= next_barrier_valid;
        dout                <= next_dout;
        dout_last           <= next_dout_last;
        state               <= next_state;

    end
end


always @(reset               or
         aw_valid            or
         ar_valid            or
         r_valid             or
         b_valid             or
         barrier_valid       or
         dout                or
         dout_last           or
         state               or
         rx_valid            or
         rx_ready            or
         rx_data             or
         rx_last             or
         aw_ready            or
         rx_connection_id    or
         ar_ready            or
         r_ready             or
         b_ready             or
         barrier_ready  

        )
begin

    next_aw_valid            <= aw_valid & (~aw_ready);
    next_ar_valid            <= ar_valid & (~ar_ready);
    next_r_valid             <= r_valid & (~r_ready);
    next_b_valid             <= b_valid & (~b_ready);
    next_barrier_valid       <= barrier_valid & (~barrier_ready);
    next_dout                <= dout;
    next_dout_last           <= dout_last;
    next_state               <= state;
    if (reset)
    begin
        next_aw_valid            <= 1'b 0;
        next_ar_valid            <= 1'b 0;
        next_r_valid             <= 1'b 0;
        next_b_valid             <= 1'b 0;
        next_barrier_valid       <= 1'b 0;
        next_dout                <= 128'b 0;
        next_dout_last           <= 1'b 0;
        next_state               <= st0;
    end
    else if (rx_valid & rx_ready)
    begin
        next_dout                  <= rx_data;
        next_dout_last             <= rx_last;  
        case(state)
        st0:
        begin
            if (rx_data[3:0]==3'b001)  //aw
            begin
                next_dout         <= {rx_data[127:4],rx_connection_id};
                next_aw_valid     <= 1'b 1;
                next_state        <= st1;
            end
            else if (rx_data[3:0]==3'b010)  //ar
            begin
                next_dout        <= {rx_data[127:4],rx_connection_id};
                next_ar_valid    <= 1'b 1;
                next_state       <= st0;
            end
            else if (rx_data[3:0]==3'b011)   //r
            begin
                next_dout        <= {rx_data[127:4],rx_connection_id};
                next_r_valid     <= 1'b 1;
                next_state       <= st2;
            end
            else if (rx_data[3:0]==3'b100)   //b
            begin
                next_dout        <= {rx_data[127:4],rx_connection_id};
                next_b_valid     <= 1'b 1;
                next_state       <= st0;
            end
            else if ((rx_data[3:0]==3'b101) | (rx_data[3:0]==3'b110))
            begin
                next_dout            <= {rx_data[127:9],rx_data[0],rx_data[7:4],rx_connection_id};
                next_barrier_valid   <= 1'b 1;
                next_state           <= st0;
            end
        end

        st1:
        begin
            next_aw_valid     <= 1'b 1;
            if (rx_last)
                next_state    <= st0;
            else
                next_state    <= st1;
        end
        st2:
        begin
            next_r_valid       <= 1'b 1;
            if (rx_last)
                next_state     <= st0;
            else
                next_state     <= st2;
        end
        default:
        begin
            next_aw_valid       <= 1'b 0;
            next_ar_valid       <= 1'b 0;
            next_r_valid        <= 1'b 0;
            next_b_valid        <= 1'b 0;
            next_barrier_valid  <= 1'b 0;
            next_state          <= st0;
        end
        endcase
    end
end

endmodule
