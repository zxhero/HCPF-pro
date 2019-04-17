# Board Design Automative Generation Script
# File Name: deoi_based_armv7_server_node_bd.tcl

# CHANGE DESIGN NAME HERE
set design_name mac_addr_reg_arb 

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
set bd_prefix mac_addr_reg_arb_
set bd_src_base ./${::proj_dir}/${::design}.srcs/sources_1/bd/mac_addr_reg_arb
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

  set axi_ic_mac_addr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_mac_addr ]
  set_property -dict [ list CONFIG.NUM_MI {1} \
			CONFIG.NUM_SI {3} \
			CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
			CONFIG.XBAR_DATA_WIDTH.VALUE_SRC {USER} ] $axi_ic_mac_addr

#=====================================
# Copy IP configuration files to local repository
#=====================================
  
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
  create_bd_port -dir I -type rst pcie_dma_user_resetn
  set_property CONFIG.ASSOCIATED_RESET {pcie_dma_user_resetn} \
				[get_bd_ports pcie_clk_250]

  # AXI DMA MM2S/S2MM channel reset 					
  create_bd_port -dir I -type rst axi_dma_resetn
  set_property CONFIG.ASSOCIATED_RESET {axi_dma_resetn} \
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
  # AXI DMA AXI-Lite
  set m_axi_dev_mac [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dev_mac ]
  set_property -dict [ list CONFIG.PROTOCOL {AXI4Lite} ] $m_axi_dev_mac

  set_property CONFIG.ASSOCIATED_BUSIF {m_axi_dev_mac} \
			[get_bd_ports ps_fclk_clk0]

  # PCIe DMA AXI-Lite 
  set pcie_dma_axi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 pcie_dma_axi ]
  set_property -dict [ list CONFIG.PROTOCOL {AXI4Lite} ] $pcie_dma_axi

  set_property CONFIG.ASSOCIATED_BUSIF {pcie_dma_axi} \
			[get_bd_ports pcie_clk_250]

  # DoCE AXI-Lite 
  set m_axi_doce_mac [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_doce_mac ]
  set_property -dict [ list CONFIG.PROTOCOL {AXI4Lite} ] $m_axi_doce_mac

  set_property CONFIG.ASSOCIATED_BUSIF {m_axi_doce_mac} \
			[get_bd_ports mcb_clk]

  # AXI-Lite to MAC address register
  set s_axi_lite_mac [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_lite_mac ]
  set_property -dict [ list CONFIG.PROTOCOL {AXI4Lite} ] $s_axi_lite_mac

  set_property CONFIG.ASSOCIATED_BUSIF {s_axi_lite_mac} \
			[get_bd_ports xgemac_clk_156]

#=============================================
# System clock connection
#=============================================

  connect_bd_net -net xgemac_clk_156 [get_bd_pins xgemac_clk_156] \
			[get_bd_pins axi_ic_mac_addr/ACLK] \
			[get_bd_pins axi_ic_mac_addr/M00_ACLK]

  connect_bd_net -net pcie_clk_250 [get_bd_pins pcie_clk_250] \
			[get_bd_pins axi_ic_mac_addr/S00_ACLK]

  connect_bd_net -net ps_fclk_clk0 [get_bd_pins ps_fclk_clk0] \
			[get_bd_pins axi_ic_mac_addr/S01_ACLK]

  connect_bd_net -net mcb_clk [get_bd_pins mcb_clk] \
			[get_bd_pins axi_ic_mac_addr/S02_ACLK]

#=============================================
# System reset connection
#=============================================
  connect_bd_net -net xgbe_mac_resetn [get_bd_pins xgbe_mac_resetn] \
			[get_bd_pins axi_ic_mac_addr/ARESETN] \
			[get_bd_pins axi_ic_mac_addr/M00_ARESETN]

  connect_bd_net -net pcie_dma_user_resetn [get_bd_pins pcie_dma_user_resetn] \
			[get_bd_pins axi_ic_mac_addr/S00_ARESETN]

  connect_bd_net -net axi_dma_resetn [get_bd_pins axi_dma_resetn] \
			[get_bd_pins axi_ic_mac_addr/S01_ARESETN]

  connect_bd_net -net mig_ic_resetn [get_bd_pins mig_ic_resetn] \
			[get_bd_pins axi_ic_mac_addr/S02_ARESETN]

#==============================================
# AXI Interface Connection
#==============================================
  # AXI DMA with AXI DMA IC and PS HP0
  connect_bd_intf_net -intf_net s_axi_lite_mac [get_bd_intf_pins s_axi_lite_mac] [get_bd_intf_pins axi_ic_mac_addr/M00_AXI]
  connect_bd_intf_net -intf_net pcie_dma_axi_pc [get_bd_intf_pins pcie_dma_axi] [get_bd_intf_pins axi_ic_mac_addr/S00_AXI]
  connect_bd_intf_net -intf_net m_axi_dev_mac [get_bd_intf_pins m_axi_dev_mac] [get_bd_intf_pins axi_ic_mac_addr/S01_AXI]
  connect_bd_intf_net -intf_net m_axi_doce_mac [get_bd_intf_pins m_axi_doce_mac] [get_bd_intf_pins axi_ic_mac_addr/S02_AXI]

#=============================================
# Create address segments
#=============================================
  create_bd_addr_seg -range 0x1000 -offset 0x70440000 [get_bd_addr_spaces m_axi_dev_mac] [get_bd_addr_segs s_axi_lite_mac/Reg] DEV_MAC_ADDR
  create_bd_addr_seg -range 0x1000 -offset 0x9000 [get_bd_addr_spaces pcie_dma_axi] [get_bd_addr_segs s_axi_lite_mac/Reg] HOST_MAC_ADDR
  create_bd_addr_seg -range 0x1000 -offset 0x1000 [get_bd_addr_spaces m_axi_doce_mac] [get_bd_addr_segs s_axi_lite_mac/Reg] DOCE_MAC_ADDR

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()

##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
