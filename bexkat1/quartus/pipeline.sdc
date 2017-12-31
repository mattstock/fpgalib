create_clock -name raw_clock_50 -period 20ns [get_ports {raw_clock_50} ] -waveform {0 10}

derive_pll_clocks
derive_clock_uncertainty

set_clock_groups -asynchronous -group { \
  pll0|altpll_component|auto_generated|pll1|clk[0]} -group { altera_reserved_tck }

# JTAG
set_input_delay -clock altera_reserved_tck 20 [ get_ports altera_reserved_tdi ]
set_input_delay -clock altera_reserved_tck 20 [ get_ports altera_reserved_tms ]
set_output_delay -clock altera_reserved_tck 20 [ get_ports altera_reserved_tdo ]
  

# all async user input and really slow stuff
set_false_path -from [get_ports {key*}] -to *
set_false_path -from [get_ports {rxd, cts}] -to *
set_false_path -from * -to [get_ports {led*}]
set_false_path -from * -to [get_ports {hex*}]
set_false_path -from * -to [get_ports {txd, rts}]

set_multicycle_path -through [get_pins -compatibility_mode {*intcalc*}] -setup -start 12
set_multicycle_path -through [get_pins -compatibility_mode {*intcalc*}] -hold -start 11
