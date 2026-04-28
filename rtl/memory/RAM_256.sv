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

module RAM_256x8 (
input  logic clk,                  // System Clock (50 Mhz)
input  logic write_enable,         // Write enable (Synchrnous)
input  logic [7:0] write_address,  // Write address (8 bits for 256 locations)
input  logic [7:0] data_in,        // Data to write (8 bits)
input  logic [7:0] read_address,   // Read address (independant of write)
output logic [7:0] data_out        // Data read out at reader_address
);


    // 256 locations, 8 bits each
    logic [7:0] memory [0:255];

    // Synchronous write
    always_ff @(posedge clk) begin
        if (write_enable) begin
            memory[write_address] <= data_in;
        end
    end

    // Asynchronous read (continuous assignment)
    assign data_out = memory[read_address];


endmodule

