module SPI_Slave_Receiver_tb();

logic clk;
logic rst_n;
logic S_CLK;
logic SS_N;
logic MOSI;
logic [7:0] received_data;
logic data_valid;

// Instantiate the SPI Slave Receiver
SPI_Slave_Receiver Test (
    .clk(clk),
    .rst_n(rst_n),
    .S_CLK(S_CLK),
    .SS_N(SS_N),
    .MOSI(MOSI),
    .received_data(received_data),
    .data_valid(data_valid)
);

// Clock generation
initial begin
    clk = 0;
    forever #10 clk = ~clk; // 50MHz clock
end

// Reset generation
initial begin
    rst_n = 1'b0;
    #20 rst_n = 1'b1;
end

// Test sequence
initial begin
    S_CLK = 1'b0;
    SS_N = 1'b1; // Inactive
    MOSI = 1'b0;
    #30; // Wait for reset to complete

    // Test case: Send 0b10101010
    SS_N = 1'b0; // Activate slave
    MOSI = 1'b1;
    #20 S_CLK = 1'b1; // Rising edge, bit 7
    #20 S_CLK = 1'b0;

    MOSI = 1'b0;
    #20 S_CLK = 1'b1; // Rising edge, bit 6
    #20 S_CLK = 1'b0;

    MOSI = 1'b1;
    #20 S_CLK = 1'b1; // Rising edge, bit 5
    #20 S_CLK = 1'b0;

    MOSI = 1'b0;
    #20 S_CLK = 1'b1; // Rising edge, bit 4
    #20 S_CLK = 1'b0;

    MOSI = 1'b1;
    #20 S_CLK = 1'b1; // Rising edge, bit 3
    #20 S_CLK = 1'b0;

    MOSI = 1'b0;
    #20 S_CLK = 1'b1; // Rising edge, bit 2
    #20 S_CLK = 1'b0;

    MOSI = 1'b1;
    #20 S_CLK = 1'b1; // Rising edge, bit 1
    #20 S_CLK = 1'b0;

    MOSI = 1'b0;
    #20 S_CLK = 1'b1; // Rising edge, bit 0
    #20 S_CLK = 1'b0;

    
    #20;        // Wait for data to be received

    @(posedge data_valid); // Wait until data is valid before checking results

    // Check results
    if (received_data == 8'b10101010 && data_valid) begin
        $display("Test case passed: Received 0b10101010");
    end else begin
        $display("Test case failed: Expected 0b10101010, got %b", received_data);
    end

    #50; // Wait before finishing

    $finish;
end
endmodule