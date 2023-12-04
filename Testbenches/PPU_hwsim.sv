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


module testbench();

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

//USB signals
logic [0:0] gpio_usb_int_tri_i;
logic gpio_usb_rst_tri_o;
logic usb_spi_miso;
logic usb_spi_mosi;
logic usb_spi_sclk;
logic usb_spi_ss;

//UART
logic uart_rtl_0_rxd;
logic uart_rtl_0_txd;

//HDMI
logic hdmi_tmds_clk_n;
logic hdmi_tmds_clk_p;
logic [2:0]hdmi_tmds_data_n;
logic [2:0]hdmi_tmds_data_p;

//HEX displays
logic [7:0] hex_segA;
logic [3:0] hex_gridA;
logic [7:0] hex_segB;
logic [3:0] hex_gridB;
		
// Instantiating the DUT
// Make sure the module and signal names match with those in your design
NES nes(.*);	

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
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
#100 reset_rtl_0 = 1;
#50 reset_rtl_0 = 0;

$display("Success!");  // Command line output in ModelSim

end

endmodule
