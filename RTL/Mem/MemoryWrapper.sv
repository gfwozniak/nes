import Games::*;

module MemoryWrapper(	
			input clk,
			input rst_n,
			input cs, // active low
			input rd,
			input wr,
			input [15:0] addr,
			inout [7:0] databus,
			input [3:0] game,
		    // test
			output [13:0] ram_addr_peek
			);
			
wire [10:0] ram_addr;
wire [14:0] rom_addr;
wire [7:0] q_rom, q_ram, q, q_rom_mario, q_rom_dk, q_rom_nestest;
wire ram_cs, rom_cs;
wire rom_rd, ram_rd, ram_wr;

assign ram_addr_peek = ram_addr;

assign ram_cs = (!cs & (addr < 16'h2000)) ? 1'b0 : 1'b1;
assign rom_cs = (!cs & (addr >= 16'h8000)) ? 1'b0 : 1'b1;
assign ram_addr = addr[10:0];
assign rom_addr = addr[14:0];
assign ram_rd = !ram_cs ? rd : 0;
assign ram_wr = !ram_cs ? wr : 0;
assign rom_rd = !rom_cs ? rd : 0;
assign q = (!rom_cs) ? q_rom : q_ram;
assign databus = (rd & !cs) ? q : 8'hzz;

// Force mario for now
assign q_rom = q_rom_nestest;
//assign q_rom = (game == MARIO) ? q_rom_mario : 
//			   (game == DONKEY_KONG) ? q_rom_dk :
//			   (game == NES_TEST) ? q_rom_nestest :
//					8'hEA; // NOP

MarioProgramRom  mario_prg_rom (
    .addra( rom_addr ),
    .clka( clk ),
    .douta( q_rom_mario )
);

DonkeyKongProgramRom  dk_prg_rom (
    .addra( rom_addr[13:0] ),
    .clka( clk ),
    .douta( q_rom_dk )
);

NesTestProgramRom  nestest_prg_rom (
    .addra( rom_addr[13:0] ),
    .clka( clk ),
    .douta( q_rom_nestest )
);

ProgramRam prg_ram (
    .addra( ram_addr ),
    .clka( clk ),
    .dina( databus ),
    .douta( q_ram ),
    .rsta( rst_n ),
    .wea( wr )
);
			

endmodule
