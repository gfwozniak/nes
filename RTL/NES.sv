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
    
    //=======================================================
	//  REG/WIRE declarations
	//=======================================================
	// THE DATA INOUT
	wire[ 7:0 ] data;
	// THE DATA INOUT

	wire read_cpu, write_cpu; // read/write signal from cpu
	wire[ 15:0 ] addr_cpu, addr_dma; // address from cpu, address from dma
	wire clk_cpu, clk_ppu, clk_vga, clk_ctrl, clk_dma, rst_n; // clk for each modules, active low rst

	wire nmi, irq, stall; // active high nmi, irq, stall for cpu generally

	wire apu_cs_n; // active low
	wire ppu_cs_n; // active low
	wire controller_cs_n; // active low
	wire mem_cs_n; // active low
	wire[4:0] apu_addr; // $00 - $18
	wire[2:0] ppu_addr; // $0 - $7
	wire controller_addr; // 0 for $4016, 1 for $4017
	wire[15:0] mem_addr;

	wire[7:0] pixel_data; // the 8 bit color to draw to the screen
	wire[13:0] vram_addr; // The address that the sprite/background renderer specifies
	wire vram_rw_sel; // 0 = read, 1 = write
	wire[7:0] vram_data_out; // The data to write to VRAM from PPUDATA
	wire frame_end;
	wire frame_start;
	wire rendering;

	wire [7:0] vram_data_in; // Data input from VRAM reads
	wire rw_ppu, rw_apu; // PPU register read/write toggle 0 = read, 1 = write
	assign rw_ppu = write_cpu ? 1'b0 : 1'b1;
	assign rw_apu = rw_ppu;

	wire rw_ctrl; // Controller read/write toggle 1 = read, 0 = write
	assign rw_ctrl = write_cpu ? 1'b0 : 1'b1;

	wire [7:0] vga_r, vga_g, vga_b;
	wire booting_n;
	
	wire [3:0] game;
	
	assign clk_ctrl = clk_cpu;
	assign clk_dma = clk_cpu;
	assign clk_mem = clk_ppu;
    
                    // VGA
                    logic clk_25MHz, clk_125MHz, clk_5MHz, clk_21MHz;
                    logic locked;
                    logic [9:0] drawX, drawY;
                
                    logic hsync, vsync, vde;
                    logic [7:0] red, green, blue;
                    logic reset_ah;            
                    assign reset_ah = reset_rtl_0;
                    
                    // PPU to VGA
                    logic [8:0] ppu_x, ppu_y;
                    
        
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
        .clk12_out(clk_ppu),
        .clk4_out(clk_cpu),
        .reset(reset_ah)
    );
    
    CPU_uw cpu(
		// output
		.read( read_cpu ), .write( write_cpu ), .addr( addr_cpu ),

		// input
		.clk( clk_cpu ), .rst( reset_ah ),
		.nmi( nmi ), .irq( 1'b1 ), .stall( stall ), // TODO added | writing for testing

		// inout
		.data( data ),

		// testing
		.pc_peek(pc_peek),
		.ir_peek(ir_peek),
		.a_peek(a_peek),
		.x_peek(x_peek),
		.y_peek(y_peek),
		.flags_peek(flags_peek),
		.other_byte_peek(other_byte_peek)
	);
	
    OAM_dma dma(
		// output
		.cpu_stall( stall ), .address_out( addr_dma ), .cpu_ram_read(cpu_ram_read), .ppu_oam_write(ppu_oam_write),

		// input
		.clk( clk_dma ), .rst_n( ~reset_ah ),
		.address_in( addr_cpu ),

		// inout
		.data( data )
	);
	
    HardwareDecoder decoder(
		// output
		.ppu_cs_n( ppu_cs_n ),
		.controller_cs_n( controller_cs_n ), .mem_cs_n( mem_cs_n ),

		.ppu_addr( ppu_addr ),
		.controller_addr( controller_addr ), .mem_addr( mem_addr ),

		// input
		.addr( addr_dma ), .rd(read_cpu), .wr(write_cpu)
	);
	
	MemoryWrapper mem(
		// input
		.clk( clk_mem ), .cs( mem_cs_n ),
		.rd( read_cpu || cpu_ram_read), .wr( write_cpu ),
		.addr( mem_addr ), .game( 4'b0000 ),
		.rst_n(0'b0),

		// inout
		.databus( data ),

		// test
		.ram_addr_peek( ram_addr_peek )
	);
	
	ControllersWrapper ctrls(
	
		// input
		.clk( clk_ctrl ), .rst_n( 1'b0), .addr( controller_addr ),
		.cs( controller_cs_n ), .rw( rw_ctrl ),

		// inout
		.cpubus( data )//,

		// testing
		//.send_cpu_states(port_wr), .cpuram_q(cpuram_q), .writing(writing),
		//.cpuram_rd_addr(cpuram_rd_addr), .cpuram_rd(cpuram_rd), .cpuram_wr_addr( cpuram_wr_addr )
	);
    
    PPU ppu (
        // output
		.irq( nmi ), .pixel_data( pixel_data ), .vram_addr_out( vram_addr ),
		.vram_rw_sel( vram_rw_sel ), .vram_data_out( vram_data_out ),
		.frame_end( frame_end ), .frame_start( frame_start ),
		.rendering( rendering ),

		// input
		.clk( clk_ppu ), .rst_n( ~reset_ah ),
		.address( ppu_addr ), .vram_data_in( vram_data_in ),
		.rw(rw_ppu || ppu_oam_write), .cs_in( ppu_cs_n ),
		.SW(SW),

		// inout
		.data( data ),
		
		// to VGA
		.screen_y(ppu_y), //[8:0] 
        .screen_x(ppu_x) //[8:0] 
    );
    
//    PPU_driver ppu_driver (
//        .clk(clk_cpu), // CPU clock
//        .rst_n(~reset_ah), // global reset
//        .nmi(nmi), // PPU nmi out
//        .address(ppu_addr), // address to ppu
//        .ppu_data(data),
//        .ppu_rw(write_cpu),
//        .ppu_cs(ppu_cs_n)
//    );
    
    PPUMemoryWrapper ppu_mem (
        .clk(clk_ppu),
        .rst_n(~reset_ah),
        .addr(vram_addr),
        .data(vram_data_out),
        .rw(vram_rw_sel),
        .game(4'b0000),
        .q(vram_data_in)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .ppu_clk(clk_ppu),
        .ppu_pixel(pixel_data),
        .ppu_x(ppu_x),
        .ppu_y(ppu_y),
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