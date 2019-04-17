# Board Design Automative Generation Script
# File Name: deoi_based_armv7_server_node_bd.tcl

# CHANGE DESIGN NAME HERE
set design_name pcie_xgbe_component

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
set bd_prefix pcie_xgbe_component_
set bd_src_base ./${::proj_dir}/${::design}.srcs/sources_1/bd/pcie_xgbe_component
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

  # Create instance: PCIe End Point (EP)
  set pcie_ep [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_7x:3.2 pcie_ep ]
  set_property -dict [ list CONFIG.Bar0_Scale {Kilobytes} \
				CONFIG.Bar0_Size {64} \
				CONFIG.Base_Class_Menu {Simple_communication_controllers} \
				CONFIG.Buf_Opt_BMA {true} \
				CONFIG.Class_Code_Base {07} \
				CONFIG.Device_ID {7042} \
				CONFIG.Link_Speed {5.0_GT/s} \
				CONFIG.Maximum_Link_Width {X4} \
				CONFIG.PCIe_Debug_Ports {false} \
				CONFIG.Pcie_fast_config {None} \
				CONFIG.Sub_Class_Interface_Menu {Other_communications_device} \
				CONFIG.Trgt_Link_Speed {4'h2} \
				CONFIG.Use_Class_Code_Lookup_Assistant {true} \
				CONFIG.User_Clk_Freq {250} \
				CONFIG.Xlnx_Ref_Board {ZC706} \
				CONFIG.cfg_mgmt_if {false} \
				CONFIG.en_ext_clk {false} \
				CONFIG.mode_selection {Advanced} \
				CONFIG.pl_interface {false} \
				CONFIG.rcv_msg_if {false} ] $pcie_ep

  # Create instance: PCIe DMA engine
  set nwl_pcie_dma [ create_bd_cell -type ip -vlnv nwlogic.com:ip:NWL_AXI_DMA:1.01 nwl_pcie_dma ]

  # Create instance: XGBE MAC and PHY 
  set xgbe_mac [ create_bd_cell -type ip -vlnv xilinx.com:ip:ten_gig_eth_mac:15.0 xgbe_mac ]
  set_property -dict [ list CONFIG.Management_Frequency {156.25} ] $xgbe_mac
	
  set xgbe_phy [ create_bd_cell -type ip -vlnv xilinx.com:ip:ten_gig_eth_pcs_pma:6.0 xgbe_phy ]
  set_property -dict [ list CONFIG.SupportLevel {1} \
				CONFIG.DClkRate {50.00} ] $xgbe_phy

#=============================================
# Clock ports
#=============================================

  # GT single-end reference clock from SFP+ cage
  set gt_ref_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_ref_clk ]
  set_property -dict [ list CONFIG.FREQ_HZ {156250000} ] $gt_ref_clk

  # PCIe EP reference clock
  set pcie_ref_clk [ create_bd_port -dir I -type clk pcie_ref_clk ]
  set_property -dict [ list CONFIG.CLK_DOMAIN {pcie_ref_clk} \
				CONFIG.FREQ_HZ {100000000} \
				CONFIG.PHASE {0.000} ] $pcie_ref_clk

  # XGBE MAC user interface clock
  set xgemac_clk_156 [ create_bd_port -dir O -type clk xgemac_clk_156 ]
  set_property -dict [ list CONFIG.FREQ_HZ {156250000} ] $xgemac_clk_156

  # PCIe DMA S2C_0 and C2S_0 interface clock
  set pcie_clk_250 [ create_bd_port -dir O -type clk pcie_clk_250 ]
  set_property -dict [ list CONFIG.FREQ_HZ {250000000} ] $pcie_clk_250

  # PS FCLK1 (125MHz) input used as DRP clock
  create_bd_port -dir I -type clk drp_clk

#==============================================
# Reset ports
#==============================================

  # PCIe EP perst
  create_bd_port -dir I -type rst perst_n

  create_bd_port -dir O -type rst pcie_user_reset_out
  create_bd_port -dir I -type rst pcie_dma_user_reset 
  create_bd_port -dir I -type rst pcie_dma_t_areset_n
  set_property CONFIG.ASSOCIATED_RESET {pcie_dma_user_reset:pcie_dma_t_areset_n} \
					[get_bd_ports pcie_clk_250]

  create_bd_port -dir O -type rst pcie_dma_s2c0_aresetn
  create_bd_port -dir O -type rst pcie_dma_c2s0_aresetn

  # XGBE PHY reset
  set xgbe_phy_reset [ create_bd_port -dir I -type rst xgbe_phy_reset ]
  set_property -dict [ list CONFIG.POLARITY {ACTIVE_HIGH} ] $xgbe_phy_reset

  create_bd_port -dir O -type rst xgbe_phy_resetdone

  # XGBE MAC reset
  set xgbe_mac_reset [ create_bd_port -dir I -type rst xgbe_mac_reset ]
  set_property -dict [ list CONFIG.POLARITY {ACTIVE_HIGH} ] $xgbe_mac_reset

  create_bd_port -dir I -type rst xgbe_mac_resetn

  set_property CONFIG.ASSOCIATED_RESET {xgbe_mac_reset:xgbe_mac_resetn} \
					[get_bd_ports xgemac_clk_156]

#==============================================
# SFP ports
#==============================================
  
  # XGBE SFP+ Cage
  create_bd_port -dir I xgbe_phy_rxn
  create_bd_port -dir I xgbe_phy_rxp
  create_bd_port -dir O xgbe_phy_txn
  create_bd_port -dir O xgbe_phy_txp

  # PCIe Slot
  create_bd_port -dir I -from 3 -to 0 pcie_exp_rxn
  create_bd_port -dir I -from 3 -to 0 pcie_exp_rxp
  create_bd_port -dir O -from 3 -to 0 pcie_exp_txn
  create_bd_port -dir O -from 3 -to 0 pcie_exp_txp

#==============================================
# Export AXI Interface
#==============================================

  # XGBE MAC AXI Lite slave interface
  set xgbe_mac_axi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 xgbe_mac_axi ]
  set_property -dict [ list CONFIG.PROTOCOL {AXI4LITE} ] $xgbe_mac_axi

  # PCIe DMA AXI Lite master interface
  set pcie_dma_axi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 pcie_dma_axi ]
  set_property -dict [ list CONFIG.PROTOCOL {AXI3} \
					CONFIG.DATA_WIDTH {64} ] $pcie_dma_axi

#==============================================
# Export AXI-STREAM Interface
#==============================================
  
  # XGBE MAC Tx and Rx interface
  set xgbe_mac_axis_tx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 xgbe_mac_axis_tx ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
					CONFIG.HAS_TLAST {1} \
					CONFIG.HAS_TKEEP {1} ] $xgbe_mac_axis_tx

  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 xgbe_mac_axis_rx

  set xgbe_mac_axis_pause [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 xgbe_mac_axis_pause ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {2} \
					CONFIG.HAS_TREADY {0} ] $xgbe_mac_axis_pause

  set_property CONFIG.ASSOCIATED_BUSIF {xgbe_mac_axis_tx:xgbe_mac_axis_rx:xgbe_mac_axis_pause:xgbe_mac_axi} \
					[get_bd_ports xgemac_clk_156]

  # PCIe backend DMA engine Tx and Rx interface
  set pcie_dma_axis_rx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_dma_axis_rx ]
  set_property -dict [ list CONFIG.TDATA_NUM_BYTES {8} \
					CONFIG.HAS_TLAST {1} \
					CONFIG.HAS_TKEEP {1} ] $pcie_dma_axis_rx

  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_dma_axis_tx
  set_property CONFIG.ASSOCIATED_BUSIF {pcie_dma_axis_rx:pcie_dma_axis_tx:pcie_dma_axi} \
					[get_bd_ports pcie_clk_250]

#==============================================
# Other ports
#==============================================
  # XGBE MAC and PHY
  create_bd_port -dir I -from 4 -to 0 xgbe_phy_prtad
  create_bd_port -dir I -from 2 -to 0 xgbe_phy_pma_pmd_type
  create_bd_port -dir O -from 7 -to 0 xgbe_phy_core_status

  create_bd_port -dir I -from 7 -to 0 xgbe_mac_tx_ifg_delay
  create_bd_intf_port -mode Master -vlnv xilinx.com:display_ten_gig_eth_mac:statistics_rtl:2.0 xgbe_mac_rx_statistics

  # PCIe EP and backend DMA
  create_bd_port -dir O pcie_ep_user_lnk_up
  create_bd_port -dir I pcie_dma_user_lnk_up

  create_bd_port -dir I -from 63 -to 0 pcie_cfg_dsn
  create_bd_port -dir I -from 1 -to 0 pcie_cfg_pm_force_state
  create_bd_port -dir I -from 4 -to 0 pcie_cfg_ds_device_number
  create_bd_port -dir I -from 4 -to 0 pcie_cfg_pciecap_interrupt_msgnum
  create_bd_port -dir I -from 7 -to 0 pcie_cfg_ds_bus_number
  create_bd_port -dir I -from 2 -to 0 pcie_cfg_ds_function_number
  create_bd_port -dir I -from 127 -to 0 pcie_cfg_err_aer_headerlog

#=============================================
# System clock connection
#=============================================

  #XGBE MAC and PHY clock
  connect_bd_intf_net -intf_net gt_ref_clk [get_bd_intf_pins gt_ref_clk] [get_bd_intf_pins xgbe_phy/refclk_diff_port]

  connect_bd_net -net xgemac_clk_156 [get_bd_pins xgbe_phy/coreclk_out] \
					[get_bd_pins xgemac_clk_156] \
					[get_bd_pins xgbe_mac/tx_clk0] \
					[get_bd_pins xgbe_mac/rx_clk0] \
					[get_bd_pins xgbe_mac/s_axi_aclk]

  #Using PS FCLK CLK1 as the DRP clock of XGBE PHY
  connect_bd_net -net drp_clk [get_bd_pins drp_clk] [get_bd_pins xgbe_phy/dclk]

  # PCIe EP reference clock
  connect_bd_net -net pcie_ep_sys_clk [get_bd_pins pcie_ref_clk] [get_bd_pins pcie_ep/sys_clk]

  # PCIe EP user clock
  connect_bd_net -net pcie_clk_250 [get_bd_pins pcie_ep/user_clk_out] \
					[get_bd_pins nwl_pcie_dma/user_clk] \
					[get_bd_pins nwl_pcie_dma/*aclk] \
					[get_bd_pins pcie_clk_250]

#=============================================
# System reset connection
#=============================================

  # XGBE MAC and PHY reset
  connect_bd_net -net xgbe_phy_resetdone [get_bd_pins xgbe_phy_resetdone] \
					[get_bd_pins xgbe_phy/resetdone_out]

  connect_bd_net -net xgbe_phy_reset [get_bd_pins xgbe_phy_reset] \
					[get_bd_pins xgbe_phy/reset]

  connect_bd_net -net xgbe_mac_reset [get_bd_pins xgbe_mac_reset] \
					[get_bd_pins xgbe_mac/reset]
  connect_bd_net -net xgbe_mac_resetn [get_bd_pins xgbe_mac_resetn] \
					[get_bd_pins xgbe_mac/*aresetn]

  # PCIe EP reset
  connect_bd_net -net perst_n [get_bd_pins perst_n] [get_bd_pins pcie_ep/sys_rst_n]

  # PCIe backend DMA reset
  connect_bd_net -net pcie_user_reset_out [get_bd_pins pcie_user_reset_out] \
					[get_bd_pins pcie_ep/user_reset_out]
	
  connect_bd_net -net pcie_dma_user_reset [get_bd_pins pcie_dma_user_reset] \
					[get_bd_pins nwl_pcie_dma/user_reset]
  connect_bd_net -net pcie_dma_t_areset_n [get_bd_pins pcie_dma_t_areset_n] \
					[get_bd_pins nwl_pcie_dma/t_areset_n]

  connect_bd_net -net s2c0_aresetn [get_bd_ports pcie_dma_s2c0_aresetn] [get_bd_pins nwl_pcie_dma/s2c0_areset_n]
  connect_bd_net -net c2s0_aresetn [get_bd_ports pcie_dma_c2s0_aresetn] [get_bd_pins nwl_pcie_dma/c2s0_areset_n]

#==============================================
# AXI Interface Connection
#==============================================
  connect_bd_intf_net -intf_net xgbe_mac_axi [get_bd_intf_pins xgbe_mac_axi] [get_bd_intf_pins xgbe_mac/s_axi]
  connect_bd_intf_net -intf_net pcie_dma_axi [get_bd_intf_pins pcie_dma_axi] [get_bd_intf_pins nwl_pcie_dma/t]

#==============================================
# AXI-Stream Interface
#==============================================

  # XGBE MAC Tx and Rx
  connect_bd_intf_net -intf_net xgbe_mac_axis_tx [get_bd_intf_pins xgbe_mac_axis_tx] [get_bd_intf_pins xgbe_mac/s_axis_tx]
  connect_bd_intf_net -intf_net xgbe_mac_axis_rx [get_bd_intf_pins xgbe_mac_axis_rx] [get_bd_intf_pins xgbe_mac/m_axis_rx]

  # PCIe backend Tx and Rx
  connect_bd_intf_net -intf_net pcie_dma_axis_tx [get_bd_intf_pins pcie_dma_axis_tx] [get_bd_intf_pins nwl_pcie_dma/s2c0]
  connect_bd_intf_net -intf_net pcie_dma_axis_rx [get_bd_intf_pins pcie_dma_axis_rx] [get_bd_intf_pins nwl_pcie_dma/c2s0]

#==============================================
# GT Port
#==============================================

  # SFP+ cage
  connect_bd_net -net xgbe_phy_rxn [get_bd_ports xgbe_phy_rxn] [get_bd_pins xgbe_phy/rxn]
  connect_bd_net -net xgbe_phy_rxp [get_bd_ports xgbe_phy_rxp] [get_bd_pins xgbe_phy/rxp]
  connect_bd_net -net xgbe_phy_txn [get_bd_ports xgbe_phy_txn] [get_bd_pins xgbe_phy/txn]
  connect_bd_net -net xgbe_phy_txp [get_bd_ports xgbe_phy_txp] [get_bd_pins xgbe_phy/txp]

  # PCIe slot
  connect_bd_net [get_bd_ports pcie_exp_rxn] [get_bd_pins pcie_ep/pci_exp_rxn]
  connect_bd_net [get_bd_ports pcie_exp_rxp] [get_bd_pins pcie_ep/pci_exp_rxp]
  connect_bd_net [get_bd_ports pcie_exp_txn] [get_bd_pins pcie_ep/pci_exp_txn]
  connect_bd_net [get_bd_ports pcie_exp_txp] [get_bd_pins pcie_ep/pci_exp_txp]

#==============================================
# XGBE MAC and PHY
#==============================================
	
  #XGMII
  connect_bd_intf_net -intf_net deoi_xgbe_xgmii [get_bd_intf_pins xgbe_mac/xgmii_xgmac] [get_bd_intf_pins xgbe_phy/xgmii_interface]

  #MDIO
  connect_bd_intf_net -intf_net deoi_xgbe_mdio [get_bd_intf_pins xgbe_mac/mdio_xgmac] [get_bd_intf_pins xgbe_phy/mdio_interface]
	
  #MISC port
  connect_bd_net -net xgbe_phy_drp [get_bd_pins xgbe_phy/drp_gnt] [get_bd_pins xgbe_phy/drp_req]
  connect_bd_intf_net -intf_net xgbe_phy_gt_drp [get_bd_intf_pins xgbe_phy/user_gt_drp_interface] [get_bd_intf_pins xgbe_phy/core_gt_drp_interface]

  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_vcc
  set const_gnd [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_gnd ]
  set_property -dict [ list CONFIG.CONST_VAL {0} ] $const_gnd

  connect_bd_net -net const_gnd [get_bd_pins const_gnd/dout] [get_bd_pins *xgbe_phy/tx_fault]
  connect_bd_net -net const_vcc [get_bd_pins const_vcc/dout] [get_bd_pins *xgbe_phy/signal_detect]
  connect_bd_net -net xgbe_phy_prtad [get_bd_pins xgbe_phy_prtad] [get_bd_pins xgbe_phy/prtad]
  connect_bd_net -net xgbe_phy_pma_pmd_type [get_bd_pins xgbe_phy_pma_pmd_type] [get_bd_pins xgbe_phy/pma_pmd_type]
  connect_bd_net -net xgbe_phy_core_status [get_bd_pins xgbe_phy_core_status] [get_bd_pins xgbe_phy/core_status]

  connect_bd_net -net const_vcc [get_bd_pins const_vcc/dout] [get_bd_pins *xgbe_mac/*dcm_locked]
  connect_bd_intf_net -intf_net xgbe_mac_rx_static [get_bd_intf_pins xgbe_mac_rx_statistics] \
					[get_bd_intf_pins xgbe_mac/rx_statistics]
  connect_bd_intf_net -intf_net xgbe_mac_pause [get_bd_intf_pins xgbe_mac_axis_pause] \
					[get_bd_intf_pins xgbe_mac/s_axis_pause]
  connect_bd_net -net xgbe_mac_tx_ifg_delay [get_bd_pins xgbe_mac_tx_ifg_delay] \
					[get_bd_pins xgbe_mac/tx_ifg_delay]
  
#==============================================
# PCIe EP and backend DMA 
#==============================================
  # AXI-Stream interface
  connect_bd_intf_net -intf_net pcie_ep_axis_rx [get_bd_intf_pins pcie_ep/m_axis_rx] [get_bd_intf_pins nwl_pcie_dma/s_axis_rx]
  connect_bd_intf_net -intf_net pcie_ep_axis_tx [get_bd_intf_pins pcie_ep/s_axis_tx] [get_bd_intf_pins nwl_pcie_dma/m_axis_tx]

  # Link up status
  connect_bd_net -net pcie_ep_user_link_up [get_bd_ports pcie_ep_user_lnk_up] [get_bd_pins pcie_ep/user_lnk_up]
  connect_bd_net -net pcie_dma_user_link_up [get_bd_ports pcie_dma_user_lnk_up] [get_bd_pins nwl_pcie_dma/user_link_up]

  # PCIe cfg ports
  connect_bd_intf_net -intf_net pcie2_cfg_err [get_bd_intf_pins nwl_pcie_dma/pcie2_cfg_err] [get_bd_intf_pins pcie_ep/pcie2_cfg_err]
  connect_bd_intf_net -intf_net pcie2_cfg_interrupt [get_bd_intf_pins nwl_pcie_dma/pcie2_cfg_interrupt] [get_bd_intf_pins pcie_ep/pcie2_cfg_interrupt]
  connect_bd_intf_net -intf_net pcie2_cfg_status [get_bd_intf_pins nwl_pcie_dma/pcie2_cfg_status] [get_bd_intf_pins pcie_ep/pcie2_cfg_status]
  connect_bd_intf_net -intf_net pcie_cfg_fc [get_bd_intf_pins nwl_pcie_dma/pcie_cfg_fc] [get_bd_intf_pins pcie_ep/pcie_cfg_fc]

  connect_bd_net -net pcie_cfg_dsn [get_bd_pins pcie_cfg_dsn] [get_bd_pins pcie_ep/cfg_dsn]
  connect_bd_net -net pcie_cfg_pm_force_state [get_bd_pins pcie_cfg_pm_force_state] [get_bd_pins pcie_ep/cfg_pm_force_state]
  connect_bd_net -net pcie_cfg_ds_device_number [get_bd_pins pcie_cfg_ds_device_number] [get_bd_pins pcie_ep/cfg_ds_device_number]
  connect_bd_net -net pcie_cfg_ds_bus_number [get_bd_pins pcie_cfg_ds_bus_number] [get_bd_pins pcie_ep/cfg_ds_bus_number]
  connect_bd_net -net pcie_cfg_ds_function_number [get_bd_pins pcie_cfg_ds_function_number] [get_bd_pins pcie_ep/cfg_ds_function_number]
  connect_bd_net -net pcie_cfg_pciecap_interrupt_msgnum [get_bd_pins pcie_cfg_pciecap_interrupt_msgnum] [get_bd_pins pcie_ep/cfg_pciecap_interrupt_msgnum]
  connect_bd_net -net pcie_cfg_err_aer_headerlog [get_bd_pins pcie_cfg_err_aer_headerlog] [get_bd_pins pcie_ep/cfg_err_aer_headerlog]

  connect_bd_net -net const_gnd [get_bd_pins nwl_pcie_dma/user_interrupt] \
					[get_bd_pins pcie_ep/cfg_err_acs] \
					[get_bd_pins pcie_ep/cfg_err_atomic_egress_blocked] \
					[get_bd_pins pcie_ep/cfg_err_internal_cor] \
					[get_bd_pins pcie_ep/cfg_err_internal_uncor] \
					[get_bd_pins pcie_ep/cfg_err_malformed] \
					[get_bd_pins pcie_ep/cfg_err_mc_blocked] \
					[get_bd_pins pcie_ep/cfg_err_norecovery] \
					[get_bd_pins pcie_ep/cfg_err_poisoned] \
					[get_bd_pins pcie_ep/cfg_interrupt_stat] \
					[get_bd_pins pcie_ep/cfg_pm_force_state_en] \
					[get_bd_pins pcie_ep/cfg_pm_halt_aspm_l0s] \
					[get_bd_pins pcie_ep/cfg_pm_halt_aspm_l1] \
					[get_bd_pins pcie_ep/cfg_pm_send_pme_to] \
					[get_bd_pins const_gnd/dout]

  connect_bd_net -net const_vcc [get_bd_pins pcie_ep/rx_np_req] \
					[get_bd_pins const_vcc/dout]
#					[get_bd_pins pcie_ep/startup_keyclearb] \
					[get_bd_pins pcie_ep/startup_usrcclkts] \
					[get_bd_pins pcie_ep/startup_usrdonets] \

  #connect_bd_net -net const_gnd  [get_bd_pins pcie_ep/startup_clk] \
					[get_bd_pins pcie_ep/startup_gsr] \
					[get_bd_pins pcie_ep/startup_gts] \
					[get_bd_pins pcie_ep/startup_pack] \
					[get_bd_pins pcie_ep/startup_usrcclko] \
					[get_bd_pins pcie_ep/startup_usrdoneo] \
					[get_bd_pins const_gnd/dout]

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()

##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
