// takes the address from the CPU and enables the appropriate hardware block and passes the necessary address to the block

module HardwareDecoder(	input[15:0] addr, input rd, input wr,
			output ppu_cs_n, // active low
			output controller_cs_n, // active low
			output mem_cs_n, // active low
			
			output[2:0] ppu_addr, // $0 - $7
			output controller_addr, // 0 for $4016, 1 for $4017
			output[15:0] mem_addr
);

assign mem_addr = addr;
assign controller_addr = addr[0];
assign ppu_addr = addr[2:0];

assign mem_cs_n = (addr < 16'h2000 || addr >= 16'h4020) ? 1'b0 : 1'b1;
assign controller_cs_n = (addr == 16'h4016 || (addr == 16'h4017 & rd)) ? 1'b0 : 1'b1;
assign ppu_cs_n = (addr >= 16'h2000 && addr <= 16'h3FFF) ? 1'b0 : 1'b1;

endmodule
