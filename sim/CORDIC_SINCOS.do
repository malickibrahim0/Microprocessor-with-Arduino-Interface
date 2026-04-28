# =============================================================
# CORDIC_SINCOS.do
# Run from: C:\Verilog-Digital-Archive\The_Project\Microprocessor\sim\
# Usage:    vsim -do CORDIC_SINCOS.do
#
# STATUS: No testbench yet - compile check only.
#         Uncomment vsim + wave block once
#         tb/core/CORDIC_SINCOS_tb.sv exists.
# Planned tests:
#   0 deg   -> sin=0x000,   cos=0x1000 (max positive)
#   90 deg  -> sin=0x1000,  cos=0x000
#   180 deg -> sin=0x000,   cos=0xF000 (negative)
#   270 deg -> sin=0xF000,  cos=0x000
#   45 deg  -> sin==cos (symmetry check)
#   Pipeline latency: 16 cycles from valid_in to valid_out
#   Quadrant pre-rotation: angles in Q2/Q3/Q4 all correct
# Key params: IW=13, OW=13, PW=20, 16 stages
# =============================================================

quietly set SRC "../rtl/core/CORDIC_SINCOS.sv"
quietly set TB  "../tb/core/CORDIC_SINCOS_tb.sv"
quietly set TOP "CORDIC_SINCOS_tb"

# ---------- Library ----------
if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

# ---------- Compile check ----------
vlog -sv -work work $SRC
echo "CORDIC_SINCOS: compile OK"

# -------------------------------------------------------
# Uncomment below once CORDIC_SINCOS_tb.sv is written
# -------------------------------------------------------
# vlog -sv -work work $TB
# vsim -t 1ns -lib work $TOP
#
# add wave -divider "== PIPELINE CONTROL =="
# add wave -radix binary       sim:/$TOP/clk
# add wave -radix binary       sim:/$TOP/reset
# add wave -radix binary       sim:/$TOP/valid_in
# add wave -radix binary       sim:/$TOP/valid_out
#
# add wave -divider "== INPUT =="
# add wave -radix hexadecimal  sim:/$TOP/angle_in
#
# add wave -divider "== OUTPUT =="
# add wave -radix decimal      sim:/$TOP/sin_out
# add wave -radix decimal      sim:/$TOP/cos_out
#
# add wave -divider "== STAGE 0 (after quadrant pre-rotation) =="
# add wave -radix decimal      sim:/$TOP/uut/x_pipe[0]
# add wave -radix decimal      sim:/$TOP/uut/y_pipe[0]
# add wave -radix hexadecimal  sim:/$TOP/uut/z_pipe[0]
#
# add wave -divider "== STAGE 8 (midpoint) =="
# add wave -radix decimal      sim:/$TOP/uut/x_pipe[8]
# add wave -radix decimal      sim:/$TOP/uut/y_pipe[8]
# add wave -radix hexadecimal  sim:/$TOP/uut/z_pipe[8]
#
# add wave -divider "== STAGE 15 (final) =="
# add wave -radix decimal      sim:/$TOP/uut/x_pipe[15]
# add wave -radix decimal      sim:/$TOP/uut/y_pipe[15]
# add wave -radix hexadecimal  sim:/$TOP/uut/z_pipe[15]
#
# run -all
# wave zoom full
