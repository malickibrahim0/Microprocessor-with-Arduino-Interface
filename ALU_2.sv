module ALU(
input  logic [7:0] Aluin_A,
input  logic [7:0] Aluin_B,
input  logic [3:0] RA_Instant,
input  logic [3:0] RB_Instant,
input  logic [3:0] OPCODE,
input  logic       prefix_active,       // 1 = use page 2
input  logic [7:0] ram_data,            // data from RAM (for POP/LDM)
input  logic [7:0] mmio_data,           // data from MMIO (for MMRD)
output logic [7:0] Alu_out,
output logic       Cout,
output logic       OF
);

//--- Page 1: Original 16 operations ---
logic [8:0] Result_P1 [0:15];

always_comb begin
    Result_P1[0]  = 9'h000;                                                    // 0: PREFIX
    Result_P1[1]  = {1'b0, RA_Instant, RB_Instant};                            // 1: LDI
    Result_P1[2]  = {1'b0, Aluin_A} + {1'b0, Aluin_B};                         // 2: ADD
    Result_P1[3]  = {1'b0, Aluin_A} - {1'b0, Aluin_B};                         // 3: SUB
    Result_P1[4]  = {1'b0, Aluin_A} + {5'b0, RB_Instant};                      // 4: ADI
    Result_P1[5]  = {1'b0, Aluin_A * Aluin_B};                                 // 5: MUL
    Result_P1[6]  = (Aluin_B == 0) ? 9'h000 : {1'b0, Aluin_A / Aluin_B};       // 6: DIV
    Result_P1[7]  = {1'b0, Aluin_B} - 9'h001;                                  // 7: DEC
    Result_P1[8]  = {1'b0, Aluin_B} + 9'h001;                                  // 8: INC
    Result_P1[9]  = {1'b0, ~(Aluin_A | Aluin_B)};                              // 9: NOR
    Result_P1[10] = {1'b0, ~(Aluin_A & Aluin_B)};                              // A: NAND
    Result_P1[11] = {1'b0, Aluin_A ^ Aluin_B};                                 // B: XOR
    Result_P1[12] = {1'b0, ~Aluin_B};                                          // C: COMP
    Result_P1[13] = 9'h000;                                                    // D: CMPJ
    Result_P1[14] = {1'b0, RA_Instant, RB_Instant};                            // E: JMP
    Result_P1[15] = 9'h000;                                                    // F: HLT
end

//Page 2: 16 new operations (selected when prefix_active = 1) 
logic [8:0] Result_P2 [0:15];

always_comb begin
    Result_P2[0]  = {1'b0, Aluin_B};                                                // P+0: PUSH  (pass B through, RAM write handled externally)
    Result_P2[1]  = {1'b0, ram_data};                                               // P+1: POP   (data from RAM)
    Result_P2[2]  = 9'h000;                                                         // P+2: CALL  (PC logic external)
    Result_P2[3]  = 9'h000;                                                         // P+3: RET   (PC logic external)
    Result_P2[4]  = {1'b0, ram_data};                                               // P+4: LDM   (load from RAM)
    Result_P2[5]  = {1'b0, Aluin_B};                                                // P+5: STM   (pass B through, RAM write handled externally)
    Result_P2[6]  = {1'b0, Aluin_A} << RB_Instant;                                  // P+6: SHL
    Result_P2[7]  = {1'b0, Aluin_A} >> RB_Instant;                                  // P+7: SHR
    Result_P2[8]  = {1'b0, Aluin_A & Aluin_B};                                      // P+8: AND
    Result_P2[9]  = {1'b0, Aluin_A | Aluin_B};                                      // P+9: OR
    Result_P2[10] = {1'b0, mmio_data};                                              // P+A: MMRD  (read from MMIO)
    Result_P2[11] = {1'b0, Aluin_B};                                                // P+B: MMWR  (pass B through, MMIO write handled externally)
    Result_P2[12] = {1'b0, (Aluin_A << RB_Instant) | (Aluin_A >> (8-RB_Instant))};  // P+C: ROTL
    Result_P2[13] = {1'b0, (Aluin_A >> RB_Instant) | (Aluin_A << (8-RB_Instant))};  // P+D: ROTR
    Result_P2[14] = {1'b0, Aluin_A} - {5'b0, RB_Instant};                           // P+E: SUBI
    Result_P2[15] = 9'h000;                                                         // P+F: RETI  (PC logic external)
end

// Select page, then select opcode within page 
logic [8:0] mux_out;

always_comb begin
    if (prefix_active)
        mux_out = Result_P2[OPCODE];
    else
        mux_out = Result_P1[OPCODE];
end

// Output assignment
always_comb begin
    Alu_out = mux_out[7:0];

    if (!prefix_active && OPCODE >= 4'h2 && OPCODE <= 4'h8) begin
        // Page 1 arithmetic
        Cout = mux_out[8];
        OF   = (~Aluin_A[7] ^ Aluin_B[7]) & mux_out[7];
    end else if (prefix_active && (OPCODE == 4'h6 || OPCODE == 4'h7 || OPCODE == 4'hE)) begin
        // Page 2 arithmetic (SHL, SHR, SUBI)
        Cout = mux_out[8];
        OF   = (~Aluin_A[7] ^ Aluin_B[7]) & mux_out[7];
    end else begin
        Cout = 1'b0;
        OF   = 1'b0;
    end
end

endmodule


