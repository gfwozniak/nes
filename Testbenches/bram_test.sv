`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2023 12:18:27 AM
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bram_tb();

timeunit 10ns;	// Half clock cycle at 50 MHz
			// This is the amount of time represented by #1 
timeprecision 1ns;

// These signals are internal because the processor will be 
// instantiated as a submodule in testbench.
logic Clk, reset_rtl_0, Run;
logic [15:0] SW;
//logic [15:0] LED;
//logic [7:0] hex_seg;
//logic [3:0] hex_grid;
//logic [7:0] hex_segB;
//logic [3:0] hex_gridB;

logic [13:0] vram_addr;
logic [7:0] vram_data_out, vram_data_in;
logic vram_rw_sel;
logic [7:0] q;

		
// Instantiating the DUT
// Make sure the module and signal names match with those in your design
PPUMemoryWrapper ppu_mem (
    .clk(Clk),
    .rst_n(~reset_rtl_0),
    .addr(vram_addr),
    .data(vram_data_out),
    .rw(vram_rw_sel),
    .game(4'b0000),
    .q(vram_data_in)
);

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#10 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 



// Testing begins here
// The initial block is not synthesizable
// Everything happens sequentially inside an initial block
// as in a software program
initial begin: TEST_VECTORS
reset_rtl_0 = 0;		// Toggle Rest
#20 reset_rtl_0 = 1;
#10 reset_rtl_0 = 0;
vram_rw_sel = 0;


#40 vram_addr = 13'h1321;
#40 vram_addr = 13'hzzz;
#40 vram_addr = 13'h00aa;
#40 vram_addr = 13'h0011;

$display("Success!");  // Command line output in ModelSim

end

endmodule
