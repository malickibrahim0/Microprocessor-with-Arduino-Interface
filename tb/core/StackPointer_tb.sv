`timescale 1ns/1ps

module tb_StackPointer();

// Signal Declarations
logic clk;
logic reset;
logic [2:0] SP_OP;
logic [7:0] SP;
logic SP_Empty;
logic SP_Full;

// Operation encodings (Matching the DUT)
localparam logic [2:0] SP_HOLD = 3'b000;
localparam logic [2:0] SP_DEC1 = 3'b001;
localparam logic [2:0] SP_INC1 = 3'b010;
localparam logic [2:0] SP_DEC2 = 3'b011;
localparam logic [2:0] SP_INC2 = 3'b100;
localparam logic [2:0] SP_DEC3 = 3'b101;
localparam logic [2:0] SP_INC3 = 3'b110;

// Instantiate Device Under Test (DUT)
StackPointer dut (
    .clk(clk),
    .reset(reset),
    .SP_OP(SP_OP),
    .SP(SP),
    .SP_Empty(SP_Empty),
    .SP_Full(SP_Full)
);

// Clock Generation (50 MHz -> 20ns period)
always begin
    clk = 0; #10;
    clk = 1; #10;
end

// Test Procedure
initial begin
    $display("Starting Stack Pointer Testbench...");

    // Initialize signals
    reset = 1;
    SP_OP = SP_HOLD;
    
    // Hold reset for a few cycles
    #25; 
    reset = 0;
    
    // Task 1: Verify Reset and Empty Flag
    check_state(8'hFF, 1, 0, "After Reset");

    // Task 2: PUSH 1 Byte (SP_DEC1)
    apply_op(SP_DEC1, "PUSH 1 Byte");
    check_state(8'hFE, 0, 0, "Post PUSH 1");

    // Task 3: CALL 16-bit PC (SP_DEC2)
    apply_op(SP_DEC2, "CALL (Push 2 Bytes)");
    check_state(8'hFC, 0, 0, "Post CALL");

    // Task 4: Interrupt Entry (SP_DEC3)
    apply_op(SP_DEC3, "Interrupt (Push 3 Bytes)");
    check_state(8'hF9, 0, 0, "Post Interrupt");

    // Task 5: RETI (SP_INC3)
    apply_op(SP_INC3, "RETI (Pop 3 Bytes)");
    check_state(8'hFC, 0, 0, "Post RETI");

    // Task 6: RET (SP_INC2)
    apply_op(SP_INC2, "RET (Pop 2 Bytes)");
    check_state(8'hFE, 0, 0, "Post RET");

    // Task 7: POP 1 Byte (SP_INC1)
    apply_op(SP_INC1, "POP 1 Byte");
    check_state(8'hFF, 1, 0, "Post POP 1 (Back to Empty)");

    // Task 8: Test SP_Full Flag
    $display("Driving SP to Full State (0x00)...");
    // Force SP near bottom to save simulation time
    force dut.SP = 8'h02; 
    #20;
    release dut.SP;
    
    apply_op(SP_DEC2, "Push 2 Bytes to hit 0x00");
    check_state(8'h00, 0, 1, "Stack Full Flag Check");

    $display("Simulation Finished.");
    $stop;
end

// Helper Task: Apply Operation
task apply_op(input [2:0] op, input string op_name);
    begin
        @(posedge clk);
        SP_OP = op;
        @(posedge clk);
        SP_OP = SP_HOLD; // Return to hold after 1 cycle
        $display("[ACTION] Executed: %s", op_name);
    end
endtask

// Helper Task: Verify State
task check_state(
    input [7:0] expected_SP, 
    input expected_Empty, 
    input expected_Full, 
    input string context_msg
);
    begin
        #1; // Brief delay for outputs to settle
        if (SP !== expected_SP)
            $display("[FAIL] %s | Expected SP: %h, Got: %h", context_msg, expected_SP, SP);
        else if (SP_Empty !== expected_Empty)
            $display("[FAIL] %s | Expected Empty: %b, Got: %b", context_msg, expected_Empty, SP_Empty);
        else if (SP_Full !== expected_Full)
            $display("[FAIL] %s | Expected Full: %b, Got: %b", context_msg, expected_Full, SP_Full);
        else
            $display("[PASS] %s | SP: %h | Empty: %b | Full: %b", context_msg, SP, SP_Empty, SP_Full);
    end
endtask

endmodule