module SPI_Slave_Receiver(
input logic clk,                    // System clock (De-10 Lite clock = 50MHz)
input logic rst_n,                  // Active low reset
input logic S_CLK,                  // External SPI Clock
input logic SS_N,                   // Active low Slave Select
input logic MOSI,                   // Master Out Slave In
output logic [7:0] received_data,   // Received data
output logic data_valid             // 1 cycle high when data is valid
);

logic [2:0] S_CLK_sync;             // Synchronize S_CLK to system clock
logic [1:0] SS_N_sync;              // Synchronize SS_N to system clock
logic [1:0] MOSI_sync;              // Synchronize MOSI to system clock

logic [2:0] bit_count;              // Counts bits received (0-7)
logic [7:0] shift_reg;              // Shift register to assemble received byte
logic S_Clk_Rising;                 // Detect rising edge of S_CLK

assign S_Clk_Rising = (S_CLK_sync[2:1] == 2'b01);       // Rising edge when previous was 0 and current is 1

// Synchronize SPI signals to system clock 
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset on active low reset
        S_CLK_sync <= 3'b000;
        SS_N_sync <= 2'b11;                       // Inactive state for SS_N
        MOSI_sync <= 2'b00;
    end else begin
        S_CLK_sync <= {S_CLK_sync[1:0], S_CLK};   // Shift in S_CLK
        SS_N_sync <= {SS_N_sync[0], SS_N};        // Shift in SS_N
        MOSI_sync <= {MOSI_sync[0], MOSI};        // Shift in MOSI
    end
end

// Main SPI reciveing logic
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset on active low reset
        bit_count <= 3'b000;
        shift_reg <= 8'b00000000;
        received_data <= 8'b00000000;
        data_valid <= 1'b0;
    end else begin
        data_valid <= 1'b0;                                                 // Default to 0, set to 1 when a byte is received

        // Only receive data when SS_N is low
        if (SS_N_sync[1] == 1'b0) begin
            if (S_Clk_Rising) begin
                shift_reg <= {shift_reg[6:0], MOSI_sync[1]};                // Shift in MOSI bit
                bit_count <= bit_count + 1;                                 // Increment bit count
        
                // when 8 bits received, capture full byte and set data valid
                if (bit_count == 3'b111) begin
                    received_data <= {shift_reg[6:0], MOSI_sync[1]};        // Capture full byte
                    data_valid <= 1'b1;                                     // Indicate data is valid
                end
            end
        end else begin
            // If SS_N is high, reset bit count 
            bit_count <= 3'b000;
            shift_reg <= 8'h00; 
        end
    end
end

endmodule

// This module is a placeholder for the SPI Master Transmitter. 
// The actual implementation would depend on the specific requirements of the SPI communication, 
// such as the data to be transmitted and the timing of the signals.
module SPI_Master_Transmitter(
input logic clk,                    // System clock (De-10 Lite clock = 50MHz)
input logic rst_n,                  // Active low reset
input logic S_CLK,                  // External SPI Clock
input logic SS_N,                   // Active low Slave Select
input logic MOSI,                   // Master Out Slave In
output logic S_CLK_out,             // External SPI Clock
output logic SS_N_out,              // Active low Slave Select
output logic MOSI_out               // Master Out Slave In
);


endmodule