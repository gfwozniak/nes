module clk_div3(clk,reset, clk_out);
 
input clk;
input reset;
output clk_out;
 
reg [1:0] pos_count, neg_count;
wire [1:0] r_nxt;
logic clk_signal;
 
	typedef enum reg[2:0] {
		P1,
		P2,
		P3,
		N1,
		N2,
		N3,
		N4
	} clock_state;
	


	clock_state pstate, nxt_pstate, nstate, nxt_nstate;
 
always_ff @(posedge clk, posedge reset) begin
    if (reset)
        pstate <= P1;
    else
        pstate <= nxt_pstate;
end

always_ff @(negedge clk, posedge reset) begin
    if (reset)
        nstate <= N1;
    else
        nstate <= nxt_nstate;
end

always_comb begin
    nxt_nstate = N1;
    nxt_pstate = P1;
    if (pstate == P1 & nstate == N1)
    begin
        if (clk)
        begin
            nxt_nstate = N2;
            nxt_pstate = P1;
        end
        else
        begin
            nxt_pstate = P1;
            nxt_nstate = N1;
        end
    end
    else if (pstate == P3 & nstate == N4)
    begin
        nxt_nstate = N1;
        nxt_pstate = P1;
    end
    else
    begin 
        case (nstate)
            N1:
                nxt_nstate = N2;
            N2:
                nxt_nstate = N3;
            N3:
                nxt_nstate = N4;
            N4:
                nxt_nstate = N1;
        endcase
        case (pstate)
            P1:
                nxt_pstate = P2;
            P2:
                nxt_pstate = P3;
            P3:
                nxt_pstate = P1;
        endcase
    end
end

always_comb begin
    if (pstate == P1)
    begin
        if (nstate == N4 | nstate == N1)
            clk_signal = 1;
        else
            clk_signal = 0;
    end
    else
        clk_signal = 0;
end

assign clk_out = clk_signal;
endmodule