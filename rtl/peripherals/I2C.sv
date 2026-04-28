// File: rtl/peripherals/I2C_Master.sv
module I2C_Master (
    input  logic       clk,         // 50 MHz system clock
    input  logic       reset,       // Active high reset
    input  logic       start,       // Pulse high to start transmission
    input  logic [7:0] device_addr, // 8-bit device write address
    input  logic [7:0] reg_addr,    // Internal register address to write
    input  logic [7:0] write_data,  // Data to write into the register
    
    output logic       scl,         // I2C Clock
    inout  tri         sda,         // I2C Bidirectional Data
    
    output logic       busy,        // High while transmitting
    output logic       ack_error    // High if slave fails to acknowledge
);

    // Clock Divider: 50 MHz to 200 kHz (250 cycles)
    // 200 kHz state ticks = 100 kHz I2C Clock (since each clock has a LOW and HIGH state)
    localparam int CLK_DIV = 250;
    logic [7:0] div_counter;
    logic       i2c_tick;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            div_counter <= 8'd0;
            i2c_tick <= 1'b0;
        end else if (div_counter == (CLK_DIV - 1)) begin
            div_counter <= 8'd0;
            i2c_tick <= 1'b1;
        end else begin
            div_counter <= div_counter + 8'd1;
            i2c_tick <= 1'b0;
        end
    end

    // Explicit Phase State Machine Encodings
    typedef enum logic [4:0] {
        IDLE,
        START1, START2,
        SEND_DEV_LOW, SEND_DEV_HIGH,
        ACK1_LOW, ACK1_HIGH,
        SEND_REG_LOW, SEND_REG_HIGH,
        ACK2_LOW, ACK2_HIGH,
        SEND_DATA_LOW, SEND_DATA_HIGH,
        ACK3_LOW, ACK3_HIGH,
        STOP1, STOP2
    } state_t;

    state_t state;
    
    logic [7:0] shift_reg;
    logic [2:0] bit_count;
    logic sda_out, sda_oe;
    
    // Tri-state buffer for bidirectional SDA pin
    assign sda = sda_oe ? sda_out : 1'bz;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            scl        <= 1'b1;
            sda_out    <= 1'b1;
            sda_oe     <= 1'b1;
            busy       <= 1'b0;
            ack_error  <= 1'b0;
            bit_count  <= 3'd7;
            shift_reg  <= 8'd0;
        end else if (i2c_tick) begin
            case (state)
                IDLE: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    sda_oe  <= 1'b1;
                    if (start) begin
                        busy      <= 1'b1;
                        ack_error <= 1'b0;
                        shift_reg <= device_addr;
                        bit_count <= 3'd7;
                        state     <= START1;
                    end else begin
                        busy      <= 1'b0;
                    end
                end

                START1: begin
                    sda_out <= 1'b0; // SDA goes low while SCL is high
                    state   <= START2;
                end
                START2: begin
                    scl     <= 1'b0; // SCL goes low
                    state   <= SEND_DEV_LOW;
                end

                SEND_DEV_LOW: begin
                    scl     <= 1'b0;
                    sda_oe  <= 1'b1;
                    sda_out <= shift_reg[7];
                    shift_reg <= {shift_reg[6:0], 1'b0};
                    state   <= SEND_DEV_HIGH;
                end
                SEND_DEV_HIGH: begin
                    scl     <= 1'b1;
                    if (bit_count == 3'd0) state <= ACK1_LOW;
                    else begin
                        bit_count <= bit_count - 3'd1;
                        state <= SEND_DEV_LOW;
                    end
                end

                ACK1_LOW: begin
                    scl    <= 1'b0;
                    sda_oe <= 1'b0; // Release SDA to read ACK
                    state  <= ACK1_HIGH;
                end
                ACK1_HIGH: begin
                    scl    <= 1'b1;
                    if (sda !== 1'b0) ack_error <= 1'b1;
                    shift_reg <= reg_addr;
                    bit_count <= 3'd7;
                    state  <= SEND_REG_LOW;
                end

                SEND_REG_LOW: begin
                    scl     <= 1'b0;
                    sda_oe  <= 1'b1;
                    sda_out <= shift_reg[7];
                    shift_reg <= {shift_reg[6:0], 1'b0};
                    state   <= SEND_REG_HIGH;
                end
                SEND_REG_HIGH: begin
                    scl     <= 1'b1;
                    if (bit_count == 3'd0) state <= ACK2_LOW;
                    else begin
                        bit_count <= bit_count - 3'd1;
                        state <= SEND_REG_LOW;
                    end
                end

                ACK2_LOW: begin
                    scl    <= 1'b0;
                    sda_oe <= 1'b0;
                    state  <= ACK2_HIGH;
                end
                ACK2_HIGH: begin
                    scl    <= 1'b1;
                    if (sda !== 1'b0) ack_error <= 1'b1;
                    shift_reg <= write_data;
                    bit_count <= 3'd7;
                    state  <= SEND_DATA_LOW;
                end

                SEND_DATA_LOW: begin
                    scl     <= 1'b0;
                    sda_oe  <= 1'b1;
                    sda_out <= shift_reg[7];
                    shift_reg <= {shift_reg[6:0], 1'b0};
                    state   <= SEND_DATA_HIGH;
                end
                SEND_DATA_HIGH: begin
                    scl     <= 1'b1;
                    if (bit_count == 3'd0) state <= ACK3_LOW;
                    else begin
                        bit_count <= bit_count - 3'd1;
                        state <= SEND_DATA_LOW;
                    end
                end

                ACK3_LOW: begin
                    scl    <= 1'b0;
                    sda_oe <= 1'b0;
                    state  <= ACK3_HIGH;
                end
                ACK3_HIGH: begin
                    scl    <= 1'b1;
                    if (sda !== 1'b0) ack_error <= 1'b1;
                    state  <= STOP1;
                end

                STOP1: begin
                    scl     <= 1'b0;
                    sda_oe  <= 1'b1;
                    sda_out <= 1'b0; // Pull SDA low while SCL is low
                    state   <= STOP2;
                end
                STOP2: begin
                    scl     <= 1'b1; // SCL goes high
                    // Next tick (back to IDLE), SDA will go high while SCL is high to create STOP condition
                    state   <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule