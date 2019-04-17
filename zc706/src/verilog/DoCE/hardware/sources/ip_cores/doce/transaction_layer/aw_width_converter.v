`timescale 1ns / 1ps

module aw_width_converter
(
    input  wire                          reset,
    input  wire                          clk,
    
    input  wire [83:0]                   aw,   //include context id and channel num
    input  wire [3:0]                    aw_connection_id,
    input  wire                          aw_valid,
    output reg                           aw_ready=1'b 0,

    input  wire [143:0]                  w,   //include w_strb and w_data
    input  wire                          w_last,
    input  wire                          w_valid,
    output reg                           w_ready=1'b 0,
    
    output reg  [127:0]                  dout=128'b 0,
	output reg  [15:0]                   dout_keep=16'b 0,
    output reg                           dout_last=1'b 0,
    output reg                           dout_valid=1'b 0,
    output reg  [3:0]                    dout_connection_id=4'b0,
    output reg  [12:0]                   dout_byte_num = 13'b0,
    input  wire                          dout_ready
);

localparam ONE_HOT = 11'b 1;
localparam st0     = ONE_HOT << 0;
localparam st1     = ONE_HOT << 1;
localparam st2     = ONE_HOT << 2;
localparam st3     = ONE_HOT << 3;
localparam st4     = ONE_HOT << 4;
localparam st5     = ONE_HOT << 5;
localparam st6     = ONE_HOT << 6;
localparam st7     = ONE_HOT << 7;
localparam st8     = ONE_HOT << 8;
localparam st9     = ONE_HOT << 9;
localparam st10     = ONE_HOT << 10;
reg  [10:0]     state = st0;
reg  [10:0]     next_state = st0;
reg  [127:0]    next_dout = 128'b 0;
reg             next_dout_last = 1'b 0;
reg  [2:0]      next_flg = 3'b 0;  //used to record which state jump to st10
reg  [143:0]    next_mid = 144'b 0;
reg  [15:0]     next_dout_keep = 16'h 0;
reg             next_dout_valid = 1'b 0;
reg  [3:0]      next_dout_connection_id= 4'b0;

reg  [2:0]      flg = 3'b 0; //used to record which state jump to st10
reg  [143:0]    mid = 144'b 0;

wire [8:0]     aw_len  = aw[77:70]+1;
reg [12:0]     next_dout_byte_num = 13'b0;

always @ (posedge clk)
begin
	if (reset)
	begin
		dout                  <= 128'b 0;
		dout_last             <= 1'b 0;
		dout_valid            <= 1'b 0;
		dout_keep             <= 16'b 0;
		flg                   <= 3'b 0;
		mid                   <= 144'b 0;
		state                 <= st0;
		dout_connection_id    <= 4'b0;
		dout_byte_num         <= 13'b0;
	end
	else
	begin
		dout                   <= next_dout;
		dout_last              <= next_dout_last;
		dout_valid             <= next_dout_valid;
		dout_keep              <= next_dout_keep;
		flg                    <= next_flg;
		mid                    <= next_mid;
		state                  <= next_state;
		dout_connection_id     <= next_dout_connection_id;
		dout_byte_num          <= next_dout_byte_num;
	end
end



always @(reset             or
         dout              or
	     dout_last         or
	     flg               or
	     mid               or
	     dout_valid        or
	     dout_keep         or
	     state             or
	     w_valid           or
	     aw_valid          or
	     dout_ready        or
	     aw_ready          or
	     w_ready           or
	     w_last            or
	     w                 or
	     aw                or
	     aw_connection_id  or
	     dout_byte_num     or
	     dout_connection_id  or
	     aw_len)
begin
	next_dout                  <= dout;
    next_dout_last             <= dout_last;
	next_flg                   <= flg;
	next_mid                   <= mid;
	next_dout_valid            <= dout_valid;
	next_dout_keep             <= dout_keep;
	next_dout_connection_id    <= dout_connection_id;
	next_dout_byte_num         <= dout_byte_num;
	next_state                 <= state;
    if (reset)
    begin
     	next_dout                <= 128'b 0;
        next_dout_last           <= 1'b 0;
		next_flg                 <= 3'b 0;
		next_mid                 <= 144'b 0;
		next_dout_valid          <= 1'b 0;
		next_dout_keep           <= 16'h 0;
		next_dout_connection_id  <= 4'b 0;
		next_dout_byte_num       <= 13'b 0;
		next_state               <= st0;
		aw_ready                 <= 1'b 0;
		w_ready                  <= 1'b 0;
    end
    else
    begin
        case (state)
        st0:
        begin
            aw_ready          <= w_valid & ((dout_valid & dout_ready) | (~dout_valid));
            w_ready           <= aw_valid & w_valid & ((dout_valid & dout_ready) | (~dout_valid));
			next_flg          <= 3'b 0;
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (aw_valid & aw_ready);
            if (aw_valid & aw_ready)
            begin
                next_dout                  <= {w[43:0],aw};
				next_dout_last             <= 1'b 0;
                next_mid                   <= w;
				next_dout_keep             <= 16'h ffff;
				next_dout_connection_id    <= aw_connection_id;
				next_dout_byte_num         <= {aw_len,4'b1011} + {aw_len,1'b0};
		    	if (w_last)
			    	next_state        <= st10;
			    else
				    next_state        <= st1;
            end
        end
        st1:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= dout_ready | (~dout_valid);
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (w_valid & w_ready);
			next_flg          <= 3'b 1;
            if (w_valid & w_ready)
            begin
                next_dout         <= {w[27:0],mid[143:44]};
                next_dout_last    <= 1'b 0;
				next_dout_keep    <= 16'h ffff;
				next_mid          <= w;
				if (w_last)
					next_state         <=st10;
				else
					next_state         <=st2;
            end
        end
        st2:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= dout_ready | (~dout_valid);
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (w_valid & w_ready);
            if (w_valid & w_ready)
            begin
                next_dout          <= {w[11:0],mid[143:28]};
                next_dout_last     <= 1'b 0;
				next_dout_keep     <= 16'h ffff;
				next_mid           <= w;
				next_state         <=st3;
				if (w_last)
					next_flg          <= 3'b 10;
				else
					next_flg          <= 3'b 0;
            end
        end
        st3:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= 1'b 0;
            next_dout_valid   <= dout_valid | dout_ready;  //(dout_valid & (~dout_ready)) | dout_ready
            if (dout_ready)
            begin
                next_dout         <= mid[139:12];
                next_dout_keep    <= 16'h ffff;
                next_dout_last    <= 1'b 0;
                if (flg==3'b10)
                    next_state        <= st10;
                else
                    next_state        <= st4;
            end
        end
        st4:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= dout_ready | (~dout_valid);
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (w_valid & w_ready);
			next_flg          <= 3'b 11;
            if (w_valid & w_ready)
            begin
                next_dout          <= {w[123:0],mid[143:140]};
                next_dout_last     <= 1'b 0;
				next_dout_keep     <= 16'h ffff;
				next_mid           <= w;
				if (w_last)
					next_state         <= st10;
			    else
					next_state         <= st5;
            end
        end
        st5:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= dout_ready | (~dout_valid);
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (w_valid & w_ready);
			next_flg          <= 3'b 100;
            if (w_valid & w_ready)
            begin
                next_dout         <= {w[107:0],mid[143:124]};
				next_dout_last    <= 1'b 0;
				next_dout_keep    <= 16'h ffff;
                next_mid          <= w;
				if (w_last)
					next_state         <=st10;
				else
					next_state         <=st6;
            end
        end
        st6:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= dout_ready | (~dout_valid);
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (w_valid & w_ready);
			next_flg          <= 3'b 101;
            if (w_valid & w_ready)
            begin
                next_dout         <= {w[91:0],mid[143:108]};
				next_dout_last    <= 1'b 0;
				next_dout_keep    <= 16'h ffff;
                next_mid          <= w;
				if (w_last)
					next_state         <=st10;
				else
					next_state         <=st7;
            end
        end
        st7:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= dout_ready | (~dout_valid);
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (w_valid & w_ready);
			next_flg          <= 3'b 110;
            if (w_valid & w_ready)
            begin
                next_dout         <= {w[75:0],mid[143:92]};
				next_dout_last    <= 1'b 0;
				next_dout_keep    <= 16'h ffff;
                next_mid          <= w;
				if (w_last)
					next_state         <=st10;
				else
					next_state         <=st8;
            end
        end
        st8:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= dout_ready | (~dout_valid);
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (w_valid & w_ready);
			next_flg          <= 3'b 111;
            if (w_valid & w_ready)
            begin
                next_dout         <= {w[59:0],mid[143:76]};
				next_dout_last    <= 1'b 0;
				next_dout_keep    <= 16'h ffff;
                next_mid          <= w;
				if (w_last)
					next_state         <=st10;
				else
					next_state         <=st9;
            end
        end
        st9:
        begin
            aw_ready          <= 1'b 0;
            w_ready           <= dout_ready | (~dout_valid);
			next_dout_valid   <= (dout_valid & (~dout_ready)) | (w_valid & w_ready);
			next_flg          <= 3'b 0;
            if (w_valid & w_ready)
            begin
                next_dout         <= {w[43:0],mid[143:60]};
				next_dout_last    <= 1'b 0;
				next_dout_keep    <= 16'h ffff;
                next_mid          <= w;
				if (w_last)
					next_state         <=st10;
				else
					next_state         <=st1;
            end
        end
        st10:
		begin
			w_ready          <= 1'b 0;
			aw_ready         <= 1'b 0;
			next_dout_valid  <= 1'b 1;
			if (dout_ready)
			begin
				next_state        <= st0;
				next_dout_last    <= 1'b 1;
				if (flg==3'b0)
				begin
				    next_dout       <= {28'b0,w[143:44]};
					next_dout_keep  <= 16'h1fff;
			    end
				else if (flg == 3'b1 )
				begin
					next_dout       <= {12'b0,w[143:28]};
					next_dout_keep  <= 16'h7fff;
				end
				else if (flg == 3'b10 )
				begin
					next_dout       <= {124'b0,w[143:140]};
					next_dout_keep  <= 16'h1;
				end
				else if (flg == 3'b11 )
				begin
					next_dout       <= {108'b0,w[143:124]};
					next_dout_keep  <= 16'h0007;
				end
				else if (flg == 3'b100 )
				begin
					next_dout       <= {92'b0,w[143:108]};
					next_dout_keep  <= 16'h001f;
				end
				else if (flg == 3'b101 )
				begin
					next_dout       <= {76'b0,w[143:92]};
					next_dout_keep  <= 16'h007f;
				end
				else if (flg == 3'b110 )
				begin
					next_dout       <= {60'b0,w[143:76]};
					next_dout_keep  <= 16'h01ff;
				end
				else if (flg == 3'b111 )
				begin
					next_dout       <= {44'b0,w[143:60]};
					next_dout_keep  <= 16'h07ff;
				end
			end

		end
		default:
		begin
			next_dout            <= 128'b 0;
	    	next_dout_last       <= 1'b 0;
			next_flg             <= 3'b 0;
			next_mid             <= 144'b 0;
			next_dout_valid      <= 1'b 0;
			next_dout_keep       <= 16'h 0;
			next_state           <= st0;
			aw_ready             <= 1'b 0;
			w_ready              <= 1'b 0;
		end
   
        endcase
    end
end

endmodule
