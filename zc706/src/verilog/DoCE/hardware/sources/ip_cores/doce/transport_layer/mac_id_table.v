/* =====================================================================
* DoCE Transport Layer Wrapper
*
* Author: Ran Zhao (zhaoran@ict.ac.cn)
* Date: 03/02/2017
* Version: v0.0.1
*=======================================================================
*/

`timescale 1ns / 1ps

module mac_id_table
(
    input                    reset,
    input                    clk,
    
	input  [3:0]             trans_axis_txd_tuser,
    output reg [47:0]        tx_dst_mac_addr,

    input  [47:0]            rx_dst_mac_addr,
    output reg [3:0]         trans_axis_rxd_tuser_i,

    input  [31:0]            s_axi_lite_awaddr,
    input                    s_axi_lite_awvalid,
    output                   s_axi_lite_awready,
    
    input  [31:0]            s_axi_lite_araddr,
    input                    s_axi_lite_arvalid,
    output                   s_axi_lite_arready,
    
    input  [31:0]            s_axi_lite_wdata,
    input  [3:0]             s_axi_lite_wstrb,
    input                    s_axi_lite_wvalid,
    output                   s_axi_lite_wready,
    
    output reg [31:0]        s_axi_lite_rdata,
    output [1:0]             s_axi_lite_rresp,
    output reg               s_axi_lite_rvalid,
    input                    s_axi_lite_rready,
    
    output [1:0]             s_axi_lite_bresp,
    output reg               s_axi_lite_bvalid,
    input                    s_axi_lite_bready
);


reg [31:0]	mac_0_low		= 32'd0;
reg [31:0]	mac_0_high		= 32'd0;
reg [31:0]	mac_1_low		= 32'd0;
reg [31:0]	mac_1_high		= 32'd0;
reg [31:0]	mac_2_low		= 32'd0;
reg [31:0]	mac_2_high		= 32'd0;
reg [31:0]	mac_3_low		= 32'd0;
reg [31:0]	mac_3_high		= 32'd0;

reg [47:0]	ip_0			= 32'd0;
reg [47:0]	ip_1			= 32'd0;
reg [47:0]	ip_2			= 32'd0;
reg [47:0]	ip_3			= 32'd0;
reg [3:0]	mac_valid		= 4'd0;

reg 		aw_valid 		= 1'b0;
reg 		ar_valid 		= 1'b0;
reg 		w_valid 		= 1'b0;

assign   s_axi_lite_awready    = ~(reset | aw_valid | s_axi_lite_bvalid);
assign   s_axi_lite_arready    = ~(reset | ar_valid | s_axi_lite_rvalid);
assign   s_axi_lite_wready     = ~(reset | w_valid | s_axi_lite_bvalid);
assign   s_axi_lite_bresp      = 2'd0;
assign   s_axi_lite_rresp      = 2'd0;

reg  [9:0]    aw_addr       = 10'd0;
reg  [9:0]    ar_addr       = 10'd0;
reg  [31:0]   w_data        = 32'd0;
reg  [3:0]    w_strb        = 4'd0;

always @(posedge clk)
begin
    if (reset)
    begin
        aw_valid            <= 1'b0;
        ar_valid            <= 1'b0;
        w_valid             <= 1'b0;

        s_axi_lite_rvalid   <= 1'b0;
        s_axi_lite_bvalid   <= 1'b0;
        
        mac_0_low       	<= 32'd0;
        mac_0_high       	<= 32'd0;
        mac_1_low       	<= 32'd1;
        mac_1_high       	<= 32'd1;
        mac_2_low       	<= 32'd2;
        mac_2_high       	<= 32'd2;
        mac_3_low       	<= 32'd3;
        mac_3_high       	<= 32'd3;
		
        ip_0       			<= 32'd0;
        ip_1       			<= 32'd1;
		ip_2       			<= 32'd2;
		ip_3       			<= 32'd3;	

		mac_valid			<= 4'd0;
		
    end
    else
    begin
        if (s_axi_lite_awready & s_axi_lite_awvalid)
        begin
            aw_addr            <= s_axi_lite_awaddr[9:0];
            aw_valid           <= 1'b1;
        end

        if (s_axi_lite_arready & s_axi_lite_arvalid)
        begin
            ar_addr            <= s_axi_lite_araddr[9:0];
            ar_valid           <= 1'b1;
        end

        if (s_axi_lite_wready & s_axi_lite_wvalid)
        begin
            w_data             <= s_axi_lite_wdata;
            w_strb             <= s_axi_lite_wstrb;
            w_valid            <= 1'b1;
        end
      
      
        if (s_axi_lite_bvalid & s_axi_lite_bready)
            s_axi_lite_bvalid  <= 1'b0;


        if (aw_valid & w_valid & (~s_axi_lite_bvalid))
        begin
            aw_valid           <= 1'b0;
            w_valid            <= 1'b0;
            s_axi_lite_bvalid  <= 1'b1;
            
            if (aw_addr == 10'h200)
                mac_0_low    <= (mac_0_low & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 10'h204)
                mac_0_high    <= (mac_0_high & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
            else if (aw_addr == 10'h208)
                mac_1_low    <= (mac_1_low & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
			else if (aw_addr == 10'h20C)
                mac_1_high    <= (mac_1_high & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
			else if (aw_addr == 10'h210)
                mac_2_low    <= (mac_2_low & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
			else if (aw_addr == 10'h214)
                mac_2_high    <= (mac_2_high & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
			else if (aw_addr == 10'h218)
                mac_3_low    <= (mac_3_low & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
			else if (aw_addr == 10'h21C)
                mac_3_high    <= (mac_3_high & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
				
			else if (aw_addr == 10'h220)
                ip_0    <= (ip_0 & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
			else if (aw_addr == 10'h224)
                ip_1    <= (ip_1 & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
			else if (aw_addr == 10'h228)
                ip_2    <= (ip_2 & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});
			else if (aw_addr == 10'h22C)
                ip_3    <= (ip_3 & {{8{~w_strb[3]}},{8{~w_strb[2]}},{8{~w_strb[1]}},{8{~w_strb[0]}}}) | (w_data & {{8{w_strb[3]}},{8{w_strb[2]}},{8{w_strb[1]}},{8{w_strb[0]}}});				

            else if (aw_addr == 10'h230)
                mac_valid        <= (mac_valid & {4{~w_strb[0]}}) | (w_data[3:0] & {4{w_strb[0]}});
		end

        if (s_axi_lite_rvalid & s_axi_lite_rready)
            s_axi_lite_rvalid    <= 1'b0;
         
        if (ar_valid & (~s_axi_lite_rvalid))
        begin
            ar_valid             <= 1'b0;
            s_axi_lite_rvalid    <= 1'b1;
			
            if (ar_addr == 10'h200)
                s_axi_lite_rdata   <= mac_0_low;
            else if (ar_addr == 10'h204)
                s_axi_lite_rdata   <= mac_0_high;
            else if (ar_addr == 10'h208)
                s_axi_lite_rdata   <= mac_1_low;
            else if (ar_addr == 10'h20C)
                s_axi_lite_rdata   <= mac_1_high;
            else if (ar_addr == 10'h210)
                s_axi_lite_rdata   <= mac_2_low;
            else if (ar_addr == 10'h214)
                s_axi_lite_rdata   <= mac_2_high;                    
            else if (ar_addr == 10'h218)
                s_axi_lite_rdata   <= mac_3_low;
            else if (ar_addr == 10'h21C)
                s_axi_lite_rdata   <= mac_3_high;
				
            else if (ar_addr == 10'h220)
                s_axi_lite_rdata   <= ip_0;
            else if (ar_addr == 10'h224)
                s_axi_lite_rdata   <= ip_1;  
            else if (ar_addr == 10'h228)
                s_axi_lite_rdata   <= ip_2;
            else if (ar_addr == 10'h22C)
                s_axi_lite_rdata   <= ip_3; 
				
            else if (ar_addr == 10'h230)
                s_axi_lite_rdata   <= {{28{1'b0}}, mac_valid}; 
				
            else
               s_axi_lite_rdata     <= 32'b0;        
        end
        
    end
end

always @(posedge clk)
begin
    if (reset)
    begin
        tx_dst_mac_addr <= 48'd0;
    end
    else
    begin
		case(trans_axis_txd_tuser)
		4'd0:	tx_dst_mac_addr <= mac_valid[0] ? ({mac_0_high[15:0], mac_0_low}) : 48'hffffffff;
		4'd1:	tx_dst_mac_addr <= mac_valid[1] ? ({mac_1_high[15:0], mac_1_low}) : 48'hffffffff;
		4'd2:	tx_dst_mac_addr <= mac_valid[2] ? ({mac_2_high[15:0], mac_2_low}) : 48'hffffffff;
		4'd3:	tx_dst_mac_addr <= mac_valid[3] ? ({mac_3_high[15:0], mac_3_low}) : 48'hffffffff;
		default: tx_dst_mac_addr <= 48'd0;
		endcase
    end
end 

wire [3:0]             trans_axis_rxd_tuser;

assign trans_axis_rxd_tuser[0] = ~|({mac_0_high[15:0], mac_0_low} ^ rx_dst_mac_addr);
assign trans_axis_rxd_tuser[1] = ~|({mac_1_high[15:0], mac_1_low} ^ rx_dst_mac_addr);
assign trans_axis_rxd_tuser[2] = ~|({mac_2_high[15:0], mac_2_low} ^ rx_dst_mac_addr);
assign trans_axis_rxd_tuser[3] = ~|({mac_3_high[15:0], mac_3_low} ^ rx_dst_mac_addr);

always @(posedge clk)
begin
    if (reset)
    begin
        trans_axis_rxd_tuser_i <= 4'd0;
    end
    else
    begin
		case(trans_axis_rxd_tuser)
		4'd1:	trans_axis_rxd_tuser_i <= 4'd0;
		4'd2:	trans_axis_rxd_tuser_i <= 4'd1;
		4'd4:	trans_axis_rxd_tuser_i <= 4'd2;
		4'd8:	trans_axis_rxd_tuser_i <= 4'd3;
		default: trans_axis_rxd_tuser_i <= 4'd4;
		endcase
    end
end 

endmodule
