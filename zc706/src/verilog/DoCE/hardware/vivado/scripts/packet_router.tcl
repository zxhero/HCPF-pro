# Board Design Automative Generation Script
# File Name: deoi_based_armv7_server_node_bd.tcl

# CHANGE DESIGN NAME HERE
set design_name packet_router 

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "ERROR: Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      puts "INFO: Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   puts "INFO: Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   puts "INFO: Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   puts "INFO: Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

puts "INFO: Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   puts $errMsg
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################

#==============================================
# Copy IP configuration from IP repository
#==============================================
set bd_prefix packet_router_
set bd_src_base ./${::proj_dir}/${::design}.srcs/sources_1/bd/packet_router
set ip_repo_base ../../../../../../../../sources/ip_catalog

proc change_ip_config_file { ip_name } {
	exec mkdir -p ../sources/ip_catalog/${::bd_prefix}${ip_name}
	exec cp ${::bd_src_base}/ip/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci \
		../sources/ip_catalog/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci
	exec rm -f ${::bd_src_base}/ip/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci
	exec ln -s ${::ip_repo_base}/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci \
		${::bd_src_base}/ip/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci 
}

# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

#===================================
# Create IP Blocks
#===================================

  # Create instance: AXI-Stream interconnect VFIFO WR
  set axis_ic_vfifo_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_ic_vfifo_in ]
  set_property -dict [ list CONFIG.NUM_SI {6} \
				CONFIG.NUM_MI {1} \
				CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
				CONFIG.XBAR_TDATA_NUM_BYTES.VALUE_SRC {USER} \
				CONFIG.XBAR_TDATA_NUM_BYTES {64} \
				CONFIG.ARB_ON_TLAST {1} \
				CONFIG.ARB_ON_MAX_XFERS {0} \
				CONFIG.S00_FIFO_DEPTH {512} \
				CONFIG.S01_FIFO_DEPTH {512} \
				CONFIG.S02_FIFO_DEPTH {512} \
				CONFIG.S03_FIFO_DEPTH {512} \
				CONFIG.S04_FIFO_DEPTH {512} \
				CONFIG.S05_FIFO_DEPTH {512} \
				CONFIG.M00_AXIS_HIGHTDEST {0x00000005} ] $axis_ic_vfifo_in

  # Create instance: AXI-Stream interconnect VFIFO RD
  set axis_ic_vfifo_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_ic_vfifo_out ]
  set_property -dict [ list CONFIG.NUM_SI {1} \
				CONFIG.NUM_MI {3} \
				CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
				CONFIG.XBAR_TDATA_NUM_BYTES.VALUE_SRC {USER} \
				CONFIG.XBAR_TDATA_NUM_BYTES {8} \
				CONFIG.ENABLE_FIFO_COUNT_PORTS {1} \
				CONFIG.M00_FIFO_DEPTH {4096} \
				CONFIG.M01_FIFO_DEPTH {4096} \
				CONFIG.M02_FIFO_DEPTH {4096} \
				CONFIG.M02_FIFO_MODE {1} \
				CONFIG.M00_AXIS_HIGHTDEST {0x00000001} \
				CONFIG.M01_AXIS_BASETDEST {0x00000002} \
				CONFIG.M01_AXIS_HIGHTDEST {0x00000003} \
				CONFIG.M02_AXIS_BASETDEST {0x00000004} \
				CONFIG.M02_AXIS_HIGHTDEST {0x00000005} ] $axis_ic_vfifo_out

  # Create instance: AXI-Stream interconnect XGBE MAC Tx Arbitration
  set axis_ic_xgbe_mac_tx_arb [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_ic_xgbe_mac_tx_arb ]
  set_property -dict [ list CONFIG.NUM_SI {2} \
				CONFIG.NUM_MI {1} \
				CONFIG.ARB_ON_TLAST {1} \
				CONFIG.ARB_ON_MAX_XFERS {0} \
				CONFIG.S01_FIFO_DEPTH {512} \
				CONFIG.S01_FIFO_MODE {1} \
				CONFIG.M00_AXIS_BASETDEST {0x00000004} \
				CONFIG.M00_AXIS_HIGHTDEST {0x00000006} ] $axis_ic_xgbe_mac_tx_arb
  
  # Create instance: AXI-Stream interconnect XGBE MAC Tx Arbitration
  set axis_ic_doce_rx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_ic_doce_rx ]
  set_property -dict [ list CONFIG.NUM_SI {1} \
				CONFIG.NUM_MI {1} \
				CONFIG.S00_FIFO_DEPTH {512} \
				CONFIG.S00_FIFO_MODE {1} ] $axis_ic_doce_rx

  # Create instance: AXI virtual FIFO
  set axi_vfifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vfifo_ctrl:2.0 axi_vfifo ]
  set_property -dict [ list CONFIG.axis_tdata_width {512} \
				CONFIG.axi_burst_size {1024} \
				CONFIG.number_of_channel {6} \
				CONFIG.dram_base_addr {60000000} \
				CONFIG.number_of_page_ch0 {1024} \
				CONFIG.number_of_page_ch1 {1024} \
				CONFIG.number_of_page_ch2 {1024} \
				CONFIG.number_of_page_ch3 {1024} \
				CONFIG.number_of_page_ch4 {1024} \
				CONFIG.number_of_page_ch5 {1024} ] $axi_vfifo

#=============================================
# Clock ports
#=============================================

  # PCIe DMA clock
  set pcie_clk_250 [ create_bd_port -dir I -type clk pcie_clk_250 ]
  set_property -dict [ list CONFIG.CLK_DOMAIN {pcie_clk_250} \
				CONFIG.FREQ_HZ {250000000} \
				CONFIG.PHASE {0.000} ] $pcie_clk_250

  # PS FCLK0 used by AXI DMA
  set ps_fclk_clk0 [ create_bd_port -dir I -type clk ps_fclk_clk0 ]
  set_property -dict [ list CONFIG.CLK_DOMAIN {ps_fclk_clk0} \
				CONFIG.FREQ_HZ {200000000} \
				CONFIG.PHASE {0.000} ] $ps_fclk_clk0

  # MIG user clock used by DoCE and VFIFO
  set mcb_clk [ create_bd_port -dir I -type clk mcb_clk ]
  set_property -dict [ list CONFIG.CLK_DOMAIN {mcb_clk} \
				CONFIG.FREQ_HZ {200000000} \
				CONFIG.PHASE {0.000} ] $mcb_clk

  # XGBE MAC clock
  set xgemac_clk_156 [ create_bd_port -dir I -type clk xgemac_clk_156 ]
  set_property -dict [ list CONFIG.CLK_DOMAIN {xgemac_clk_156} \
				CONFIG.FREQ_HZ {156250000} \
				CONFIG.PHASE {0.000} ] $xgemac_clk_156

#==============================================
# Reset ports
#==============================================

  # PCIe DMA S2C/C2S channel reset
  create_bd_port -dir I -type rst pcie_dma_s2c0_aresetn
  create_bd_port -dir I -type rst pcie_dma_c2s0_aresetn
  set_property CONFIG.ASSOCIATED_RESET {pcie_dma_s2c0_aresetn:pcie_dma_c2s0_aresetn} \
				[get_bd_ports pcie_clk_250]

  # AXI DMA MM2S/S2MM channel reset 					
  create_bd_port -dir I -type rst axi_dma_mm2s_resetn
  create_bd_port -dir I -type rst axi_dma_s2mm_resetn
  set_property CONFIG.ASSOCIATED_RESET {axi_dma_mm2s_resetn:axi_dma_s2mm_resetn} \
				[get_bd_ports ps_fclk_clk0]

  # DoCE and packet router reset
  create_bd_port -dir I -type rst mig_ic_resetn
  set_property CONFIG.ASSOCIATED_RESET {mig_ic_resetn} \
				[get_bd_ports mcb_clk]
  
  # XGBE MAC reset
  create_bd_port -dir I -type rst xgbe_mac_resetn
  set_property CONFIG.ASSOCIATED_RESET {xgbe_mac_resetn} \
				[get_bd_ports xgemac_clk_156]

#==============================================
# Export AXI Interface
#==============================================
  # AXI master interface from 
  set network_path_vfifo_axi_master [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 network_path_vfifo_axi_master ]
  set_property -dict [ list CONFIG.DATA_WIDTH {512} ] $network_path_vfifo_axi_master

#==============================================
# Export AXI-STREAM Interface
#==============================================
  
  # PCIe backend DMA engine Tx and Rx interface
  set pcie_dma_to_axi_dma [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_dma_to_axi_dma ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
				CONFIG.HAS_TLAST {1} \
				CONFIG.HAS_TKEEP {1} \
				CONFIG.TDEST_WIDTH {3} ] $pcie_dma_to_axi_dma

  set pcie_dma_to_xgbe_mac [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_dma_to_xgbe_mac ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
				CONFIG.HAS_TLAST {1} \
				CONFIG.HAS_TKEEP {1} \
				CONFIG.TDEST_WIDTH {3} ] $pcie_dma_to_xgbe_mac

  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_dma_axis_rx

  set_property CONFIG.ASSOCIATED_BUSIF {pcie_dma_axis_rx:pcie_dma_to_axi_dma:pcie_dma_to_xgbe_mac} \
				[get_bd_ports pcie_clk_250]

  # AXI DMA Tx and Rx interface
  set axi_dma_to_pcie_dma [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 axi_dma_to_pcie_dma ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
				CONFIG.HAS_TLAST {1} \
				CONFIG.HAS_TKEEP {1} \
				CONFIG.TDEST_WIDTH {3} ] $axi_dma_to_pcie_dma

  set axi_dma_to_xgbe_mac [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 axi_dma_to_xgbe_mac ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
				CONFIG.HAS_TLAST {1} \
				CONFIG.HAS_TKEEP {1} \
				CONFIG.TDEST_WIDTH {3} ] $axi_dma_to_xgbe_mac

  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 axi_dma_str_rxd

  set_property CONFIG.ASSOCIATED_BUSIF {axi_dma_str_rxd:axi_dma_to_pcie_dma:axi_dma_to_xgbe_mac} \
				[get_bd_ports ps_fclk_clk0]

  # DoCE Tx and Rx interface
  set doce_axis_txd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 doce_axis_txd ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
				CONFIG.HAS_TLAST {1} \
				CONFIG.HAS_TKEEP {1} \
				CONFIG.TDEST_WIDTH {3} ] $doce_axis_txd

  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 doce_axis_rxd

  set_property CONFIG.ASSOCIATED_BUSIF {doce_axis_txd:doce_axis_rxd} \
				[get_bd_ports mcb_clk]

  # XGBE MAC Tx and Rx interface
  set xgbe_mac_to_pcie_dma [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 xgbe_mac_to_pcie_dma ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
				CONFIG.HAS_TLAST {1} \
				CONFIG.HAS_TKEEP {1} \
				CONFIG.TDEST_WIDTH {3} ] $xgbe_mac_to_pcie_dma

  set xgbe_mac_to_axi_dma [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 xgbe_mac_to_axi_dma ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
				CONFIG.HAS_TLAST {1} \
				CONFIG.HAS_TKEEP {1} \
				CONFIG.TDEST_WIDTH {3} ] $xgbe_mac_to_axi_dma

  set xgbe_mac_to_doce [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 xgbe_mac_to_doce]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
				CONFIG.HAS_TLAST {1} \
				CONFIG.HAS_TKEEP {1} \
				CONFIG.TDEST_WIDTH {3} ] $xgbe_mac_to_doce

  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 router_mac_axis_tx

  set_property CONFIG.ASSOCIATED_BUSIF {router_mac_axis_tx:xgbe_mac_to_pcie_dma:xgbe_mac_to_axi_dma:xgbe_mac_to_doce} \
				[get_bd_ports xgemac_clk_156]

#=============================================
# Other ports
#=============================================
  create_bd_port -dir O -from 5 -to 0 vfifo_s2mm_channel_full
  create_bd_port -dir I -from 5 -to 0 vfifo_mm2s_channel_full

  create_bd_port -dir I axis_ic_vfifo_in_s00_req_suppress
  create_bd_port -dir I axis_ic_vfifo_in_s01_req_suppress
  create_bd_port -dir I axis_ic_vfifo_in_s02_req_suppress
  create_bd_port -dir I axis_ic_vfifo_in_s03_req_suppress
  create_bd_port -dir I axis_ic_vfifo_in_s04_req_suppress
  create_bd_port -dir I axis_ic_vfifo_in_s05_req_suppress

  create_bd_port -dir O -from 11 -to 0 axis_ic_vfifo_out_m00_data_cnt
  create_bd_port -dir O -from 11 -to 0 axis_ic_vfifo_out_m01_data_cnt
  create_bd_port -dir O -from 11 -to 0 axis_ic_vfifo_out_m02_data_cnt

#=============================================
# System clock connection
#=============================================

  connect_bd_net -net pcie_clk_250 [get_bd_ports pcie_clk_250] \
				[get_bd_pins axis_ic_vfifo_in/S02_AXIS_ACLK] \
				[get_bd_pins axis_ic_vfifo_in/S05_AXIS_ACLK] \
				[get_bd_pins axis_ic_vfifo_out/M00_AXIS_ACLK]

  connect_bd_net -net ps_fclk_clk0 [get_bd_ports ps_fclk_clk0] \
				[get_bd_pins axis_ic_vfifo_in/S00_AXIS_ACLK] \
				[get_bd_pins axis_ic_vfifo_in/S04_AXIS_ACLK] \
				[get_bd_pins axis_ic_vfifo_out/M01_AXIS_ACLK]

  connect_bd_net -net xgemac_clk_156 [get_bd_ports xgemac_clk_156] \
				[get_bd_pins axis_ic_vfifo_in/S01_AXIS_ACLK] \
				[get_bd_pins axis_ic_vfifo_in/S03_AXIS_ACLK] \
				[get_bd_pins axis_ic_vfifo_out/M02_AXIS_ACLK] \
				[get_bd_pins axis_ic_xgbe_mac_tx_arb/ACLK] \
				[get_bd_pins axis_ic_xgbe_mac_tx_arb/S00_AXIS_ACLK] \
				[get_bd_pins axis_ic_xgbe_mac_tx_arb/M00_AXIS_ACLK] \
				[get_bd_pins axis_ic_doce_rx/S00_AXIS_ACLK]

  connect_bd_net -net mcb_clk [get_bd_ports mcb_clk] \
				[get_bd_pins axis_ic_vfifo_in/ACLK] \
				[get_bd_pins axis_ic_vfifo_in/M00_AXIS_ACLK] \
				[get_bd_pins axis_ic_vfifo_out/ACLK] \
				[get_bd_pins axis_ic_vfifo_out/S00_AXIS_ACLK] \
				[get_bd_pins axis_ic_xgbe_mac_tx_arb/S01_AXIS_ACLK] \
				[get_bd_pins axi_vfifo/aclk] \
				[get_bd_pins axis_ic_doce_rx/ACLK] \
				[get_bd_pins axis_ic_doce_rx/M00_AXIS_ACLK]

#=============================================
# System reset connection
#=============================================

  # AXIS_IC
  connect_bd_net -net pcie_dma_s2c0_aresetn [get_bd_ports pcie_dma_s2c0_aresetn] \
				[get_bd_pins axis_ic_vfifo_in/S02_AXIS_ARESETN] \
				[get_bd_pins axis_ic_vfifo_in/S05_AXIS_ARESETN]

  connect_bd_net -net pcie_dma_c2s0_aresetn [get_bd_ports pcie_dma_c2s0_aresetn] \
				[get_bd_pins axis_ic_vfifo_out/M00_AXIS_ARESETN] \

  connect_bd_net -net axi_dma_mm2s_resetn [get_bd_ports axi_dma_mm2s_resetn] \
				[get_bd_pins axis_ic_vfifo_in/S00_AXIS_ARESETN] \
				[get_bd_pins axis_ic_vfifo_in/S04_AXIS_ARESETN]

  connect_bd_net -net axi_dma_s2mm_resetn [get_bd_ports axi_dma_s2mm_resetn] \
				[get_bd_pins axis_ic_vfifo_out/M01_AXIS_ARESETN] \

  connect_bd_net -net xgbe_mac_resetn [get_bd_ports xgbe_mac_resetn] \
				[get_bd_pins axis_ic_vfifo_in/S01_AXIS_ARESETN] \
				[get_bd_pins axis_ic_vfifo_in/S03_AXIS_ARESETN] \
				[get_bd_pins axis_ic_vfifo_out/M02_AXIS_ARESETN] \
				[get_bd_pins axis_ic_xgbe_mac_tx_arb/ARESETN] \
				[get_bd_pins axis_ic_xgbe_mac_tx_arb/S00_AXIS_ARESETN] \
				[get_bd_pins axis_ic_xgbe_mac_tx_arb/M00_AXIS_ARESETN] \
				[get_bd_pins axis_ic_doce_rx/S00_AXIS_ARESETN]

  connect_bd_net -net mig_ic_resetn [get_bd_ports mig_ic_resetn] \
				[get_bd_pins axis_ic_vfifo_in/ARESETN] \
				[get_bd_pins axis_ic_vfifo_in/M00_AXIS_ARESETN] \
				[get_bd_pins axis_ic_vfifo_out/ARESETN] \
				[get_bd_pins axis_ic_vfifo_out/S00_AXIS_ARESETN] \
				[get_bd_pins axis_ic_xgbe_mac_tx_arb/S01_AXIS_ARESETN] \
				[get_bd_pins axi_vfifo/aresetn] \
				[get_bd_pins axis_ic_doce_rx/ARESETN] \
				[get_bd_pins axis_ic_doce_rx/M00_AXIS_ARESETN]

#==============================================
# AXI Interface Connection
#==============================================
  connect_bd_intf_net -intf_net axi_vfifo_master [get_bd_intf_pins network_path_vfifo_axi_master] \
					[get_bd_intf_pins axi_vfifo/M_AXI]

#==============================================
# AXI-Stream Interface
#==============================================

  #AXIS-IC VFIFO IN
  connect_bd_intf_net -intf_net axi_dma_to_pcie_dma [get_bd_intf_pins axi_dma_to_pcie_dma] \
					[get_bd_intf_pins axis_ic_vfifo_in/S00_AXIS]

  connect_bd_intf_net -intf_net xgbe_mac_to_pcie_dma [get_bd_intf_ports xgbe_mac_to_pcie_dma] \
					[get_bd_intf_pins axis_ic_vfifo_in/S01_AXIS]

  connect_bd_intf_net -intf_net pcie_dma_to_axi_dma [get_bd_intf_pins pcie_dma_to_axi_dma] \
					[get_bd_intf_pins axis_ic_vfifo_in/S02_AXIS]

  connect_bd_intf_net -intf_net xgbe_mac_to_axi_dma [get_bd_intf_ports xgbe_mac_to_axi_dma] \
					[get_bd_intf_pins axis_ic_vfifo_in/S03_AXIS]

  connect_bd_intf_net -intf_net axi_dma_to_xgbe_mac [get_bd_intf_pins axi_dma_to_xgbe_mac] \
					[get_bd_intf_pins axis_ic_vfifo_in/S04_AXIS]

  connect_bd_intf_net -intf_net pcie_dma_to_xgbe_mac [get_bd_intf_pins pcie_dma_to_xgbe_mac] \
					[get_bd_intf_pins axis_ic_vfifo_in/S05_AXIS]

  connect_bd_intf_net -intf_net vfifo_s_axis [get_bd_intf_pins axis_ic_vfifo_in/M00_AXIS] \
					[get_bd_intf_pins axi_vfifo/S_AXIS]
 
  #AXIS-IC VFIFO Out
  connect_bd_intf_net -intf_net vfifo_m_axis [get_bd_intf_pins axi_vfifo/M_AXIS] \
					[get_bd_intf_pins axis_ic_vfifo_out/S00_AXIS]

  connect_bd_intf_net -intf_net pcie_dma_axis_rx [get_bd_intf_pins pcie_dma_axis_rx] \
					[get_bd_intf_pins axis_ic_vfifo_out/M00_AXIS]

  connect_bd_intf_net -intf_net axi_dma_str_rxd [get_bd_intf_pins axi_dma_str_rxd] \
					[get_bd_intf_pins axis_ic_vfifo_out/M01_AXIS]

  connect_bd_intf_net -intf_net axis_ic_vfifo_out_M02 [get_bd_intf_pins axis_ic_vfifo_out/M02_AXIS] \
					[get_bd_intf_pins axis_ic_xgbe_mac_tx_arb/S00_AXIS]
 
  #AXIS IC XGBE MAC Tx
  connect_bd_intf_net -intf_net doce_axis_txd [get_bd_intf_pins doce_axis_txd] \
					[get_bd_intf_pins axis_ic_xgbe_mac_tx_arb/S01_AXIS]

  connect_bd_intf_net -intf_net router_mac_axis_tx [get_bd_intf_pins router_mac_axis_tx] \
					[get_bd_intf_pins axis_ic_xgbe_mac_tx_arb/M00_AXIS]

  # AXIS IC DoCE Rx
  connect_bd_intf_net -intf_net xgbe_mac_to_doce [get_bd_intf_ports xgbe_mac_to_doce] \
					[get_bd_intf_pins axis_ic_doce_rx/S00_AXIS]

  connect_bd_intf_net -intf_net doce_axis_rxd [get_bd_intf_pins doce_axis_rxd] \
					[get_bd_intf_pins axis_ic_doce_rx/M00_AXIS]

#===========================================
# Other ports
#===========================================
  connect_bd_net [get_bd_ports vfifo_s2mm_channel_full] [get_bd_pins axi_vfifo/vfifo_s2mm_channel_full] 
  connect_bd_net [get_bd_ports vfifo_mm2s_channel_full] [get_bd_pins axi_vfifo/vfifo_mm2s_channel_full] 

  connect_bd_net [get_bd_ports axis_ic_vfifo_in_s00_req_suppress] [get_bd_pins axis_ic_vfifo_in/S00_ARB_REQ_SUPPRESS]
  connect_bd_net [get_bd_ports axis_ic_vfifo_in_s01_req_suppress] [get_bd_pins axis_ic_vfifo_in/S01_ARB_REQ_SUPPRESS]
  connect_bd_net [get_bd_ports axis_ic_vfifo_in_s02_req_suppress] [get_bd_pins axis_ic_vfifo_in/S02_ARB_REQ_SUPPRESS]
  connect_bd_net [get_bd_ports axis_ic_vfifo_in_s03_req_suppress] [get_bd_pins axis_ic_vfifo_in/S03_ARB_REQ_SUPPRESS]
  connect_bd_net [get_bd_ports axis_ic_vfifo_in_s04_req_suppress] [get_bd_pins axis_ic_vfifo_in/S04_ARB_REQ_SUPPRESS]
  connect_bd_net [get_bd_ports axis_ic_vfifo_in_s05_req_suppress] [get_bd_pins axis_ic_vfifo_in/S05_ARB_REQ_SUPPRESS]

  connect_bd_net [get_bd_ports axis_ic_vfifo_out_m00_data_cnt] [get_bd_pins axis_ic_vfifo_out/M00_AXIS_WR_DATA_COUNT]
  connect_bd_net [get_bd_ports axis_ic_vfifo_out_m01_data_cnt] [get_bd_pins axis_ic_vfifo_out/M01_AXIS_WR_DATA_COUNT]
  connect_bd_net [get_bd_ports axis_ic_vfifo_out_m02_data_cnt] [get_bd_pins axis_ic_vfifo_out/M02_AXIS_WR_DATA_COUNT]

  set const_gnd [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_gnd ]
  set_property -dict [ list CONFIG.CONST_VAL {0} ] $const_gnd

  connect_bd_net [get_bd_pins const_gnd/dout] \
					[get_bd_pins axis_ic_xgbe_mac_tx_arb/S00_ARB_REQ_SUPPRESS] \
					[get_bd_pins axis_ic_xgbe_mac_tx_arb/S01_ARB_REQ_SUPPRESS]

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()

##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
