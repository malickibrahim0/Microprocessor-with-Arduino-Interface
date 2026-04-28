`timescale 1ns/1ps

module tb_MMIO_Decoder();

// System Signals
logic clk;
logic reset;

// CPU Interface
logic [7:0]  MMIO_address;
logic [31:0] MMIO_write_data;
logic        MMIO_write_enable;
logic        MMIO_read_enable;
logic [31:0] MMIO_read_data;

// Peripheral Interface: CORDIC
logic        CORDIC_start;
logic [19:0] CORDIC_angle;
logic [12:0] CORDIC_sin;
logic [12:0] CORDIC_cos;
logic        CORDIC_busy;
logic        CORDIC_done;

// Peripheral Interface: Image / FIFO
logic [7:0]  IMG_threshold;
logic [3:0]  IMG_kernel;
logic [7:0]  IMG_status;

// Instantiate DUT
MMIO_Decoder uut (.*); // Implicit port connection for matching names

// Clock Generation (50 MHz)
always begin
    clk = 0; #10;
    clk = 1; #10;
end

// Test Procedure
initial begin
    $display("Starting MMIO Decoder Testbench...");

    // 1. Initialize Inputs
    reset = 1;
    MMIO_address = 0;
    MMIO_write_data = 0;
    MMIO_write_enable = 0;
    MMIO_read_enable = 0;
    
    CORDIC_sin = 0;
    CORDIC_cos = 0;
    CORDIC_busy = 0;
    CORDIC_done = 0;
    IMG_status = 0;

    #25; 
    reset = 0;

    // 2. Write to Configuration Registers
    $display("\n--- Testing Writes to Registers ---");
    cpu_write(8'h01, 32'h000A_BCDE); // Write CORDIC Angle
    cpu_write(8'h10, 32'h0000_00AA); // Write IMG Threshold
    cpu_write(8'h11, 32'h0000_0005); // Write IMG Kernel

    // Verify Outputs dynamically updated
    #1;
    if (CORDIC_angle == 20'hABCDE) $display("[PASS] CORDIC Angle Output");
    if (IMG_threshold == 8'hAA)    $display("[PASS] IMG Threshold Output");
    if (IMG_kernel == 4'h5)        $display("[PASS] IMG Kernel Output");

    // 3. Test CORDIC Start Pulse
    $display("\n--- Testing CORDIC Start Pulse ---");
    cpu_write(8'h00, 32'h0000_0001); // Write 1 to start CORDIC
    // The start pulse should assert during the write cycle
    
    // 4. Test Reads from Peripherals
    $display("\n--- Testing Reads from Peripherals ---");
    
    // Mock hardware accelerator responses
    CORDIC_sin  = 13'h1FFF; 
    CORDIC_cos  = 13'h0000;
    CORDIC_busy = 0;
    CORDIC_done = 1;
    IMG_status  = 8'hFF;

    cpu_read(8'h02, 32'h0000_1FFF, "Read CORDIC Sine");
    cpu_read(8'h00, 32'h0000_0002, "Read CORDIC Status (Done=1, Busy=0)");
    cpu_read(8'hF0, 32'h0000_00FF, "Read IMG Status");

    $display("\nSimulation Finished.");
    $stop;
end

// Helper Task: CPU Write
task cpu_write(input [7:0] addr, input [31:0] data);
    begin
        @(posedge clk);
        MMIO_address = addr;
        MMIO_write_data = data;
        MMIO_write_enable = 1;
        
        // Check start pulse combinationally
        if (addr == 8'h00 && data[0] == 1) begin
            #1; // Brief delay to let combinational logic settle
            if (CORDIC_start == 1) $display("[PASS] CORDIC_start pulse asserted.");
        end

        @(posedge clk);
        MMIO_write_enable = 0;
        MMIO_address = 0;
    end
endtask

// Helper Task: CPU Read
task cpu_read(input [7:0] addr, input [31:0] expected, input string msg);
    begin
        @(posedge clk);
        MMIO_address = addr;
        MMIO_read_enable = 1;
        #1; // Wait for combinational read mux to settle
        
        if (MMIO_read_data !== expected)
            $display("[FAIL] %s | Addr: %h | Expected: %h | Got: %h", msg, addr, expected, MMIO_read_data);
        else
            $display("[PASS] %s | Data: %h", msg, MMIO_read_data);
            
        @(posedge clk);
        MMIO_read_enable = 0;
        MMIO_address = 0;
    end
endtask

endmodule