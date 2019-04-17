# Vivado Launch Script using Board Design

#=============================================
# Basic Design Settings
#=============================================
set design zynq_deoi_overlay_x86_xgbe 
set top zynq_deoi_overlay_x86_xgbe
set proj_dir runs
set synth_constraints zynq_deoi_overlay_x86_xgbe.xdc

set device xc7z045-2-ffg900

#==============================================
# Project Settings
#==============================================
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device}
set_property source_mgmt_mode DisplayOnly [current_project]
set_property top ${top} [current_fileset]

add_files -fileset constrs_1 -norecurse "../sources/constraints/${synth_constraints}"

# Add custom IP repo
set_property ip_repo_paths "../sources/ip_package" [current_fileset]
update_ip_catalog -rebuild

#==============================================
# Block Design Automative Generation
#==============================================

# Zynq ARM SoC related part (Zynq PS, AXI DMA and MIG engine)
source scripts/deoi_soc_component.tcl

make_wrapper -files [get_files ./${proj_dir}/${design}.srcs/sources_1/bd/deoi_soc_component/deoi_soc_component.bd] -top
import_files -force -norecurse ./${proj_dir}/${design}.srcs/sources_1/bd/deoi_soc_component/hdl/deoi_soc_component_wrapper.v

validate_bd_design
save_bd_design
close_bd_design deoi_soc_component

# PCIe EP and XGBE MAC/PHY related part
source scripts/pcie_xgbe_component.tcl

make_wrapper -files [get_files ./${proj_dir}/${design}.srcs/sources_1/bd/pcie_xgbe_component/pcie_xgbe_component.bd] -top
import_files -force -norecurse ./${proj_dir}/${design}.srcs/sources_1/bd/pcie_xgbe_component/hdl/pcie_xgbe_component_wrapper.v

validate_bd_design
save_bd_design
close_bd_design pcie_xgbe_component

# On-chip packet router related part (AXIS-IC and VFIFO)
source scripts/packet_router.tcl

make_wrapper -files [get_files ./${proj_dir}/${design}.srcs/sources_1/bd/packet_router/packet_router.bd] -top
import_files -force -norecurse ./${proj_dir}/${design}.srcs/sources_1/bd/packet_router/hdl/packet_router_wrapper.v

validate_bd_design
save_bd_design
close_bd_design packet_router 

# AXI-IC for MAC address register
source scripts/mac_addr_reg_arb.tcl

make_wrapper -files [get_files ./${proj_dir}/${design}.srcs/sources_1/bd/mac_addr_reg_arb/mac_addr_reg_arb.bd] -top
import_files -force -norecurse ./${proj_dir}/${design}.srcs/sources_1/bd/mac_addr_reg_arb/hdl/mac_addr_reg_arb_wrapper.v

validate_bd_design
save_bd_design
close_bd_design mac_addr_reg_arb 

# Top level HDL instantiating clocking components
add_files -norecurse -force ../sources/hdl/zynq_deoi_overlay_x86_xgbe.v
update_compile_order -fileset sources_1

#==============================================
# Read IP configuration files used outside Block design
#==============================================

# FIFOs used in XGBE Rx interface
read_ip -files "../sources/ip_catalog/xgbe_rx_if/axis_async_fifo/axis_async_fifo.xci"
read_ip -files "../sources/ip_catalog/xgbe_rx_if/cmd_fifo_xgemac_rxif/cmd_fifo_xgemac_rxif.xci"

# AXIS register slice used in DMA packet dispatch module for timing closure
read_ip -files "../sources/ip_catalog/packet_dispatch/axis_reg_slice/axis_reg_slice.xci"

# AXIS and FIFO infrastructure used in DoCE design
read_ip -files "../sources/ip_catalog/doce/axi_lite_crossbar/axi_lite_crossbar.xci"
read_ip -files "../sources/ip_catalog/doce/axis_cmd_fifo/axis_cmd_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/axis_data_fifo/axis_data_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/axis_dc_128_to_64/axis_dc_128_to_64.xci"
read_ip -files "../sources/ip_catalog/doce/axis_dc_64_to_128/axis_dc_64_to_128.xci"
read_ip -files "../sources/ip_catalog/doce/m_ar_fifo/m_ar_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/m_aw_fifo/m_aw_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/m_b_fifo/m_b_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/m_w_fifo/m_w_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/m_r_stream_data_fifo/m_r_stream_data_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/r_num_fifo/r_num_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/s_ar_fifo/s_ar_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/s_aw_fifo/s_aw_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/s_b_fifo/s_b_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/s_r_fifo/s_r_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/s_w_stream_data_fifo/s_w_stream_data_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/rx_barrier_fifo/rx_barrier_fifo.xci"
read_ip -files "../sources/ip_catalog/doce/tx_stream_switch/tx_stream_switch.xci"

#==============================================
# Add source RTL files
#==============================================

# Si5324 configuration
add_files -norecurse -force ../sources/hdl/clock_control/clock_control.vhd
add_files -norecurse -force ../sources/hdl/clock_control/clock_control_program.vhd
add_files -norecurse -force ../sources/hdl/clock_control/kcpsm6.vhd

# XGBE MAC/PHY configuration, Rx interface and XGBE path sub top module
add_files -norecurse -force ../sources/hdl/xgbe_path/axi_10g_ethernet_0_axi_lite_sm.v
add_files -norecurse -force ../sources/hdl/xgbe_path/rx_interface.v
add_files -norecurse -force ../sources/hdl/xgbe_path/xgbe_path.v

# MAC address register
add_files -norecurse -force ../sources/hdl/common/mac_addr_reg.v

# PCIe backend DMA AXI3 to AXI4-Lite converter
add_files -norecurse -force ../sources/hdl/common/axi_shim.v

# Packet dispatcher
add_files -norecurse -force ../sources/hdl/packet_dispatch/dma_pkt_forward.v
add_files -norecurse -force ../sources/hdl/packet_dispatch/xgbe_mac_rx_dispatch.v

# Common synchronizer
add_files -norecurse -force ../sources/hdl/common/synchronizer_simple.v

# DoCE custom design
add_files -norecurse -force ../sources/ip_cores/doce/doce_top.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/doce_transaction_layer.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/ar_decode.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/aw_decode.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/aw_width_converter.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/axi_rx.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/axi_tx.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/barrier_tx.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/id_inquire.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/m_inter_tx.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/r_connection_id_gene.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/r_decode.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/r_width_converter.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/rx_switch.v
add_files -norecurse -force ../sources/ip_cores/doce/transaction_layer/s_inter_tx.v

add_files -norecurse -force ../sources/ip_cores/doce/transport_layer/mac_id_table.v
add_files -norecurse -force ../sources/ip_cores/doce/transport_layer/rx_fsm.v
add_files -norecurse -force ../sources/ip_cores/doce/transport_layer/tx_fsm.v
add_files -norecurse -force ../sources/ip_cores/doce/transport_layer/transport_layer.v



#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_async_fifo.vhd
#add_files -norecurse -force ../sources/ip_cores/deoi/asitv10_axisc_register_slice.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_awr_fifo.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_b_fifo.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_ch0_ctrl.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_cir_buf.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_ddr_clk_gen.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_decoder.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_ecc_dec.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_ecc_enc.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_lite_ar_seq.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_lite_aw_seq.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_lite_decoder.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_lite_master.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_lite_slave.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_lite_tdm.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_master.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_packer.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_phy_calib.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_phy_if.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_phy_init.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_reset_sync.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_sio_input.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_sio_output.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_slave.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_sync_cell.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_tdm.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_chip2chip_unpacker.v
#add_files -norecurse -force ../sources/ip_cores/deoi/axi_deoi.v

update_compile_order -fileset sources_1

#==============================================
# Design Flow Settings
#==============================================
# Setting Synthesis options
set_property strategy {Vivado Synthesis defaults} [get_runs synth_1]

# Setting Implementation options
set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
# The following implementation options will increase runtime, but get the best timing results
set_property strategy Performance_Explore [get_runs impl_1]

#==============================================
# Setup Simulation Environment
#==============================================

