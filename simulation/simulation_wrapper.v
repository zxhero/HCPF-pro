`timescale 10ns / 1ns

`define INSTNUM 18
module tb();
	reg		CPU_clk;
	reg		CPU_reset;
	reg	[63:0]	instruction	[`INSTNUM:0];
	reg	[4:0]	ins_index;	
	wire last_inst;
	reg		finish;
	initial begin
		CPU_clk = 1'b0;
		CPU_reset = 1'b1;
		//read 
		instruction[0] = {2'b00,10'd16,12'd0,10'd0,28'd0,2'b1};   
		instruction[1] = {2'b00,10'd16,12'd0,10'd4,28'd16,2'b1};
		instruction[2] = {2'b00,10'd16,12'd0,10'd8,28'd0,2'd2};
		instruction[3] = {2'b00,10'd16,12'd0,10'd12,28'd16,2'd2};
		instruction[4] = {2'b00,10'd16,12'd0,10'd16,28'd0,2'd3};
		instruction[5] = {2'b00,10'd16,12'd0,10'd20,28'd16,2'd3};
		//write read buffer
		instruction[6] = {2'b11,10'd4,9'd0,10'd0,32'd3,1'b0};
		instruction[7] = {2'b11,10'd4,9'd0,10'd1,32'd4,1'b0};
		//read finish, no write back
		instruction[8] = {2'b00,10'b00,4'b1,44'b0,2'b1,2'b00};
		//write write buffer
		instruction[9] = {2'b11, 10'd4,9'd0,10'd0,32'd512,1'b1};
		instruction[10] = {2'b11, 10'd4,9'd0,10'd1,32'd214,1'b1};
		instruction[11] = {2'b11, 10'd4,9'd0,10'd2,32'd1224,1'b1};
		instruction[12] = {2'b11, 10'd4,9'd0,10'd3,32'd0214,1'b1};
		//send write request
		instruction[13] = {2'b01,10'd16,14'd0,10'd0,28'd32};
		instruction[14] = {2'b00,10'd16,12'd0,10'd24,28'd32,2'b01};
		//read finish, write back
		instruction[15] = {2'b11,10'd4,9'd0,10'd3,32'd54,1'b0};
		instruction[16] = {2'b11,10'd4,9'd0,10'd3,32'd54,1'b0};
		instruction[17] = {2'b00,10'd16,4'b0,2'b01,22'd0,10'd4,10'd0,2'b11,2'b00};
		//conflict between write write buffer and write back instructions
		instruction[18] = {2'b11, 10'd4,9'd0,10'd6,32'd888,1'b1};
		# 3
		CPU_reset = 1'b0;

		//# 2000000
		//$finish;
	end

	always begin
		# 1 CPU_clk = ~CPU_clk;
	end
	
	always @(posedge CPU_clk)
	begin
	   if(finish)
	   #100
	       $finish;
	end
	
	wire	awvalid;
	wire [31:0]		awaddr;
	wire [2:0]		awsize;
	wire [7:0]		awlen;
	wire 	awready;
	wire	wvalid;
	wire	wlast;
	wire [63:0]		wdata;
	wire	wready;
	wire	bready;
	wire	arvalid;
	wire [31:0]		araddr;
	wire [2:0]		arsize;
	wire [5:0]     arid;
	wire [7:0]		arlen;
	wire	arready;
	wire	rready;
	wire [63:0]		rdata;
	wire	rvalid;
	wire	rlast;
	wire [5:0]     rid;
	reg		RWrequest_valid;
	wire	RWrequest_ready;
	wire [1:0]		RWrequest_bits_request_type;
	wire [61:0]		RWrequest_bits_others;
	reg [63:0]		read_offset1;
	wire [127:0]	data1;
	reg [63:0]		read_offset23;
	wire [127:0]	data23;
	reg    [5:0]   rd_id;
	wire [7:0]     wstrb;
	
	always @(posedge CPU_clk)
	begin
	    read_offset1 <= {2'b01, 6'd0, 14'd0, 10'd0, 22'd0,10'd2};
	    read_offset23 <= {2'b10, 6'd0, 14'd0, 10'd2, 22'd0,10'd3};
	end
	
	always @(posedge CPU_clk)
	begin
	   if(CPU_reset)
	       rd_id <= 'd0;
	   else if(rready && rvalid && rlast)
	       rd_id <= rd_id+'d1;
	   else
	       rd_id <= rd_id;
	end
	
	assign last_inst = (RWrequest_valid == 1'b1 && RWrequest_ready == 1'b1 && ins_index == `INSTNUM);
	always @(posedge CPU_clk)
	begin
		if(CPU_reset || last_inst == 1'b1)
			ins_index <= 'd0;
		else if((RWrequest_valid == 1'b1 && RWrequest_ready == 1'b1))
		      # 7
			ins_index <= ins_index + 'd1;
		else
			ins_index <= ins_index;
	end
	
	always @(posedge CPU_clk)
	begin	
		if(CPU_reset)
			finish <= 'd0;
		else if(last_inst == 1'b1)
			finish <= 'd1;
		else
			finish <= finish;
	end
	
	//assign	RWrequest_bits_others = instruction[ins_index][61:0];
	//assign RWrequest_bits_request_type = instruction[ins_index][63:62];
	always @(posedge CPU_clk)
	begin
		if(CPU_reset)
			RWrequest_valid <= 'd0;
		else if(RWrequest_valid == 1'b0 && finish == 1'b0)
		      # 7
			RWrequest_valid <= 1'b1;
		else if(RWrequest_valid == 1'b1 && RWrequest_ready == 1'b1)
			RWrequest_valid <= 1'b0;
		else
			RWrequest_valid <= RWrequest_valid;
	end
	
	HCPFTLModule	hcpftl( // @[:@1908.2]
		.clock						(CPU_clk), // @[:@1909.4]
		.reset						(CPU_reset), // @[:@1910.4]
		.io_WStageAxi_aw_vaild 	(awvalid),// @[:@1911.4]
		.io_WStageAxi_aw_addr 		(awaddr),// @[:@1911.4]
		.io_WStageAxi_aw_size		(awsize), // @[:@1911.4]
		.io_WStageAxi_aw_len		(awlen), // @[:@1911.4]
		.io_WStageAxi_aw_ready		(awready), // @[:@1911.4]
		.io_WStageAxi_w_vaild		(wvalid), // @[:@1911.4]
		.io_WStageAxi_w_last		(wlast), // @[:@1911.4]
		.io_WStageAxi_w_data		(wdata), // @[:@1911.4]
		.io_WStageAxi_w_ready		(wready), // @[:@1911.4]
		.io_WStageAxi_w_strb          (wstrb),
		.io_WStageAxi_b_ready		(bready), // @[:@1911.4]
		.io_RStageAxi_ar_vaild		(arvalid), // @[:@1911.4]
		.io_RStageAxi_ar_addr		(araddr), // @[:@1911.4]
		.io_RStageAxi_ar_size		(arsize), // @[:@1911.4]
		.io_RStageAxi_ar_id			(arid), // @[:@1911.4]
		.io_RStageAxi_ar_len		(arlen), // @[:@1911.4]
		.io_RStageAxi_ar_ready		(arready), // @[:@1911.4]
		.io_RStageAxi_r_ready		(rready), // @[:@1911.4]
		.io_RStageAxi_r_data		(rdata), // @[:@1911.4]
		.io_RStageAxi_r_valid		(rvalid), // @[:@1911.4]
		.io_RStageAxi_r_last		(rlast), // @[:@1911.4]
		//.io_RStageAxi_r_id			({3'b000, rd_id[0], (rd_id[2:1] + 2'b01)}), // @[:@1911.4]
		.io_RStageAxi_r_id            (rid),
		//.io_out, // @[:@1911.4]
		.io_RWrequest_ready			(RWrequest_ready), // @[:@1911.4]
		.io_RWrequest_valid			(RWrequest_valid), // @[:@1911.4]
		.io_RWrequest_bits	(instruction[ins_index]), // @[:@1911.4]
		//.io_RWrequest_bits_others		(RWrequest_bits_others), // @[:@1911.4]
		.io_read_offset1				(read_offset1), // @[:@1911.4]
		.io_read_data1					(data1), // @[:@1911.4]
		.io_read_offset23				(read_offset23), // @[:@1911.4]
		.io_read_data23 				(data23),// @[:@1911.4]
		.io_PtrReset                      (last_inst)
);

	sim_1_wrapper	sim_1
		(.S_AXI_0_araddr			(araddr[11:0]),
		.S_AXI_0_arburst			('d1),
		.S_AXI_0_arcache			('d0),
		.S_AXI_0_arid               (arid),
		.S_AXI_0_arlen				(arlen),
		.S_AXI_0_arlock				('d0),
		.S_AXI_0_arprot				('d0),
		.S_AXI_0_arready			(arready),
		.S_AXI_0_arsize				(arsize),
		.S_AXI_0_arvalid			(arvalid),
		.S_AXI_0_awaddr				(awaddr[11:0]),
		.S_AXI_0_awburst			('d1),
		.S_AXI_0_awcache			('d0),
		.S_AXI_0_awid                 ('d0),
		.S_AXI_0_awlen				(awlen),
		.S_AXI_0_awlock				('d0),
		.S_AXI_0_awprot				('d0),
		.S_AXI_0_awready			(awready),
		.S_AXI_0_awsize				(awsize),
		.S_AXI_0_awvalid			(awvalid),
		.S_AXI_0_bready				(bready),
		//.S_AXI_0_bresp				('d0),
		.S_AXI_0_bvalid				(),
		.S_AXI_0_rdata				(rdata),
		.S_AXI_0_rlast				(rlast),
		.S_AXI_0_rready				(rready),
		//.S_AXI_0_rresp				('d0),
		.S_AXI_0_rvalid				(rvalid),
		.S_AXI_0_rid                 (rid),
		.S_AXI_0_wdata				(wdata),
		.S_AXI_0_wlast				(wlast),
		.S_AXI_0_wready				(wready),
		.S_AXI_0_wstrb			     (wstrb),
		.S_AXI_0_wvalid				(wvalid),
		.s_axi_aclk_0				(CPU_clk),
		.s_axi_aresetn_0			(~CPU_reset)
		);
		endmodule