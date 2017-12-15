create_clock -name raw_clock_50 -period 20ns [get_ports {raw_clock_50} ] -waveform {0 10}

derive_pll_clocks
derive_clock_uncertainty

# all async user input and really slow stuff
set_false_path -from [get_ports {key*}] -to *
set_false_path -from * -to [get_ports {led*}]
set_false_path -from * -to [get_ports {hex*}]

set_multicycle_path -through [get_pins -compatibility_mode {*intcalc*}] -setup -start 12
set_multicycle_path -through [get_pins -compatibility_mode {*intcalc*}] -hold -start 11
