`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2023 08:14:46 PM
// Design Name: 
// Module Name: Adder
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


module Branch_Adder(input logic     [15:0]  Add_PC,
                    input logic     [7:0]   Add_Rel,
                    output logic    [15:0]  New_PC,
                    output logic            Same_Page
                    );

    logic [7:0] Sub_Rel;
    
    assign Sub_Rel = ~(Add_Rel) + 8'd1;
    
    always_comb begin
        if (Add_Rel[7] == 1'b0)     // Addition
            New_PC = Add_PC + Add_Rel;
        else                        // Subtraction
            New_PC = Add_PC - Sub_Rel;
            
        if (New_PC[15:8] == Add_PC[15:8])   // Same page
            Same_Page = 1'b1;
        else                                // Different page
            Same_Page = 1'b0;
    end

endmodule
