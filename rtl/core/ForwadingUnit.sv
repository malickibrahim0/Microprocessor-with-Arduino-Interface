module ForwardingUnit(
input  logic [4:0] IF_EX_RA, IF_EX_RB, // 5 bits addresses 32 hardware registers
input  logic [4:0] EX_WB_RD,
input  logic [3:0] EX_WB_OPCODE,
output logic ForwardA, 
output logic ForwardB
);

localparam LDI  = 4'h1;
localparam COMP = 4'hC;

logic WB_writes;

// Determine if the instruction in the WB stage actually writes to a register.
always_comb begin
WB_writes = (EX_WB_OPCODE >= LDI) && (EX_WB_OPCODE <= COMP);
end

// Forwarding logic
always_comb begin
ForwardA = 1'b0;
ForwardB = 1'b0;

// Only forward if it is a valid write AND the destination is not Register 0
if (WB_writes && (EX_WB_RD != 5'b00000)) begin
    
    // If WB destination matches the A input
    if (EX_WB_RD == IF_EX_RA) begin
        ForwardA = 1'b1;
    end
    
    // If WB destination matches the B input
    if (EX_WB_RD == IF_EX_RB) begin
        ForwardB = 1'b1;
    end
end
end

endmodule