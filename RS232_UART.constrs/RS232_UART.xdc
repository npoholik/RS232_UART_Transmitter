set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -name clk -period 10.00 -waveform {0 5} [get_ports clk]
  
###################################################################################################################

##Pmod Header JB
##Sch name = JB1
	set_property PACKAGE_PIN A14 [get_ports {output}]					
		set_property IOSTANDARD LVCMOS33 [get_ports {output}]
		set_property SLEW FAST [get_ports {output}]
