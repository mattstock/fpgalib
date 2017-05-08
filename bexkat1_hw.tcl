# TCL File Generated by Component Editor 16.1
# Sun May 07 12:29:14 EDT 2017
# DO NOT MODIFY


# 
# bexkat1 "bexkat1" v1.0
#  2017.05.07.12:29:14
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module bexkat1
# 
set_module_property DESCRIPTION ""
set_module_property NAME bexkat1
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME bexkat1
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL bexkat1_avalon
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file alu.v VERILOG PATH bexkat1/alu.v
add_fileset_file bexkat1.v SYSTEM_VERILOG PATH bexkat1/bexkat1.v TOP_LEVEL_FILE
add_fileset_file bexkat1.vh SYSTEM_VERILOG_INCLUDE PATH bexkat1/bexkat1.vh
add_fileset_file businterface.v VERILOG PATH bexkat1/businterface.v
add_fileset_file control.v VERILOG PATH bexkat1/control.v
add_fileset_file exceptions.vh SYSTEM_VERILOG_INCLUDE PATH bexkat1/exceptions.vh
add_fileset_file floatingpoint.v VERILOG PATH bexkat1/floatingpoint.v
add_fileset_file fp_addsub.qip OTHER PATH bexkat1/fp_addsub.qip
add_fileset_file fp_addsub.v VERILOG PATH bexkat1/fp_addsub.v
add_fileset_file fp_cmp.qip OTHER PATH bexkat1/fp_cmp.qip
add_fileset_file fp_cmp.v VERILOG PATH bexkat1/fp_cmp.v
add_fileset_file fp_cvtis.qip OTHER PATH bexkat1/fp_cvtis.qip
add_fileset_file fp_cvtis.v VERILOG PATH bexkat1/fp_cvtis.v
add_fileset_file fp_cvtsi.qip OTHER PATH bexkat1/fp_cvtsi.qip
add_fileset_file fp_cvtsi.v VERILOG PATH bexkat1/fp_cvtsi.v
add_fileset_file fp_div.hex HEX PATH bexkat1/fp_div.hex
add_fileset_file fp_div.qip OTHER PATH bexkat1/fp_div.qip
add_fileset_file fp_div.v VERILOG PATH bexkat1/fp_div.v
add_fileset_file fp_mult.qip OTHER PATH bexkat1/fp_mult.qip
add_fileset_file fp_mult.v VERILOG PATH bexkat1/fp_mult.v
add_fileset_file fp_sqrt.qip OTHER PATH bexkat1/fp_sqrt.qip
add_fileset_file fp_sqrt.v VERILOG PATH bexkat1/fp_sqrt.v
add_fileset_file fpu.v VERILOG PATH bexkat1/fpu.v
add_fileset_file intcalc.v VERILOG PATH bexkat1/intcalc.v
add_fileset_file intsdiv.qip OTHER PATH bexkat1/intsdiv.qip
add_fileset_file intsdiv.v VERILOG PATH bexkat1/intsdiv.v
add_fileset_file intsmult.qip OTHER PATH bexkat1/intsmult.qip
add_fileset_file intsmult.v VERILOG PATH bexkat1/intsmult.v
add_fileset_file intudiv.qip OTHER PATH bexkat1/intudiv.qip
add_fileset_file intudiv.v VERILOG PATH bexkat1/intudiv.v
add_fileset_file intumult.qip OTHER PATH bexkat1/intumult.qip
add_fileset_file intumult.v VERILOG PATH bexkat1/intumult.v
add_fileset_file registerfile.v VERILOG PATH bexkat1/registerfile.v


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point avalon_master_0
# 
add_interface avalon_master_0 avalon start
set_interface_property avalon_master_0 addressUnits SYMBOLS
set_interface_property avalon_master_0 associatedClock clock
set_interface_property avalon_master_0 associatedReset reset
set_interface_property avalon_master_0 bitsPerSymbol 8
set_interface_property avalon_master_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_master_0 burstcountUnits WORDS
set_interface_property avalon_master_0 doStreamReads false
set_interface_property avalon_master_0 doStreamWrites false
set_interface_property avalon_master_0 holdTime 0
set_interface_property avalon_master_0 linewrapBursts false
set_interface_property avalon_master_0 maximumPendingReadTransactions 0
set_interface_property avalon_master_0 maximumPendingWriteTransactions 0
set_interface_property avalon_master_0 readLatency 0
set_interface_property avalon_master_0 readWaitTime 1
set_interface_property avalon_master_0 setupTime 0
set_interface_property avalon_master_0 timingUnits Cycles
set_interface_property avalon_master_0 writeWaitTime 0
set_interface_property avalon_master_0 ENABLED true
set_interface_property avalon_master_0 EXPORT_OF ""
set_interface_property avalon_master_0 PORT_NAME_MAP ""
set_interface_property avalon_master_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_master_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_master_0 avm_waitrequest_n waitrequest_n Input 1
add_interface_port avalon_master_0 avm_write write Output 1
add_interface_port avalon_master_0 avm_read read Output 1
add_interface_port avalon_master_0 avm_address address Output 32
add_interface_port avalon_master_0 avm_readdata readdata Input 32
add_interface_port avalon_master_0 avm_writedata writedata Output 32
add_interface_port avalon_master_0 avm_byteenable byteenable Output 4


# 
# connection point conduit_end_0
# 
add_interface conduit_end_0 conduit end
set_interface_property conduit_end_0 associatedClock clock
set_interface_property conduit_end_0 associatedReset ""
set_interface_property conduit_end_0 ENABLED true
set_interface_property conduit_end_0 EXPORT_OF ""
set_interface_property conduit_end_0 PORT_NAME_MAP ""
set_interface_property conduit_end_0 CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end_0 SVD_ADDRESS_GROUP ""

add_interface_port conduit_end_0 coe_supervisor supervisor Output 1
add_interface_port conduit_end_0 coe_exception exception Output 4
add_interface_port conduit_end_0 coe_halt halt Output 1
add_interface_port conduit_end_0 coe_int_en int_en Output 1


# 
# connection point interrupt_receiver
# 
add_interface interrupt_receiver interrupt start
set_interface_property interrupt_receiver associatedAddressablePoint ""
set_interface_property interrupt_receiver associatedClock clock
set_interface_property interrupt_receiver associatedReset reset
set_interface_property interrupt_receiver irqScheme INDIVIDUAL_REQUESTS
set_interface_property interrupt_receiver ENABLED true
set_interface_property interrupt_receiver EXPORT_OF ""
set_interface_property interrupt_receiver PORT_NAME_MAP ""
set_interface_property interrupt_receiver CMSIS_SVD_VARIABLES ""
set_interface_property interrupt_receiver SVD_ADDRESS_GROUP ""

add_interface_port interrupt_receiver inr_irq irq Input 3

