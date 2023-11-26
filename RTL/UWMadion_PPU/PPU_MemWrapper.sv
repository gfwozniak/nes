

module PPUMemoryWrapper(input clk,
                                input clk2x,
								input rst_n,
								input [3:0] game,
								input [13:0] addr,
								input [7:0] data,
								input rw,
								output [7:0] q);

wire [12:0] rom_addr;
wire [10:0] ram_addr;
wire [7:0] rom_q, ram_q, mario_rom_q, test_rom_q, rom_douta, ram_douta;
wire ram_en, rom_en;
reg [7:0] rom_out, ram_out, rom_out_d, ram_out_d;

reg prev_rom_en;
reg prev_ram_en;

assign ram_en = addr[13];
assign rom_en = ~addr[13];

assign rom_addr = addr[12:0];

// Force vertical mirroring PPUMemoryWrapper.sv
assign ram_addr = addr[10:0];
// Force test rom
assign rom_q = mario_rom_q;

assign q = prev_ram_en ? ram_out : prev_rom_en ? rom_out : 8'hzz;

					
		
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		prev_rom_en <= 1'b0;
		prev_ram_en <= 1'b0;
	end
	else begin
		prev_rom_en <= rom_en;
		prev_ram_en <= ram_en;
	end
end

//    reg [7:0] addr, addr_D;

//always @(posedge clk, negedge rst_n) begin
//	if (!rst_n) begin

//	end
//	else begin
//		addr <= rom_en;
//	end
//end

//MarioCharacterRom mario_rom(
//	.address(rom_addr),
//	.clock(clk),
//	.rden(~rw),
//	.q(mario_rom_q));





always_ff @ (posedge clk2x) begin
	   rom_out <= rom_out_d;
	   ram_out <= ram_out_d;
end

always_comb begin
    rom_out_d = rom_out;
    ram_out_d = ram_out;
    if (clk)
    begin
        rom_out_d = rom_douta;
        ram_out_d = ram_douta;
    end
end



char_rom mario_rom (.addra(rom_addr), .clka(clk2x), .douta(rom_douta));
blk_mem_gen_1 vram (
    .addra({3'b000,ram_addr}),
    .clka(clk2x),
    .dina(data),
    .douta(ram_douta),
    .ena(1'b1),
    .wea(rw)
    );
	
//PPUVram vram(
//	.address(ram_addr),
//	.clock(clk),
//	.data(data),
//	.rden(~rw),
//	.wren(rw),
//	.q(ram_q));

endmodule