#=============================================================================
# 200MHz system clock for DoCE
#=============================================================================
create_clock -period 5.000 -name mcb_clk_ref [get_ports clk_ref_p]

# Bank 34
set_property VCCAUX_IO DONTCARE [get_ports clk_ref_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_ref_p]
set_property LOC H9 [get_ports clk_ref_p]

# Bank 34
set_property VCCAUX_IO DONTCARE [get_ports clk_ref_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_ref_n]
set_property LOC G9 [get_ports clk_ref_n]

#=============================================================================
# XGBE GT reference clock from Si5324 (BANK 110)
#=============================================================================
create_clock -period 6.400 -name gt_xgbe_ref_clk [get_ports gt_xgbe_ref_clk_p]

set_property LOC AC8 [get_ports gt_xgbe_ref_clk_p]
set_property LOC AC7 [get_ports gt_xgbe_ref_clk_n]

create_clock -period 6.400 -name clk156 [get_pins u_xgbe_component/xgbe_component_i/xgbe_phy/inst/ten_gig_eth_pcs_pma_shared_clock_reset_block/coreclk_bufg_inst/O]
create_clock -period 3.103 -name xphy_rxusrclkout0 [get_pins u_xgbe_component/xgbe_component_i/xgbe_phy/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i/RXOUTCLK]
create_clock -period 3.103 -name xphy_txusrclkout0 [get_pins u_xgbe_component/xgbe_component_i/xgbe_phy/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i/TXOUTCLK]
#=============================================================================
# 50MHz generated clock for Si5324
#=============================================================================
create_generated_clock -name clk50 -source [get_ports clk_ref_p] -divide_by 4 [get_pins {clk_divide_reg[1]/Q}]
#=============================================================================
# Domain crossing constraints
#=============================================================================
# rocket clk and mcb_clk
#set_clock_groups -name async_rocket_mig -asynchronous -group [get_clocks -include_generated_clocks SYSCLK_P] -group [get_clocks -include_generated_clocks mcb_clk_ref]
# mcb_clk and xgemac_clk
set_clock_groups -name async_xgbe_mig -asynchronous -group [get_clocks clk156] -group [get_clocks -include_generated_clocks mcb_clk_ref]
# xgemac_clk and XGBE PHY internal clock
set_clock_groups -name async_rxusrclk_xgemac -asynchronous -group [get_clocks xphy_rxusrclkout?] -group [get_clocks clk156]

set_clock_groups -name async_txusrclk_xgemac -asynchronous -group [get_clocks xphy_txusrclkout?] -group [get_clocks clk156]
#=============================================================================
# Back-end implementation constraints
#=============================================================================
# I/O banks attribute for DDR3 SODIMM on ZC706 board
set_property DCI_CASCADE {34} [get_iobanks 33]
#=============================================================================
# Location constraints
#=============================================================================
#GT Placement ## XGBE PHY ## MGT_BANK_111
set_property LOC GTXE2_CHANNEL_X0Y10 [get_cells u_xgbe_component/xgbe_component_i/xgbe_phy/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i]

#I2C related for Si5324
set_property IOSTANDARD LVCMOS18 [get_ports i2c_clk]
set_property SLEW SLOW [get_ports i2c_clk]
set_property DRIVE 16 [get_ports i2c_clk]
set_property PULLUP TRUE [get_ports i2c_clk]
set_property LOC AJ14 [get_ports i2c_clk]

set_property IOSTANDARD LVCMOS18 [get_ports i2c_data]
set_property SLEW SLOW [get_ports i2c_data]
set_property DRIVE 16 [get_ports i2c_data]
set_property PULLUP TRUE [get_ports i2c_data]
set_property LOC AJ18 [get_ports i2c_data]

set_property IOSTANDARD LVCMOS18 [get_ports si5324_rst_n]
set_property SLEW SLOW [get_ports si5324_rst_n]
set_property DRIVE 16 [get_ports si5324_rst_n]
set_property LOC W23 [get_ports si5324_rst_n]

#======================
# LED for Debug
#======================
set_property IOSTANDARD LVCMOS18 [get_ports xgbe_phy_up]
set_property SLEW SLOW [get_ports xgbe_phy_up]
set_property LOC W21 [get_ports xgbe_phy_up]

set_property IOSTANDARD LVCMOS18 [get_ports xgbe_mac_config_done]
set_property SLEW SLOW [get_ports xgbe_mac_config_done]
set_property LOC Y21 [get_ports xgbe_mac_config_done]

set_property IOSTANDARD LVCMOS15 [get_ports pl_ddr3_calib_done]
set_property SLEW SLOW [get_ports pl_ddr3_calib_done]
set_property LOC A17 [get_ports pl_ddr3_calib_done]

set_property IOSTANDARD LVCMOS15 [get_ports debug_inf]
set_property SLEW SLOW [get_ports debug_inf]
set_property LOC G2 [get_ports debug_inf]