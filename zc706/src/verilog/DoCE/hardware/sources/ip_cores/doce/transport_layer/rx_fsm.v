/* =====================================================================
* DoCE Transport Layer Wrapper
*
* Author: Ran Zhao (zhaoran@ict.ac.cn)
* Date: 03/07/2017
* Version: v0.0.1
*=======================================================================
*/

`timescale 1ps / 1ps

module rx_fsm (
    output reg [127:0] 	axi_str_tdata_to_trans,
    output reg [15:0]  	axi_str_tkeep_to_trans,
    output reg        	axi_str_tvalid_to_trans,
    output reg        	axi_str_tlast_to_trans,
    output reg [3:0]   	axi_str_tuser_to_trans,
	input		   		axi_str_tready_from_trans,   

	output         		axi_str_tready_to_router,
    input [127:0]  		axi_str_tdata_from_router,   
    input [15:0]   		axi_str_tkeep_from_router,   
    input          		axi_str_tvalid_from_router,
    input          		axi_str_tlast_from_router,
			
	input [3:0]    		trans_axis_rxd_tuser,
	output [47:0]  		rx_dst_mac_addr,
			
    input          		user_clk,
    input          		reset
);



  //Reg declaration
  reg  [3:0]		trans_axis_rxd_tuser_i;
  reg				pkt_firstbeat;

  localparam
     //states for Read FSM
     READ_MAC_HEADER    = 2'b01,
     BEGIN_READ   		= 2'b10;

  reg  [1:0]   state_rd = READ_MAC_HEADER;

  assign rx_dst_mac_addr = axi_str_tdata_from_router[95:48];
  assign axi_str_tready_to_router = axi_str_tready_from_trans;
  
  always @(posedge user_clk)
  begin
	if(reset)
	begin
		state_rd  <= READ_MAC_HEADER;
		trans_axis_rxd_tuser_i <= 4'd0;
		pkt_firstbeat <= 1'b1;
	end
	else
	begin
		case(state_rd)
		  READ_MAC_HEADER : begin
					 if(axi_str_tvalid_from_router & axi_str_tready_to_router)
					 begin
						  state_rd <=  BEGIN_READ;
					 end
					 else
					 begin
						  state_rd <=  READ_MAC_HEADER;
					 end
					end 
		  BEGIN_READ : begin
		                 if(axi_str_tvalid_from_router & axi_str_tready_to_router)
						  pkt_firstbeat <= axi_str_tlast_from_router;
						 if(pkt_firstbeat)
							trans_axis_rxd_tuser_i <= trans_axis_rxd_tuser;
						 else
							trans_axis_rxd_tuser_i <= trans_axis_rxd_tuser_i;
						 if(axi_str_tlast_from_router & axi_str_tvalid_from_router & axi_str_tready_to_router)
						 begin
							  state_rd                <= READ_MAC_HEADER;
						 end 
						 else
						 begin
							  state_rd                <= BEGIN_READ;
						 end 
					 end
		  default    :   state_rd                <= READ_MAC_HEADER;
	 endcase
	end
  end     
 
  always @ *
  begin
       if(state_rd==READ_MAC_HEADER)
       begin 
			axi_str_tdata_to_trans	<= 128'd0;
			axi_str_tuser_to_trans	<= 4'd0;
			axi_str_tvalid_to_trans <= 1'b0;
			axi_str_tkeep_to_trans 	<= 16'd0;
			axi_str_tlast_to_trans  <= 1'b0;
       end  
       else if(state_rd==BEGIN_READ)
       begin
			axi_str_tdata_to_trans	<= axi_str_tuser_to_trans[2] ? 128'd0 : axi_str_tdata_from_router;
			axi_str_tuser_to_trans	<= pkt_firstbeat ? trans_axis_rxd_tuser : trans_axis_rxd_tuser_i;
			axi_str_tvalid_to_trans <= axi_str_tuser_to_trans[2] ? 1'd0 :axi_str_tvalid_from_router;
			axi_str_tkeep_to_trans 	<= axi_str_tuser_to_trans[2] ? 16'd0 :axi_str_tkeep_from_router;
			axi_str_tlast_to_trans  <= axi_str_tuser_to_trans[2] ? 1'd0 :axi_str_tlast_from_router;
       end 
       else
       begin
			axi_str_tdata_to_trans	<= 128'd0;
			axi_str_tuser_to_trans	<= 4'd0;
			axi_str_tvalid_to_trans <= 1'b0;
			axi_str_tkeep_to_trans 	<= 16'd0;
			axi_str_tlast_to_trans  <= 1'b0;
       end
  end

endmodule
