# =============================================================
# I2C_Master.do
# Run from: C:\Verilog-Digital-Archive\The_Project\Microprocessor\sim\
# Usage:    vsim -do I2C_Master.do
#
# STATUS: No testbench yet - compile check only.
#         Uncomment the vsim + wave block once
#         tb/peripherals/I2C_tb.sv exists.
# Planned tests: single write transaction (START + addr + reg + data + STOP),
#                ACK error injection (sda held high during ack window),
#                back-to-back transactions, busy flag timing
# Note: SDA is tri-state (inout tri). Testbench must drive
#       sda low during ACK windows using a pulldown model.
# =============================================================

quietly set SRC "../rtl/peripherals/I2C.sv"
quietly set TB  "../tb/peripherals/I2C_tb.sv"
quietly set TOP "I2C_tb"

# ---------- Library ----------
if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

# ---------- Compile check ----------
vlog -sv -work work $SRC
echo "I2C_Master: compile OK"

# -------------------------------------------------------
# Uncomment below once I2C_tb.sv is written
# -------------------------------------------------------
# vlog -sv -work work $TB
# vsim -t 1ns -lib work $TOP
#
# add wave -divider "== CONTROL =="
# add wave -radix binary       sim:/$TOP/clk
# add wave -radix binary       sim:/$TOP/reset
# add wave -radix binary       sim:/$TOP/start
# add wave -radix binary       sim:/$TOP/busy
# add wave -radix binary       sim:/$TOP/ack_error
#
# add wave -divider "== INPUTS =="
# add wave -radix hexadecimal  sim:/$TOP/device_addr
# add wave -radix hexadecimal  sim:/$TOP/reg_addr
# add wave -radix hexadecimal  sim:/$TOP/write_data
#
# add wave -divider "== I2C BUS =="
# add wave -radix binary       sim:/$TOP/scl
# add wave -radix binary       sim:/$TOP/sda
#
# add wave -divider "== STATE MACHINE =="
# add wave                     sim:/$TOP/uut/state
# add wave -radix binary       sim:/$TOP/uut/i2c_tick
# add wave -radix unsigned     sim:/$TOP/uut/div_counter
# add wave -radix unsigned     sim:/$TOP/uut/bit_count
# add wave -radix hexadecimal  sim:/$TOP/uut/shift_reg
#
# add wave -divider "== SDA DRIVER =="
# add wave -radix binary       sim:/$TOP/uut/sda_out
# add wave -radix binary       sim:/$TOP/uut/sda_oe
#
# run -all
# wave zoom full
