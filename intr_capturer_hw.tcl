# TCL File Generated by Component Editor 13.0
# Mon Dec 10 18:37:36 MYT 2012
# DO NOT MODIFY


# 
# intr_capturer "Interrupt Capture Module" v1.0
# Altera Corporation 2012.12.10.18:37:36
# This component capture interrupt inputs and presents them as registers readable via Avalon Slave port
# 

# 
# request TCL package from ACDS 13.0
# 
package require -exact qsys 13.0


# 
# module intr_capturer
# 
set_module_property DESCRIPTION "This component capture interrupt inputs and presents them as registers readable via Avalon Slave port"
set_module_property NAME intr_capturer
set_module_property VERSION 1.0
set_module_property INTERNAL false 
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP Other
set_module_property AUTHOR "Altera Corporation"
set_module_property DISPLAY_NAME "Interrupt Capture Module"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL intr_capturer
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file intr_capturer.v VERILOG PATH intr_capturer/intr_capturer.v

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL intr_capturer
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file intr_capturer.v VERILOG PATH intr_capturer/intr_capturer.v

add_fileset SIM_VHDL SIM_VHDL vhdl_from_verilog
set_fileset_property SIM_VHDL top_level intr_capturer

proc vhdl_from_verilog { outputName } {
    set fileloc [create_temp_file simgen_init.txt]
    send_message info ${fileloc}
    set fileHandle [ open  ${fileloc} w ]
    puts ${fileHandle} "DECLARE_VHDL_COMPONENT=timmy\n"
    close ${fileHandle}

    set SIMGEN_PARAMS "--simgen_parameter=CBX_HDL_LANGUAGE=VHDL,SIMGEN_RAND_POWERUP_FFS=OFF,SIMGEN_OBFUSCATE=OFF,SIMGEN_MAX_TULIP_COUNT=0,SIMGEN_INITIALIZATION_FILE=${fileloc},SIMGEN_VHDL_LIBRARY_LIST=work"

    set foo [call_simgen intr_capturer.v "$SIMGEN_PARAMS --simgen_arbitrary_blackbox=+timmy" ]
    set foo "${foo}.vho"
    #set foo [simgen_file bob.v bob VHDL {tom.v timmy.v} +timmy ${fileloc} work ]

    add_fileset_file intr_capturer.vho VHDL PATH ${foo}
    #add_fileset_file timmy.vhd VHDL PATH timmy.vhd
}

# 
# parameters
# 
add_parameter NUM_INTR INTEGER 32
set_parameter_property NUM_INTR DEFAULT_VALUE 32
set_parameter_property NUM_INTR DISPLAY_NAME NUM_INTR
set_parameter_property NUM_INTR TYPE INTEGER
set_parameter_property NUM_INTR UNITS None
set_parameter_property NUM_INTR ALLOWED_RANGES 1:64
set_parameter_property NUM_INTR HDL_PARAMETER true


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
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink rst_n reset_n Input 1


# 
# connection point avalon_slave_0
# 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset_sink
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 addr address Input 1
add_interface_port avalon_slave_0 read read Input 1
add_interface_port avalon_slave_0 rddata readdata Output 32
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point interrupt_receiver
# 
add_interface interrupt_receiver interrupt start
set_interface_property interrupt_receiver associatedAddressablePoint ""
set_interface_property interrupt_receiver associatedClock clock
set_interface_property interrupt_receiver associatedReset reset_sink
set_interface_property interrupt_receiver irqScheme INDIVIDUAL_REQUESTS
set_interface_property interrupt_receiver ENABLED true
set_interface_property interrupt_receiver EXPORT_OF ""
set_interface_property interrupt_receiver PORT_NAME_MAP ""
set_interface_property interrupt_receiver SVD_ADDRESS_GROUP ""

add_interface_port interrupt_receiver interrupt_in irq Input NUM_INTR

