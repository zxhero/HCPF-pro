# Board Design Automative Generation Script
# File Name: deoi_based_armv7_server_node_bd.tcl

# CHANGE DESIGN NAME HERE
set design_name deoi_soc_component 

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
set bd_prefix deoi_soc_component_
set bd_src_base ./${::proj_dir}/${::design}.srcs/sources_1/bd/deoi_soc_component
set ip_repo_base ../../../../../../../../sources/ip_catalog

proc change_ip_config_file { ip_name } {
	exec mkdir -p ../sources/ip_catalog/${::bd_prefix}${ip_name}
	exec cp ${::bd_src_base}/ip/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci \
		../sources/ip_catalog/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci
	exec rm -f ${::bd_src_base}/ip/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci
	exec ln -s ${::ip_repo_base}/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci \
		${::bd_src_base}/ip/${::bd_prefix}${ip_name}/${::bd_prefix}${ip_name}.xci 
}

proc change_mig_config_file { ip_name } {
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

  # Create instance: AXI DMA engine and related AXI-IC
  set axi_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma ]
  set_property -dict [ list CONFIG.c_include_mm2s_dre {1} \
			CONFIG.c_m_axi_mm2s_data_width {64} \
			CONFIG.c_m_axis_mm2s_tdata_width {64} \
			CONFIG.c_mm2s_burst_size {256} \
			CONFIG.c_m_axi_s2mm_data_width.VALUE_SRC {USER} \
			CONFIG.c_m_axi_s2mm_data_width {64} \
			CONFIG.c_sg_use_stsapp_length {1} \
			CONFIG.c_include_s2mm_dre {1} \
			CONFIG.c_s2mm_burst_size {256} \
			CONFIG.c_sg_include_stscntrl_strm {0} \
			CONFIG.c_sg_use_stsapp_length {0} ] $axi_dma

  set axi_ic_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_dma ]
  set_property -dict [ list CONFIG.NUM_MI {1} \
			CONFIG.NUM_SI {3} \
			CONFIG.S00_HAS_DATA_FIFO {2} \
			CONFIG.S01_HAS_DATA_FIFO {2} \
			CONFIG.S02_HAS_DATA_FIFO {2} \
			CONFIG.STRATEGY {2} \
			CONFIG.S00_HAS_REGSLICE {1} ] $axi_ic_dma

  # Create instance: memory_interface_generator for DDR3 memory in programmable logic
  set mig_pl_ddr3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:2.4 mig_pl_ddr3 ]

  exec ln -s ${::ip_repo_base}/${::bd_prefix}mig_pl_ddr3_0/mig_a.prj \
			${::bd_src_base}/ip/${::bd_prefix}mig_pl_ddr3_0/mig_a.prj

  set_property -dict [ list CONFIG.XML_INPUT_FILE {mig_a.prj} ] $mig_pl_ddr3

  # Create instance: Zynq Processing System
  set armv7_ps [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 armv7_processing_system ]
  set_property -dict [ list CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {800} \
				CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {200} \
				CONFIG.PCW_USE_M_AXI_GP1 {1} \
				CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {1} \
				CONFIG.PCW_M_AXI_GP1_ENABLE_STATIC_REMAP {1} \
				CONFIG.PCW_USE_S_AXI_HP0 {1} \
				CONFIG.PCW_USE_S_AXI_ACP {0} \
				CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} \
				CONFIG.PCW_USE_DEFAULT_ACP_USER_VAL {1} \
				CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
				CONFIG.PCW_IRQ_F2P_INTR {1} \
				CONFIG.preset {ZC706} ] $armv7_ps 

  # Create instance: axi_ic for the GP0 port of Zynq Processing System
  set axi_ic_ps_gp0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_ps_gp0 ]
  set_property -dict [ list CONFIG.NUM_MI {2} \
				CONFIG.NUM_SI {1} \
				CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
				CONFIG.XBAR_DATA_WIDTH.VALUE_SRC {USER} \
				CONFIG.M00_HAS_REGSLICE {1} ] $axi_ic_ps_gp0

  set axi_ic_mig [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_mig ]
  set_property -dict [ list CONFIG.NUM_MI {1} \
				CONFIG.NUM_SI {3} \
				CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
				CONFIG.XBAR_DATA_WIDTH.VALUE_SRC {USER} \
				CONFIG.XBAR_DATA_WIDTH {512} ] $axi_ic_mig

  # Create instance: axi_ic for memory-mapped I/O registers (AXI_DMA and DoCE engine)
  set axi_ic_mmio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_mmio ]
  set_property -dict [ list CONFIG.NUM_MI {3} \
				CONFIG.NUM_SI {1} \
				CONFIG.S00_HAS_REGSLICE {1} \
				CONFIG.S01_HAS_REGSLICE {1} ] $axi_ic_mmio

  # Create instance: AXI protocol converter
  set axi_to_lite_pc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_to_lite_pc ]
  set_property -dict [ list CONFIG.SI_PROTOCOL.VALUE_SRC {USER} \
				CONFIG.MI_PROTOCOL.VALUE_SRC {USER} ] $axi_to_lite_pc

  set axi3_to_axi4_pc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi3_to_axi4_pc ]
  set_property -dict [ list CONFIG.SI_PROTOCOL.VALUE_SRC {USER} \
				CONFIG.SI_PROTOCOL {AXI3} \
				CONFIG.MI_PROTOCOL.VALUE_SRC {USER} \
				CONFIG.MI_PROTOCOL {AXI4} ] $axi3_to_axi4_pc

  # Create instance: AXI register slice
  set axi_32_to_64_dc_sg [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_32_to_64_dc_sg ]
  set_property -dict [ list CONFIG.SI_DATA_WIDTH {USER} \
				CONFIG.SI_DATA_WIDTH {32} \
				CONFIG.MI_DATA_WIDTH {USER} \
				CONFIG.MI_DATA_WIDTH {64} ] $axi_32_to_64_dc_sg

#=============================================
# ARMv7 Processing System (PS) ports
#=============================================
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 PS_DDR3
  create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO
  
#=============================================
# Clock ports
#=============================================
  # System single-end reference clock
  set ref_clk [ create_bd_port -dir I -type clk ref_clk ]
  set_property -dict [ list CONFIG.CLK_DOMAIN {ref_clk} \
				CONFIG.FREQ_HZ {200000000} \
				CONFIG.PHASE {0.000}  ] $ref_clk

  # PL MIG output ui clk
  create_bd_port -dir O -type clk mcb_clk

  # PS FCLK0 output
  create_bd_port -dir O -type clk ps_fclk_clk0_out
  set ps_fclk_clk0 [ create_bd_port -dir I -type clk ps_fclk_clk0 ]
  set_property -dict [ list CONFIG.CLK_DOMAIN {deoi_soc_component_armv7_processing_system_0_FCLK_CLK0} \
				CONFIG.FREQ_HZ {200000000} \
				CONFIG.PHASE {0.000} ] $ps_fclk_clk0

#==============================================
# Reset ports
#==============================================
  #PL system reset using PS-PL user_reset_n signal
  create_bd_port -dir O -type rst ps_user_reset_n

  # Synchronous dma reset signal
  create_bd_port -dir I -type rst axi_dma_reset_n 
  set_property CONFIG.ASSOCIATED_RESET {axi_dma_reset_n} [get_bd_ports ps_fclk_clk0]

  # MIG AXI related reset signal
  set mig_pl_ddr3_reset [ create_bd_port -dir I -type rst mig_pl_ddr3_reset ]
  set_property -dict [ list CONFIG.POLARITY {ACTIVE_HIGH} ] $mig_pl_ddr3_reset

  create_bd_port -dir O -type rst mig_ic_resetn

  # AXI DMA Tx/Rx interface reset signal
  create_bd_port -dir O -type rst axi_dma_mm2s_resetn
  create_bd_port -dir O -type rst axi_dma_s2mm_resetn

#==============================================
# Export AXI Interface
#==============================================
  # Connect to DoCE AXI master
  set doce_axi_master [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 doce_axi_master ]
  set_property -dict [ list CONFIG.ID_WIDTH {10} ] $doce_axi_master

  # Connect to VFIFO AXI master
  set network_path_vfifo_axi_master [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 network_path_vfifo_axi_master ]
  set_property -dict [ list CONFIG.ID_WIDTH {3} \
			CONFIG.DATA_WIDTH {512} ] $network_path_vfifo_axi_master

  # Connect to Dev MAC address register slice
  set m_axi_dev_mac [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dev_mac ]
  set_property -dict [ list CONFIG.PROTOCOL {AXI4Lite} ] $m_axi_dev_mac

  # Connect to DoCE AXI-Lite slave
  set doce_axi_lite_slave [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 doce_axi_lite_slave ]
  set_property -dict [ list CONFIG.PROTOCOL {AXI4Lite} ] $doce_axi_lite_slave

  # Connect to DoCE AXI slave
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 doce_axi_slave

  set_property CONFIG.ASSOCIATED_BUSIF {doce_axi_master:network_path_vfifo_axi_master:doce_axi_lite_slave:doce_axi_slave} \
			[get_bd_ports mcb_clk]

#==============================================
# Exported AXI-STREAM interface
#==============================================
  set axi_dma_str_rxd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 axi_dma_str_rxd ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
			CONFIG.HAS_TLAST {1} \
			CONFIG.HAS_TKEEP {1} ] $axi_dma_str_rxd
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 axi_dma_str_txd

  set_property CONFIG.ASSOCIATED_BUSIF {axi_dma_str_txd:axi_dma_str_rxd:m_axi_dev_mac} \
			[get_bd_ports ps_fclk_clk0]

#==============================================
# Other ports
#==============================================
  # PL DDR3 related signals
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 PL_DDR3
  create_bd_port -dir O mig_calib_done

#=============================================
# System clock connection
#=============================================
  connect_bd_net -net armv7_ps_fclk_0_out [get_bd_pin armv7_processing_system/FCLK_CLK0] [get_bd_pins ps_fclk_clk0_out]
  
  connect_bd_net -net mcb_clk [get_bd_pins mig_pl_ddr3/ui_clk] [get_bd_pins mcb_clk]

  # MIG reference clk and system clk
  connect_bd_net -net ref_clk [get_bd_pins ref_clk] \
			[get_bd_pins mig_pl_ddr3/sys_clk_i] \
			[get_bd_pins mig_pl_ddr3/clk_ref_i]

  # AXI DMA engine is driven by PS FCLK0
  connect_bd_net -net armv7_ps_fclk_0 [get_bd_pins ps_fclk_clk0] \
			[get_bd_pins axi_dma/*aclk]

  # ARMv7 Processing System clock
  connect_bd_net -net mcb_clk [get_bd_pins mcb_clk] \
			[get_bd_pins armv7_processing_system/M_AXI_GP?_ACLK] \
			[get_bd_pins armv7_processing_system/S_AXI_ACP_ACLK] \

  connect_bd_net -net armv7_ps_fclk_0 [get_bd_pins ps_fclk_clk0] \
			[get_bd_pins armv7_processing_system/S_AXI_HP0_ACLK]

  # AXI_IC_PS_GP0
  connect_bd_net -net mcb_clk [get_bd_pins mcb_clk] \
			[get_bd_pins axi_ic_ps_gp0/*ACLK] \
			[get_bd_pins axi_ic_mig/*ACLK] \
			[get_bd_pins axi_to_lite_pc/aclk] \
			[get_bd_pins axi3_to_axi4_pc/aclk]

  # AXI_IC_MMIO clock
  connect_bd_net -net armv7_ps_fclk_0 [get_bd_pins ps_fclk_clk0] \
			[get_bd_pins axi_ic_mmio/M01_ACLK] \
			[get_bd_pins axi_ic_mmio/M02_ACLK]

  connect_bd_net -net mcb_clk [get_bd_pins mcb_clk] \
			[get_bd_pins axi_ic_mmio/ACLK] \
			[get_bd_pins axi_ic_mmio/S00_ACLK] \
			[get_bd_pins axi_ic_mmio/M00_ACLK]

  # AXI_IC_DMA
  connect_bd_net -net armv7_ps_fclk_0 [get_bd_pins ps_fclk_clk0] \
			[get_bd_pins axi_ic_dma/*ACLK] \
			[get_bd_pins axi_32_to_64_dc_sg/*aclk]

#=============================================
# System reset connection
#=============================================
  connect_bd_net -net armv7_ps_fclk_resetn_0 [get_bd_pins armv7_processing_system/FCLK_RESET0_N] [get_bd_pins ps_user_reset_n]

  # AXI DMA and DMA IC reset 
  connect_bd_net -net axi_dma_reset_n [get_bd_pins axi_dma_reset_n] \
			[get_bd_pins axi_dma/axi_resetn] \
			[get_bd_pins axi_ic_dma/*aresetn] \
			[get_bd_pins axi_32_to_64_dc_sg/*aresetn]

  # PL DDR3 MIG async reset signal
  connect_bd_net -net mig_pl_ddr3_reset [get_bd_pins mig_pl_ddr3_reset] [get_bd_pins mig_pl_ddr3/sys_rst]

  # PL DDR3 AXI Interface reset
  set mig_ic_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram:12.0 mig_ic_reset]
  set_property -dict [ list CONFIG.Width.VALUE_SRC {USER} \
			CONFIG.Width {1} \
			CONFIG.Depth {2} \
			CONFIG.DefaultData {0} \
			CONFIG.AsyncInitVal {0} \
			CONFIG.SyncInitVal {0} ] $mig_ic_reset

  connect_bd_net -net mcb_clk [get_bd_pins mcb_clk] [get_bd_pins mig_ic_reset/CLK]
  connect_bd_net -net mig_calib_done [get_bd_pins mig_pl_ddr3/init_calib_complete] [get_bd_pins mig_ic_reset/D] [get_bd_pins mig_calib_done]
  connect_bd_net -net mig_ic_reset_n [get_bd_pins mig_ic_reset/Q] [get_bd_pins mig_pl_ddr3/aresetn]

  #AXI_IC_PS_GP0 reset signals
  connect_bd_net -net mig_ic_reset_n [get_bd_pins mig_ic_reset/Q] \
			[get_bd_pins axi_ic_ps_gp0/*ARESETN] \
			[get_bd_pins axi_ic_mig/*ARESETN] \
			[get_bd_pins axi_to_lite_pc/aresetn] \
			[get_bd_pins axi3_to_axi4_pc/aresetn] \
			[get_bd_ports mig_ic_resetn]

  # AXI_IC_MMIO reset signal
  connect_bd_net -net axi_dma_reset_n [get_bd_pins axi_dma_reset_n] \
			[get_bd_pins axi_ic_mmio/M01_ARESETN] \
			[get_bd_pins axi_ic_mmio/M02_ARESETN]

  connect_bd_net -net mig_ic_reset_n [get_bd_pins mig_ic_reset/Q] \
			[get_bd_pins axi_ic_mmio/ARESETN] \
			[get_bd_pins axi_ic_mmio/S00_ARESETN] \
			[get_bd_pins axi_ic_mmio/M00_ARESETN]

#==============================================
# AXI Interface Connection
#==============================================
  # AXI DMA with AXI DMA IC and PS HP0
  connect_bd_intf_net -intf_net axi_dma_m_axi_sg [get_bd_intf_pins axi_dma/M_AXI_SG] [get_bd_intf_pins axi_32_to_64_dc_sg/S_AXI]
  connect_bd_intf_net -intf_net axi_dma_m_axi_sg_dc [get_bd_intf_pins axi_32_to_64_dc_sg/M_AXI] [get_bd_intf_pins axi_ic_dma/S00_AXI]

  connect_bd_intf_net -intf_net axi_dma_m_axi_mm2s [get_bd_intf_pins axi_dma/M_AXI_MM2S] [get_bd_intf_pins axi_ic_dma/S01_AXI]
  connect_bd_intf_net -intf_net axi_dma_m_axi_s2mm [get_bd_intf_pins axi_dma/M_AXI_S2MM] [get_bd_intf_pins axi_ic_dma/S02_AXI]
  connect_bd_intf_net -intf_net armv7_ps_S_AXI_HP0 [get_bd_intf_pins axi_ic_dma/M00_AXI] [get_bd_intf_pins armv7_processing_system/S_AXI_HP0]

  # PS GP0 AXI IC
  connect_bd_intf_net -intf_net armv7_ps_M_AXI_GP0 [get_bd_intf_pins axi_ic_ps_gp0/S00_AXI] [get_bd_intf_pins armv7_processing_system/M_AXI_GP0] 
  connect_bd_intf_net -intf_net axi_ic_ps_gp0_M00 [get_bd_intf_pins axi_ic_ps_gp0/M00_AXI] [get_bd_intf_pins axi_ic_mig/S01_AXI] 
  connect_bd_intf_net -intf_net axi_ic_ps_gp0_M01 [get_bd_intf_pins axi_ic_ps_gp0/M01_AXI] [get_bd_intf_pins axi_to_lite_pc/S_AXI] 
 
  # MIG AXI IC
  connect_bd_intf_net -intf_net vfifo_axi_master  [get_bd_intf_pins network_path_vfifo_axi_master] [get_bd_intf_pins axi_ic_mig/S00_AXI]
  connect_bd_intf_net -intf_net mig_axi [get_bd_intf_pins axi_ic_mig/M00_AXI] [get_bd_intf_pins mig_pl_ddr3/S_AXI]

  # AXI MMIO IC
  connect_bd_intf_net -intf_net axi_ic_mmio_S00_AXI [get_bd_intf_pins axi_ic_mmio/S00_AXI] [get_bd_intf_pins axi_to_lite_pc/M_AXI]
  connect_bd_intf_net -intf_net axi_ic_mmio_M00_AXI [get_bd_intf_pins axi_ic_mmio/M00_AXI] [get_bd_intf_pins doce_axi_lite_slave]
  connect_bd_intf_net -intf_net axi_ic_mmio_M01_AXI [get_bd_intf_pins axi_ic_mmio/M01_AXI] [get_bd_intf_pins axi_dma/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_ic_mmio_M02_AXI [get_bd_intf_pins axi_ic_mmio/M02_AXI] [get_bd_intf_pins m_axi_dev_mac]

  # DoCE slave interface
  connect_bd_intf_net -intf_net armv7_ps_M_AXI_GP1 [get_bd_intf_pins armv7_processing_system/M_AXI_GP1] [get_bd_intf_pins axi3_to_axi4_pc/S_AXI]
  connect_bd_intf_net -intf_net doce_axi_slave [get_bd_intf_pins doce_axi_slave] [get_bd_intf_pins axi3_to_axi4_pc/M_AXI]
  
  # AXI IC DoCE master
  connect_bd_intf_net -intf_net doce_axi_master [get_bd_intf_ports doce_axi_master] [get_bd_intf_pins axi_ic_mig/S02_AXI]

#=============================================
# Interrupt signal connection
#=============================================
  # Create instance: concat_intr, and set properties
  set concat_intr [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_intr ]
  set_property -dict [ list CONFIG.NUM_PORTS {2} ] $concat_intr
	  
  connect_bd_net [get_bd_pins axi_dma/s2mm_introut] [get_bd_pins concat_intr/In0]
  connect_bd_net [get_bd_pins axi_dma/mm2s_introut] [get_bd_pins concat_intr/In1]
  connect_bd_net [get_bd_pins concat_intr/dout] [get_bd_pins armv7_processing_system/IRQ_F2P]

#=============================================
# AXI DMA connection
#=============================================
  connect_bd_intf_net -intf_net axi_dma_str_rxd [get_bd_intf_pins axi_dma/S_AXIS_S2MM] [get_bd_intf_pins axi_dma_str_rxd]
  connect_bd_intf_net -intf_net axi_dma_str_txd [get_bd_intf_pins axi_dma/M_AXIS_MM2S] [get_bd_intf_pins axi_dma_str_txd]

  connect_bd_net -net axi_dma_mm2s_prmry_reset [get_bd_pins axi_dma/mm2s_prmry_reset_out_n] [get_bd_pins axi_dma_mm2s_resetn]
  connect_bd_net -net axi_dma_s2mm_prmry_reset [get_bd_pins axi_dma/s2mm_prmry_reset_out_n] [get_bd_pins axi_dma_s2mm_resetn]

#=============================================
# PL DDR connection
#=============================================
  connect_bd_intf_net [get_bd_intf_pins PL_DDR3] [get_bd_intf_pins mig_pl_ddr3/DDR3]

  set device_temp [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 device_temp ]
  set_property -dict [ list CONFIG.CONST_VAL {0} \
					CONFIG.CONST_WIDTH {12} ] $device_temp

  connect_bd_net [get_bd_pins mig_pl_ddr3/device_temp_i] [get_bd_pins device_temp/dout]

#=============================================
# ARMv7 Processing System connection
#=============================================
  connect_bd_intf_net [get_bd_intf_pins PS_DDR3] [get_bd_intf_pins armv7_processing_system/DDR]
  connect_bd_intf_net [get_bd_intf_pins FIXED_IO] [get_bd_intf_pins armv7_processing_system/FIXED_IO]

#=============================================
# Create address segments
#=============================================
  # AXI DMA Master address space
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma/Data_SG] [get_bd_addr_segs armv7_processing_system/S_AXI_HP0/HP0_DDR_LOWOCM] AXI_DMA_SG
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma/Data_MM2S] [get_bd_addr_segs armv7_processing_system/S_AXI_HP0/HP0_DDR_LOWOCM] AXI_DMA_MM2S
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma/Data_S2MM] [get_bd_addr_segs armv7_processing_system/S_AXI_HP0/HP0_DDR_LOWOCM] AXI_DMA_S2MM

  # PL DDR3
  create_bd_addr_seg -range 0x20000000 -offset 0x40000000 [get_bd_addr_spaces armv7_processing_system/Data] [get_bd_addr_segs mig_pl_ddr3/memmap/memaddr] PS_VIEW_MIG
  create_bd_addr_seg -range 0x10000000 -offset 0x60000000 [get_bd_addr_spaces network_path_vfifo_axi_master] [get_bd_addr_segs mig_pl_ddr3/memmap/memaddr] VFIFO_VIEW_MIG

  # PS GP1
  create_bd_addr_seg -range 0x40000000 -offset 0x80000000 [get_bd_addr_spaces armv7_processing_system/Data] [get_bd_addr_segs doce_axi_slave/Reg] PS_GP1_DEOI

  # MMIO registers
  create_bd_addr_seg -range 0x400000 -offset 0x70000000 [get_bd_addr_spaces armv7_processing_system/Data] [get_bd_addr_segs doce_axi_lite_slave/Reg] PS_VIEW_DEOI_MMIO
  create_bd_addr_seg -range 0x10000 -offset 0x70400000 [get_bd_addr_spaces armv7_processing_system/Data] [get_bd_addr_segs axi_dma/S_AXI_LITE/Reg] PS_VIEW_AXI_DMA
  create_bd_addr_seg -range 0x1000 -offset 0x70440000 [get_bd_addr_spaces armv7_processing_system/Data] [get_bd_addr_segs m_axi_dev_mac/Reg] PS_VIEW_DEV_MAC

  # DEOI master interface
  create_bd_addr_seg -range 0x20000000 -offset 0x40000000 [get_bd_addr_spaces doce_axi_master] [get_bd_addr_segs mig_pl_ddr3/memmap/memaddr] DOCE_PL_MEM

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()

##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
