module ALU_32(
    input  logic [31:0] Aluin_A, Aluin_B,
    input  logic [31:0] RA_Instant, RB_Instant,
    input  logic [3:0]  OPCODE,
    input  logic        prefix_active,
    input  logic [31:0] ram_data,
    input  logic [31:0] mmio_data,
    output logic [31:0] Alu_out,
    output logic        Cout, OF, zero
);

    logic [32:0] mux_out;
    logic [4:0]  shift_amt;
    logic [4:0]  inv_shift;

    always_comb begin
        // Safe shift bounds for ROL/ROR
        shift_amt = RB_Instant[4:0];
        inv_shift = 5'd32 - shift_amt; 
        
        // Default assignment to prevent inferred latches
        mux_out = 33'h0;

        // Synthesis-friendly opcode decoding
        if (!prefix_active) begin
            case (OPCODE)
                4'h0: mux_out = 33'h0;                                               // NOP
                4'h1: mux_out = {1'b0, RA_Instant[15:0], RB_Instant[15:0]};          // LDI
                4'h2: mux_out = {1'b0, Aluin_A} + {1'b0, Aluin_B};                   // ADD
                4'h3: mux_out = {1'b0, Aluin_A} - {1'b0, Aluin_B};                   // SUB
                4'h4: mux_out = {1'b0, Aluin_A} + {1'b0, RB_Instant};                // ADI
                4'h5: mux_out = {1'b0, Aluin_A * Aluin_B};                           // MUL
                4'h6: mux_out = (Aluin_B == 0) ? 33'h0 : {1'b0, Aluin_A / Aluin_B};  // DIV
                4'h7: mux_out = {1'b0, Aluin_B} - 33'h1;                             // DEC
                4'h8: mux_out = {1'b0, Aluin_B} + 33'h1;                             // INC
                4'h9: mux_out = {1'b0, ~(Aluin_A | Aluin_B)};                        // NOR
                4'hA: mux_out = {1'b0, ~(Aluin_A & Aluin_B)};                        // NAND
                4'hB: mux_out = {1'b0, Aluin_A ^ Aluin_B};                           // XOR
                4'hC: mux_out = {1'b0, ~Aluin_B};                                    // COMP
                4'hD, 4'hE, 4'hF: mux_out = 33'h0;                                   // CMPJ, JMP, HLT
                default: mux_out = 33'h0;
            endcase
        end else begin
            case (OPCODE)
                4'h0: mux_out = {1'b0, Aluin_B};                                     // MOV
                4'h1: mux_out = {1'b0, ram_data};                                    // LOAD
                4'h2, 4'h3: mux_out = 33'h0;                                         // JAL, JALR
                4'h4: mux_out = {1'b0, ram_data};                                    // LOAD_ALT
                4'h5: mux_out = {1'b0, Aluin_B};                                     // CORDIC_TRIG
                4'h6: mux_out = {1'b0, Aluin_A} << shift_amt;                        // SHL
                4'h7: mux_out = {1'b0, Aluin_A} >> shift_amt;                        // SHR
                4'h8: mux_out = {1'b0, Aluin_A & Aluin_B};                           // AND
                4'h9: mux_out = {1'b0, Aluin_A | Aluin_B};                           // OR
                4'hA: mux_out = {1'b0, mmio_data};                                   // MMIO_RD
                4'hB: mux_out = {1'b0, Aluin_B};                                     // MMIO_WR
                4'hC: mux_out = {1'b0, (Aluin_A << shift_amt) | (Aluin_A >> inv_shift)}; // ROL
                4'hD: mux_out = {1'b0, (Aluin_A >> shift_amt) | (Aluin_A << inv_shift)}; // ROR
                4'hE: mux_out = {1'b0, Aluin_A} - {1'b0, RB_Instant};                // SUI
                4'hF: mux_out = 33'h0;                                               // RETI
                default: mux_out = 33'h0;
            endcase
        end
        
        // Output Assignments
        Alu_out = mux_out[31:0];
        Cout    = mux_out[32];
        zero    = (Alu_out == 32'h0);

        // Overflow Logic
        if (!prefix_active && OPCODE == 4'h2) begin
            OF = (Aluin_A[31] == Aluin_B[31]) && (mux_out[31] != Aluin_A[31]);
        end else if (!prefix_active && OPCODE == 4'h4) begin
            OF = (Aluin_A[31] == RB_Instant[31]) && (mux_out[31] != Aluin_A[31]);
        end else if (!prefix_active && OPCODE == 4'h3) begin
            OF = (Aluin_A[31] != Aluin_B[31]) && (mux_out[31] != Aluin_A[31]);
        end else begin
            OF = 1'b0;
        end
    end

endmodule
