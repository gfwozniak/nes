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
                reset_rtl_0,
                SW,
                Run,
                gpio_usb_int_tri_i,
                usb_spi_miso,
                uart_rtl_0_rxd;
                

// Instantiating the DUT
// Make sure the module and signal names match with those in your design
NES_toplevel    nes(.*
                    );

// Toggle the clock
// #1 means wait for a delay of 1 timeunit (in terms of 5 MHz)
always begin : CLOCK_GENERATION
    #1 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 1'b0;
    reset_rtl_0 = 1'b0;
    SW = 16'h0000;
    Run = 1'b0;
    gpio_usb_int_tri_i = 1'b0;
    usb_spi_miso = 1'b0;
    uart_rtl_0_rxd = 1'b0;
end 


initial begin: TEST_VECTORS
    reset_rtl_0 = 1'b1;  // Toggle Reset
    
    
    #20 reset_rtl_0 = 1'b0;
    
    // Now just wait and look up the results
end

endmodule
