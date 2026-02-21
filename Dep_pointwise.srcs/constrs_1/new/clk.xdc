create_clock -period 10.000 -name clk -waveform {0.000 5.000}

create_clock -period 2.000 -name clk_1 -waveform {0.000 1.000} -add [get_ports clk]
