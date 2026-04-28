// This will be used for when a program needs to remeber something temporarily
// and get it back in reverse order. 


// The Stack lives in the 256x8 RAM.
// The StackPointer (SP) is an 8-bit register that tracks where the top of the stack currently is.

// When the CPU execcturs PUSH, POP, CALL or RE, The StackPointer gets upadted and a RAM
// access happens at the address the StackPointer points to.

// Used a Descedning-empty method:
// PUSH Sequence: memory[SP] <= data_in;
//                SP <= SP - 1
// POP Sequence: SP <= SP + 1
//               data_out = memory[SP + 1]
// First Byte is a 0xFF

// PUSH Behavior (one byte per cycle):
// 1. RAM Write: memory[SP] <= low_byte(rX)
// 2. SP Upadte: SP <= SP - 1
// For all a 32-bit register the Controller iterates 4 times
// Each Cycle is wrting one byte and decramenting SP

// POP Behavior (one byte per cycle):
// 1. SP Update: SP <= SP + 1 (pre-increment yo point at the last pushed byte)
// 2. RAM read: rx <- memory[SP + 1]

// Call write_address Behavior:
// 1. Ram Wrirtes: memory[SP] <= PC[7:0] (low byte)
//                 memory[SP - 1] <= PC[15:8] (high byte)
// 2. SP Update: SP <= SP - 2 
// 3. PC Update: PC <= write_address


// RET Behavior:
// 1. SP update: SP <= SP + 2
// 2  RAM reads: PC_High = memory[SP + 1]
//               PC_Low  = memory[SP + 2]
// 3. PC update: PC < {PC_High, PC_Low}

// RETI (Return from Interupt)
// 1. SP update: SP <= SP + 3
// 2. RAM reads: flags = memory[SP + 1]
//               PC_High = memory[SP + 2]
//               PC_Low = memory[SP + 3]
// 3. Updates: PC <= {PC_High, PC_Low}
//              FLAGS <= flags

// (reason for (-2 and +2) is the PC is 16 bit and RAM is 8 bit ) 

module StackPointer (
input  logic clk,
input  logic reset,
input  logic [2:0] SP_OP,    // From Controller 
output logic [7:0] SP,       // Current pointer to top-level mux
output logic  SP_Empty,      // Debug/Status flags 
output logic  SP_Full
);

// Operation encodings 
localparam logic [2:0] SP_HOLD = 3'b000;        // No change
localparam logic [2:0] SP_DEC1 = 3'b001;        // PUSH 1 byte
localparam logic [2:0] SP_INC1 = 3'b010;        // POP 1 byte
localparam logic [2:0] SP_DEC2 = 3'b011;        // CALL (16-bit PC)
localparam logic [2:0] SP_INC2 = 3'b100;        // RET
localparam logic [2:0] SP_DEC3 = 3'b101;        // Interrupt Entry (PC + flags)
localparam logic [2:0] SP_INC3 = 3'b110;        // RETI

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        SP <= 8'hFF;        // Descedning Empty Method Start
    end else begin
        case (SP_OP)
            SP_DEC1: SP <= SP - 8'd1;       
            SP_INC1: SP <= SP + 8'd1;
            SP_DEC2: SP <= SP - 8'd2;
            SP_INC2: SP <= SP + 8'd2;
            SP_DEC3: SP <= SP - 8'd3;
            SP_INC3: SP <= SP + 8'd3;
            default: SP <= SP; // SP_HOLD
        endcase
    end
end
// For debugging with LEDS
assign SP_Empty = (SP == 8'hFF);        // Nothing has been pushed 
assign SP_Full  = (SP == 8'h00);        // One more push and we have to wrap

endmodule