module ForwardingUnit_tb();
logic [4:0] IF_EX_RA, IF_EX_RB;
logic [4:0] EX_WB_RD;
logic [3:0] EX_WB_OPCODE;
logic ForwardA, ForwardB;

localparam LDI = 4'h1;
localparam COMP = 4'hC;
localparam CMPJ = 4'hD;
localparam NOP = 4'h0;

ForwardingUnit TEST (.IF_EX_RA(IF_EX_RA), .IF_EX_RB(IF_EX_RB), 
                     .EX_WB_RD(EX_WB_RD), .EX_WB_OPCODE(EX_WB_OPCODE), 
                     .ForwardA(ForwardA), .ForwardB(ForwardB));



initial begin
$monitor("Time: %0t | OPCODE: %01h | RD: %01h | RA: %01h | RB: %01h || FwdA: %b | FwdB: %b", 
              $time, EX_WB_OPCODE, EX_WB_RD, IF_EX_RA, IF_EX_RB, ForwardA, ForwardB);

    // Initialize inputs
    EX_WB_OPCODE = NOP;
    EX_WB_RD = 5'h0;
    IF_EX_RA = 5'h0;
    IF_EX_RB = 5'h0;
    #10;

    // Test Case 1: Forwarding to A (RD = RA)
    EX_WB_OPCODE = LDI;
    EX_WB_RD = 5'hA;
    IF_EX_RA = 5'hA;
    IF_EX_RB = 5'hB;
    #10;

    // Test Case 2: Forwarding to B (RD = RB)
    EX_WB_OPCODE = COMP;
    EX_WB_RD = 5'hB;
    IF_EX_RA = 5'hA;
    IF_EX_RB = 5'hB;
    #10;

    // Test Case 3: Invalid Write / Branch (RD matches, but no write occurs)
    EX_WB_OPCODE = CMPJ;
    EX_WB_RD = 5'hB;
    IF_EX_RA = 5'hA;
    IF_EX_RB = 5'hB;
    #10;
    
    // Test Case 4: Dual Forwarding (Both RA and RB need the same value)
    EX_WB_OPCODE = LDI;
    EX_WB_RD = 5'hC;
    IF_EX_RA = 5'hC;
    IF_EX_RB = 5'hC;
    #10;

    // Test Case 5: Register 0 Trap (Write to R0 should be ignored)
    EX_WB_OPCODE = LDI;
    EX_WB_RD = 5'h0;
    IF_EX_RA = 5'h0;
    IF_EX_RB = 5'h0;
    #10;

    $stop;



end

endmodule