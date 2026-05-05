module ALU_32_tb();
// 32-bit Input Vectors
logic [31:0] Aluin_A, Aluin_B;
logic [31:0] RA_Instant, RB_Instant;
logic [3:0]  OPCODE_EX;
logic  prefix_active;
logic [31:0] RAM_data;
logic [31:0] MMIO_data;

// Output Vectors
logic [31:0] Alu_out;
logic Cout, OF, zero;

// Instantiate the 32-bit ALU
ALU_32 TEST (
.Aluin_A(Aluin_A), .Aluin_B(Aluin_B), 
.RA_Instant(RA_Instant), .RB_Instant(RB_Instant), 
.OPCODE_EX(OPCODE_EX), .prefix_active(prefix_active),
.RAM_data(RAM_data), .MMIO_data(MMIO_data),
.Alu_out(Alu_out), .Cout(Cout), .OF(OF), .zero(zero)
);

// Task modified to accept the prefix state as an argument
task randomize_inputs(input logic current_prefix);
begin
    prefix_active = current_prefix;
    
    for (int i = 0; i < 16; i++) begin
        OPCODE_EX = i;
        
        // $urandom generates a full 32-bit unsigned integer natively
        Aluin_A    = $urandom;
        Aluin_B    = $urandom;
        RA_Instant = $urandom;
        RB_Instant = $urandom;
        RAM_data   = $urandom;
        MMIO_data  = $urandom;
        
        #10; // Wait for combinational logic to settle
        
        // Print formatted 8-character hex for 32-bit values
        $display("PFX: %b | OP: %h | A: %08h | B: %08h || OUT: %08h | C:%b O:%b Z:%b", 
                    prefix_active, OPCODE_EX, Aluin_A, Aluin_B, Alu_out, Cout, OF, zero);
    end
end
endtask

// Cross reference result with a calculator for verification
initial begin
$display("--- Starting Base ISA Tests (Prefix = 0) ---");
randomize_inputs(1'b0); 

$display("\n--- Starting Extended ISA Tests (Prefix = 1) ---");
randomize_inputs(1'b1); 

$finish; // End the simulation safely
end

endmodule