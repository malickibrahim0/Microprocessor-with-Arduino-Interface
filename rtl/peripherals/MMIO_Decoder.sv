// Register Map:
// 0x00 CORDIC_CTRL  R/W  bit0=start(wr-pulse)/busy(rd), bit1=done(rd-only)
// 0x01 CORDIC_ANGLE W    20-bit phase input
// 0x02 CORDIC_SIN   R    13-bit sine result
// 0x03 CORDIC_COS   R    13-bit cosine result
// 0x10 IMG_THRESH   W    8-bit threshold
// 0x11 IMG_KERNEL   W    4-bit kernel select  (port reserved, reg added)
// 0xF0 IMG_STATUS   R    8-bit FIFO/frame flags

module MMIO_Decoder (
input  logic clk,
input  logic reset,

// CPU Interface
input  logic [7:0]  MMIO_address,      // Unified address bus
input  logic [31:0] MMIO_write_data,         
input  logic        MMIO_write_enable,
input  logic        MMIO_read_enable,        
output logic [31:0] MMIO_read_data,          

// Peripheral Interface: CORDIC
output logic        CORDIC_start,
output logic [19:0] CORDIC_angle,
input  logic [12:0] CORDIC_sin,
input  logic [12:0] CORDIC_cos,
input  logic        CORDIC_busy,
input  logic        CORDIC_done,

// Peripheral Interface: Image / FIFO
output logic [7:0]  IMG_threshold,
output logic [3:0]  IMG_kernel,              
input  logic [7:0]  IMG_status
);

// Address Map
localparam logic [7:0] ADDR_CORDIC_CTRL  = 8'h00;
localparam logic [7:0] ADDR_CORDIC_ANGLE = 8'h01;
localparam logic [7:0] ADDR_CORDIC_SIN   = 8'h02;
localparam logic [7:0] ADDR_CORDIC_COS   = 8'h03;
localparam logic [7:0] ADDR_IMG_THRESH   = 8'h10;
localparam logic [7:0] ADDR_IMG_KERNEL   = 8'h11;
localparam logic [7:0] ADDR_FIFO_DATA    = 8'hF0;

// Internal Registers
logic [19:0] angle_reg;
logic [7:0]  thresh_reg;
logic [3:0]  kernel_reg;

// Write Strobes (combinational)
logic write_ctrl, wr_angle, wr_thresh, wr_kernel;

always_comb begin
    write_ctrl = 1'b0;
    wr_angle   = 1'b0;
    wr_thresh  = 1'b0;
    wr_kernel  = 1'b0;
    if (MMIO_write_enable) begin                    
        case (MMIO_address)                    
            ADDR_CORDIC_CTRL:  write_ctrl = 1'b1;
            ADDR_CORDIC_ANGLE: wr_angle   = 1'b1;
            ADDR_IMG_THRESH:   wr_thresh  = 1'b1;
            ADDR_IMG_KERNEL:   wr_kernel  = 1'b1;
            default: ;
        endcase
    end
end

// Latched Register State
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        angle_reg  <= 20'd0;
        thresh_reg <= 8'd0;
        kernel_reg <= 4'd0;
    end else begin
        if (wr_angle)  angle_reg  <= MMIO_write_data[19:0];  
        if (wr_thresh) thresh_reg <= MMIO_write_data[7:0];
        if (wr_kernel) kernel_reg <= MMIO_write_data[3:0];
    end
end

// Output Assignments
assign CORDIC_start  = write_ctrl & MMIO_write_data[0]; 
assign CORDIC_angle  = angle_reg;
assign IMG_threshold = thresh_reg;
assign IMG_kernel    = kernel_reg;

// Read Mux
always_comb begin
    MMIO_read_data = 32'd0;                         
    if (MMIO_read_enable) begin                    
        case (MMIO_address)                    
            ADDR_CORDIC_CTRL:  MMIO_read_data = {30'd0, CORDIC_done, CORDIC_busy};
            ADDR_CORDIC_ANGLE: MMIO_read_data = {12'd0, angle_reg};
            ADDR_CORDIC_SIN:   MMIO_read_data = {19'd0, CORDIC_sin};
            ADDR_CORDIC_COS:   MMIO_read_data = {19'd0, CORDIC_cos};
            ADDR_FIFO_DATA:    MMIO_read_data = {24'd0, IMG_status};
            default:           MMIO_read_data = 32'd0;
        endcase
    end
end

endmodule