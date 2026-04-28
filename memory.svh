// Auto-generated from fib.asm
// Assembled on 2026-04-21T00:36:51
// Do not edit by hand. Regenerate with assembler.py

localparam int PROGRAM_ROM_SIZE = 17;
logic [31:0] PROGRAM_ROM [0:PROGRAM_ROM_SIZE-1] = '{
    32'h00000001, // 00: LDI  R0, 0          ; R0 = 0             (Fib base)
    32'h01000021, // 01: LDI  R1, 1          ; R1 = 1             (Fib base)
    32'h00000041, // 02: LDI  R2, 0          ; R2 = 0             (loop counter)
    32'h0a000061, // 03: LDI  R3, 10         ; R3 = 10            (iteration bound)
    32'h0a00640d, // 04: CMPJ R2, R3, done   ; if R2 >= R3, exit loop
    32'h00002082, // 05: ADD  R4, R0, R1     ; R4 = R0 + R1
    32'h00000204, // 06: ADI  R0, R1, 0      ; R0 = R1 + 0       (slide)
    32'h00000824, // 07: ADI  R1, R4, 0      ; R1 = R4 + 0       (slide)
    32'h00004048, // 08: INC  R2, R2         ; R2++
    32'h0400000e, // 09: JMP  loop           ; repeat
    32'h020002b6, // 0a: SHL  R5, R1, 2      ; R5 = R1 << 2      (shift test)
    32'h01000ad7, // 0b: SHR  R6, R5, 1      ; R6 = R5 >> 1
    32'h000062f8, // 0c: AND  R7, R1, R3     ; R7 = R1 & R3
    32'h00006319, // 0d: OR   R8, R1, R3     ; R8 = R1 | R3
    32'h0000632b, // 0e: XOR  R9, R1, R3     ; R9 = R1 ^ R3      (Page 1)
    32'h00002150, // 0f: MOV  RA, R1         ; R10 = R1          (Page 2 MOV)
    32'h0000000f  // 10: HLT
};
