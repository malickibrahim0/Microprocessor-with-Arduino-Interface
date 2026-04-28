# =============================================================
# RAM_256.do
# Run from: C:\Verilog-Digital-Archive\The_Project\Microprocessor\sim\
# Usage:    vsim -do RAM_256.do
# Tests:    sequential write + readback,
#           simultaneous read/write different addresses,
#           async read without clock edge,
#           address 0x0A, 0x1F, 0xFF boundary checks
# =============================================================

quietly set SRC "../rtl/memory/RAM_256.sv"
quietly set TB  "../tb/memory/RAM_256_tb.sv"
quietly set TOP "tb_RAM_256x8"              

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
add wave -radix binary       sim:/$TOP/write_enable

add wave -divider "== WRITE PORT =="
add wave -radix hexadecimal  sim:/$TOP/write_address
add wave -radix hexadecimal  sim:/$TOP/data_in

add wave -divider "== READ PORT =="
add wave -radix hexadecimal  sim:/$TOP/read_address
add wave -radix hexadecimal  sim:/$TOP/data_out


# ---------- Run ----------
run -all

wave zoom full
