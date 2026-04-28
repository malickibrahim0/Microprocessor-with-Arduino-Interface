`timescale 1ns/1ps

module tb_RAM_256x8();

// Signal Declarations
logic clk;
logic write_enable;
logic [7:0] write_address;
logic [7:0] data_in;
logic [7:0] read_address;
logic [7:0] data_out;

// Instantiate Device Under Test (DUT)
RAM_256x8 RAM_TEST (
    .clk(clk),
    .write_enable(write_enable),
    .write_address(write_address),
    .data_in(data_in),
    .read_address(read_address),
    .data_out(data_out)
);

// Clock Generation (50 MHz -> 20ns period)
always begin
    clk = 0; #10;
    clk = 1; #10;
end

// Test Procedure
initial begin
    // Initialize signals
    write_enable = 0;
    write_address = 0;
    data_in = 0;
    read_address = 0;

    $display("Starting RAM Testbench...");
    @(posedge clk);

    // Task 1: Write data to a few locations
    write_to_ram(8'h0A, 8'hAA); // Address 10, Data AA
    write_to_ram(8'h1F, 8'h55); // Address 31, Data 55
    write_to_ram(8'hFF, 8'h12); // Address 255, Data 12

    // Task 2: Read back and verify
    #10; // Small delay
    check_ram(8'h0A, 8'hAA);
    check_ram(8'h1F, 8'h55);
    check_ram(8'hFF, 8'h12);

    // Task 3: Verify Asynchronous behavior 
    // (Read address changes without clk edge)
    read_address = 8'h0A;
    #2; 
    if (data_out == 8'hAA) 
        $display("[PASS] Async Read check: Addr 0A = AA");
    
    $display("Simulation Finished.");
    $stop;
end

// Helper Task: Write
task write_to_ram(input [7:0] addr, input [7:0] data);
    begin
        @(posedge clk);
        write_enable = 1;
        write_address = addr;
        data_in = data;
        @(posedge clk);
        write_enable = 0;
        $display("[WRITE] Addr: %h | Data: %h", addr, data);
    end
endtask

// Helper Task: Verify
task check_ram(input [7:0] addr, input [7:0] expected_data);
    begin
        read_address = addr;
        #1; // Wait for logic propagation
        if (data_out !== expected_data)
            $display("[FAIL] Addr: %h | Expected: %h | Got: %h", addr, expected_data, data_out);
        else
            $display("[PASS] Addr: %h | Data: %h", addr, data_out);
    end
endtask

endmodule