# =============================================================
# StackPointer.do
# Run from: C:\Verilog-Digital-Archive\The_Project\Microprocessor\sim\
# Usage:    vsim -do StackPointer.do
# Tests:    SP init, DEC1/INC1, DEC2/INC2, DEC3/INC3,
#           SP_Empty flag, SP_Full flag, wrap-around
# =============================================================

quietly set SRC "../rtl/core/StackPointer.sv"
quietly set TB  "../tb/core/StackPointer_tb.sv"
quietly set TOP "tb_StackPointer"           ;# ✅ fixed: was StackPointer_tb

# ---------- Library ----------
if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

# ---------- Compile ----------
vlog -sv -work work $SRC
vlog -sv -work work $TB

# ---------- Simulate ----------
vsim -t 1ns -lib work $TOP

# ---------- Waves ----------
add wave -divider "== CONTROL =="
add wave -radix binary       sim:/$TOP/clk
add wave -radix binary       sim:/$TOP/reset
add wave -radix binary       sim:/$TOP/SP_OP

add wave -divider "== STACK POINTER =="
add wave -radix hexadecimal  sim:/$TOP/SP
add wave -radix binary       sim:/$TOP/SP_Empty
add wave -radix binary       sim:/$TOP/SP_Full

add wave -divider "== DUT INTERNALS =="
add wave -radix hexadecimal  sim:/$TOP/dut/SP     ;# ✅ fixed: was uut

# ---------- Run ----------
run -all

wave zoom full
