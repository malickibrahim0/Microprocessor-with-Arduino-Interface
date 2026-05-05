module Program_Counter_32(
input  logic clk, reset,
// Signals from the Execute Stage (IF_EX struct)
input  logic [3:0] OPCODE_EX,
input  logic [31:0] IF_EX_PC,      // The PC of the instruction evaluating the jump
input  logic [31:0] Alu_out,       // The target address for JMP
input  logic [31:0] A, B,          // 32 bit Register values to evaluate CMPJ
input  logic [31:0] Branch_Offset, // The offset for CMPJ
output logic [31:0] PC,            // Current fetch address sent to ROM
output logic branch_taken          // Flag sent to top-level to trigger a flush
);

logic [31:0] PC_reg, next_PC;

localparam JMP  = 4'hE;
localparam CMPJ = 4'hD;
localparam HLT = 4'hF;


always_comb begin
    // Default: Increment the fetch counter by 1
    next_PC = PC_reg + 32'h0000_0004;
    branch_taken = 1'b0;

    // Override if a jump is executing
    case (OPCODE_EX)
        JMP: begin
            next_PC = Alu_out;
            branch_taken = 1'b1;
        end
        CMPJ: begin
            if (A >= B) begin
                // CMPJ jumps relative to the instruction's own PC
                next_PC = IF_EX_PC + Branch_Offset; 
                branch_taken = 1'b1;
            end
        end
        HLT: begin
            next_PC = PC_reg;       // Freeze the PC in place
            branch_taken = 1'b1;    // Constantly flush the invalid instructions behind it
        end
        default: begin
            next_PC = PC_reg + 32'h0000_0004;
            branch_taken = 1'b0;
        end
    endcase
end

// Clock the PC
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        PC_reg <= 32'h0000_0000;
    else
        PC_reg <= next_PC;
end

// Route the internal register to the output port
assign PC = PC_reg;

endmodule

