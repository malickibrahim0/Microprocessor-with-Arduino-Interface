// File: rtl/vision/vga_controller.sv
module vga_controller(
    input  logic        clk_50mhz,  // Main system clock
    input  logic        reset,
    input  logic [7:0]  pixel_in,   // 8-bit grayscale from Sobel
    output logic        vga_hs,     // Horizontal Sync
    output logic        vga_vs,     // Vertical Sync
    output logic [3:0]  vga_r,      // 4-bit Red
    output logic [3:0]  vga_g,      // 4-bit Green
    output logic [3:0]  vga_b,      // 4-bit Blue
    output logic [9:0]  pixel_x,    // Current X coordinate request
    output logic [9:0]  pixel_y,    // Current Y coordinate request
    output logic        video_on    // High when in visible drawing area
);

    // Generate 25MHz Pixel Clock from 50MHz
    logic clk_25mhz;
    always_ff @(posedge clk_50mhz or posedge reset) begin
        if (reset) clk_25mhz <= 1'b0;
        else       clk_25mhz <= ~clk_25mhz;
    end

    // VGA 640x480 @ 60Hz Timings
    localparam H_DISPLAY       = 640;
    localparam H_FRONT_PORCH   = 16;
    localparam H_SYNC_PULSE    = 96;
    localparam H_BACK_PORCH    = 48;
    localparam H_TOTAL         = 800;

    localparam V_DISPLAY       = 480;
    localparam V_FRONT_PORCH   = 10;
    localparam V_SYNC_PULSE    = 2;
    localparam V_BACK_PORCH    = 33;
    localparam V_TOTAL         = 525;

    logic [9:0] h_count, v_count;

    always_ff @(posedge clk_25mhz or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) v_count <= 10'd0;
                else                        v_count <= v_count + 10'd1;
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    // Sync Signals (Active Low for 640x480)
    assign vga_hs = ~((h_count >= H_DISPLAY + H_FRONT_PORCH) && (h_count < H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE));
    assign vga_vs = ~((v_count >= V_DISPLAY + V_FRONT_PORCH) && (v_count < V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE));

    // Video On logic
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
    assign pixel_x  = h_count;
    assign pixel_y  = v_count;

    // Output Mapping: Expand 8-bit Grayscale to 12-bit RGB
    // Use the top 4 bits of the Sobel output for each color channel
    assign vga_r = video_on ? pixel_in[7:4] : 4'd0;
    assign vga_g = video_on ? pixel_in[7:4] : 4'd0;
    assign vga_b = video_on ? pixel_in[7:4] : 4'd0;

endmodule