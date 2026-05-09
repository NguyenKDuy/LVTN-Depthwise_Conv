# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DATA_128" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_64" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MEM_LATENCY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WEIGHT_MEM_LATENCY" -parent ${Page_0}


}

proc update_PARAM_VALUE.DATA_128 { PARAM_VALUE.DATA_128 } {
	# Procedure called to update DATA_128 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_128 { PARAM_VALUE.DATA_128 } {
	# Procedure called to validate DATA_128
	return true
}

proc update_PARAM_VALUE.DATA_64 { PARAM_VALUE.DATA_64 } {
	# Procedure called to update DATA_64 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_64 { PARAM_VALUE.DATA_64 } {
	# Procedure called to validate DATA_64
	return true
}

proc update_PARAM_VALUE.MEM_LATENCY { PARAM_VALUE.MEM_LATENCY } {
	# Procedure called to update MEM_LATENCY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MEM_LATENCY { PARAM_VALUE.MEM_LATENCY } {
	# Procedure called to validate MEM_LATENCY
	return true
}

proc update_PARAM_VALUE.WEIGHT_MEM_LATENCY { PARAM_VALUE.WEIGHT_MEM_LATENCY } {
	# Procedure called to update WEIGHT_MEM_LATENCY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WEIGHT_MEM_LATENCY { PARAM_VALUE.WEIGHT_MEM_LATENCY } {
	# Procedure called to validate WEIGHT_MEM_LATENCY
	return true
}


proc update_MODELPARAM_VALUE.DATA_128 { MODELPARAM_VALUE.DATA_128 PARAM_VALUE.DATA_128 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_128}] ${MODELPARAM_VALUE.DATA_128}
}

proc update_MODELPARAM_VALUE.DATA_32 { MODELPARAM_VALUE.DATA_32 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "DATA_32". Setting updated value from the model parameter.
set_property value 32 ${MODELPARAM_VALUE.DATA_32}
}

proc update_MODELPARAM_VALUE.DATA_64 { MODELPARAM_VALUE.DATA_64 PARAM_VALUE.DATA_64 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_64}] ${MODELPARAM_VALUE.DATA_64}
}

proc update_MODELPARAM_VALUE.WEIGHT_MEM_LATENCY { MODELPARAM_VALUE.WEIGHT_MEM_LATENCY PARAM_VALUE.WEIGHT_MEM_LATENCY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WEIGHT_MEM_LATENCY}] ${MODELPARAM_VALUE.WEIGHT_MEM_LATENCY}
}

proc update_MODELPARAM_VALUE.MEM_LATENCY { MODELPARAM_VALUE.MEM_LATENCY PARAM_VALUE.MEM_LATENCY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MEM_LATENCY}] ${MODELPARAM_VALUE.MEM_LATENCY}
}

