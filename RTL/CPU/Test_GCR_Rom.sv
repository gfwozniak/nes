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


module Test_GCR_Rom(input logic   Clk,
			    input logic [14:0]  address,
		        output logic [7:0]  data
				);
							
always_comb begin
    case(address)
        // Start - Reset
        15'h8000:   data = 8'ha9;   // LDA imm
        15'h8001:   data = 8'h1e;   // PPUMASK
        15'h8002:   data = 8'h8d;   // STA abs PPUMASK
        15'h8003:   data = 8'h01;
        15'h8004:   data = 8'h20;
        15'h8005:   data = 8'ha9;   // LDA imm
        15'h8006:   data = 8'h80;   // PPUCTRL
        15'h8007:   data = 8'h8d;   // STA abs PPUCTRL
        15'h8008:   data = 8'h00;   
        15'h8009:   data = 8'h20;
        15'h800a:   data = 8'ha9;   // LDA imm
        15'h800b:   data = 8'h00;   // PPUCTRL
        15'h800c:   data = 8'h8d;   // STA abs PPUSCROLL
        15'h800d:   data = 8'h05;   
        15'h800e:   data = 8'h20;
        
        
        // Start - NMI
        15'ha000:   data = 8'had;   // LDA abs
        15'ha001:   data = 8'h02;   // PPUSTATUS
        15'ha002:   data = 8'h20;
        15'ha003:   data = 8'ha9;   // LDA imm
        15'ha004:   data = 8'h00; 
        15'ha005:   data = 8'h8d;   // STA abs PPUADDR
        15'ha006:   data = 8'h06;   
        15'ha007:   data = 8'h20;
        15'ha008:   data = 8'ha9;   // LDA imm
        15'ha009:   data = 8'h20; 
        15'ha00a:   data = 8'h8d;   // STA abs PPUADDR
        15'ha00b:   data = 8'h06;   
        15'ha00c:   data = 8'h20;
        
        15'ha00d:   data = 8'had;   // LDA abs
        15'ha00e:   data = 8'h02;   // PPUSTATUS
        15'ha00f:   data = 8'h20;
        15'ha010:   data = 8'ha9;   // LDA imm
        15'ha011:   data = 8'hc0; 
        15'ha012:   data = 8'h8d;   // STA abs PPUADDR
        15'ha013:   data = 8'h06;   
        15'ha014:   data = 8'h20;
        15'ha015:   data = 8'ha9;   // LDA imm
        15'ha016:   data = 8'h23; 
        15'ha017:   data = 8'h8d;   // STA abs PPUADDR
        15'ha018:   data = 8'h06;   
        15'ha019:   data = 8'h20;
        
        15'ha01a:   data = 8'had;   // LDA abs
        15'ha01b:   data = 8'h02;   // PPUSTATUS
        15'ha01c:   data = 8'h20;
        15'ha01d:   data = 8'ha9;   // LDA imm
        15'ha01e:   data = 8'h00; 
        15'ha01f:   data = 8'h8d;   // STA abs PPUADDR
        15'ha020:   data = 8'h06;   
        15'ha021:   data = 8'h20;
        15'ha022:   data = 8'ha9;   // LDA imm
        15'ha023:   data = 8'h3f; 
        15'ha024:   data = 8'h8d;   // STA abs PPUADDR
        15'ha025:   data = 8'h06;   
        15'ha026:   data = 8'h20;
       
        15'ha027:   data = 8'had;   // LDA abs
        15'ha028:   data = 8'h02;   // PPUSTATUS
        15'ha029:   data = 8'h20;
        15'ha02a:   data = 8'ha9;   // LDA imm
        15'ha02b:   data = 8'h01; 
        15'ha02c:   data = 8'h8d;   // STA abs PPUADDR
        15'ha02d:   data = 8'h06;   
        15'ha02e:   data = 8'h20;
        15'ha02f:   data = 8'ha9;   // LDA imm
        15'ha030:   data = 8'h3f; 
        15'ha031:   data = 8'h8d;   // STA abs PPUADDR
        15'ha032:   data = 8'h06;   
        15'ha033:   data = 8'h20;
        
        15'ha034:   data = 8'had;   // LDA abs
        15'ha035:   data = 8'h02;   // PPUSTATUS
        15'ha036:   data = 8'h20;
        15'ha037:   data = 8'ha9;   // LDA imm
        15'ha038:   data = 8'h02; 
        15'ha039:   data = 8'h8d;   // STA abs PPUADDR
        15'ha03a:   data = 8'h06;   
        15'ha03b:   data = 8'h20;
        15'ha03c:   data = 8'ha9;   // LDA imm
        15'ha03d:   data = 8'h3f; 
        15'ha03e:   data = 8'h8d;   // STA abs PPUADDR
        15'ha03f:   data = 8'h06;   
        15'ha040:   data = 8'h20;
        
        15'ha041:   data = 8'had;   // LDA abs
        15'ha042:   data = 8'h02;   // PPUSTATUS
        15'ha043:   data = 8'h20;
        15'ha044:   data = 8'ha9;   // LDA imm
        15'ha045:   data = 8'h03; 
        15'ha046:   data = 8'h8d;   // STA abs PPUADDR
        15'ha047:   data = 8'h06;   
        15'ha048:   data = 8'h20;
        15'ha049:   data = 8'ha9;   // LDA imm
        15'ha04a:   data = 8'h3f; 
        15'ha04b:   data = 8'h8d;   // STA abs PPUADDR
        15'ha04c:   data = 8'h06;   
        15'ha04d:   data = 8'h20;
      
        

        
        
        // Start - BRK/IRQ
        15'hb040:   data = 8'hb8;   // CLV
        15'hb041:   data = 8'h50;   // BVC
        15'hb042:   data = 8'h05;   
        15'hb047:   data = 8'he8;   // INX
        15'hb048:   data = 8'h4c;   // JMP to $8000
        15'hb049:   data = 8'h00;   
        15'hb04a:   data = 8'h80;

        
        // NMI vector
        15'hfffa:   data = 8'h00;
        15'hfffb:   data = 8'ha0;
        // Reset vector
        15'hfffc:   data = 8'h00;
        15'hfffd:   data = 8'h80;
        // BRK/IRQ vector
        15'hfffe:   data = 8'h40;
        15'hffff:   data = 8'hb0;
        
        default:    data = 8'hEA;   // EA = NOP (No Operation)
    endcase
end

endmodule
