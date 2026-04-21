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

// 33-bit arrays to catch the 33rd carry bit
logic [32:0] Result_P1 [0:15];
logic [32:0] Result_P2 [0:15];

always_comb begin
    // Page 1: Original Arithmetic
    Result_P1 = '{default: 33'h0};
    Result_P2 = '{default: 33'h0};
    Result_P1[0]  = 33'h0;                                               
    Result_P1[1]  = {1'b0, RA_Instant[15:0], RB_Instant[15:0]}; // Packed LDI
    Result_P1[2]  = {1'b0, Aluin_A} + {1'b0, Aluin_B};                   
    Result_P1[3]  = {1'b0, Aluin_A} - {1'b0, Aluin_B};                   
    Result_P1[4]  = {1'b0, Aluin_A} + {1'b0, RB_Instant};                
    Result_P1[5]  = {1'b0, Aluin_A * Aluin_B};                           
    Result_P1[6]  = (Aluin_B == 0) ? 33'h0 : {1'b0, Aluin_A / Aluin_B};  
    Result_P1[7]  = {1'b0, Aluin_B} - 33'h1;                             
    Result_P1[8]  = {1'b0, Aluin_B} + 33'h1;                             
    Result_P1[9]  = {1'b0, ~(Aluin_A | Aluin_B)};                        
    Result_P1[10] = {1'b0, ~(Aluin_A & Aluin_B)};                        
    Result_P1[11] = {1'b0, Aluin_A ^ Aluin_B};                           
    Result_P1[12] = {1'b0, ~Aluin_B};                                    
    Result_P1[13] = 33'h0;                                               
    Result_P1[14] = 33'h0;                                               
    Result_P1[15] = 33'h0;                                               

    // Page 2: Extended Operations 
    Result_P2[0]  = {1'b0, Aluin_B};                                     
    Result_P2[1]  = {1'b0, ram_data};                                    
    Result_P2[2]  = 33'h0;                                               
    Result_P2[3]  = 33'h0;                                               
    Result_P2[4]  = {1'b0, ram_data};                                    
    Result_P2[5]  = {1'b0, Aluin_B};                                     
    // Shift operations mask RB_Instant to 5 bits (0-31 shifts)
    Result_P2[6]  = {1'b0, Aluin_A} << RB_Instant[4:0];                  
    Result_P2[7]  = {1'b0, Aluin_A} >> RB_Instant[4:0];                  
    Result_P2[8]  = {1'b0, Aluin_A & Aluin_B};                           
    Result_P2[9]  = {1'b0, Aluin_A | Aluin_B};                           
    Result_P2[10] = {1'b0, mmio_data};                                   
    Result_P2[11] = {1'b0, Aluin_B};                                     
    Result_P2[12] = {1'b0, (Aluin_A << RB_Instant[4:0]) | (Aluin_A >> (32 - RB_Instant[4:0]))}; 
    Result_P2[13] = {1'b0, (Aluin_A >> RB_Instant[4:0]) | (Aluin_A << (32 - RB_Instant[4:0]))}; 
    Result_P2[14] = {1'b0, Aluin_A} - {1'b0, RB_Instant};                
    Result_P2[15] = 33'h0;                                               
end

logic [32:0] mux_out;
always_comb begin
    if (prefix_active) 
        mux_out = Result_P2[OPCODE];
    else 
        mux_out = Result_P1[OPCODE];
    
    Alu_out = mux_out[31:0];
    Cout    = mux_out[32];
    zero    = (Alu_out == 32'h0);

    // 32-bit Overflow Logic for Addition
    if (!prefix_active && (OPCODE == 4'h2 || OPCODE == 4'h4)) begin
        OF = (Aluin_A[31] == Aluin_B[31]) && (mux_out[31] != Aluin_A[31]);
    // Overflow Logic for Subtraction
    end else if (!prefix_active && OPCODE == 4'h3) begin
        OF = (Aluin_A[31] != Aluin_B[31]) && (mux_out[31] != Aluin_A[31]);
    end else begin
        OF = 1'b0;
    end
end

endmodule