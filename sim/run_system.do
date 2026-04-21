# run_system.do - Full system simulation
# Usage: cd sim && vsim -do run_system.do

if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vlog -sv ../rtl/core/*.sv
vlog -sv ../rtl/memory/*.sv
vlog -sv ../rtl/peripherals/*.sv
vlog -sv ../rtl/top/*.sv
vlog -sv ../tb/system/*.sv

# vsim -voptargs=+acc work.System_TB
# add wave -position insertpoint sim:/System_TB/*
# run -all
