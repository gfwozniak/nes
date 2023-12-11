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
import Games::*;

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
    
    logic clk_25MHz, clk_125MHz, clk_5MHz, clk_21MHz, clk_CPU, clk_PPU;
    logic locked;
    logic locked2;
    logic [9:0] drawX, drawY;

    logic hsync, vsync, vde;
    logic [7:0] red, green, blue;
    logic reset_ah;
    
    assign reset_ah = reset_rtl_0;
    
    logic [7:0] ppu_pixel;
    logic [8:0] ppu_x, ppu_y;
    
    // PPU
    logic[13:0] vram_addr;
    logic[7:0] vram_data_in, vram_data_out;
    logic vram_rw_sel;
    logic nmi;
    logic [2:0] ppu_reg_address;
    wire [7:0] ppu_reg_data;
    logic ppu_rw, ppu_cs;
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .clk_out3(clk_5MHz),
        .clk_out4(clk_21MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    // CPU clock calculation
    clk_div3_v2 clk_divider3 (
        .clk(clk_21MHz),
        .clk12_out(clk_PPU),
        .clk4_out(clk_CPU),
        .reset(reset_ah)
    );
    
    PPU ppu (
        .clk(clk_PPU), // PPU system clock
        .rst_n(~reset_ah), // active low reset
        .data(ppu_reg_data), // line for PPU->CPU and CPU->PPU data
        .address(ppu_reg_address), // PPU register select
        .vram_data_in(vram_data_in), // Data input from VRAM reads
        .rw(ppu_rw), // PPU register read/write toggle
        .cs_in(ppu_cs), // PPU chip select
        .irq(nmi), // connected to the 6502's NMI pin
        .pixel_data(ppu_pixel), // the 8 bit color to draw to the screen
        .vram_addr_out(vram_addr), // The address that the sprite/background renderer specifies
        .vram_rw_sel(vram_rw_sel),
        .vram_data_out(vram_data_out), // The data to write to VRAM from PPUDATA
        .frame_end(),
        .frame_start(),
        .rendering(),
        .screen_y(ppu_x), //[8:0] 
        .screen_x(ppu_y) //[8:0] 
    );
    
    PPU_driver ppu_driver (
        .clk(clk_CPU), // CPU clock
        .rst_n(~reset_ah), // global reset
        .nmi(nmi), // PPU nmi out
        .address(ppu_reg_address), // address to ppu
        .ppu_data(ppu_reg_data),
        .ppu_rw(ppu_rw),
        .ppu_cs(ppu_cs)
    );
    
    PPUMemoryWrapper ppu_mem (
        .clk(clk_PPU),
        .rst_n(~reset_ah),
        .addr(vram_addr),
        .data(vram_data_out),
        .rw(vram_rw_sel),
        .game(4'b0000),
        .q(vram_data_in)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .ppu_clk(clk_PPU),
        .ppu_pixel(ppu_pixel),
        .ppu_x(ppu_y),
        .ppu_y(ppu_x),
        .pixel_clk(clk_25MHz),
        .reset(1'b0),
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
        .rst(1'b0),
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