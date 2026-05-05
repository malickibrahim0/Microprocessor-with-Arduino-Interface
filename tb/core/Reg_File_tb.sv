module Register_File_32_tb();

logic clk, reset;
logic write_enable;
logic [4:0]  RA, RB, RD;           
logic [3:0]  OPCODE_WB;            
logic [31:0] RF_data_in;           
logic [31:0] RF_data_out_A, RF_data_out_B;

// Instantiate the 32-bit Register File
Register_File_32 TEST (
    .clk(clk), 
    .reset(reset), 
    .write_enable(write_enable), 
    .read_addr_A(RA), 
    .read_addr_B(RB), 
    .write_addr(RD), 
    .write_data(RF_data_in), 
    .out_data_A(RF_data_out_A), 
    .out_data_B(RF_data_out_B)
);

// Clock generation (Period = 20ns)
initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
end

// Reset generation
initial begin
    reset = 1'b1;
    #20 reset = 1'b0;
end

// Task for testing Write-Before-Read / Internal Forwarding
// Note: If your RegFile is truly asynchronous on read, 
// it should show the data as soon as the clock edge hits.
task internal_bypass_test();
    begin
        // Test sequence: Write to R5 and read from R5 simultaneously
        RA = 5'h05; 
        RB = 5'h05; 
        RD = 5'h05; 
        write_enable = 1'b1; 
        RF_data_in = 32'hCAFE_BABE; 
        
        #15; // Wait for the positive edge to commit the write
        
        if (RF_data_out_A == 32'hCAFE_BABE)
            $display("SUCCESS: Internal Forwarding/Read-after-Write Passed.");
        else
            $display("FAILURE: Expected CAFE_BABE, got %h", RF_data_out_A);
        
        #5; // Finish cycle
    end
endtask

// Test sequence
initial begin
    $monitor("Time: %0t | WE: %b | RD: %02h | Data: %08h | RA: %02h (A: %08h) | RB: %02h (B: %08h)",
                $time, write_enable, RD, RF_data_in, RA, RF_data_out_A, RB, RF_data_out_B);
                
    // Initial state
    RA = 5'h0; RB = 5'h0; RD = 5'h0; write_enable = 1'b0; RF_data_in = 32'h0; 
    
    // Align to the negative clock edge for stimulus
    #25;   
    
    // TEST CASE 1: The Register 0 Trap     
    // Attempting to write AA to R0. Should remain 0.
    write_enable = 1'b1; RD = 5'h00; RF_data_in = 32'hAAAA_AAAA; 
    #20; 
    
    // TEST CASE 2: Standard Multi-Register Write     
    RD = 5'h01; RF_data_in = 32'hBBBB_BBBB; #20;
    RD = 5'h02; RF_data_in = 32'hCCCC_CCCC; #20;
    
    // TEST CASE 3: Dual Port Read     
    // Reading R1 and R2 simultaneously
    write_enable = 1'b0; RA = 5'h01; RB = 5'h02;
    #20;

    // TEST CASE 4: Internal Bypass Check     
    internal_bypass_test();

    $finish;
end
endmodule