module StackPointer_32 (
input  logic clk,
input  logic reset,
input  logic [2:0] SP_OP,   
output logic [31:0] SP,          // 32-bit pointer for 32-bit address space
output logic SP_Empty,
output logic SP_Full
);

// 32-bit Word-Aligned Encodings 
localparam logic [2:0] SP_HOLD = 3'b000;
localparam logic [2:0] SP_DEC4 = 3'b001;    // PUSH 32-bit Word
localparam logic [2:0] SP_INC4 = 3'b010;    // POP 32-bit Word
localparam logic [2:0] SP_DEC8 = 3'b011;    // CALL (Push 32-bit PC + Status)
localparam logic [2:0] SP_INC8 = 3'b100;    // RET  (Pop 32-bit PC + Status)

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        SP <= 32'h0000_FFFF;        // Top of Stack (adjust based on RAM size)
    end else begin
        case (SP_OP)
            SP_DEC4: SP <= SP - 32'd4;       
            SP_INC4: SP <= SP + 32'd4;
            SP_DEC8: SP <= SP - 32'd8;
            SP_INC8: SP <= SP + 32'd8;
            default: SP <= SP;
        endcase
    end
end

assign SP_Empty = (SP == 32'h0000_FFFF);
assign SP_Full  = (SP == 32'h0000_0000);

endmodule