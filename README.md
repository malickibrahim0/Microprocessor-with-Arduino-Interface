# Microprocessor-with-Arduino-Interface

32-bit pipelined RISC SoC targeting Intel MAX10 (DE10-Lite).

## Architecture
- 3-stage pipelined RISC core with forwarding
- 32-instruction ISA via PREFIX mechanism (16 base + 16 extended)
- CORDIC co-processor (planned: Phase 3)
- SPI slave + async Gray-coded FIFO (planned: Phase 4)
- Arduino Uno SPI master interface

## Current state
- ALU: all 32 opcodes implemented (Page 1 arithmetic/logic, Page 2 extended)
- Register file: 16x32-bit
- ROM: 256x32-bit with $readmemh init
- Assembler: two-pass Python assembler in `tools/asm/`

## Tools
- SystemVerilog, Quartus Prime Lite 20.1, ModelSim Intel FPGA 2020.1
- DE10-Lite (Intel MAX10 10M50DAF484C7G)
- Python 3.x assembler (no dependencies)

## Building a program
```powershell
python tools\asm\assembler.py tools\asm\tests\programs\fib.asm --out memory
```
Writes `memory.hex` and `memory.svh` at repo root.

## Author
Malick Ibrahim - Western Kentucky University, EE
