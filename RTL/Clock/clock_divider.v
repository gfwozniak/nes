module clk_div3_v2(clk, reset, clk12_out, clk4_out);
     
    input clk;
    input reset;
    output clk12_out;
    output clk4_out;
     
    reg [3:0] pos_count;
    wire [1:0] r_nxt;
     
    always @(posedge clk) begin
        if (reset) pos_count <= 0;
        else if (pos_count == 11) pos_count <= 0;
        else pos_count <= pos_count + 1;
    end
     
    assign clk12_out = (pos_count % 4 < 2) ? 1'b1 : 1'b0;
    assign clk4_out = (pos_count >= 0 && pos_count < 6) ? 1'b1 : 1'b0;
endmodule