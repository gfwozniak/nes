module ControllersWrapper(
			input clk,
			input rst_n,
			input cs,
			input rw,
			input addr,
			inout [7:0] cpubus
			);

logic controller1_cs_n, controller2_cs_n;
assign controller1_cs_n = addr | cs;
assign controller2_cs_n = rw ? (~addr | cs) : (cs | addr);

// Force controller to send no signal (idle controller) for now
assign cpubus = (rw && (!controller1_cs_n ^ !controller2_cs_n)) ? 8'h00 : 8'hzz;


endmodule
