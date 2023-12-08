module clk_div3_v2(clk, reset, clk12_out, clk4_out);
     
    input clk;
    input reset;
    output clk12_out;
    output clk4_out;
     
    reg [3:0] pos_count = 0;
    reg clk12, clk4;
    wire nxt_clk12, nxt_clk4;
     
    always @(posedge clk) begin
        clk12 <= nxt_clk12;
        clk4 <= nxt_clk4;
        if (reset) pos_count <= 0;
        else if (pos_count == 11) pos_count <= 0;
        else pos_count <= pos_count + 1;
    end
    
    assign nxt_clk12 = (pos_count % 4 < 2) ? 1'b1 : 1'b0;
    assign nxt_clk4 = (pos_count >= 0 && pos_count < 6) ? 1'b1 : 1'b0;
    
    assign clk12_out = clk12;
    assign clk4_out = clk4;
    
endmodule