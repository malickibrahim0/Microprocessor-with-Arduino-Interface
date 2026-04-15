module ROM_32(
input  logic clk,
input  logic [31:0] Program_Counter,
output logic [31:0] Instruction_Bus
);

// 256 locations of 32-bit words
logic [31:0] mem [0:255];

initial begin
    // Load program into memory
    $readmemh("memory.hex", mem);
end

assign Instruction_Bus = mem[Program_Counter[9:2]];
endmodule

module Instruction_Decoder_32(
input  logic [31:0] instruction_in,    
output logic [3:0]  alu_opcode,
output logic [31:0] ra_instant_ext, // 32-bit zero-extended (unsigned ISA)
output logic [31:0] rb_instant_ext, // 32-bit zero-extended (unsigned ISA)
output logic        prefix_active,    
output logic [3:0]  read_addr_a,
output logic [3:0]  read_addr_b,
output logic [3:0]  write_addr,
output logic        reg_write_enable
);

always_comb begin
    alu_opcode     = instruction_in[3:0];
    
    // Extract 4-bit immediates, zero-extend to 32 bits (no sign extension)
    ra_instant_ext = {28'h0, instruction_in[7:4]};
    rb_instant_ext = {28'h0, instruction_in[11:8]};
    
    read_addr_a    = instruction_in[15:12];
    read_addr_b    = instruction_in[19:16];
    write_addr     = instruction_in[23:20];
    prefix_active  = instruction_in[24];
    
    // CMPJ (0xD), JMP (0xE), HLT (0xF) do not write back to register file
    if (!prefix_active && (alu_opcode == 4'hE || alu_opcode == 4'hD || alu_opcode == 4'hF)) begin
        reg_write_enable = 1'b0;
    end else begin
        reg_write_enable = 1'b1;
    end
end

endmodule

