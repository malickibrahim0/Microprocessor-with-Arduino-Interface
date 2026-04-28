module Register_File_32(
input  logic clk,
input  logic reset,
input  logic write_enable,
input  logic [3:0] read_addr_A,
input  logic [3:0] read_addr_B,
input  logic [3:0] write_addr,
input  logic [31:0] write_data,    // Comes from Alu_out
output logic [31:0] out_data_A,    // Feeds Aluin_A
output logic [31:0] out_data_B     // Feeds Aluin_B
);

// 16 registers, each 32 bits wide
logic [31:0] registers [0:15];

// Asynchronous Read (Feed ALU immediately)
assign out_data_A = registers[read_addr_A];
assign out_data_B = registers[read_addr_B];

// Synchronous Write (Save ALU result on clock edge)
always_ff @(posedge clk) begin
if (reset) begin
        for (int i = 0; i < 16; i++) begin
            registers[i] <= 32'h0;
        end
    end else if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end

endmodule

