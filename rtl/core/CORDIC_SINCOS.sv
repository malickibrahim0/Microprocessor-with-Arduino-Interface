// File: rtl/core/CORDIC_SINCOS.sv
module CORDIC_SINCOS #(
    parameter W = 16,
    parameter N = 16 // Enforced 16 stages
)(
    input  logic        clk, reset, start,
    input  logic signed [W-1:0] angle_in,
    output logic signed [W-1:0] cos_out, sin_out,
    output logic        done
);

    // 1/K pre-scale: round(0.60725 * 2^15)
    localparam logic signed [W-1:0] INV_K = 16'sd19898;

    // Atan table (16 stages, Q1.15 format)
    localparam logic signed [W-1:0] ATAN_TABLE [0:N-1] = '{
        16'sh2000, 16'sh12E4, 16'sh09FB, 16'sh0511,
        16'sh028B, 16'sh0146, 16'sh00A3, 16'sh0051,
        16'sh0029, 16'sh0014, 16'sh000A, 16'sh0005,
        16'sh0003, 16'sh0001, 16'sh0001, 16'sh0000
    };

    logic signed [W-1:0] x [0:N], y [0:N], z [0:N];
    logic                valid [0:N];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x[0] <= '0; y[0] <= '0; z[0] <= '0; valid[0] <= 1'b0;
        end else begin
            x[0] <= INV_K;
            y[0] <= 16'sd0;
            z[0] <= angle_in;
            valid[0] <= start;
        end
    end

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : stage
            logic signed [W-1:0] x_shifted, y_shifted;
            logic signed [W-1:0] x_next, y_next, z_next;

            assign x_shifted = x[i] >>> i;
            assign y_shifted = y[i] >>> i;

            always_comb begin
                if (z[i][W-1]) begin // Negative phase
                    x_next = x[i] + y_shifted;
                    y_next = y[i] - x_shifted;
                    z_next = z[i] + ATAN_TABLE[i];
                end else begin       // Positive phase
                    x_next = x[i] - y_shifted;
                    y_next = y[i] + x_shifted;
                    z_next = z[i] - ATAN_TABLE[i];
                end
            end

            always_ff @(posedge clk or posedge reset) begin
                if (reset) begin
                    x[i+1] <= '0; y[i+1] <= '0; z[i+1] <= '0; valid[i+1] <= 1'b0;
                end else begin
                    x[i+1] <= x_next;
                    y[i+1] <= y_next;
                    z[i+1] <= z_next;
                    valid[i+1] <= valid[i];
                end
            end
        end
    endgenerate

    assign cos_out = x[N];
    assign sin_out = y[N];
    assign done    = valid[N];

endmodule