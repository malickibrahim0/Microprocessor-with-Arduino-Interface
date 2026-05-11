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

/* 

 THIS IS FROM 8 BIT MICROPROCESSOR NEED TO ALSO EXPAND TO 32 Bits

typedef struct packed {
logic [15:0] IR;
logic [7:0] PC;
logic [7:0] A, B;
logic [3:0] RA, RB, RD;
logic [3:0] OPCODE;
} IF_EX_t;

typedef struct packed {
logic [7:0] alu_out;
logic [3:0] RD;
logic [3:0] OPCODE;
} EX_WB_t;

module Lab5_Pipelined(
input  clk, reset, 
output logic [3:0] OPCODE_WB,
output logic [7:0] PC, Alu_out, RF_data_in, 
output logic Cout, OF 
); 

// Combinational logic for the Fetch stage
logic [15:0] IR_from_ROM;
logic [7:0]  RF_data_out_A, RF_data_out_B;

// Combinational logic for the Execute stage
logic [7:0]  alu_result_logic;

// Pipeline Registers and Next-State Logic
IF_EX_t IF_EX, next_IF_EX;
EX_WB_t EX_WB, next_EX_WB;

// logic to trigger the flush
logic branch_taken;

// Forwarding 
logic ForwardA, ForwardB;
logic [7:0] alu_in_A, alu_in_B;

// 1. The IF stage

// Calculates the address of next instruction and sends it to the PC (IF stage)
Program_Counter_Pipelined PC_Address (.clk(clk), .reset(reset), .OPCODE_EX(IF_EX.OPCODE), .IF_EX_PC(IF_EX.PC), 
                                   .Alu_out(alu_result_logic), .A(alu_in_A), .B(alu_in_B), .RD(IF_EX.RD), 
                                   .PC(PC), .branch_taken(branch_taken));

// Get the PC address and ouputs instruction from ROM (IF stage)
ROM_Pipelined Instruction_Memory (.PC(PC), .IR(IR_from_ROM)); 

// Read/Slices the instructions and sends them to the Register File (IF stage)
// The Register File immediately sends the data onto RF_data_out_A and RF_data_out_B
RegFile_Pipelined RegFile_Read (.clk(clk), .reset(reset), .RA(IR_from_ROM[11:8]), .RB(IR_from_ROM[7:4]), .RD(EX_WB.RD), 
                                .OPCODE_WB(EX_WB.OPCODE), .RF_data_in(EX_WB.alu_out), .RF_data_out_A(RF_data_out_A),
                                .RF_data_out_B(RF_data_out_B));

// Fill the NEXT IF_EX state combinationally 
assign next_IF_EX.IR = IR_from_ROM;
assign next_IF_EX.PC = PC;
assign next_IF_EX.OPCODE = IR_from_ROM[15:12];
assign next_IF_EX.RA = IR_from_ROM[11:8];
assign next_IF_EX.RB = IR_from_ROM[7:4];
assign next_IF_EX.RD = IR_from_ROM[3:0];
assign next_IF_EX.A  = RF_data_out_A;
assign next_IF_EX.B  = RF_data_out_B;

// Once the IF stage is completed, will enter the EX stage
// Before the EX stage, will calculate the forwarding logic
ForwardingUnit FWD_UNIT (.IF_EX_RA(IF_EX.RA), .IF_EX_RB(IF_EX.RB), .EX_WB_RD(EX_WB.RD), .EX_WB_OPCODE(EX_WB.OPCODE),
                         .ForwardA(ForwardA), .ForwardB(ForwardB));

// The Hardware Forwarding Multiplexers
// If Forward flag is 1, bypass the stale register data and grab the ALU result from the WB stage
assign alu_in_A = ForwardA ? EX_WB.alu_out : IF_EX.A;
assign alu_in_B = ForwardB ? EX_WB.alu_out : IF_EX.B;


// 2. The EX stage (ALU & PC Check)

// The ALU receives the inputs from the IF stage and calculates the ALU result
// The PC_Address is also checking for branch conditions
ALU_Pipelined ALU (.Aluin_A(alu_in_A), .Aluin_B(alu_in_B), .RA_Instant(IF_EX.RA), .RB_Instant(IF_EX.RB), 
                        .OPCODE_EX(IF_EX.OPCODE), .Alu_out(alu_result_logic), .Cout(Cout), .OF(OF));

// Clock the NEXT states into the REGISTERS sequentially
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        IF_EX <= '0;
        EX_WB <= '0;
    end else if (branch_taken) begin
        // THE FLUSH: A jump is happening. 
        // The instruction currently sitting in next_IF_EX is wrong.
        // We force IF_EX to 0 (which maps to NOP: 16'h0000) to kill it.
        IF_EX <= '0; 
        
        // Note: The jump instruction itself is currently in IF_EX, so it 
        // still needs to move forward into EX_WB normally!
        EX_WB <= next_EX_WB; 
    end else begin
        // Normal sequential flow
        IF_EX <= next_IF_EX;
        EX_WB <= next_EX_WB;
    end
end

// 3. The WB stage

// Fill the NEXT EX_WB state combinationally
assign next_EX_WB.alu_out = alu_result_logic;        // Grab the combinational ALU result
assign next_EX_WB.RD      = IF_EX.RD;                // Pass along the destination register
assign next_EX_WB.OPCODE   = IF_EX.OPCODE;           // Pass along the opcode


// Assign top-level outputs for physical validation debugging
assign Alu_out    = EX_WB.alu_out;
assign RF_data_in = EX_WB.alu_out;
assign OPCODE_WB  = EX_WB.OPCODE;

endmodule


module lab5_Pipelined_pv(
input clk,                         // 50MHz (PIN_P11)
input SW0,                         // SW0: asynchronous (active high) reset 
input SW1,                         // SW1: single-step mode 
input SW2, SW3, SW4,               // SW2-SW4: 7-seg Display select
input KEY0,                        // single-step mode clock input (active low)
output logic [6:0] SevSeg5, SevSeg4, SevSeg3, SevSeg2, SevSeg1, SevSeg0,
output logic [7:0] LED             
);

// Internal signals
logic [3:0] OPCODE;                
logic [7:0] PC, Alu_out, RF_data_in;     
logic Cout, OF;                    
logic clk_slow;                    
logic clk_MCU;                     
logic [7:0] SevSeg_Display [5:0];  
logic [2:0] Display_Select;        
logic [14:0] counter;              

// Debouncing signals
logic [2:0] key0_shift;
logic key0_debounced;

// Clock Divider (50MHz to ~1kHz)
always_ff @(posedge clk) begin
    if (SW0) begin
        counter <= 15'd0;
        clk_slow <= 1'b0;
    end else if (counter >= 15'd24999) begin
        counter <= 15'd0;
        clk_slow <= ~clk_slow; 
    end else begin
        counter <= counter + 1'd1;
    end
end

// Debouncer sampled at 1kHz
always_ff @(posedge clk_slow or posedge SW0) begin
    if (SW0) begin
        key0_shift <= 3'b111;     
        key0_debounced <= 1'b1;
    end else begin
        key0_shift <= {key0_shift[1:0], KEY0};
        if (key0_shift == 3'b111)      key0_debounced <= 1'b1;
        else if (key0_shift == 3'b000) key0_debounced <= 1'b0;
    end
end

assign clk_MCU = (SW1) ? key0_debounced : clk_slow;  
assign LED = PC; 
assign Display_Select = {SW4, SW3, SW2}; 


Lab5_Pipelined MCU_Pipelined (
    .clk(clk_MCU), 
    .reset(SW0), 
    .OPCODE_WB(OPCODE), 
    .PC(PC), 
    .Alu_out(Alu_out),
    .RF_data_in(RF_data_in), 
    .Cout(Cout), 
    .OF(OF)
);

// 7-Segment Multiplexer Logic
function automatic logic [7:0] get_7SEG_value(input [3:0] value);
    if (value <= 4'h9) return 8'h30 + value; 
    else               return 8'h41 + (value - 4'hA); 
endfunction

always_comb begin
    // Use 8'h00 for true blanking
    SevSeg_Display = '{default: 8'h00}; 

    case (Display_Select)  
        3'b000 : begin // "IBRAHI"
            SevSeg_Display[5] = 8'h49; SevSeg_Display[4] = 8'h42; 
            SevSeg_Display[3] = 8'h52; SevSeg_Display[2] = 8'h41; 
            SevSeg_Display[1] = 8'h48; SevSeg_Display[0] = 8'h49; 
        end
        3'b011 : begin // ALU Result
            SevSeg_Display[1] = get_7SEG_value(Alu_out[7:4]);
            SevSeg_Display[0] = get_7SEG_value(Alu_out[3:0]);
        end
        3'b101 : begin // Writeback Data
            SevSeg_Display[1] = get_7SEG_value(RF_data_in[7:4]);
            SevSeg_Display[0] = get_7SEG_value(RF_data_in[3:0]);
        end
        3'b110 : begin // Program Counter
            SevSeg_Display[1] = get_7SEG_value(PC[7:4]);
            SevSeg_Display[0] = get_7SEG_value(PC[3:0]);
        end
        3'b111 : begin // Opcode
            SevSeg_Display[0] = get_7SEG_value(OPCODE);
        end
        default : ;
    endcase
end

// ASCII Decoders
ASCII27Seg SEG_5 (.AsciiCode(SevSeg_Display[5]), .HexSeg(SevSeg5));
ASCII27Seg SEG_4 (.AsciiCode(SevSeg_Display[4]), .HexSeg(SevSeg4));
ASCII27Seg SEG_3 (.AsciiCode(SevSeg_Display[3]), .HexSeg(SevSeg3));
ASCII27Seg SEG_2 (.AsciiCode(SevSeg_Display[2]), .HexSeg(SevSeg2));
ASCII27Seg SEG_1 (.AsciiCode(SevSeg_Display[1]), .HexSeg(SevSeg1));
ASCII27Seg SEG_0 (.AsciiCode(SevSeg_Display[0]), .HexSeg(SevSeg0));

endmodule
*/
