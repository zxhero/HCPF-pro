
`timescale 1ns / 1ps

module r_decode
(
    input  wire              reset,
    input  wire              clk,
   
    input  wire [127:0]      r_decode,
    input  wire              r_decode_last,
    input  wire              r_decode_valid,
    output wire              r_decode_ready,

    output reg  [148:0]      r=149'b 0,
    output reg               r_valid=1'b 0,
    input  wire              r_ready
);

assign    r_decode_ready = (~reset) & ((~r_valid) | r_ready); 



localparam SW         = 2;
localparam ONE_HOT    = 2'b 1;
localparam st0        = ONE_HOT << 0;
localparam st1        = ONE_HOT << 1;
reg  [SW-1:0]    state =st0;
reg  [SW-1:0]    next_state =st0;

reg [103:0]      r_mid = 104'b 0;
reg [148:0]      next_r = 149'b0;
reg [103:0]      next_r_mid = 104'b 0;
reg              next_r_valid = 1'b 0;


always @(posedge clk)
begin

   if (reset)
   begin
       r              <= 149'b 0;
       r_mid          <= 104'b 0;
       r_valid        <= 1'b 0;
       state          <= st0;
   end
   else
   begin
       r              <= next_r;
       r_mid          <= next_r_mid;
       r_valid        <= next_r_valid;
       state          <= next_state;
   end
end


always @(reset            or
         r                or
         r_mid            or
         r_valid          or
         r_ready          or
         state            or
         r_decode_valid   or
         r_decode_ready   or
         r_decode         or
         r_decode_last
         )
begin
    next_r              <= r;
    next_r_mid          <= r_mid;
    next_r_valid        <= r_valid & (~r_ready);
    next_state          <= state;
    if (reset)
    begin
        next_r              <= 149'b 0;
        next_r_mid          <= 104'b 0;
        next_r_valid        <= 1'b 0;
        next_state          <= st0;
    end
    else if (r_decode_valid & r_decode_ready)
    begin
        next_r_mid         <= r_decode[127:24];   //104bit
        case (state)
        st0:
        begin
            next_r[147:128]    <= {r_decode[23:4]};
            next_r_valid       <= 1'b 0;
            next_state         <= st1;
        end
        st1:
        begin
            next_r[148]        <= r_decode_last;
            next_r[127:0]      <= {r_decode[23:0],r_mid};
            next_r_valid       <= 1'b 1;
            if (r_decode_last)
                next_state       <= st0;
            else
                next_state       <= st1;
        end
        default:
        begin
            next_r              <= 149'b 0;
            next_r_mid          <= 104'b 0;
            next_r_valid        <= 1'b 0;
            next_state          <= st0;
        end
        endcase
    end
end

endmodule
