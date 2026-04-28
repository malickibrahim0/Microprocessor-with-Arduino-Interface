# =============================================================
# MMIO_Decoder.do
# Run from: C:\Verilog-Digital-Archive\The_Project\Microprocessor\sim\
# Usage:    vsim -do MMIO_Decoder.do
# Tests:    CORDIC_CTRL write/read, CORDIC_ANGLE latch,
#           SIN/COS readback, IMG_THRESH/KERNEL write,
#           IMG_STATUS readback, default address returns 0
# =============================================================

quietly set SRC "../rtl/peripherals/MMIO_Decoder.sv"
quietly set TB  "../tb/peripherals/MMIO_Decoder_tb.sv"
quietly set TOP "tb_MMIO_Decoder"

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
add wave -divider "== CLOCK / RESET =="
add wave -radix binary       sim:/$TOP/clk
add wave -radix binary       sim:/$TOP/reset

add wave -divider "== CPU WRITE BUS =="
add wave -radix hexadecimal  sim:/$TOP/MMIO_address
add wave -radix hexadecimal  sim:/$TOP/MMIO_write_data
add wave -radix binary       sim:/$TOP/MMIO_write_enable
add wave -radix binary       sim:/$TOP/MMIO_read_enable

add wave -divider "== CPU READ BUS =="
add wave -radix hexadecimal  sim:/$TOP/MMIO_read_data

add wave -divider "== CORDIC PERIPHERAL =="
add wave -radix binary       sim:/$TOP/CORDIC_start
add wave -radix hexadecimal  sim:/$TOP/CORDIC_angle
add wave -radix decimal      sim:/$TOP/CORDIC_sin
add wave -radix decimal      sim:/$TOP/CORDIC_cos
add wave -radix binary       sim:/$TOP/CORDIC_busy
add wave -radix binary       sim:/$TOP/CORDIC_done

add wave -divider "== IMAGE PERIPHERAL =="
add wave -radix hexadecimal  sim:/$TOP/IMG_threshold
add wave -radix hexadecimal  sim:/$TOP/IMG_kernel
add wave -radix hexadecimal  sim:/$TOP/IMG_status

add wave -divider "== DUT REGISTERS =="
add wave -radix hexadecimal  sim:/$TOP/uut/angle_reg
add wave -radix hexadecimal  sim:/$TOP/uut/thresh_reg
add wave -radix hexadecimal  sim:/$TOP/uut/kernel_reg

add wave -divider "== WRITE STROBES =="
add wave -radix binary       sim:/$TOP/uut/write_ctrl
add wave -radix binary       sim:/$TOP/uut/wr_angle
add wave -radix binary       sim:/$TOP/uut/wr_thresh
add wave -radix binary       sim:/$TOP/uut/wr_kernel

# ---------- Run ----------
run -all

wave zoom full
