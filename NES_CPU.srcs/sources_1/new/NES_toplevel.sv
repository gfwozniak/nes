`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2023 09:07:53 PM
// Design Name: 
// Module Name: NES_toplevel
// Project Name: NES
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module NES_toplevel(input logic Clk_CPU,
                                Clk_MEM,
                                Reset,
                                IRQ,
                                NMI,
                                RDY,
                                Start
                    );
                    
logic [15:0]    address;
logic [7:0]     DB_in, db,
                DB_out;
logic           RW,
                SYNC,
                M2;

// CPU
CPU_v3 cpu(.*,
           .Clk(Clk_CPU),
           .AB_out(address)
           );
           
always_comb begin
    if (Start) begin
        if (address == 16'hfffc)
            DB_in = 8'h00;
        else if (address == 16'hfffd)
            DB_in = 8'h04;
//        else if (address == 16'h0400)
//            DB_in = 8'hea;
        else
            DB_in = db;     
    end
    else
        DB_in = db;
end


// Test ROM
Test_ROM_v2 rom(.addra(address),
                .clka(Clk_MEM),
                .dina(DB_out),
                .douta(db),
                .wea(~RW)
                );
     

endmodule
