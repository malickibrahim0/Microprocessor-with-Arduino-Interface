; ---------------------------------------------------------------------------
; Fibonacci benchmark - 32-bit RISC SoC
; ---------------------------------------------------------------------------
; Computes Fibonacci numbers for 10 iterations, then exercises extended ISA.
;
; New instruction format (LSB-contiguous):
;   [31:24] rb_instant (8-bit)
;   [23:17] ra_instant (7-bit)
;   [16:13] read_rb
;   [12:9]  read_ra
;   [8:5]   write_rd
;   [4]     prefix
;   [3:0]   opcode
;
; Expected final registers:
;   R0  = 55   (Fib(10))
;   R1  = 89   (Fib(11))
;   R2  = 10   (loop counter)
;   R3  = 10   (iteration bound)
;   R4  = 89   (last temp)
; ---------------------------------------------------------------------------

        LDI  R0, 0          ; R0 = 0             (Fib base)
        LDI  R1, 1          ; R1 = 1             (Fib base)
        LDI  R2, 0          ; R2 = 0             (loop counter)
        LDI  R3, 10         ; R3 = 10            (iteration bound)

loop:
        CMPJ R2, R3, done   ; if R2 >= R3, exit loop
        ADD  R4, R0, R1     ; R4 = R0 + R1
        ADI  R0, R1, 0      ; R0 = R1 + 0       (slide)
        ADI  R1, R4, 0      ; R1 = R4 + 0       (slide)
        INC  R2, R2         ; R2++
        JMP  loop           ; repeat

done:
        ; Extended ISA exercise (Page 2)
        SHL  R5, R1, 2      ; R5 = R1 << 2      (shift test)
        SHR  R6, R5, 1      ; R6 = R5 >> 1
        AND  R7, R1, R3     ; R7 = R1 & R3
        OR   R8, R1, R3     ; R8 = R1 | R3
        XOR  R9, R1, R3     ; R9 = R1 ^ R3      (Page 1)
        MOV  RA, R1         ; R10 = R1          (Page 2 MOV)

        HLT
