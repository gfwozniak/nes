module clk_div10(clk,reset, clk_out,sync);
 
input clk;
input sync;
input reset;
output clk_out;
 
reg [3:0] pos_count;
wire [3:0] r_nxt;
 
always @(posedge sync)
if (reset)
pos_count <=0;
else if (pos_count ==9) pos_count <= 0;
else pos_count<= pos_count +1;
 
assign clk_out = ((pos_count < 5));
endmodule