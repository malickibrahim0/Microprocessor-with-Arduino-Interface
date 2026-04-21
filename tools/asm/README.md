# SoC Assembler

Two-pass assembler for the 32-bit pipelined RISC SoC
(`Microprocessor-with-Arduino-Interface`).

## Quick start

```powershell
# Assemble a program
python assembler.py tests\programs\fib.asm

# Write output to a specific location (your ROM init file)
python assembler.py tests\programs\fib.asm --out ..\..\memory

# Debug: see all fields decoded
python assembler.py tests\programs\fib.asm --debug

# Verify against a reference .hex
python assembler.py tests\programs\fib.asm --verify reference.hex
```

## Supported mnemonics

### Page 1 (prefix=0)

| Op  | Mnemonic | Operands         | Description |
|-----|----------|------------------|-------------|
| 0x0 | NOP      |                  | No operation |
| 0x1 | LDI      | rd, imm          | Load immediate (0..255) |
| 0x2 | ADD      | rd, ra, rb       | rd = ra + rb |
| 0x3 | SUB      | rd, ra, rb       | rd = ra - rb |
| 0x4 | ADI      | rd, ra, imm8     | rd = ra + imm8 |
| 0x5 | MUL      | rd, ra, rb       | rd = ra * rb |
| 0x6 | DIV      | rd, ra, rb       | Stubbed in ALU; ALU returns 0 |
| 0x7 | DEC      | rd, rb           | rd = rb - 1 |
| 0x8 | INC      | rd, rb           | rd = rb + 1 |
| 0x9 | NOR      | rd, ra, rb       | rd = ~(ra \| rb) |
| 0xA | NAND     | rd, ra, rb       | rd = ~(ra & rb) |
| 0xB | XOR      | rd, ra, rb       | rd = ra ^ rb |
| 0xC | COMP     | rd, rb           | rd = ~rb |
| 0xD | CMPJ     | ra, rb, target   | if (ra >= rb) jump to target |
| 0xE | JMP      | target           | PC = target (0..32767) |
| 0xF | HLT      |                  | Halt |

### Page 2 (prefix=1)

| Op  | Mnemonic     | Operands         | Description |
|-----|--------------|------------------|-------------|
| 0x0 | MOV          | rd, rb           | rd = rb |
| 0x1 | LOAD         | rd, ra           | rd = RAM[ra] |
| 0x2 | JAL          | rd, target       | Jump-and-link (PC handled in top) |
| 0x3 | JALR         | rd, ra           | Jump-and-link register |
| 0x4 | LOAD_ALT     | rd, ra           | rd = RAM[ra] (alt path) |
| 0x5 | CORDIC_TRIG  | ra, rb           | Trigger CORDIC (no writeback) |
| 0x6 | SHL          | rd, ra, imm5     | rd = ra << imm5 |
| 0x7 | SHR          | rd, ra, imm5     | rd = ra >> imm5 |
| 0x8 | AND          | rd, ra, rb       | rd = ra & rb |
| 0x9 | OR           | rd, ra, rb       | rd = ra \| rb |
| 0xA | MMIO_RD      | rd, ra           | rd = MMIO[ra] |
| 0xB | MMIO_WR      | ra, rb           | MMIO[ra] = rb (no writeback) |
| 0xC | ROL          | rd, ra, imm5     | rd = rotate_left(ra, imm5) |
| 0xD | ROR          | rd, ra, imm5     | rd = rotate_right(ra, imm5) |
| 0xE | SUI          | rd, ra, imm8     | rd = ra - imm8 |
| 0xF | RETI         |                  | Return from interrupt |

## Assembly syntax

```asm
; Comments start with ';' or '//'
label_name:
    MNEMONIC op1, op2, op3    ; operands separated by commas

; Registers: R0..R15, or hex-style R0..R9/RA..RF
; Immediates: decimal, 0x.., 0b.., optionally prefixed with '#'
```

## Instruction format (32 bits, LSB-contiguous)

```
 [31:24] rb_instant (8-bit immediate)
 [23:17] ra_instant (7-bit immediate)
 [16:13] read_rb
 [12:9]  read_ra
 [8:5]   write_rd
 [4]     prefix (0 = Page 1, 1 = Page 2)
 [3:0]   opcode
```

For JMP/CMPJ/JAL targets, the 15-bit target is packed into
`{ra_instant[6:0], rb_instant[7:0]}` giving 32768-word reach.

## Output formats

- **`.hex`**: one hex word per line, `$readmemh`-compatible.
  Drop this into `memory.hex` where your ROM module reads from.
- **`.svh`**: SystemVerilog include with `localparam` array.
  Use via `` `include "rom_init.svh" `` in your ROM module if you prefer
  inline ROM initialization over `$readmemh`.

## Files

- `assembler.py` - CLI entry point and two-pass logic
- `isa.py`       - Opcode tables, field encoding rules
- `parser.py`    - Source tokenizer and comment stripping
- `tests/programs/fib.asm` - Fibonacci benchmark

## Regenerating memory.hex

From the repo root:

```powershell
python tools\asm\assembler.py tools\asm\tests\programs\fib.asm --out memory
```

This writes `memory.hex` and `memory.svh` at the repo root, ready for the
ROM module's `$readmemh` call.
