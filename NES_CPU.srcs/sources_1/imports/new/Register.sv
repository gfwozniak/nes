`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2023 12:59:38 AM
// Design Name: 
// Module Name: Register
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


module Register
    #(parameter width = 16)
    (input logic [width-1:0] A,
    input logic LD,
    input logic Clk, Reset,
    output logic [width-1:0] Z);
        
    always_ff @ (posedge Clk or posedge Reset)
    begin
        if (Reset)
            Z <= '0;
        else if (LD)
            Z <= A;
        else
            Z <= Z;
    end
    
endmodule
