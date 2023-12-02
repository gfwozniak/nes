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
    
    logic clk_25MHz, clk_125MHz, clk_5MHz, clk_CPU, clk_DMA, clk_PPU, clk_MEM, clk_BRAM, clk_CTRL;
    logic locked;
    logic locked2;
    
    assign reset_ah = reset_rtl_0;
    
    // VGA / HDMI
    logic [9:0] drawX, drawY;
    logic hsync, vsync, vde;
    logic [7:0] red, green, blue;
    logic reset_ah;
    
    // PPU
    logic[13:0] vram_addr;
    logic[7:0] vram_data_in, vram_data_out;
    logic vram_rw_sel;
    logic nmi;
    logic [2:0] ppu_addr;
    wire [7:0] ppu_reg_data;
    logic ppu_rw, ppu_cs_n;
    reg ppu_oam_write;
    
    logic [7:0] ppu_pixel;
    logic [8:0] ppu_x, ppu_y;
    
    // CPU
    logic [15:0] addr_cpu;
    logic [7:0] db_in, db_out;
    logic rw_cpu;
    reg stall;
    
    // Controller
    logic controller_cs_n;
    logic controller_addr;
    wire rw_ctrl; // Controller read/write toggle 1 = read, 0 = write
	assign rw_ctrl = rw_cpu;
	assign clk_CTRL = clk_CPU;
    
    // DMA / Memory
    logic mem_cs_n;
    logic [15:0] mem_addr;
    reg [15:0] addr_dma;
    logic [7:0] data;
    reg cpu_ram_read;
    wire [3:0] game;
    assign clk_DMA = clk_CPU;
    assign clk_MEM = clk_PPU;
    
    
    // MicroBlaze setup for keyboard input
//    mb_block mb_block_i(
//        .clk_100MHz(Clk),
//        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
//        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
//        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
//        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
//        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
//        .uart_rtl_0_rxd(uart_rtl_0_rxd),
//        .uart_rtl_0_txd(uart_rtl_0_txd),
//        .usb_spi_miso(usb_spi_miso),
//        .usb_spi_mosi(usb_spi_mosi),
//        .usb_spi_sclk(usb_spi_sclk),
//        .usb_spi_ss(usb_spi_ss)
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
    
    clk_wiz_ppu clk_ppu (
        .clk_out1(clk_BRAM),
        .clk_out2(clk_PPU),
        .reset(reset_ah),
        .locked(locked2),
        .clk_in1(clk_25MHz)
    );
    
    // CPU clock calculation
    clk_div3 clk_divider3 (
        .clk(clk_PPU),
        .clk_out(clk_CPU),
        .reset(reset_ah)
    );
    
    CPU cpu (
        // input
        .Clk(clk_CPU),      
        .Reset(reset_ah),   // active high reset
        .IRQ(1'b0),         // IRQ doesn't seem to be used for our implementation so we keep it constant 0
        .NMI(nmi),
        .RDY(~stall),
        .DB_in(db_in),
        
        // output
        .AB_out(addr_cpu),
        .DB_out(db_out), 
        .RW(rw_cpu)
    );
    
    ConvertToInOut ctio (   
        .indata(db_in),
	    .outdata(db_out),
	    .rw(rw_cpu),
	    .inoutdata(data)
    );
    
    PPU ppu (
        .clk(clk_PPU), // PPU system clock
        .rst_n(~reset_ah), // active low reset
        .data(data), // line for PPU->CPU and CPU->PPU data
        .address(ppu_addr), // PPU register select
        .vram_data_in(vram_data_in), // Data input from VRAM reads
        .rw(ppu_rw || ppu_oam_write), // PPU register read/write toggle
        .cs_in(ppu_cs_n), // PPU chip select
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
    
    PPUMemoryWrapper ppu_mem (
        .clk(clk_PPU),
        .clk2x(clk_BRAM),
        .rst_n(~reset_ah),
        .addr(vram_addr),
        .data(vram_data_out),
        .rw(vram_rw_sel),
        .game(game),
        .q(vram_data_in)
    );
    
    HardwareDecoder decoder (
        // output
	    .ppu_cs_n( ppu_cs_n ),
		.controller_cs_n( controller_cs_n ), .mem_cs_n( mem_cs_n ),

		.ppu_addr( ppu_addr ),
		.controller_addr( controller_addr ), .mem_addr( mem_addr ),

		// input
		.addr( addr_dma ), .rd(rw_cpu), .wr(~rw_cpu)
    );
    
    OAM_dma dma(
		// output
		.cpu_stall( stall ), .address_out( addr_dma ), .cpu_ram_read(cpu_ram_read), .ppu_oam_write(ppu_oam_write),

		// input
		.clk( clk_DMA ), .rst_n( ~reset_ah ),
		.address_in( addr_cpu ),

		// inout
		.data( data )
	);
	
	MemoryWrapper mem(
		// input
		.clk( clk_mem ), .cs( mem_cs_n ),
		.rd( rw_cpu || cpu_ram_read ), .wr( ~rw_cpu ),
		.addr( mem_addr ), .game( game ),

		// inout
		.databus( data )

		// test
		//.ram_addr_peek( ram_addr_peek )
	);
	
	ControllersWrapper ctrls(
		// input
		.clk( clk_CTRL ), .rst_n( ~reset_ah ), .addr( controller_addr ),
		.cs( controller_cs_n ), .rw( rw_ctrl ),

		// inout
		.cpubus( data )
	);
	
	GameSelect sel(
		// input
		.SW( SW ), .rst_n( rst_n ),
		
		// output
		.game( game )
	);
    
    //VGA Sync signal generator
    vga_controller vga (
        .ppu_clk(clk_PPU),
        .ppu_pixel(ppu_pixel),
        .ppu_x(ppu_y),
        .ppu_y(ppu_x),
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
    
    // Old code
    
//    PPU ppu(
//		// output
//		.irq( nmi ), .pixel_data( pixel_data ), .vram_addr_out( vram_addr ),
//		.vram_rw_sel( vram_rw_sel ), .vram_data_out( vram_data_out ),
//		.frame_end( frame_end ), .frame_start( frame_start ),
//		.rendering( rendering ),

//		// input
//		.clk( clk_ppu ), .rst_n( rst_n & locked & ~booting_n ),
//		.address( ppu_addr ), .vram_data_in( vram_data_in ),
//		.rw(rw_ppu || ppu_oam_write), .cs_in( ppu_cs_n ),

//		// inout
//		.data( data )
//	);
    
//    PPU_driver ppu_driver (
//        .clk(clk_CPU), // CPU clock
//        .rst_n(~reset_ah), // global reset
//        .nmi(nmi), // PPU nmi out
//        .address(ppu_reg_address), // address to ppu
//        .ppu_data(ppu_reg_data),
//        .ppu_rw(ppu_rw),
//        .ppu_cs(ppu_cs)
//    );

    
endmodule
