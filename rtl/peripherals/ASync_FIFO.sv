// File: rtl/core/Async_FIFO.sv
module Async_FIFO #(
    parameter DSIZE = 8,  // 8-bit pixel/sensor data
    parameter ASIZE = 4   // 4-bit address for depth of 16
)(
    // Write Domain (Arduino SPI Clock)
    input  logic             wclk,
    input  logic             wrst_n,
    input  logic             winc,
    input  logic [DSIZE-1:0] wdata,
    output logic             wfull,

    // Read Domain (FPGA 50MHz System Clock)
    input  logic             rclk,
    input  logic             rrst_n,
    input  logic             rinc,
    output logic [DSIZE-1:0] rdata,
    output logic             rempty
);

    logic [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

    // Dual-Port Memory Instance
    fifomem #(DSIZE, ASIZE) fifomem_inst (
        .wclk(wclk), 
        .wclken(winc & ~wfull), 
        .waddr(wptr[ASIZE-1:0]), 
        .wdata(wdata),
        .raddr(rptr[ASIZE-1:0]), 
        .rdata(rdata)
    );

    // Sync Read Pointer to Write Domain [cite: 1554-1573]
    sync_r2w #(ASIZE) sync_r2w_inst (
        .wclk(wclk), 
        .wrst_n(wrst_n), 
        .rptr(rptr), 
        .wq2_rptr(wq2_rptr)
    );

    // Sync Write Pointer to Read Domain [cite: 1554-1573]
    sync_w2r #(ASIZE) sync_w2r_inst (
        .rclk(rclk), 
        .rrst_n(rrst_n), 
        .wptr(wptr), 
        .rq2_wptr(rq2_wptr)
    );

    // Empty Logic (Read Domain)
    rptr_empty #(ASIZE) rptr_empty_inst (
        .rclk(rclk), 
        .rrst_n(rrst_n), 
        .rinc(rinc),
        .rq2_wptr(rq2_wptr), 
        .rempty(rempty), 
        .rptr(rptr)
    );

    // Full Logic (Write Domain)
    wptr_full #(ASIZE) wptr_full_inst (
        .wclk(wclk), 
        .wrst_n(wrst_n), 
        .winc(winc),
        .wq2_rptr(wq2_rptr), 
        .wfull(wfull), 
        .wptr(wptr)
    );

endmodule

module fifomem #(parameter DSIZE = 8, parameter ASIZE = 4) (
    input  logic             wclk,
    input  logic             wclken,
    input  logic [ASIZE-1:0] waddr,
    input  logic [DSIZE-1:0] wdata,
    input  logic [ASIZE-1:0] raddr,
    output logic [DSIZE-1:0] rdata
);
    logic [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

    always_ff @(posedge wclk) begin
        if (wclken) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata = mem[raddr]; // Asynchronous read
endmodule


module sync_r2w #(parameter ASIZE = 4) (
    input  logic             wclk,
    input  logic             wrst_n,
    input  logic [ASIZE:0]   rptr,
    output logic [ASIZE:0]   wq2_rptr
);
    logic [ASIZE:0] wq1_rptr;
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) {wq2_rptr, wq1_rptr} <= 0;
        else         {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
    end
endmodule

module sync_w2r #(parameter ASIZE = 4) (
    input  logic             rclk,
    input  logic             rrst_n,
    input  logic [ASIZE:0]   wptr,
    output logic [ASIZE:0]   rq2_wptr
);
    logic [ASIZE:0] rq1_wptr;
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) {rq2_wptr, rq1_wptr} <= 0;
        else         {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
    end
endmodule

module rptr_empty #(parameter ASIZE = 4) (
    input  logic             rclk,
    input  logic             rrst_n,
    input  logic             rinc,
    input  logic [ASIZE:0]   rq2_wptr,
    output logic             rempty,
    output logic [ASIZE:0]   rptr
);
    logic [ASIZE:0] rbin, rbin_next, rgray_next;
    logic           rempty_val;

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin   <= 0;
            rptr   <= 0;
            rempty <= 1'b1;
        end else begin
            rbin   <= rbin_next;
            rptr   <= rgray_next;
            rempty <= rempty_val;
        end
    end

    // Binary counter and Gray code conversion [cite: 1501]
    assign rbin_next  = rbin + (rinc & ~rempty);
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;
    
    // Empty when all bits (including MSB) are equal [cite: 1546]
    assign rempty_val = (rgray_next == rq2_wptr);
endmodule

module wptr_full #(parameter ASIZE = 4) (
    input  logic             wclk,
    input  logic             wrst_n,
    input  logic             winc,
    input  logic [ASIZE:0]   wq2_rptr,
    output logic             wfull,
    output logic [ASIZE:0]   wptr
);
    logic [ASIZE:0] wbin, wbin_next, wgray_next;
    logic           wfull_val;

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin  <= 0;
            wptr  <= 0;
            wfull <= 1'b0;
        end else begin
            wbin  <= wbin_next;
            wptr  <= wgray_next;
            wfull <= wfull_val;
        end
    end

    // Binary counter and Gray code conversion [cite: 1501]
    assign wbin_next  = wbin + (winc & ~wfull);
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;
    
    // Full when lower bits are equal but top two MSBs differ [cite: 1547]
    assign wfull_val = (wgray_next == {~wq2_rptr[ASIZE:ASIZE-1], wq2_rptr[ASIZE-2:0]});
endmodule