`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2023 08:54:26 PM
// Design Name: 
// Module Name: InstantiateRAM
// Project Name: 
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


module Test_ROM(input logic   Clk,
			    input logic [15:0]  address,
		        output logic [7:0]  data
				);
							
always_comb begin
    case(address)
        // Start - Reset
        16'h8000:   data = 8'h09;   // ORA imm
        16'h8001:   data = 8'b00111111;
        16'h8002:   data = 8'h29;   // ANDA imm
        16'h8003:   data = 8'b00111100;
        16'h8004:   data = 8'h21;   // ANDA X_ind
        16'h8005:   data = 8'h50;   // Address to fetch
        16'h8006:   data = 8'h20;   // JSR to $a000
        16'h8007:   data = 8'h00;   
        16'h8008:   data = 8'ha0;
        
        // Start - NMI
        16'ha000:   data = 8'h18;   // CLC
        16'ha009:   data = 8'h60;   // RTS
        
        // Start - BRK/IRQ
        16'hb040:   data = 8'hb8;   // CLV
        16'hb041:   data = 8'h50;   // BVC
        16'hb042:   data = 8'h05;   
        16'hb047:   data = 8'he8;   // INX
        16'hb048:   data = 8'h4c;   // JMP to $8000
        16'hb049:   data = 8'h00;   
        16'hb04a:   data = 8'h80;
        
        // Variables
        16'h0050:   data = 8'h00;
        16'h0051:   data = 8'h90;
        
        16'h9000:   data = 8'b00110011;
        
        // NMI vector
        16'hfffa:   data = 8'h00;
        16'hfffb:   data = 8'ha0;
        // Reset vector
        16'hfffc:   data = 8'h00;
        16'hfffd:   data = 8'h80;
        // BRK/IRQ vector
        16'hfffe:   data = 8'h40;
        16'hffff:   data = 8'hb0;
        
        default:    data = 8'hEA;   // EA = NOP (No Operation)
    endcase
end

endmodule
