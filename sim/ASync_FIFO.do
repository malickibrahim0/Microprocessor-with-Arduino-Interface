# =============================================================
# ASync_FIFO.do
# Run from: C:\Verilog-Digital-Archive\The_Project\Microprocessor\sim\
# Usage:    vsim -do ASync_FIFO.do
#
# STATUS: No testbench yet - compile check only.
#         Uncomment vsim + wave block once
#         tb/peripherals/ASync_FIFO_tb.sv exists.
# Planned tests: write/read same clock (sanity),
#                slow write / fast read (underflow check),
#                fast write / slow read (full/overflow check),
#                Gray-code pointer inspection across clock domains,
#                double-flop synchronizer latency verification
# Reference: Cummings SNUG 2002 Style 2
# =============================================================

quietly set SRC "../rtl/peripherals/ASync_FIFO.sv"
quietly set TB  "../tb/peripherals/ASync_FIFO_tb.sv"
quietly set TOP "ASync_FIFO_tb"

# ---------- Library ----------
if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

# ---------- Compile check ----------
vlog -sv -work work $SRC
echo "ASync_FIFO: compile OK"

# -------------------------------------------------------
# Uncomment below once ASync_FIFO_tb.sv is written
# -------------------------------------------------------
# vlog -sv -work work $TB
# vsim -t 1ns -lib work $TOP
#
# add wave -divider "== WRITE DOMAIN =="
# add wave -radix binary       sim:/$TOP/wr_clk
# add wave -radix binary       sim:/$TOP/wr_rst_n
# add wave -radix binary       sim:/$TOP/wr_en
# add wave -radix hexadecimal  sim:/$TOP/wr_data
# add wave -radix binary       sim:/$TOP/full
#
# add wave -divider "== READ DOMAIN =="
# add wave -radix binary       sim:/$TOP/rd_clk
# add wave -radix binary       sim:/$TOP/rd_rst_n
# add wave -radix binary       sim:/$TOP/rd_en
# add wave -radix hexadecimal  sim:/$TOP/rd_data
# add wave -radix binary       sim:/$TOP/empty
#
# add wave -divider "== GRAY POINTERS =="
# add wave -radix binary       sim:/$TOP/uut/wptr_gray
# add wave -radix binary       sim:/$TOP/uut/rptr_gray
# add wave -radix binary       sim:/$TOP/uut/wptr_gray_sync1
# add wave -radix binary       sim:/$TOP/uut/wptr_gray_sync2
# add wave -radix binary       sim:/$TOP/uut/rptr_gray_sync1
# add wave -radix binary       sim:/$TOP/uut/rptr_gray_sync2
#
# add wave -divider "== BINARY POINTERS =="
# add wave -radix unsigned     sim:/$TOP/uut/wptr_bin
# add wave -radix unsigned     sim:/$TOP/uut/rptr_bin
#
# run -all
# wave zoom full
