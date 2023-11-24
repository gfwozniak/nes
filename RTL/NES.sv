`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Zuofu Cheng
// 
// Create Date: 12/11/2022 10:48:49 AM
// Design Name: 
// Module Name: mb_usb_hdmi_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Top level for mb_lwusb test project, copy mb wrapper here from Verilog and modify
// to SV
// Dependencies: microblaze block design
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module NES(
    input logic Clk,
    input logic reset_rtl_0,
    input logic [15:0] SW,
    input logic Run,
    
    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
    );
    
    logic clk_25MHz, clk_125MHz, clk_5MHz;
    logic locked;
    logic [9:0] drawX, drawY;

    logic hsync, vsync, vde;
    logic [7:0] red, green, blue;
    logic reset_ah;
    
    assign reset_ah = reset_rtl_0;
    
    logic [7:0] ppu_pixel;
    logic [9:0] ppu_x, ppu_y;
    
    
//    //Keycode HEX drivers
//    HexDriver HexA (
//        .clk(Clk),
//        .reset(reset_ah),
//        .in({keycode0_gpio[31:28], keycode0_gpio[27:24], keycode0_gpio[23:20], keycode0_gpio[19:16]}),
//        .hex_seg(hex_segA),
//        .hex_grid(hex_gridA)
//    );
    
//    HexDriver HexB (
//        .clk(Clk),
//        .reset(reset_ah),
//        .in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
//        .hex_seg(hex_segB),
//        .hex_grid(hex_gridB)
//    );
   
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .clk_out3(clk_5MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
//    PPU ppu (
//        .SW(SW),
//        .ppu_clk(clk_5MHz),
//        .ppu_pixel(ppu_pixel),
//        .ppu_x(ppu_x),
//        .ppu_y(ppu_y),
//        .reset(reset_ah)
//    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .ppu_clk(clk_5MHz),
        .ppu_pixel(ppu_pixel),
        .ppu_x(ppu_x),
        .ppu_y(ppu_y),
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY),
        .Red(red),
        .Green(green),
        .Blue(blue),
        .SW(SW),
        .Run(Run)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

    
endmodule
