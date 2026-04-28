// File: rtl/vision/sobel_conv.sv
module sobel_conv(
    input  logic        clk,
    input  logic [71:0] pixel_data, // 9 pixels (8 bits each)
    input  logic        pixel_data_valid,
    output logic [7:0]  convolved_data,
    output logic        convolved_data_valid
);

    // Map the 72-bit vector to a 3x3 grid [cite: 973-983]
    // p00 p01 p02
    // p10 p11 p12
    // p20 p21 p22
    logic [7:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;
    assign {p02, p01, p00, p12, p11, p10, p22, p21, p20} = pixel_data;

    // 12-bit signed logic prevents overflow during arithmetic
    logic signed [11:0] gx, gy;
    logic signed [11:0] abs_gx, abs_gy;
    logic [11:0]        sum;
    logic               valid_pipe;

    always_ff @(posedge clk) begin
        // Stage 1: Calculate Gx and Gy
        // Gx = -p00 + p02 - 2*p10 + 2*p12 - p20 + p22
        gx <= $signed({4'b0, p02}) - $signed({4'b0, p00}) + 
              $signed({3'b0, p12, 1'b0}) - $signed({3'b0, p10, 1'b0}) + 
              $signed({4'b0, p22}) - $signed({4'b0, p20});

        // Gy = p00 + 2*p01 + p02 - p20 - 2*p21 - p22
        gy <= $signed({4'b0, p00}) + $signed({3'b0, p01, 1'b0}) + $signed({4'b0, p02}) - 
              $signed({4'b0, p20}) - $signed({3'b0, p21, 1'b0}) - $signed({4'b0, p22});
              
        valid_pipe <= pixel_data_valid;

        // Stage 2: Absolute values
        abs_gx <= (gx < 0) ? -gx : gx;
        abs_gy <= (gy < 0) ? -gy : gy;
        convolved_data_valid <= valid_pipe;

        // Stage 3: Sum and Clamp to 8 bits (255 max)
        sum = abs_gx + abs_gy;
        convolved_data <= (sum > 12'd255) ? 8'd255 : sum[7:0];
    end

endmodule
