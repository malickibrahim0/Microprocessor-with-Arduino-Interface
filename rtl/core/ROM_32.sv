module ROM_32(
input  logic clk,
input  logic [31:0] Program_Counter,
output logic [31:0] Instruction_Bus
);


reg [31:0] mem [0:255];

initial
begin
  $readmemh("c:/Verilog-Digital-Archive/The_Project/Microprocessor/memory.hex", mem);
end

assign Instruction_Bus = mem[Program_Counter[9:2]];

endmodule

module Instruction_Decoder_32(
input  logic [31:0] instruction_in,
output logic [3:0]  alu_opcode,
output logic [31:0] ra_instant_ext,
output logic [31:0] rb_instant_ext,
output logic        prefix_active,
output logic [3:0]  read_addr_a,
output logic [3:0]  read_addr_b,
output logic [3:0]  write_addr,
output logic        reg_write_enable
);

always_comb begin
// 1. Default Assignments to prevent latches
reg_write_enable = 1'b1;

// 2. Standard Slicing
alu_opcode     = instruction_in[3:0];
prefix_active  = instruction_in[4];
write_addr     = instruction_in[8:5];
read_addr_a    = instruction_in[12:9];
read_addr_b    = instruction_in[16:13];

// 3. Sign-extend 7-bit and 8-bit immediates (Supports negative jumps/math)
ra_instant_ext = {{25{instruction_in[23]}}, instruction_in[23:17]};
rb_instant_ext = {{24{instruction_in[31]}}, instruction_in[31:24]};

// 4. Exception Handling for Write Enable
if (!prefix_active) begin
    case (alu_opcode)
        4'hE, 4'hD, 4'hF: reg_write_enable = 1'b0; // JMP, CMPJ, HLT
        default:          reg_write_enable = 1'b1;
    endcase
end else begin
    case (alu_opcode)
        4'h3, 4'h5, 4'hB, 4'hF: reg_write_enable = 1'b0; // JAL, CORDIC, MMIO_WR, RETI
        default:                reg_write_enable = 1'b1;
    endcase
end
end

endmodule