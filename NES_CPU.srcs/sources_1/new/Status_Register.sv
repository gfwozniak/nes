`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2023 09:06:40 PM
// Design Name: 
// Module Name: Status_Register
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


module Status_Register(
    input logic Clk,
                Reset,
                LD,
                C_in,
                Z_in,
                I_in,
                D_in,
                B_in,
                V_in,
                N_in,
    output logic C,
                 Z,
                 I,
                 D,
                 B,
                 V,
                 N
    );
    
    always_ff @ (posedge Clk or posedge Reset)
    begin
        if (Reset)
        begin
            C <= '0;
            Z <= '0;
            I <= '0;
            D <= '0;
            B <= '0;
            V <= '0;
            N <= '0;
        end
        else if (LD)
        begin
            C <= C_in;
            Z <= Z_in;
            I <= I_in;
            D <= D_in;
            B <= B_in;
            V <= V_in;
            N <= N_in;
        end
        else
        begin
            C <= C;
            Z <= Z;
            I <= I;
            D <= D;
            B <= B;
            V <= V;
            N <= N;
        end
    end
    
endmodule
