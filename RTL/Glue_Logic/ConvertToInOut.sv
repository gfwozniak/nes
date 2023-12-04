module ConvertToInOut #(parameter WIDTH=8)(
	input logic [WIDTH-1:0] indata,
	output logic [WIDTH-1:0] outdata,
	input logic rw,
	inout logic [WIDTH-1:0] inoutdata
	);
	
	parameter  WRITE = 0,
	           READ = 1;
	
	assign inoutdata = (rw == WRITE) ? indata : 8'hzz;



always_comb begin
    if (rw == READ)
        outdata = inoutdata;
end
	
endmodule