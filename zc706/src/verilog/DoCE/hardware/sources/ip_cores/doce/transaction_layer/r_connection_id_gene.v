`timescale 1ns / 1ps

module r_connection_id_gene
(
    input  wire         reset,
    input  wire         clk,
   
    input  wire [127:0] data,
    input  wire         last,
    input  wire         valid,
    output reg          ready = 1'b0,
    
    input  wire [8:0]   num,
    input  wire         num_valid,
    output reg          num_ready = 1'b 0,
    
   
    output reg [127:0]  r_channel=128'b0,
    output reg [3:0]    r_channel_connection_id=4'b0,
    output reg [12:0]   r_channel_byte_num = 13'b0,
    output reg [15:0]   r_channel_keep=16'b0,
    output reg          r_channel_last=1'b0,
    output reg          r_channel_valid=1'b0,
    input  wire         r_channel_ready

);



localparam SW         = 2;
localparam ONE_HOT    = 2'b 1;
localparam st0        = ONE_HOT << 0;
localparam st1        = ONE_HOT << 1;
reg [SW-1:0]        state           = st0;
reg [SW-1:0]        next_state      = st0;

reg [127:0]  next_r_channel=128'b0;
reg [3:0]    next_r_channel_connection_id=4'b0;
reg [12:0]   next_r_channel_byte_num=13'b0;
reg [15:0]   next_r_channel_keep=16'b0;
reg          next_r_channel_last=1'b0;
reg          next_r_channel_valid=1'b0;

always @(posedge clk)
begin
    if (reset)
    begin
        r_channel                <= 128'b 0;
        r_channel_connection_id  <= 4'b 0;
        r_channel_keep           <= 16'h 0;
        r_channel_last           <= 1'b 0;
        r_channel_valid          <= 1'b 0;
        r_channel_byte_num       <= 13'b 0;
        state                    <= st0;
    end
    else
    begin
        r_channel                <= next_r_channel;
        r_channel_connection_id  <= next_r_channel_connection_id;
        r_channel_keep           <= next_r_channel_keep;
        r_channel_last           <= next_r_channel_last;
        r_channel_valid          <= next_r_channel_valid;
        r_channel_byte_num       <= next_r_channel_byte_num;
        state                    <= next_state;
    end
end


always @(reset                     or 
         r_channel                 or
         r_channel_connection_id   or
         r_channel_keep            or
         r_channel_last            or
         r_channel_valid           or
         state                     or
         r_channel_ready           or
         data                      or
         last                      or
         valid                     or
         ready                     or
         r_channel_byte_num        or
         num                       or
         num_valid                 or
         num_ready
         )
begin
    next_r_channel                <= r_channel;
    next_r_channel_connection_id  <= r_channel_connection_id;
    next_r_channel_keep           <= r_channel_keep;
    next_r_channel_last           <= r_channel_last;
    next_r_channel_valid          <= r_channel_valid;
    next_r_channel_byte_num       <= r_channel_byte_num;
    next_state                    <= state;
    if (reset)
    begin
        ready                         <= 1'b 0;
        num_ready                     <= 1'b 0;
        next_r_channel                <= 128'b 0;
        next_r_channel_connection_id  <= 4'b 0;
        next_r_channel_keep           <= 16'h 0;
        next_r_channel_last           <= 1'b 0;
        next_r_channel_valid          <= 1'b 0;
        next_r_channel_byte_num       <= 13'b 0;
        next_state                    <= st0;
    end
    else
    begin
        case (state)
        st0:
        begin
            ready                    <= num_valid & ((~r_channel_valid) | r_channel_ready);
            num_ready                <= valid & ready;
            next_r_channel_valid     <= (r_channel_valid & (~r_channel_ready)) | (valid & ready);
            if (valid & ready)
            begin
                next_r_channel                <= {data[127:24],data[19:0],4'b0011};
                next_r_channel_connection_id  <= data[23:20];
                next_r_channel_byte_num       <= {num,4'b 11};
                next_r_channel_keep           <= 16'h ffff;
                next_r_channel_last           <= last;
                next_state                    <= st1;
            end
        end
        st1:
        begin
            ready                    <= (~r_channel_valid) | r_channel_ready;
            num_ready                <= 1'b 0;
            next_r_channel_valid     <= (r_channel_valid & (~r_channel_ready)) | (valid & ready);
            if (valid & ready)
            begin
                next_r_channel             <= data;
                next_r_channel_last        <= last;
                if (last)
                begin
                    next_r_channel_keep        <= 16'h 0007;
                    next_state                 <= st0;
                end
                else
                begin
                    next_r_channel_keep        <= 16'h ffff;
                    next_state                 <= st1;
                end

            end
        end
        default:
        begin
            ready                         <= 1'b 0;
            num_ready                     <= 1'b 0;
            next_r_channel                <= 128'b 0;
            next_r_channel_connection_id  <= 4'b 0;
            next_r_channel_byte_num       <= 13'b 0;
            next_r_channel_keep           <= 16'h 0;
            next_r_channel_last           <= 1'b 0;
            next_r_channel_valid          <= 1'b 0;
            next_state                    <= st0;
        end
        endcase
    end
end



endmodule
