# TCL File Generated by Component Editor 16.1
# Thu May 04 20:48:18 EDT 2017
# DO NOT MODIFY


# 
# mandelbrot "mandelbrot" v1.0
#  2017.05.04.20:48:18
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module mandelbrot
# 
set_module_property DESCRIPTION ""
set_module_property NAME mandelbrot
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME mandelbrot
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL mandelbrot_avalon
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file mandelbrot.v SYSTEM_VERILOG PATH mandelbrot/mandelbrot.v TOP_LEVEL_FILE
add_fileset_file mand_add.qip OTHER PATH mandelbrot/mand_add.qip
add_fileset_file mand_add.v VERILOG PATH mandelbrot/mand_add.v
add_fileset_file mand_comp.qip OTHER PATH mandelbrot/mand_comp.qip
add_fileset_file mand_comp.v VERILOG PATH mandelbrot/mand_comp.v
add_fileset_file mand_fifo.qip OTHER PATH mandelbrot/mand_fifo.qip
add_fileset_file mand_fifo.v VERILOG PATH mandelbrot/mand_fifo.v
add_fileset_file mand_fifo_in.qip OTHER PATH mandelbrot/mand_fifo_in.qip
add_fileset_file mand_fifo_in.v VERILOG PATH mandelbrot/mand_fifo_in.v
add_fileset_file mand_fifo_out.qip OTHER PATH mandelbrot/mand_fifo_out.qip
add_fileset_file mand_fifo_out.v VERILOG PATH mandelbrot/mand_fifo_out.v
add_fileset_file mand_mult.qip OTHER PATH mandelbrot/mand_mult.qip
add_fileset_file mand_mult.v VERILOG PATH mandelbrot/mand_mult.v
add_fileset_file mand_sub.qip OTHER PATH mandelbrot/mand_sub.qip
add_fileset_file mand_sub.v VERILOG PATH mandelbrot/mand_sub.v
add_fileset_file mandmem.qip OTHER PATH mandelbrot/mandmem.qip
add_fileset_file mandmem.v VERILOG PATH mandelbrot/mandmem.v
add_fileset_file shift.qip OTHER PATH mandelbrot/shift.qip
add_fileset_file shift.v VERILOG PATH mandelbrot/shift.v
add_fileset_file mandpipe.v VERILOG PATH mandelbrot/mandpipe.v


# 
# parameters
# 


# 
# display items
# 


# 
# connection point avalon_slave_0
# 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 read read Input 1
add_interface_port avalon_slave_0 write write Input 1
add_interface_port avalon_slave_0 chipselect chipselect Input 1
add_interface_port avalon_slave_0 byteenable byteenable Input 4
add_interface_port avalon_slave_0 readdata readdata Output 32
add_interface_port avalon_slave_0 writedata writedata Input 32
add_interface_port avalon_slave_0 waitrequest_n waitrequest_n Output 1
add_interface_port avalon_slave_0 address address Input 3
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


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

