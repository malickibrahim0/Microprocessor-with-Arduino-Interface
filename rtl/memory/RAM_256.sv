// Holds the data (things that change at run time)
// Since the RAM and ROM are are at seprate places the CPU can fetch an instruction
// and read data in the same cycle, becasue the two memories are physically two diffrent arrays.

// What RAM stores:
// Local Variables: Values that do not fit in the the 16-but register file or that needs to be temperorily saved for other functions
// The Stack: When PUSH or CALL is used, the byte will be in the RAM (StackPointer)
// Pixel buffers and intermediete results: Sobel and CORDOC buffers will land here for a bit 

// The reason for a dedicaated write_addess and read_address is becauase the CPU may want to read one address while 
// the pipeline is writing back another address.
// merging them into a single will lose parallelism and the pipeliene wouldn't work 

module RAM_32bit (
input  logic clk,
input  logic write_enable,
input  logic [31:0] address,      // 32-bit address bus
input  logic [31:0] data_in,      // 32-bit data input
output logic [31:0] data_out      // 32-bit data output
);

// 1024 locations, 32 bits each (4KB of Data RAM)
logic [31:0] memory [0:1023];

// Synchronous write
always_ff @(posedge clk) begin
    if (write_enable) begin
        // Using address bits [11:2] to maintain 4-byte word alignment
        memory[address[11:2]] <= data_in;
    end
end

// Asynchronous read for the Execute Stage
assign data_out = memory[address[11:2]];

endmodule

