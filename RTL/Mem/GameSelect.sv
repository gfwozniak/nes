import Games::*;

module GameSelect(
		input rst_n,
		input [15:0] SW,
		output logic [3:0] game
	);
	
initial
	game = NES_TEST;
			
always @(negedge rst_n) begin
	if (SW == 16'd1) begin // MARIO
		game = MARIO;
	end
	else if (SW == 16'd2) begin // DK
		game = DONKEY_KONG;
	end
	else begin
		game = NES_TEST;
	end
end

endmodule