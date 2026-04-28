# =============================================================
# SPI_Slave.do
# Run from: C:\Verilog-Digital-Archive\The_Project\Microprocessor\sim\
# Usage:    vsim -do SPI_Slave.do
# Tests:    Single byte receive, multi-byte frame,
#           CS abort mid-byte (shift_reg clears),
#           data_valid pulse width = 1 cycle
# =============================================================

quietly set SRC "../rtl/peripherals/SPI.sv"
quietly set TB  "../tb/peripherals/SPI_tb.sv"
quietly set TOP "SPI_Slave_Receiver_tb"

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
add wave -divider "== SYSTEM =="
add wave -radix binary       sim:/$TOP/clk
add wave -radix binary       sim:/$TOP/rst_n

add wave -divider "== SPI BUS (raw) =="
add wave -radix binary       sim:/$TOP/S_CLK
add wave -radix binary       sim:/$TOP/SS_N
add wave -radix binary       sim:/$TOP/MOSI

add wave -divider "== SYNC CHAIN =="
add wave -radix binary       sim:/$TOP/Test/S_CLK_sync
add wave -radix binary       sim:/$TOP/Test/SS_N_sync
add wave -radix binary       sim:/$TOP/Test/MOSI_sync
add wave -radix binary       sim:/$TOP/Test/S_Clk_Rising

add wave -divider "== RECEIVE STATE =="
add wave -radix unsigned     sim:/$TOP/Test/bit_count
add wave -radix hexadecimal  sim:/$TOP/Test/shift_reg

add wave -divider "== OUTPUT =="
add wave -radix hexadecimal  sim:/$TOP/received_data
add wave -radix binary       sim:/$TOP/data_valid

# ---------- Run ----------
run -all

wave zoom full
