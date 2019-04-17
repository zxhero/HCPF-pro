`timescale 1 ps / 1 ps
`include "clocking.vh"

module rocketchip_wrapper
   (
   inout [14:0]DDR_addr,
  inout [2:0]DDR_ba,
  inout DDR_cas_n,
  inout DDR_ck_n,
  inout DDR_ck_p,
  inout DDR_cke,
  inout DDR_cs_n,
  inout [3:0]DDR_dm,
  inout [31:0]DDR_dq,
  inout [3:0]DDR_dqs_n,
  inout [3:0]DDR_dqs_p,
  inout DDR_odt,
  inout DDR_ras_n,
  inout DDR_reset_n,
  inout DDR_we_n,

  inout FIXED_IO_ddr_vrn,
  inout FIXED_IO_ddr_vrp,
  inout [53:0]FIXED_IO_mio,
  inout FIXED_IO_ps_clk,
  inout FIXED_IO_ps_porb,
  inout FIXED_IO_ps_srstb,
	
	output [31:0]hcpf_M_AXI_araddr,
	output [1:0]hcpf_M_AXI_arburst,
	output [3:0]hcpf_M_AXI_arcache,
	output [5:0]hcpf_M_AXI_arid,
	output [7:0]hcpf_M_AXI_arlen,
	output [0:0]hcpf_M_AXI_arlock,
	output [2:0]hcpf_M_AXI_arprot,
	output [3:0]hcpf_M_AXI_arqos,
	input [0:0]hcpf_M_AXI_arready,
	output [3:0]hcpf_M_AXI_arregion,
	output [2:0]hcpf_M_AXI_arsize,
	output [0:0]hcpf_M_AXI_arvalid,
	output [31:0]hcpf_M_AXI_awaddr,
	output [1:0]hcpf_M_AXI_awburst,
	output [3:0]hcpf_M_AXI_awcache,
	output [5:0]hcpf_M_AXI_awid,
	output [7:0]hcpf_M_AXI_awlen,
	output [0:0]hcpf_M_AXI_awlock,
	output [2:0]hcpf_M_AXI_awprot,
	output [3:0]hcpf_M_AXI_awqos,
	input [0:0]hcpf_M_AXI_awready,
	output [3:0]hcpf_M_AXI_awregion,
	output [2:0]hcpf_M_AXI_awsize,
	output [0:0]hcpf_M_AXI_awvalid,
	input [5:0]hcpf_M_AXI_bid,
	output [0:0]hcpf_M_AXI_bready,
	input [1:0]hcpf_M_AXI_bresp,
	input [0:0]hcpf_M_AXI_bvalid,
	input [63:0]hcpf_M_AXI_rdata,
	input [5:0]hcpf_M_AXI_rid,
	input [0:0]hcpf_M_AXI_rlast,
	output [0:0]hcpf_M_AXI_rready,
	input [1:0]hcpf_M_AXI_rresp,
	input [0:0]hcpf_M_AXI_rvalid,
	output [63:0]hcpf_M_AXI_wdata,
	output [0:0]hcpf_M_AXI_wlast,
	input [0:0]hcpf_M_AXI_wready,
	output [7:0]hcpf_M_AXI_wstrb,
	output [0:0]hcpf_M_AXI_wvalid,
	
	output [31:0]mbus_M_AXI_araddr,
	output [1:0]mbus_M_AXI_arburst,
	output [3:0]mbus_M_AXI_arcache,
	output [5:0]mbus_M_AXI_arid,
	output [7:0]mbus_M_AXI_arlen,
	output [0:0]mbus_M_AXI_arlock,
	output [2:0]mbus_M_AXI_arprot,
	output [3:0]mbus_M_AXI_arqos,
	input [0:0]mbus_M_AXI_arready,
	output [3:0]mbus_M_AXI_arregion,
	output [2:0]mbus_M_AXI_arsize,
	output [0:0]mbus_M_AXI_arvalid,
	output [31:0]mbus_M_AXI_awaddr,
	output [1:0]mbus_M_AXI_awburst,
	output [3:0]mbus_M_AXI_awcache,
	output [5:0]mbus_M_AXI_awid,
	output [7:0]mbus_M_AXI_awlen,
	output [0:0]mbus_M_AXI_awlock,
	output [2:0]mbus_M_AXI_awprot,
	output [3:0]mbus_M_AXI_awqos,
	input [0:0]mbus_M_AXI_awready,
	output [3:0]mbus_M_AXI_awregion,
	output [2:0]mbus_M_AXI_awsize,
	output [0:0]mbus_M_AXI_awvalid,
	input [5:0]mbus_M_AXI_bid,
	output [0:0]mbus_M_AXI_bready,
	input [1:0]mbus_M_AXI_bresp,
	input [0:0]mbus_M_AXI_bvalid,
	input [63:0]mbus_M_AXI_rdata,
	input [5:0]mbus_M_AXI_rid,
	input [0:0]mbus_M_AXI_rlast,
	output [0:0]mbus_M_AXI_rready,
	input [1:0]mbus_M_AXI_rresp,
	input [0:0]mbus_M_AXI_rvalid,
	output [63:0]mbus_M_AXI_wdata,
	output [0:0]mbus_M_AXI_wlast,
	input [0:0]mbus_M_AXI_wready,
	output [7:0]mbus_M_AXI_wstrb,
	output [0:0]mbus_M_AXI_wvalid,
  
	output [31:0]tile_M_AXI_araddr,
	output [1:0]tile_M_AXI_arburst,
	output [3:0]tile_M_AXI_arcache,
	output [6:0]tile_M_AXI_arid,
	output [7:0]tile_M_AXI_arlen,
	output [0:0]tile_M_AXI_arlock,
	output [2:0]tile_M_AXI_arprot,
	output [3:0]tile_M_AXI_arqos,
	input [0:0]tile_M_AXI_arready,
	output [3:0]tile_M_AXI_arregion,
	output [2:0]tile_M_AXI_arsize,
	output [0:0]tile_M_AXI_arvalid,
	output [31:0]tile_M_AXI_awaddr,
	output [1:0]tile_M_AXI_awburst,
	output [3:0]tile_M_AXI_awcache,
	output [6:0]tile_M_AXI_awid,
	output [7:0]tile_M_AXI_awlen,
	output [0:0]tile_M_AXI_awlock,
	output [2:0]tile_M_AXI_awprot,
	output [3:0]tile_M_AXI_awqos,
	input [0:0]tile_M_AXI_awready,
	output [3:0]tile_M_AXI_awregion,
	output [2:0]tile_M_AXI_awsize,
	output [0:0]tile_M_AXI_awvalid,
	input [6:0]tile_M_AXI_bid,
	output [0:0]tile_M_AXI_bready,
	input [1:0]tile_M_AXI_bresp,
	input [0:0]tile_M_AXI_bvalid,
	input [63:0]tile_M_AXI_rdata,
	input [6:0]tile_M_AXI_rid,
	input [0:0]tile_M_AXI_rlast,
	output [0:0]tile_M_AXI_rready,
	input [1:0]tile_M_AXI_rresp,
	input [0:0]tile_M_AXI_rvalid,
	output [63:0]tile_M_AXI_wdata,
	output [0:0]tile_M_AXI_wlast,
	input [0:0]tile_M_AXI_wready,
	output [7:0]tile_M_AXI_wstrb,
	output [0:0]tile_M_AXI_wvalid,
	
	input         io_mmio_axi_aw_ready, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output        io_mmio_axi_aw_valid, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output [30:0] io_mmio_axi_aw_bits_addr, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	input         io_mmio_axi_w_ready, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output        io_mmio_axi_w_valid, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output [63:0] io_mmio_axi_w_bits_data, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output [7:0]  io_mmio_axi_w_bits_strb, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output        io_mmio_axi_b_ready, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	input         io_mmio_axi_b_valid, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	input  [1:0]  io_mmio_axi_b_bits_resp, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	input         io_mmio_axi_ar_ready, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output        io_mmio_axi_ar_valid, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output [30:0] io_mmio_axi_ar_bits_addr, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	output        io_mmio_axi_r_ready, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	input         io_mmio_axi_r_valid, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	input  [63:0] io_mmio_axi_r_bits_data, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	input  [1:0]  io_mmio_axi_r_bits_resp, // @[:Top.ZynqFPGAConfig.fir@183370.4]
	
	input		mcb_clk,
	input		mig_ic_resetn,
	output		tile_aresetn,
	output		host_clk,
	output		FCLK_RESET0_N,
	output      debug_inf,
	output      debug_inf_1,
	output      debug_inf_2
	//input		dcm_locked
	);
//`ifndef differential_clock
//    input clk);
//`else
    //input SYSCLK_P,
    //input gclk_i);
//`endif
  
  wire [31:0]M_AXI_araddr;
  wire [1:0]M_AXI_arburst;
  wire [7:0]M_AXI_arlen;
  wire M_AXI_arready;
  wire [2:0]M_AXI_arsize;
  wire M_AXI_arvalid;
  wire [31:0]M_AXI_awaddr;
  wire [1:0]M_AXI_awburst;
  wire [7:0]M_AXI_awlen;
  wire [3:0]M_AXI_wstrb;
  wire M_AXI_awready;
  wire [2:0]M_AXI_awsize;
  wire M_AXI_awvalid;
  wire M_AXI_bready;
  wire M_AXI_bvalid;
  wire [31:0]M_AXI_rdata;
  wire M_AXI_rlast;
  wire M_AXI_rready;
  wire M_AXI_rvalid;
  wire [31:0]M_AXI_wdata;
  wire M_AXI_wlast;
  wire M_AXI_wready;
  wire M_AXI_wvalid;
  wire [11:0] M_AXI_arid, M_AXI_awid; // outputs from ARM core
  wire [11:0] M_AXI_bid, M_AXI_rid;   // inputs to ARM core

  wire S_AXI_arready;
  wire S_AXI_arvalid;
  wire [31:0] S_AXI_araddr;
  wire [5:0]  S_AXI_arid;
  wire [2:0]  S_AXI_arsize;
  wire [7:0]  S_AXI_arlen;
  wire [1:0]  S_AXI_arburst;
  wire S_AXI_arlock;
  wire [3:0]  S_AXI_arcache;
  wire [2:0]  S_AXI_arprot;
  wire [3:0]  S_AXI_arqos;
  //wire [3:0]  S_AXI_arregion;

  wire S_AXI_awready;
  wire S_AXI_awvalid;
  wire [31:0] S_AXI_awaddr;
  wire [5:0]  S_AXI_awid;
  wire [2:0]  S_AXI_awsize;
  wire [7:0]  S_AXI_awlen;
  wire [1:0]  S_AXI_awburst;
  wire S_AXI_awlock;
  wire [3:0]  S_AXI_awcache;
  wire [2:0]  S_AXI_awprot;
  wire [3:0]  S_AXI_awqos;
  //wire [3:0]  S_AXI_awregion;

  wire S_AXI_wready;
  wire S_AXI_wvalid;
  wire [7:0]  S_AXI_wstrb;
  wire [63:0] S_AXI_wdata;
  wire S_AXI_wlast;

  wire S_AXI_bready;
  wire S_AXI_bvalid;
  wire [1:0] S_AXI_bresp;
  wire [5:0] S_AXI_bid;

  wire S_AXI_rready;
  wire S_AXI_rvalid;
  wire [1:0]  S_AXI_rresp;
  wire [5:0]  S_AXI_rid;
  wire [63:0] S_AXI_rdata;
  wire S_AXI_rlast;

  wire reset, reset_cpu;
  
  wire  FCLK_CLK,gclk_fbout, host_clk_i, mmcm_locked;

  wire hcpf_AXI_arready;
  wire hcpf_AXI_arvalid;
  wire [31:0] hcpf_AXI_araddr;
  wire [5:0]  hcpf_AXI_arid;
  wire [2:0]  hcpf_AXI_arsize;
  wire [7:0]  hcpf_AXI_arlen;
  wire [1:0]  hcpf_AXI_arburst;

  wire hcpf_AXI_awready;
  wire hcpf_AXI_awvalid;
  wire [31:0] hcpf_AXI_awaddr;
  wire [5:0]  hcpf_AXI_awid;
  wire [2:0]  hcpf_AXI_awsize;
  wire [7:0]  hcpf_AXI_awlen;
  wire [1:0]  hcpf_AXI_awburst;

  wire hcpf_AXI_wready;
  wire hcpf_AXI_wvalid;
  wire [63:0] hcpf_AXI_wdata;
  wire hcpf_AXI_wlast;
  wire [7:0] hcpf_AXI_wstrb;

  wire hcpf_AXI_bready;
  wire hcpf_AXI_bvalid;

  wire hcpf_AXI_rready;
  wire hcpf_AXI_rvalid;
  wire [5:0]  hcpf_AXI_rid;
  wire [63:0] hcpf_AXI_rdata;
  wire hcpf_AXI_rlast;
  
  wire [31:0] mem_araddr;
  wire [31:0] mem_awaddr;
  
 assign debug_inf = S_AXI_araddr[31:28] == 4'd1;//tile_aresetn;//S_AXI_arready;
 assign debug_inf_1 = mem_araddr[31:28] == 4'd8;//S_AXI_arready;//io_mmio_axi_ar_ready;
 //assign debug_inf_2 = hcpf_M_AXI_arready;
  system system_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FCLK_RESET0_N(FCLK_RESET0_N),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        // master AXI interface (zynq = master, fpga = slave)
        .M_AXI_araddr(M_AXI_araddr),
        .M_AXI_arburst(M_AXI_arburst), // burst type
        .M_AXI_arcache(),
        .M_AXI_arid(M_AXI_arid),
        .M_AXI_arlen(M_AXI_arlen), // burst length (#transfers)
        .M_AXI_arlock(),
        .M_AXI_arprot(),
        .M_AXI_arqos(),
        .M_AXI_arready(M_AXI_arready),
        .M_AXI_arregion(),
        .M_AXI_arsize(M_AXI_arsize), // burst size (bits/transfer)
        .M_AXI_arvalid(M_AXI_arvalid),
        //
        .M_AXI_awaddr(M_AXI_awaddr),
        .M_AXI_awburst(M_AXI_awburst),
        .M_AXI_awcache(),
        .M_AXI_awid(M_AXI_awid),
        .M_AXI_awlen(M_AXI_awlen),
        .M_AXI_awlock(),
        .M_AXI_awprot(),
        .M_AXI_awqos(),
        .M_AXI_awready(M_AXI_awready),
        .M_AXI_awregion(),
        .M_AXI_awsize(M_AXI_awsize),
        .M_AXI_awvalid(M_AXI_awvalid),
        //
        .M_AXI_bid(M_AXI_bid),
        .M_AXI_bready(M_AXI_bready),
        .M_AXI_bresp(2'b00),
        .M_AXI_bvalid(M_AXI_bvalid),
        //
        .M_AXI_rdata(M_AXI_rdata),
        .M_AXI_rid(M_AXI_rid),
        .M_AXI_rlast(M_AXI_rlast),
        .M_AXI_rready(M_AXI_rready),
        .M_AXI_rresp(),
        .M_AXI_rvalid(M_AXI_rvalid),
        //
        .M_AXI_wdata(M_AXI_wdata),
        .M_AXI_wlast(M_AXI_wlast),
        .M_AXI_wready(M_AXI_wready),
        .M_AXI_wstrb(M_AXI_wstrb),
        .M_AXI_wvalid(M_AXI_wvalid),

        // slave AXI interface (fpga = master, zynq = slave) 
        // connected directly to DDR controller to handle test chip mem
        .S_AXI_araddr(S_AXI_araddr),
        .S_AXI_arburst(S_AXI_arburst),
        .S_AXI_arcache(S_AXI_arcache),
        .S_AXI_arid(S_AXI_arid),
        .S_AXI_arlen(S_AXI_arlen),
        .S_AXI_arlock(S_AXI_arlock),
        .S_AXI_arprot(S_AXI_arprot),
        .S_AXI_arqos(S_AXI_arqos),
        .S_AXI_arready(S_AXI_arready),
      //  .S_AXI_arregion(4'b0),
        .S_AXI_arsize(S_AXI_arsize),
        .S_AXI_arvalid(S_AXI_arvalid),
        //
        .S_AXI_awaddr(S_AXI_awaddr),
        .S_AXI_awburst(S_AXI_awburst),
        .S_AXI_awcache(S_AXI_awcache),
        .S_AXI_awid(S_AXI_awid),
        .S_AXI_awlen(S_AXI_awlen),
        .S_AXI_awlock(S_AXI_awlock),
        .S_AXI_awprot(S_AXI_awprot),
        .S_AXI_awqos(S_AXI_awqos),
        .S_AXI_awready(S_AXI_awready),
        //.S_AXI_awregion(4'b0),
        .S_AXI_awsize(S_AXI_awsize),
        .S_AXI_awvalid(S_AXI_awvalid),
        //
        .S_AXI_bid(S_AXI_bid),
        .S_AXI_bready(S_AXI_bready),
        .S_AXI_bresp(S_AXI_bresp),
        .S_AXI_bvalid(S_AXI_bvalid),
        //
        .S_AXI_rid(S_AXI_rid),
        .S_AXI_rdata(S_AXI_rdata),
        .S_AXI_rlast(S_AXI_rlast),
        .S_AXI_rready(S_AXI_rready),
        .S_AXI_rresp(S_AXI_rresp),
        .S_AXI_rvalid(S_AXI_rvalid),
        //
        .S_AXI_wdata(S_AXI_wdata),
        .S_AXI_wlast(S_AXI_wlast),
        .S_AXI_wready(S_AXI_wready),
        .S_AXI_wstrb(S_AXI_wstrb),
        .S_AXI_wvalid(S_AXI_wvalid),
		
        // slave AXI interface (fpga = master, zynq = slave) 
        // connected directly to DDR controller to handle test chip mem
		.hcpf_S_AXI_araddr({2'd0,hcpf_AXI_araddr[27:0],2'd0}),
        .hcpf_S_AXI_arburst(hcpf_AXI_arburst),
        .hcpf_S_AXI_arcache('d0),
        .hcpf_S_AXI_arid(hcpf_AXI_arid),
        .hcpf_S_AXI_arlen(hcpf_AXI_arlen),
        .hcpf_S_AXI_arlock('d0),
        .hcpf_S_AXI_arprot('d0),
        .hcpf_S_AXI_arqos('d0),
        .hcpf_S_AXI_arready(hcpf_AXI_arready),
        //.hcpf_S_AXI_arregion(4'b0),
        .hcpf_S_AXI_arsize(hcpf_AXI_arsize),
        .hcpf_S_AXI_arvalid(hcpf_AXI_arvalid),
        //
        .hcpf_S_AXI_awaddr({2'd0,hcpf_AXI_awaddr[27:0],2'd0}),
        .hcpf_S_AXI_awburst(hcpf_AXI_awburst),
        .hcpf_S_AXI_awcache('d0),
        .hcpf_S_AXI_awid(hcpf_AXI_awid),
        .hcpf_S_AXI_awlen(hcpf_AXI_awlen),
        .hcpf_S_AXI_awlock('d0),
        .hcpf_S_AXI_awprot('d0),
        .hcpf_S_AXI_awqos('d0),
        .hcpf_S_AXI_awready(hcpf_AXI_awready),
        //.hcpf_S_AXI_awregion(4'b0),
        .hcpf_S_AXI_awsize(hcpf_AXI_awsize),
        .hcpf_S_AXI_awvalid(hcpf_AXI_awvalid),
        //
        .hcpf_S_AXI_bid(),
        .hcpf_S_AXI_bready(hcpf_AXI_bready),
        .hcpf_S_AXI_bresp(),
        .hcpf_S_AXI_bvalid(hcpf_AXI_bvalid),
        //
        .hcpf_S_AXI_rid(hcpf_AXI_rid),
        .hcpf_S_AXI_rdata(hcpf_AXI_rdata),
        .hcpf_S_AXI_rlast(hcpf_AXI_rlast),
        .hcpf_S_AXI_rready(hcpf_AXI_rready),
        .hcpf_S_AXI_rresp(),
        .hcpf_S_AXI_rvalid(hcpf_AXI_rvalid),
        //
        .hcpf_S_AXI_wdata(hcpf_AXI_wdata),
        .hcpf_S_AXI_wlast(hcpf_AXI_wlast),
        .hcpf_S_AXI_wready(hcpf_AXI_wready),
        .hcpf_S_AXI_wstrb(hcpf_AXI_wstrb),
        .hcpf_S_AXI_wvalid(hcpf_AXI_wvalid),
        .ext_clk_in(host_clk),
		.mcb_clk(mcb_clk),
		.mig_ic_resetn(mig_ic_resetn),
		.tile_aresetn(tile_aresetn),
		//.dcm_locked_0(dcm_locked),
		.FCLK_CLK0_0			(FCLK_CLK),
		//.debug_inf_1              (debug_inf_1),
		//.debug_inf_2              (debug_inf_2),
		//.debug_inf                (debug_inf),
		.S00_AXI_arready_0           (debug_inf_2),
        //connect to PL DDR
		.hcpf_M_AXI_araddr		(hcpf_M_AXI_araddr),
		.hcpf_M_AXI_arburst		(hcpf_M_AXI_arburst),
		.hcpf_M_AXI_arcache		(hcpf_M_AXI_arcache),
		.hcpf_M_AXI_arid		(hcpf_M_AXI_arid),
		.hcpf_M_AXI_arlen		(hcpf_M_AXI_arlen),
		.hcpf_M_AXI_arlock		(hcpf_M_AXI_arlock),
		.hcpf_M_AXI_arprot		(hcpf_M_AXI_arprot),
		.hcpf_M_AXI_arqos		(hcpf_M_AXI_arqos),
		.hcpf_M_AXI_arready		(hcpf_M_AXI_arready),
		.hcpf_M_AXI_arregion	(hcpf_M_AXI_arregion),
		.hcpf_M_AXI_arsize		(hcpf_M_AXI_arsize),
		.hcpf_M_AXI_arvalid		(hcpf_M_AXI_arvalid),
		.hcpf_M_AXI_awaddr		(hcpf_M_AXI_awaddr),
		.hcpf_M_AXI_awburst		(hcpf_M_AXI_awburst),
		.hcpf_M_AXI_awcache		(hcpf_M_AXI_awcache),
		.hcpf_M_AXI_awid		(hcpf_M_AXI_awid),
		.hcpf_M_AXI_awlen		(hcpf_M_AXI_awlen),
		.hcpf_M_AXI_awlock		(hcpf_M_AXI_awlock),
		.hcpf_M_AXI_awprot		(hcpf_M_AXI_awprot),
		.hcpf_M_AXI_awqos		(hcpf_M_AXI_awqos),
		.hcpf_M_AXI_awready		(hcpf_M_AXI_awready),
		.hcpf_M_AXI_awregion	(hcpf_M_AXI_awregion),
		.hcpf_M_AXI_awsize		(hcpf_M_AXI_awsize),
		.hcpf_M_AXI_awvalid		(hcpf_M_AXI_awvalid),
		.hcpf_M_AXI_bid			(hcpf_M_AXI_bid),
		.hcpf_M_AXI_bready		(hcpf_M_AXI_bready),
		.hcpf_M_AXI_bresp		(hcpf_M_AXI_bresp),
		.hcpf_M_AXI_bvalid		(hcpf_M_AXI_bvalid),
		.hcpf_M_AXI_rdata		(hcpf_M_AXI_rdata),
		.hcpf_M_AXI_rid			(hcpf_M_AXI_rid),
		.hcpf_M_AXI_rlast		(hcpf_M_AXI_rlast),
		.hcpf_M_AXI_rready		(hcpf_M_AXI_rready),
		.hcpf_M_AXI_rresp		(hcpf_M_AXI_rresp),
		.hcpf_M_AXI_rvalid		(hcpf_M_AXI_rvalid),
		.hcpf_M_AXI_wdata		(hcpf_M_AXI_wdata),
		.hcpf_M_AXI_wlast		(hcpf_M_AXI_wlast),
		.hcpf_M_AXI_wready		(hcpf_M_AXI_wready),
		.hcpf_M_AXI_wstrb		(hcpf_M_AXI_wstrb),
		.hcpf_M_AXI_wvalid		(hcpf_M_AXI_wvalid),
	   //connect to PL DDR
		.mbus_M_AXI_araddr		(mbus_M_AXI_araddr),
		.mbus_M_AXI_arburst		(mbus_M_AXI_arburst),
		.mbus_M_AXI_arcache		(mbus_M_AXI_arcache),
		.mbus_M_AXI_arid		(mbus_M_AXI_arid),
		.mbus_M_AXI_arlen		(mbus_M_AXI_arlen),
		.mbus_M_AXI_arlock		(mbus_M_AXI_arlock),
		.mbus_M_AXI_arprot		(mbus_M_AXI_arprot),
		.mbus_M_AXI_arqos		(mbus_M_AXI_arqos),
		.mbus_M_AXI_arready		(mbus_M_AXI_arready),
		.mbus_M_AXI_arregion	(mbus_M_AXI_arregion),
		.mbus_M_AXI_arsize		(mbus_M_AXI_arsize),
		.mbus_M_AXI_arvalid		(mbus_M_AXI_arvalid),
		.mbus_M_AXI_awaddr		(mbus_M_AXI_awaddr),
		.mbus_M_AXI_awburst		(mbus_M_AXI_awburst),
		.mbus_M_AXI_awcache		(mbus_M_AXI_awcache),
		.mbus_M_AXI_awid		(mbus_M_AXI_awid),
		.mbus_M_AXI_awlen		(mbus_M_AXI_awlen),
		.mbus_M_AXI_awlock		(mbus_M_AXI_awlock),
		.mbus_M_AXI_awprot		(mbus_M_AXI_awprot),
		.mbus_M_AXI_awqos		(mbus_M_AXI_awqos),
		.mbus_M_AXI_awready		(mbus_M_AXI_awready),
		.mbus_M_AXI_awregion	(mbus_M_AXI_awregion),
		.mbus_M_AXI_awsize		(mbus_M_AXI_awsize),
		.mbus_M_AXI_awvalid		(mbus_M_AXI_awvalid),
		.mbus_M_AXI_bid			(mbus_M_AXI_bid),
		.mbus_M_AXI_bready		(mbus_M_AXI_bready),
		.mbus_M_AXI_bresp		(mbus_M_AXI_bresp),
		.mbus_M_AXI_bvalid		(mbus_M_AXI_bvalid),
		.mbus_M_AXI_rdata		(mbus_M_AXI_rdata),
		.mbus_M_AXI_rid			(mbus_M_AXI_rid),
		.mbus_M_AXI_rlast		(mbus_M_AXI_rlast),
		.mbus_M_AXI_rready		(mbus_M_AXI_rready),
		.mbus_M_AXI_rresp		(mbus_M_AXI_rresp),
		.mbus_M_AXI_rvalid		(mbus_M_AXI_rvalid),
		.mbus_M_AXI_wdata		(mbus_M_AXI_wdata),
		.mbus_M_AXI_wlast		(mbus_M_AXI_wlast),
		.mbus_M_AXI_wready		(mbus_M_AXI_wready),
		.mbus_M_AXI_wstrb		(mbus_M_AXI_wstrb),
		.mbus_M_AXI_wvalid		(mbus_M_AXI_wvalid),
	   //connect to DoCE
		.tile_M_AXI_araddr		(tile_M_AXI_araddr),
		.tile_M_AXI_arburst		(tile_M_AXI_arburst),
		.tile_M_AXI_arcache		(tile_M_AXI_arcache),
		.tile_M_AXI_arid		(tile_M_AXI_arid),
		.tile_M_AXI_arlen		(tile_M_AXI_arlen),
		.tile_M_AXI_arlock		(tile_M_AXI_arlock),
		.tile_M_AXI_arprot		(tile_M_AXI_arprot),
		.tile_M_AXI_arqos		(tile_M_AXI_arqos),
		.tile_M_AXI_arready		(tile_M_AXI_arready),
		.tile_M_AXI_arregion	(tile_M_AXI_arregion),
		.tile_M_AXI_arsize		(tile_M_AXI_arsize),
		.tile_M_AXI_arvalid		(tile_M_AXI_arvalid),
		.tile_M_AXI_awaddr		(tile_M_AXI_awaddr),
		.tile_M_AXI_awburst		(tile_M_AXI_awburst),
		.tile_M_AXI_awcache		(tile_M_AXI_awcache),
		.tile_M_AXI_awid		(tile_M_AXI_awid),
		.tile_M_AXI_awlen		(tile_M_AXI_awlen),
		.tile_M_AXI_awlock		(tile_M_AXI_awlock),
		.tile_M_AXI_awprot		(tile_M_AXI_awprot),
		.tile_M_AXI_awqos		(tile_M_AXI_awqos),
		.tile_M_AXI_awready		(tile_M_AXI_awready),
		.tile_M_AXI_awregion	(tile_M_AXI_awregion),
		.tile_M_AXI_awsize		(tile_M_AXI_awsize),
		.tile_M_AXI_awvalid		(tile_M_AXI_awvalid),
		.tile_M_AXI_bid			(tile_M_AXI_bid),
		.tile_M_AXI_bready		(tile_M_AXI_bready),
		.tile_M_AXI_bresp		(tile_M_AXI_bresp),
		.tile_M_AXI_bvalid		(tile_M_AXI_bvalid),
		.tile_M_AXI_rdata		(tile_M_AXI_rdata),
		.tile_M_AXI_rid			(tile_M_AXI_rid),
		.tile_M_AXI_rlast		(tile_M_AXI_rlast),
		.tile_M_AXI_rready		(tile_M_AXI_rready),
		.tile_M_AXI_rresp		(tile_M_AXI_rresp),
		.tile_M_AXI_rvalid		(tile_M_AXI_rvalid),
		.tile_M_AXI_wdata		(tile_M_AXI_wdata),
		.tile_M_AXI_wlast		(tile_M_AXI_wlast),
		.tile_M_AXI_wready		(tile_M_AXI_wready),
		.tile_M_AXI_wstrb		(tile_M_AXI_wstrb),
		.tile_M_AXI_wvalid		(tile_M_AXI_wvalid)
        );

  assign reset = !FCLK_RESET0_N || !mmcm_locked;

  // Memory given to Rocket is the upper 256 MB of the 512 MB DRAM
  wire [3:0] high_araddr;
  wire [3:0] high_awaddr;
  assign high_araddr = mem_araddr[29:28] == 2'd0 ? 4'd1
                         : (mem_araddr[29:28] == 2'd1 ? 4'd0 : {2'd0,mem_araddr[29:28]});
  assign high_awaddr = mem_awaddr[29:28] == 2'd0 ? 4'd1
                                                : (mem_awaddr[29:28] == 2'd1 ? 4'd0 : {2'd0,mem_awaddr[29:28]});
  assign S_AXI_araddr = {high_araddr, mem_araddr[27:0]};
  assign S_AXI_awaddr = {high_awaddr, mem_awaddr[27:0]};//{2'd0, mem_awaddr[29:0]

  Top top(
   .clock(host_clk),
   .reset(reset),

   .io_ps_axi_slave_aw_ready (M_AXI_awready),
   .io_ps_axi_slave_aw_valid (M_AXI_awvalid),
   .io_ps_axi_slave_aw_bits_addr (M_AXI_awaddr),
   .io_ps_axi_slave_aw_bits_len (M_AXI_awlen),
   .io_ps_axi_slave_aw_bits_size (M_AXI_awsize),
   .io_ps_axi_slave_aw_bits_burst (M_AXI_awburst),
   .io_ps_axi_slave_aw_bits_id (M_AXI_awid),
   .io_ps_axi_slave_aw_bits_lock (1'b0),
   .io_ps_axi_slave_aw_bits_cache (4'b0),
   .io_ps_axi_slave_aw_bits_prot (3'b0),
   .io_ps_axi_slave_aw_bits_qos (4'b0),

   .io_ps_axi_slave_ar_ready (M_AXI_arready),
   .io_ps_axi_slave_ar_valid (M_AXI_arvalid),
   .io_ps_axi_slave_ar_bits_addr (M_AXI_araddr),
   .io_ps_axi_slave_ar_bits_len (M_AXI_arlen),
   .io_ps_axi_slave_ar_bits_size (M_AXI_arsize),
   .io_ps_axi_slave_ar_bits_burst (M_AXI_arburst),
   .io_ps_axi_slave_ar_bits_id (M_AXI_arid),
   .io_ps_axi_slave_ar_bits_lock (1'b0),
   .io_ps_axi_slave_ar_bits_cache (4'b0),
   .io_ps_axi_slave_ar_bits_prot (3'b0),
   .io_ps_axi_slave_ar_bits_qos (4'b0),

   .io_ps_axi_slave_w_valid (M_AXI_wvalid),
   .io_ps_axi_slave_w_ready (M_AXI_wready),
   .io_ps_axi_slave_w_bits_data (M_AXI_wdata),
   .io_ps_axi_slave_w_bits_strb (M_AXI_wstrb),
   .io_ps_axi_slave_w_bits_last (M_AXI_wlast),

   .io_ps_axi_slave_r_valid (M_AXI_rvalid),
   .io_ps_axi_slave_r_ready (M_AXI_rready),
   .io_ps_axi_slave_r_bits_id (M_AXI_rid),
   .io_ps_axi_slave_r_bits_resp (),
   .io_ps_axi_slave_r_bits_data (M_AXI_rdata),
   .io_ps_axi_slave_r_bits_last (M_AXI_rlast),

   .io_ps_axi_slave_b_valid (M_AXI_bvalid),
   .io_ps_axi_slave_b_ready (M_AXI_bready),
   .io_ps_axi_slave_b_bits_id (M_AXI_bid),
   .io_ps_axi_slave_b_bits_resp (),

   .io_mem_axi_ar_valid (S_AXI_arvalid),
   .io_mem_axi_ar_ready (S_AXI_arready),
   .io_mem_axi_ar_bits_addr (mem_araddr),
   .io_mem_axi_ar_bits_id (S_AXI_arid),
   .io_mem_axi_ar_bits_size (S_AXI_arsize),
   .io_mem_axi_ar_bits_len (S_AXI_arlen),
   .io_mem_axi_ar_bits_burst (S_AXI_arburst),
   .io_mem_axi_ar_bits_cache (S_AXI_arcache),
   .io_mem_axi_ar_bits_lock (S_AXI_arlock),
   .io_mem_axi_ar_bits_prot (S_AXI_arprot),
   .io_mem_axi_ar_bits_qos (S_AXI_arqos),
   .io_mem_axi_aw_valid (S_AXI_awvalid),
   .io_mem_axi_aw_ready (S_AXI_awready),
   .io_mem_axi_aw_bits_addr (mem_awaddr),
   .io_mem_axi_aw_bits_id (S_AXI_awid),
   .io_mem_axi_aw_bits_size (S_AXI_awsize),
   .io_mem_axi_aw_bits_len (S_AXI_awlen),
   .io_mem_axi_aw_bits_burst (S_AXI_awburst),
   .io_mem_axi_aw_bits_cache (S_AXI_awcache),
   .io_mem_axi_aw_bits_lock (S_AXI_awlock),
   .io_mem_axi_aw_bits_prot (S_AXI_awprot),
   .io_mem_axi_aw_bits_qos (S_AXI_awqos),
   .io_mem_axi_w_valid (S_AXI_wvalid),
   .io_mem_axi_w_ready (S_AXI_wready),
   .io_mem_axi_w_bits_strb (S_AXI_wstrb),
   .io_mem_axi_w_bits_data (S_AXI_wdata),
   .io_mem_axi_w_bits_last (S_AXI_wlast),
   .io_mem_axi_b_valid (S_AXI_bvalid),
   .io_mem_axi_b_ready (S_AXI_bready),
   .io_mem_axi_b_bits_resp (S_AXI_bresp),
   .io_mem_axi_b_bits_id (S_AXI_bid),
   .io_mem_axi_r_valid (S_AXI_rvalid),
   .io_mem_axi_r_ready (S_AXI_rready),
   .io_mem_axi_r_bits_resp (S_AXI_rresp),
   .io_mem_axi_r_bits_id (S_AXI_rid),
   .io_mem_axi_r_bits_data (S_AXI_rdata),
   .io_mem_axi_r_bits_last (S_AXI_rlast),

   .io_hcpf_axi_aw_ready (hcpf_AXI_awready), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_aw_valid (hcpf_AXI_awvalid), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_aw_bits_id (hcpf_AXI_awid),
   .io_hcpf_axi_aw_bits_addr (hcpf_AXI_awaddr), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_aw_bits_len (hcpf_AXI_awlen), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_aw_bits_size (hcpf_AXI_awsize),
   .io_hcpf_axi_aw_bits_burst (hcpf_AXI_awburst),
   .io_hcpf_axi_aw_bits_lock (),
   .io_hcpf_axi_aw_bits_cache (),
   .io_hcpf_axi_aw_bits_prot (),
   .io_hcpf_axi_aw_bits_qos (),
   
   .io_hcpf_axi_w_ready (hcpf_AXI_wready), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_w_valid (hcpf_AXI_wvalid), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_w_bits_data (hcpf_AXI_wdata), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_w_bits_strb (hcpf_AXI_wstrb),
   .io_hcpf_axi_w_bits_last (hcpf_AXI_wlast), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   
   .io_hcpf_axi_b_ready (hcpf_AXI_bready),
   .io_hcpf_axi_b_valid (hcpf_AXI_bvalid),
   .io_hcpf_axi_b_bits_id ('d0),
   .io_hcpf_axi_b_bits_resp (),
   
   .io_hcpf_axi_ar_ready (hcpf_AXI_arready), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_ar_valid (hcpf_AXI_arvalid), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_ar_bits_id (hcpf_AXI_arid),
   .io_hcpf_axi_ar_bits_addr (hcpf_AXI_araddr), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_ar_bits_len (hcpf_AXI_arlen), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_ar_bits_size (hcpf_AXI_arsize),
   .io_hcpf_axi_ar_bits_burst (hcpf_AXI_arburst),
   .io_hcpf_axi_ar_bits_lock (),
   .io_hcpf_axi_ar_bits_cache (),
   .io_hcpf_axi_ar_bits_prot (),
   .io_hcpf_axi_ar_bits_qos (),
   
   .io_hcpf_axi_r_ready (hcpf_AXI_rready), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_r_valid (hcpf_AXI_rvalid), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_r_bits_id (hcpf_AXI_rid),
   .io_hcpf_axi_r_bits_data (hcpf_AXI_rdata), // @[:Top.ZynqFPGAConfig.fir@136622.4]
   .io_hcpf_axi_r_bits_resp (),
   .io_hcpf_axi_r_bits_last (hcpf_AXI_rlast),
   
   .io_mmio_axi_aw_ready		(io_mmio_axi_aw_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_valid		(io_mmio_axi_aw_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_id		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_addr	(io_mmio_axi_aw_bits_addr), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_len		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_size	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_burst	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_lock	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_cache	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_prot	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_aw_bits_qos		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_w_ready			(io_mmio_axi_w_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_w_valid			(io_mmio_axi_w_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_w_bits_data		(io_mmio_axi_w_bits_data), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_w_bits_strb		(io_mmio_axi_w_bits_strb), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_w_bits_last		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_b_ready			(io_mmio_axi_b_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_b_valid			(io_mmio_axi_b_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_b_bits_id		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_b_bits_resp		(io_mmio_axi_b_bits_resp), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_ready		(io_mmio_axi_ar_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_valid		(io_mmio_axi_ar_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_id		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_addr	(io_mmio_axi_ar_bits_addr), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_len		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_size	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_burst	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_lock	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_cache	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_prot	(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_ar_bits_qos		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_r_ready			(io_mmio_axi_r_ready), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_r_valid			(io_mmio_axi_r_valid), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_r_bits_id		(), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_r_bits_data		(io_mmio_axi_r_bits_data), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_r_bits_resp		(io_mmio_axi_r_bits_resp), // @[:Top.ZynqFPGAConfig.fir@183370.4]
   .io_mmio_axi_r_bits_last		 ()// @[:Top.ZynqFPGAConfig.fir@183370.4]
  );
//`ifndef differential_clock
//  IBUFG ibufg_gclk (.I(clk), .O(gclk_i));
//`else//
//  IBUFDS #(.DIFF_TERM("TRUE"), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("DEFAULT")) clk_ibufds (.O(gclk_i), .I(SYSCLK_P), .IB(SYSCLK_N));
//`endif
  BUFG  bufg_host_clk (.I(host_clk_i), .O(host_clk));

  MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT_F(`RC_CLK_MULT),
    .CLKFBOUT_PHASE(0.0),
    .CLKIN1_PERIOD(`ZYNQ_CLK_PERIOD),
    .CLKOUT1_DIVIDE(1),
    .CLKOUT2_DIVIDE(1),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT0_DIVIDE_F(`RC_CLK_DIVIDE),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0.0),
    .CLKOUT1_PHASE(0.0),
    .CLKOUT2_PHASE(0.0),
    .CLKOUT3_PHASE(0.0),
    .CLKOUT4_PHASE(0.0),
    .CLKOUT5_PHASE(0.0),
    .CLKOUT6_PHASE(0.0),
    .CLKOUT4_CASCADE("FALSE"),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.0),
    .STARTUP_WAIT("FALSE")
  ) MMCME2_BASE_inst (
    .CLKOUT0(host_clk_i),
    .CLKOUT0B(),
    .CLKOUT1(),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBOUT(gclk_fbout),
    .CLKFBOUTB(),
    .LOCKED(mmcm_locked),
    .CLKIN1(FCLK_CLK),
    .PWRDWN(1'b0),
    .RST(1'b0),
    .CLKFBIN(gclk_fbout));

endmodule
