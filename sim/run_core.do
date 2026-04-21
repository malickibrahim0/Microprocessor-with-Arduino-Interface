# run_core.do - Compile and simulate core RTL
# Usage: cd sim && vsim -c -do run_core.do

if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vlog -sv ../rtl/core/*.sv

# Uncomment once tb is written:
# vlog -sv ../tb/core/Core_TB.sv
# vsim -voptargs=+acc work.Core_TB
# add wave -position insertpoint sim:/Core_TB/*
# run -all
