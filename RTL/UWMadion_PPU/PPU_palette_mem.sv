module PPU_palette_mem(
	input clk,
	input rst_n,
	input [4:0] pal_addr,
	input [7:0] palette_data_in,
	input palette_mem_rw,
	input palette_mem_en,
	output [7:0] color_out,
	
	// DEBUG ONLY NOT FOR RELEASE
	output reg [7:0] red,
	output reg [7:0] green,
	output reg [7:0] blue
	);
	
	integer i;
	
	reg [7:0] palette_mem [31:0];
	reg [7:0] color;
	
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			/*
			for (i = 0; i < 32; i = i + 1)
				palette_mem[i] <= 8'h00;
			*/
			palette_mem[0] <= 8'h22;
			palette_mem[1] <= 8'h29;
			palette_mem[2] <= 8'h1a;
			palette_mem[3] <= 8'h0f;
			palette_mem[4] <= 8'h22;
			palette_mem[5] <= 8'h36;
			palette_mem[6] <= 8'h17;
			palette_mem[7] <= 8'h0f;
			palette_mem[8] <= 8'h22;
			palette_mem[9] <= 8'h30;
			palette_mem[10] <= 8'h21;
			palette_mem[11] <= 8'h0f;
			palette_mem[12] <= 8'h22;
			palette_mem[13] <= 8'h27;
			palette_mem[14] <= 8'h17;
			palette_mem[15] <= 8'h0f;
			palette_mem[16] <= 8'h00;
			palette_mem[17] <= 8'h16;
			palette_mem[18] <= 8'h27;
			palette_mem[19] <= 8'h18;
			palette_mem[20] <= 8'h00;
			palette_mem[21] <= 8'h1a;
			palette_mem[22] <= 8'h30;
			palette_mem[23] <= 8'h27;
			palette_mem[24] <= 8'h00;
			palette_mem[25] <= 8'h16;
			palette_mem[26] <= 8'h30;
			palette_mem[27] <= 8'h27;
			palette_mem[28] <= 8'h00;
			palette_mem[29] <= 8'h0f;
			palette_mem[30] <= 8'h36;
			palette_mem[31] <= 8'h17;
			
		end
		else begin
			if (palette_mem_en && palette_mem_rw) begin
				if (pal_addr[1:0] == 0)
					palette_mem[{1'b0, pal_addr[3:0]}] <= palette_data_in;
				else
					palette_mem[pal_addr] <= palette_data_in;
			end
		end
	end
	
	always_comb begin
		color = 8'h00;
		if (palette_mem_en && !palette_mem_rw)
			if (pal_addr[1:0] == 0)
				color = palette_mem[0]; //color = 8'h22;
			else
				color = palette_mem[pal_addr];
	end
	
	assign color_out = (palette_mem_en) ? color : 8'hzz;
	
	// DEBUG ONLY NOT FOR RELEASE
	always_comb begin
	
		red = 8'h00;
		blue = 8'h00;
		green = 8'h00;
	
		case(color)
			0: {red, green, blue} = 24'h7C7C7C;
			1: {red, green, blue} = 24'h0000FC;
			2: {red, green, blue} = 24'h0000BC;
			3: {red, green, blue} = 24'h4428BC;
			4: {red, green, blue} = 24'h940084;
			5: {red, green, blue} = 24'hA80020;
			6: {red, green, blue} = 24'hA81000;
			7: {red, green, blue} = 24'h881400;
			8: {red, green, blue} = 24'h503000;
			9: {red, green, blue} = 24'h007800;
			10: {red, green, blue} = 24'h006800;
			11: {red, green, blue} = 24'h005800;
			12: {red, green, blue} = 24'h004058;
			13: {red, green, blue} = 24'h000000;
			14: {red, green, blue} = 24'h000000;
			15: {red, green, blue} = 24'h000000;
			16: {red, green, blue} = 24'hBCBCBC;
			17: {red, green, blue} = 24'h0078F8;
			18: {red, green, blue} = 24'h0058F8;
			19: {red, green, blue} = 24'h6844FC;
			20: {red, green, blue} = 24'hD800CC;
			21: {red, green, blue} = 24'hE40058;
			22: {red, green, blue} = 24'hF83800;
			23: {red, green, blue} = 24'hE45C10;
			24: {red, green, blue} = 24'hAC7C00;
			25: {red, green, blue} = 24'h00B800;
			26: {red, green, blue} = 24'h00A800;
			27: {red, green, blue} = 24'h00A844;
			28: {red, green, blue} = 24'h008888;
			29: {red, green, blue} = 24'h000000;
			30: {red, green, blue} = 24'h000000;
			31: {red, green, blue} = 24'h000000;
			32: {red, green, blue} = 24'hF8F8F8;
			33: {red, green, blue} = 24'h3CBCFC;
			34: {red, green, blue} = 24'h6888FC;
			35: {red, green, blue} = 24'h9878F8;
			36: {red, green, blue} = 24'hF878F8;
			37: {red, green, blue} = 24'hF85898;
			38: {red, green, blue} = 24'hF87858;
			39: {red, green, blue} = 24'hFCA044;
			40: {red, green, blue} = 24'hF8B800;
			41: {red, green, blue} = 24'hB8F818;
			42: {red, green, blue} = 24'h58D854;
			43: {red, green, blue} = 24'h58F898;
			44: {red, green, blue} = 24'h00E8D8;
			45: {red, green, blue} = 24'h787878;
			46: {red, green, blue} = 24'h000000;
			47: {red, green, blue} = 24'h000000;
			48: {red, green, blue} = 24'hFCFCFC;
			49: {red, green, blue} = 24'hA4E4FC;
			50: {red, green, blue} = 24'hB8B8F8;
			51: {red, green, blue} = 24'hD8B8F8;
			52: {red, green, blue} = 24'hF8B8F8;
			53: {red, green, blue} = 24'hF8A4C0;
			54: {red, green, blue} = 24'hF0D0B0;
			55: {red, green, blue} = 24'hFCE0A8;
			56: {red, green, blue} = 24'hF8D878;
			57: {red, green, blue} = 24'hD8F878;
			58: {red, green, blue} = 24'hB8F8B8;
			59: {red, green, blue} = 24'hB8F8D8;
			60: {red, green, blue} = 24'h00FCFC;
			61: {red, green, blue} = 24'hF8D8F8;
			62: {red, green, blue} = 24'h000000;
			63: {red, green, blue} = 24'h000000;
		endcase	
	end
	
endmodule
