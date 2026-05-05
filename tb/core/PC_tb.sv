module Program_Counter_32_tb();
logic clk, reset;
logic [3:0] OPCODE_EX;
logic [31:0] IF_EX_PC, Alu_out, A, B;
logic [31:0] Branch_Offset;
logic [31:0] PC;
logic branch_taken;

localparam JMP  = 4'hE;
localparam CMPJ = 4'hD;
localparam HLT = 4'hF;
localparam NOP = 4'h0;  // Default case for testing

Program_Counter_32 TEST (
    .clk(clk), .reset(reset), .OPCODE_EX(OPCODE_EX), .IF_EX_PC(IF_EX_PC), 
    .Alu_out(Alu_out), .A(A), .B(B), .Branch_Offset(Branch_Offset), 
    .PC(PC), .branch_taken(branch_taken)
);
// Clock generation (Period = 20)
initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
end

// Reset generation
initial begin
    reset = 1'b1;
    #20 reset = 1'b0;
end

always @(negedge clk) begin
    $display("Time: %0t | PC: %08h, IF_EX_PC: %08h, Alu_out: %08h, A: %08h, B: %08h, Offset: %08h, branch_taken: %01h", 
             $time, PC, IF_EX_PC, Alu_out, A, B, Branch_Offset, branch_taken);
end

initial begin
    // Initialization
    OPCODE_EX = NOP; 
    IF_EX_PC = 32'h0000_0000; 
    Alu_out = 32'h0000_0000; 
    A = 32'h0000_0000; 
    B = 32'h0000_0000; 
    Branch_Offset = 32'h0000_000;
    #25;

    // Test Case 1 - NOP (No Operation)
    // PC should count normally by 4
    OPCODE_EX = NOP;
    #20;


    // Test Case 2 - JMP
    // PC should jump to Alu_out (0xB0)
    OPCODE_EX = JMP;
    IF_EX_PC = 32'h0000_00A0;
    Alu_out = 32'h0000_00B0;
    #20;


    // Test Case 3 - CMPJ (Condtion False)
    // A < B, Branch fails
    // PC should count normally from B0 to B4.
    OPCODE_EX = CMPJ;
    IF_EX_PC = 32'h0000_00A0;
    A = 32'h0000_00C0;
    B = 32'h0000_00D0;
    Branch_Offset = 32'h0000_008;     // Jump forward by 8 bytes (2 instructions)
    #20;

    // Test Case 4 - CMPJ (Condition True)
    // A >= B, so branch Suceeds 
    // PC should jump to IF_EX_PC + Offset (0xA0 + 0x8 = 0xA8)
    OPCODE_EX = CMPJ;
    IF_EX_PC = 32'h0000_00A0;
    A = 32'h0000_00D0;
    B = 32'h0000_00C0;
    Branch_Offset = 32'h0000_008;
    #20;

    // Test Case 5 - HLT
    // PC Should freeze
    OPCODE_EX = HLT;
    #40; 

    $stop;

end

endmodule