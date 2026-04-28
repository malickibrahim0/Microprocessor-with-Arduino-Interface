module ROM_32(
    input  logic clk,
    input  logic [31:0] Program_Counter,
    output logic [31:0] Instruction_Bus
  );


  reg [31:0] mem [0:255];

  initial
  begin
    // Absolute path bypasses TerosHDL working directory mismatches
    $readmemh("c:/Verilog-Digital-Archive/The_Project/Microprocessor/memory.hex", mem);
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

  always_comb
  begin
    alu_opcode     = instruction_in[3:0];
    prefix_active  = instruction_in[4];
    write_addr     = instruction_in[8:5];
    read_addr_a    = instruction_in[12:9];
    read_addr_b    = instruction_in[16:13];

    // Zero-extend 7-bit and 8-bit immediates
    ra_instant_ext = {25'h0, instruction_in[23:17]};
    rb_instant_ext = {24'h0, instruction_in[31:24]};

    // Disable writeback for control and MMIO_WR instructions
    if (!prefix_active && (alu_opcode == 4'hE || alu_opcode == 4'hD || alu_opcode == 4'hF))
    begin
      reg_write_enable = 1'b0;
    end
    else if (prefix_active && (alu_opcode == 4'h3 || alu_opcode == 4'h5 || alu_opcode == 4'hB || alu_opcode == 4'hF))
    begin
      reg_write_enable = 1'b0;
    end
    else
    begin
      reg_write_enable = 1'b1;
    end
  end

endmodule
