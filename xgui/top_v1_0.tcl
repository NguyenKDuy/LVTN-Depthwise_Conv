# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDR_BIAS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ADDR_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ADDR_IMG" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ADDR_IMG_R" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ADDR_POINT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SUB_W" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDR_BIAS { PARAM_VALUE.ADDR_BIAS } {
	# Procedure called to update ADDR_BIAS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_BIAS { PARAM_VALUE.ADDR_BIAS } {
	# Procedure called to validate ADDR_BIAS
	return true
}

proc update_PARAM_VALUE.ADDR_DEPTH { PARAM_VALUE.ADDR_DEPTH } {
	# Procedure called to update ADDR_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_DEPTH { PARAM_VALUE.ADDR_DEPTH } {
	# Procedure called to validate ADDR_DEPTH
	return true
}

proc update_PARAM_VALUE.ADDR_IMG { PARAM_VALUE.ADDR_IMG } {
	# Procedure called to update ADDR_IMG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_IMG { PARAM_VALUE.ADDR_IMG } {
	# Procedure called to validate ADDR_IMG
	return true
}

proc update_PARAM_VALUE.ADDR_IMG_R { PARAM_VALUE.ADDR_IMG_R } {
	# Procedure called to update ADDR_IMG_R when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_IMG_R { PARAM_VALUE.ADDR_IMG_R } {
	# Procedure called to validate ADDR_IMG_R
	return true
}

proc update_PARAM_VALUE.ADDR_POINT { PARAM_VALUE.ADDR_POINT } {
	# Procedure called to update ADDR_POINT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_POINT { PARAM_VALUE.ADDR_POINT } {
	# Procedure called to validate ADDR_POINT
	return true
}

proc update_PARAM_VALUE.DATA_W { PARAM_VALUE.DATA_W } {
	# Procedure called to update DATA_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_W { PARAM_VALUE.DATA_W } {
	# Procedure called to validate DATA_W
	return true
}

proc update_PARAM_VALUE.SUB_W { PARAM_VALUE.SUB_W } {
	# Procedure called to update SUB_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SUB_W { PARAM_VALUE.SUB_W } {
	# Procedure called to validate SUB_W
	return true
}


proc update_MODELPARAM_VALUE.DATA_W { MODELPARAM_VALUE.DATA_W PARAM_VALUE.DATA_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_W}] ${MODELPARAM_VALUE.DATA_W}
}

proc update_MODELPARAM_VALUE.ADDR_BIAS { MODELPARAM_VALUE.ADDR_BIAS PARAM_VALUE.ADDR_BIAS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_BIAS}] ${MODELPARAM_VALUE.ADDR_BIAS}
}

proc update_MODELPARAM_VALUE.ADDR_DEPTH { MODELPARAM_VALUE.ADDR_DEPTH PARAM_VALUE.ADDR_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_DEPTH}] ${MODELPARAM_VALUE.ADDR_DEPTH}
}

proc update_MODELPARAM_VALUE.ADDR_POINT { MODELPARAM_VALUE.ADDR_POINT PARAM_VALUE.ADDR_POINT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_POINT}] ${MODELPARAM_VALUE.ADDR_POINT}
}

proc update_MODELPARAM_VALUE.ADDR_IMG { MODELPARAM_VALUE.ADDR_IMG PARAM_VALUE.ADDR_IMG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_IMG}] ${MODELPARAM_VALUE.ADDR_IMG}
}

proc update_MODELPARAM_VALUE.ADDR_IMG_R { MODELPARAM_VALUE.ADDR_IMG_R PARAM_VALUE.ADDR_IMG_R } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_IMG_R}] ${MODELPARAM_VALUE.ADDR_IMG_R}
}

proc update_MODELPARAM_VALUE.SUB_W { MODELPARAM_VALUE.SUB_W PARAM_VALUE.SUB_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SUB_W}] ${MODELPARAM_VALUE.SUB_W}
}

