`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2023 08:48:02 PM
// Design Name: 
// Module Name: CPU
// Project Name: NES CPU
// Target Devices: 
// Tool Versions: 
// Description: NES CPU for ECE 385 Final Project
// 
// Dependencies: 
// 
// Revision: 1.0
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CPU_v1(input logic  Clk, 
                        Reset, 
                        IRQ, 
                        NMI,
                        RDY,
           input logic  [7:0]   Data_Bus_in,
           output logic [15:0]  Address_Bus_out,
           output logic [7:0]   Data_Bus_out,
           output logic RW, // High = Read, Low = Write
                        SYNC,
                        M2
           );
          
// REFACTOR CODE, REMEMBER ABOUT INFERRED LATCHES!!!!!
// MAKE A NEW VERSION AND KEEP THIS ONE AS AN OLD COPY!!!!!
                       
// Instantiating internal variables



logic [15:0]    PC_Reg_in,
                PC_Reg_out,
                Next_Address,
                Stack_Pointer;  
logic [7:0] SP_Reg_out, 
            A_Reg_out,
            X_Reg_out,
            Y_Reg_out,
            P_Reg_out,
            I_Reg_out,
            SP_Reg_in, 
            A_Reg_in,
            X_Reg_in,
            Y_Reg_in,
            P_Reg_in,
            I_Reg_in,
            Int_Data_Bus; // Internal data bus  
logic       PC_Reg_LD,
            SP_Reg_LD, 
            A_Reg_LD,
            X_Reg_LD,
            Y_Reg_LD,
            P_Reg_LD,
            I_Reg_LD,
            Address_Inc,    // Address Increment  
            PC_Inc,         // PC Increment
            Halt;           // Based on RDY signal
logic [3:0] Total_Cycle_Count, Curr_Cycle,  // Keeps track of how many cycles are in the current instruction
            Addr_Cycle_Count,   // Addressing
            Op_Cycle_Count, Curr_Op_Cycle,  // Opcode
            Reset_Seq;  // Reset Sequence
            
// Phase Two
assign M2 = Clk;
            
// Instantiating registers

// Program Counter (PC) - 16 bits
Register PC_Reg(.Clk(Clk), .Reset(Reset), .LD(PC_Reg_LD), .A(PC_Reg_in), .Z(PC_Reg_out));

// Stack Pointer (SP) - 8 bits
Register SP_Reg(.Clk(Clk), .Reset(Reset), .LD(SP_Reg_LD), .A(SP_Reg_in), .Z(SP_Reg_out));

// Accumulator (A) - 8 bits
Register A_Reg(.Clk(Clk), .Reset(Reset), .LD(A_Reg_LD), .A(A_Reg_in), .Z(A_Reg_out));
    
// Index Register X (X) - 8 bits
Register X_Reg(.Clk(Clk), .Reset(Reset), .LD(X_Reg_LD), .A(X_Reg_in), .Z(X_Reg_out));

// Index Register Y (Y) - 8 bits
Register Y_Reg(.Clk(Clk), .Reset(Reset), .LD(Y_Reg_LD), .A(Y_Reg_in), .Z(Y_Reg_out));

// Status Register - 8 bits - NV_BDIZC
Register P_Reg(.Clk(Clk), .Reset(Reset), .LD(P_Reg_LD), .A(P_Reg_in), .Z(P_Reg_out));

// Instruction Register - 8 bits
Register I_Reg(.Clk(Clk), .Reset(Reset), .LD(I_Reg_LD), .A(Data_Bus_in), .Z(I_Reg_out));


// Instantiating opcode states

enum logic [7:0] {  RESET,
                    ADC,    // Add descriptions here!!!
                    ANDA,   // AND replaced with ANDA,
                    ASL,
                    BCC,
                    BCS,
                    BEQ,
                    BITT,   // BIT replaced with BITT
                    BMI,
                    BNE,
                    BPL,
                    BRK,
                    BVC,
                    BVS,
                    CLC,
                    CLD,
                    CLI,
                    CLV,
                    CMP,
                    CPX,
                    CPY,
                    DEC,
                    DEX,
                    DEY,
                    EOR,
                    INC,
                    INX,
                    INY,
                    JMP,
                    JSR,
                    LDA,
                    LDX,
                    LDY,
                    LSR,
                    NOP,
                    ORA,
                    PHA,
                    PHP,
                    PLA,
                    PLP,
                    ROL,
                    ROR,
                    RTI,
                    RTS,
                    SBC,
                    SEC,
                    SED,
                    SEI,
                    STA,
                    STX,
                    STY,
                    TAX,
                    TAY,
                    TSX,
                    TXA,
                    TXS,
                    TYA 
                    }   Op_State;

// Instantiating addressing mode states

enum logic [3:0] {  A,      // Accumulator
                    abs,    // Absolute
                    abs_X,  // Absolute, X-indexed
                    abs_Y,  // Absolute, Y-indexed
                    imm,    // Immediate or #
                    impl,   // Implied
                    ind,    // Indirect
                    X_ind,  // X-indexed, indirect
                    ind_Y,  // Indirect, Y-indexed
                    rel,    // Relative
                    zpg,    // Zeropage
                    zpg_X,  // Zeropage, X-indexed
                    zpg_Y   // Zeropage, Y-indexed
                    }   Addr_State;


// Phase Two

always_ff @ (posedge Clk) begin

    // Reset sequence
    if (Reset)
        Reset_Seq = 4'd1;
    else
        Reset_Seq = 4'd0;
    case (Reset_Seq)
            4'd1:   begin
                        Op_State = RESET;
                        Reset_Seq = 4'd2; 
                        // Addressing
                        Address_Inc = 1'b0;
                        Address_Bus_out = Address_Bus_out;
                        RW = 1'b1;
                        // Status Register
                        P_Reg_LD = 1'b1;
                        P_Reg_in = 8'b00000100;
                    end
            4'd2:   begin
                        Reset_Seq = 4'd3; 
                    end
            4'd3:   begin
                        Reset_Seq = 4'd4;  
                    end
            4'd4:   begin
                        Reset_Seq = 4'd5;
                    end 
            4'd5:   begin
                        Reset_Seq = 4'd6; 
                        Address_Inc = 1'b0;
                        Address_Bus_out = 16'hFFFC;
                        RW = 1'b1;
                        P_Reg_LD = 1'b1;
                        P_Reg_in = 8'b00000100;
                    end
            4'd6:   begin
                        Reset_Seq = 4'd7;
                        Int_Data_Bus = Data_Bus_in;
                        Address_Bus_out = 16'hFFFD;
                        P_Reg_LD = 1'b0;
                    end
            4'd7:   begin
                        Reset_Seq = 4'd8;
                        Address_Bus_out = {Data_Bus_in, Int_Data_Bus};
                        PC_Inc = 1'b0;
                        PC_Reg_LD = 1'b1;
                        PC_Reg_in = Address_Bus_out;
                    end
            default: ;  // Do nothing
    endcase 
    
    // THINK ABOUT: SHOULD I ADD A RW = 1 IF SYNC IS ON HERE?
    
    // Decode Instructions
    if (Curr_Cycle == 4'd1 || Reset_Seq > 4'd0 || Halt)
        ;   // Do nothing
    // Store data into data bus unless it's an implied opcode (has no operand)
    else if (Curr_Cycle == 4'd2 && Addr_State != impl) begin 
        Int_Data_Bus = Data_Bus_in;
    end
    // Addressing Cycles
    // Beware of this count changing... Check for additional special case opcodes that have funky cycle times
    else if (Curr_Cycle < Total_Cycle_Count) begin // Addressing
        unique case (Addr_State)
            X_ind:  unique case (Curr_Cycle)
                        4'd3:   begin
                                    Int_Data_Bus = Int_Data_Bus + X_Reg_out;
                                    Address_Bus_out = {Int_Data_Bus, 8'h00};
                                    RW = 1'b1;
                                end
                        4'd4:      Int_Data_Bus = Data_Bus_in;
                        4'd5:   begin
                                    Address_Bus_out = {Data_Bus_in, Int_Data_Bus};
                                    RW = 1'b1;
                                end
                    endcase
            abs:    begin
                        Address_Bus_out = {Data_Bus_in, Int_Data_Bus};
                        RW = 1'b1;
                    end
            abs_Y:  begin
                        Int_Data_Bus = Int_Data_Bus + X_Reg_out;
                        Address_Bus_out = {Data_Bus_in, Int_Data_Bus};
                        RW = 1'b1;
                    end
        endcase
    end
    // Opcode Cycles
    else begin
        unique case (Op_State)
            ADC:    begin
                        A_Reg_LD = 1'b1;
                        A_Reg_in = A_Reg_out + Data_Bus_in + P_Reg_out[0];
                        // Check how to set status registers! (for carry)
                    end
            ANDA:   begin
                        A_Reg_LD = 1'b1;
                        A_Reg_in = A_Reg_out && Data_Bus_in;
                    end
            JMP:    begin
                        Address_Bus_out = {Data_Bus_in, Int_Data_Bus};
                        PC_Reg_LD = 1'b1;
                        PC_Reg_in = Address_Bus_out;
                        Address_Inc = 1'b0;
                    end
            ORA:    begin
                        A_Reg_LD = 1'b1;
                        A_Reg_in = A_Reg_out || Data_Bus_in;
                    end
        endcase
        
    // Assign next address if address_inc is turned on
    if (Reset_Seq == 4'd0 && ~Halt && Address_Inc)
        Address_Bus_out = Address_Bus_out + 15'd1;
    end
    
    // Assign next PC value
    if (Reset_Seq == 4'd0 && ~Halt && PC_Inc)
        PC_Reg_in = PC_Reg_out + 15'd1;
end

// Phase One

always_ff @ (negedge Clk) begin
    // Timing control
    
    // Reset sequence
    if (Reset_Seq > 4'd0 && Reset_Seq != 4'd7)
        Curr_Cycle = 4'd1;
    else if (Reset_Seq == 4'd7) begin
        Reset_Seq = 4'd0;
        SYNC = 1'b1;
        I_Reg_LD = 1'b1;
        Address_Inc = 1'b1;
        PC_Inc = 1'b1;
        Curr_Cycle = 4'd1;
    end
    // If current operation is on last cycle, start new operation next cycle
    else if (Curr_Cycle == Total_Cycle_Count) begin
        SYNC = 1'b1;
        I_Reg_LD = 1'b1;
        Curr_Cycle = 4'd1;
    end
    // Write states ignore RDY line being pulled down
    else if (~RDY && RW)
        Halt = 1'b1;
    else if (RDY && Halt)
        Halt = 1'b0;
    // Pull sync down after one clock cycle
    else if (SYNC) begin
        SYNC = 1'b0;
        I_Reg_LD = 1'b0;
        Curr_Cycle = Curr_Cycle + 4'd1;
    end
    else
        Curr_Cycle = Curr_Cycle + 4'd1;
end

// Timing control

always_comb begin
    // Reset signal values
    if (Reset_Seq > 4'd0) begin
        SP_Reg_LD = 1'b0;
        A_Reg_LD = 1'b0;
        X_Reg_LD = 1'b0;
        Y_Reg_LD = 1'b0;
        Op_Cycle_Count = 4'd1;
        Addr_Cycle_Count = 4'd0;
    end
    
    // Assign next state
    unique case (I_Reg_out)
        // Pick out a few states for now so we can test before we move forward with others
        8'h09:  begin
                    Op_State = ORA;
                    Addr_State = imm;
                end
        8'h21:  begin
                    Op_State = ANDA;
                    Addr_State = X_ind;
                end
        8'h29:  begin
                    Op_State = ANDA;
                    Addr_State = imm;
                end
        8'h4C:  begin
                    Op_State = JMP;
                    Addr_State = abs;
                end
        8'h79:  begin
                    Op_State = ADC;
                    Addr_State = abs_Y;
                end
    endcase
end 

always_comb begin
    unique case (Op_State)
        RESET:  Op_Cycle_Count = 4'd1;
        ADC:    Op_Cycle_Count = 4'd2;
        ANDA:   Op_Cycle_Count = 4'd2;
        JMP:    Op_Cycle_Count = 4'd1;
        ORA:    Op_Cycle_Count = 4'd2;
    endcase
    
    unique case (Addr_State)
        imm:    Addr_Cycle_Count = 4'd0;
        X_ind:  Addr_Cycle_Count = 4'd4;
        abs:    Addr_Cycle_Count = 4'd2;
        abs_Y:  Addr_Cycle_Count = 4'd2;
    endcase
    
    Total_Cycle_Count = Op_Cycle_Count + Addr_Cycle_Count;
end
                   
// Interrupt Logic

assign Stack_Pointer = {8'h01, (8'hFF - SP_Reg_out)};

   

   
    
endmodule
