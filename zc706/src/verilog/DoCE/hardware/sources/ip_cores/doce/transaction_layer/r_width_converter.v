`timescale 1ns / 1ps
module r_width_converter
(
    input  wire                         reset,
    input  wire                         clk,
    
    input  wire [127:0]                 rdata_in,
    input  wire                         rlast_in,
    input  wire [23:0]                  config_in,
    input  wire                         valid_in,
    output reg                          ready_out =1'b 0,
    
 
    output reg                          rlast_out = 1'b 0,
    output reg  [127:0]                 rdata_out = 128'b 0,
    output reg                          valid_out = 1'b 0,
    input  wire                         ready_in,
    
    output reg  [8:0]                   num = 9'b0,
    output reg                          num_valid = 1'b0,
    input  wire                         num_ready
);

localparam SW         = 3;
localparam ONE_HOT    = 3'b 1;
localparam st0        = ONE_HOT << 0;
localparam st1        = ONE_HOT << 1;
localparam st2        = ONE_HOT << 2;
reg [SW-1:0]        state           = st0;
reg [SW-1:0]        next_state      = st0;


reg [23:0]          mid_rdata       = 24'b 0; 

reg [127:0]         next_rdata_out  = 128'b 0;
reg                 next_rlast_out  = 1'b 0;
reg                 next_valid_out  = 1'b 0;
reg [23:0]          next_mid_rdata  = 24'b 0;

reg  [8:0]          next_num = 9'b0;
reg                 next_num_valid = 1'b0;


always @(posedge clk)
begin
    if (reset)
    begin
        rdata_out   <= 128'b 0;
        rlast_out   <= 1'b 0;
        valid_out   <= 1'b 0;
        mid_rdata   <= 24'b 0;
        num         <= 9'b 0;
        num_valid   <= 1'b 0;
        state       <= st0;
    end
   
    else
    begin
        rdata_out   <= next_rdata_out;
        rlast_out   <= next_rlast_out;
        valid_out   <= next_valid_out;
        mid_rdata   <= next_mid_rdata;
        num         <= next_num;
        num_valid   <= next_num_valid;
        state       <= next_state;
    end
end



always @(reset              or
         rdata_out          or
         rlast_out          or
         valid_out          or
         mid_rdata          or
         state              or
         rdata_in           or
         rlast_in           or
         ready_in           or
         valid_in           or
         ready_out          or
         config_in          or
         num                or
         num_valid          or
         num_ready
         )
begin
    next_rdata_out   <= rdata_out;
    next_rlast_out   <= rlast_out;
    next_valid_out   <= valid_out;
    next_mid_rdata   <= mid_rdata;
    next_state       <= state;
    next_num         <= num;
    next_num_valid   <= num_valid & (~num_ready);
    if (reset)
    begin
        ready_out        <= 1'b 0;
        next_rdata_out   <= 128'b 0;
        next_rlast_out   <= 1'b 0;
        next_valid_out   <= 1'b 0;
        next_mid_rdata   <= 24'b 0;
        next_state       <= st0;
        next_num         <= 9'b 0;
        next_num_valid   <= 1'b 0;
    end
   
    else
    begin
        case (state)
        st0:
        begin
            ready_out       <= num_ready & ((~valid_out) | ready_in);
            next_valid_out  <= (valid_out & (~ready_in)) | (valid_in & ready_out);
            if (valid_in & ready_out)
            begin
                next_rdata_out  <= {rdata_in[103:0],config_in};
                next_rlast_out  <= 1'b 0;
                next_mid_rdata  <= rdata_in[127:104];
                next_num        <= 9'b 1;
                if (rlast_in)
                    next_state    <= st2;
                else
                    next_state   <= st1;
            end
        end
   
        st1:
        begin
            ready_out       <= (~valid_out) | ready_in;
            next_valid_out  <= (valid_out & (~ready_in)) | (valid_in & ready_out);
            if (valid_in & ready_out)
            begin
                next_rdata_out   <= {rdata_in[103:0],mid_rdata};
                next_rlast_out   <= 1'b 0;
                next_mid_rdata   <= rdata_in[127:104];
                next_num         <= num + 1;
                if (rlast_in)
                    next_state      <= st2;
                else
                    next_state      <= st1;
            end
        end
        st2:
        begin
            ready_out        <= 1'b 0;
            next_valid_out   <= 1'b 1;
            if (ready_in)
            begin
                next_rdata_out   <= {104'b0,mid_rdata};
                next_rlast_out   <= 1'b 1;
                next_num_valid   <= 1'b 1;
                next_state       <= st0;
            end
        end
        default:
        begin
            ready_out        <= 1'b 0;
            next_rdata_out   <= 128'b 0;
            next_rlast_out   <= 1'b 0;
            next_valid_out   <= 1'b 0;
            next_mid_rdata   <= 24'b 0;
            next_num_valid   <= 1'b 0;
            next_state       <= st0;
        end
        endcase
    end
end
endmodule
