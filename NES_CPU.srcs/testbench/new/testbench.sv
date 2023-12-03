`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2023 09:37:43 PM
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


module testbench();

timeunit 100ns;	 // Half clock cycle at 5 MHz
                 // We want half clock cycle at 1 MHz
			     // 1MHz is the amount of time represented by #5
timeprecision 10ns;

// These signals are internal because the processor will be 
// instantiated as a submodule in testbench.
logic           Clk, 
                Reset = 1'b0,
                IRQ = 1'b0,
                NMI = 1'b0,
                RDY = 1'b1;
                


// Instantiating the DUT
// Make sure the module and signal names match with those in your design
NES_toplevel    nes(.*
                    );

// Toggle the clock
// #5 means wait for a delay of 1 timeunit (in terms of 1 MHz)
always begin : CLOCK_GENERATION
    #5 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 


initial begin: TEST_VECTORS
    Reset = 1;  // Toggle Reset
    
    
    #20 Reset = 0;
    
    // Now just wait and look up the results
end

endmodule
