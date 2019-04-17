
`timescale 1ns / 1ps

module aw_decode
(
    input  wire              reset,
    input  wire              clk,

    input  wire [48:0]       phy_base_0,
    input  wire [48:0]       phy_base_1,

    
    input  wire [127:0]      aw_w,
    input  wire              aw_w_last,
    input  wire              aw_w_valid,
    output wire              aw_w_ready,

    output reg  [79:0]       aw = 80'b 0,
    output reg               aw_valid=1'b 0,
    input  wire              aw_ready,
    
    output reg  [143:0]      w = 80'b 0,
    output reg               w_last = 1'b 0,
    output reg               w_valid=1'b 0,
    input  wire              w_ready
);


localparam SW         = 10;
localparam ONE_HOT    = 10'b 1;
localparam st0        = ONE_HOT << 0;
localparam st1        = ONE_HOT << 1;
localparam st2        = ONE_HOT << 2;
localparam st3        = ONE_HOT << 3;
localparam st4        = ONE_HOT << 4;
localparam st5        = ONE_HOT << 5;
localparam st6        = ONE_HOT << 6;
localparam st7        = ONE_HOT << 7;
localparam st8        = ONE_HOT << 8;
localparam st9        = ONE_HOT << 9;
reg [SW-1:0]   state =st0;
reg [SW-1:0]   next_state =st0;

reg [83:0]     aw_m = 84'b0;
reg [83:0]     next_aw =84'b0;
reg [143:0]    next_w =144'b0;
reg            next_aw_valid =1'b0;
reg            next_w_valid =1'b0;
reg            next_w_last = 1'b0;
reg [127:0]    next_mid =128'b0;

reg [127:0]    mid =128'b0;

always @(posedge clk)
begin
    if (reset)
    begin
        aw_m        <= 84'b 0;
        w           <= 144'b 0;
        aw_valid    <= 1'b 0;
        w_valid     <= 1'b 0;
        w_last      <= 1'b 0;
        mid         <= 128'b 0;
        state       <= st0;
    end
    else
    begin
        w           <= next_w;
        aw_valid    <= next_aw_valid;
        w_valid     <= next_w_valid;
        w_last      <= next_w_last;
        mid         <= next_mid;
        state       <= next_state;
        aw_m        <= next_aw;
        
   end
end

always @(aw_m       or
         phy_base_0[48:44]   or
         phy_base_1[48:44]
         )
begin
    aw[3:0]     <= aw_m[3:0];
    aw[79:48]   <= aw_m[83:52];
    if ((aw_m[7:4] == phy_base_0[47:44]) & phy_base_0[48])
        aw[47:4]          <= aw_m[51:8] | phy_base_0[43:0];
    else if ((aw_m[7:4] == phy_base_1[47:44]) & phy_base_1[48])
        aw[47:4]          <= aw_m[51:8] | phy_base_1[43:0];
    else
        aw[47:4]          <= aw_m[51:8];
end





assign aw_w_ready   = (~reset) & (((state == st0) & ((~aw_valid) | aw_ready)) |  ((state != st0) & ((~w_valid) | w_ready)));


always @(reset            or
         aw_m             or
         w                or
         aw_valid         or
         aw_ready         or
         w_valid          or
         w_ready          or
         w_last           or
         aw_w_last        or
         mid              or
         state            or
         aw_w_valid       or
         aw_w_ready       or
         aw_w
         )
begin
    next_aw          <= aw_m;
    next_w           <= w;
    next_aw_valid    <= aw_valid & (~aw_ready);
    next_w_valid     <= w_valid & (~w_ready);
    next_w_last      <= w_last;
    next_mid         <= mid;
    next_state       <= state;
    if (reset)
    begin
        next_aw         <= 84'b 0;
        next_w          <= 144'b 0;
        next_aw_valid   <= 1'b 0;
        next_w_valid    <= 1'b 0;
        next_w_last     <= 1'b 0;
        next_mid        <= 128'b 0;
        next_state      <= st0;
    end
    else if (aw_w_valid & aw_w_ready)
    begin
        next_mid        <= aw_w;
        next_w_last     <= aw_w_last;
        case (state)
        st0:
        begin
            next_aw         <= aw_w[83:0];
            next_aw_valid   <= 1'b 1;
            next_state      <= st1;
        end
        st1:
        begin
            next_w          <= {aw_w[99:0],mid[127:84]};
            next_w_valid    <= 1'b 1;
            if (aw_w_last)
                next_state      <= st0;
            else
                next_state      <= st2;
        end
        st2:
        begin
            next_w          <= {aw_w[115:0],mid[127:100]};
            next_w_valid    <= 1'b 1;
            if (aw_w_last)
                next_state     <= st0;
            else
                next_state      <= st3;
        end
        st3:
        begin
            next_w[139:0]    <= {aw_w[127:0],mid[127:116]};
            next_w_valid     <= 1'b 0;
            next_state       <= st4;
        end
        st4:
        begin
            next_w[143:140]  <= aw_w[3:0];
            next_w_valid     <= 1'b 1;
            if (aw_w_last)
                next_state       <= st0;
            else
                next_state       <= st5;
        end

        st5:
        begin
            next_w           <= {aw_w[19:0],mid[127:4]};
            next_w_valid     <= 1'b 1;
            if (aw_w_last)
                next_state       <= st0;
            else
                next_state       <= st6;
        end        

        st6:
        begin
            next_w           <= {aw_w[35:0],mid[127:20]};
            next_w_valid     <= 1'b 1;
            if (aw_w_last)
                next_state       <= st0;
            else
                next_state       <= st7;
        end  

        st7:
        begin
            next_w           <= {aw_w[51:0],mid[127:36]};
            next_w_valid     <= 1'b 1;
            if (aw_w_last)
                next_state       <= st0;
            else
                next_state       <= st8;
        end

        st8:
        begin
            next_w           <= {aw_w[67:0],mid[127:52]};
            next_w_valid     <= 1'b 1;
            if (aw_w_last)
                next_state       <= st0;
            else
                next_state       <= st9;
        end
        st9:
        begin
            next_w           <= {aw_w[83:0],mid[127:68]};
            next_w_valid     <= 1'b 1;
            if (aw_w_last)
                next_state       <= st0;
            else
                next_state       <= st1;
        end
        default:
        begin
            next_aw         <= 84'b 0;
            next_w          <= 144'b 0;
            next_aw_valid   <= 1'b 0;
            next_w_valid    <= 1'b 0;
            next_w_last     <= 1'b 0;
            next_mid        <= 128'b 0;
            next_state      <= st0;
        end
        endcase
    end
end
endmodule
