/* RAM Integration:

Load flow (LDM and POP variants)
IF stage : Fetch LDM r1, [r2] (PC advances)
EX stage : ALU computes read_address = r2 + offset
           RAM data_out = memory[read_address] (async read, same cycle)
           write_data = data_out
RWB stage : RegFile[r1] <= write_data (sync write on edge)
RAM read happens in EX 

IF stage : Fetch STM [r2], r1 (PC advances)
EX stage : ALU computes write_address = r2 + offset
           data_in = RegFile[r1]
           write_address = 1
RWB stage : (On clock edge, memory[write_address] <= data_in)
The write commits on the clock edge entering RWB
From a progammer's POV STM has finished by the time yhe next instrcution EX stage beins 

In the 16-bit ISA w/ 32-bit file but an 8-bit RAM a PUSH of a full 32-but register requires
4 byte cycle. The controller manages this sequencing. Need to document tradeoff in README

*/


/* StackPointer Inegration 

logic [7:0] RAM_read_address_mux;
logic [7:0] RAM_data_in_mux;
logic RAM_write_enable_mux;

always_comb begin
// Defaults: no RAM access
    RAM_read_address_mux = 8'h00;
    RAM_data_in_mux = 8'h00;
    RAM_write_enable_mux = 1'b0;

unique case (1'b1)
    // Memory load/store from ALU address
    LDM_active: begin
        RAM_read_address_mux = alu_out[7:0];
        RAM_write_enable_mux = 1'b0;
    end

    STM_active: begin
    RAM_read_address_mux = alu_out[7:0];
    RAM_data_in_mux = regfile_b[7:0];
    RAM_write_enable_mux = 1'b1;
    end
    // Stack operations drive address from SP
    PUSH_active: begin
    RAM_read_address_mux = sp;
    RAM_data_in_mux = regfile_a[7:0];
    RAM_write_enable_mux = 1'b1;
    end

POP_active: begin
    RAM_read_address_mux = sp + 8'd1; // pre-increment for read
    RAM_write_enable_mux = 1'b0;
    end

    // CALL / RET handled by Controller sequencing similarly
default: ;
endcase
end    


*/