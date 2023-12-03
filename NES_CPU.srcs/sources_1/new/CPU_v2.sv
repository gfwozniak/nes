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


module CPU_v2(input logic   Clk, 
                            Reset, 
                            IRQ, 
                            NMI,
                            RDY,
           input logic  [7:0]   DB_in,  // Data Bus in
           output logic [15:0]  AB_out, // Address Bus out
           output logic [7:0]   DB_out, // Data Bus out
           output logic RW, // High = Read, Low = Write
                        SYNC,
                        M2
           );
          
                       
// Instantiating internal variables

logic [15:0]    PC_Reg_out,
                PC_Reg_in,
                Stack_Pointer;  
logic [7:0]     DB_buff,    // Data Bus buffer
                SP_Reg_out, 
                A_Reg_out,
                X_Reg_out,
                Y_Reg_out,
                P_Reg_out,
                I_Reg_out,
                D_Reg_out,
                SP_Reg_in, 
                A_Reg_in,
                X_Reg_in,
                Y_Reg_in,
                P_Reg_in,
                D_Reg_in;
logic           LD_PC,
                LD_SP, 
                LD_A,
                LD_X,
                LD_Y,
                LD_P,
                LD_I,
                LD_D,
                Address_Inc,        // Address Increment  
                PC_Inc,             // PC Increment
                Halt_RDY,           // Based on RDY signal
                Halt_Reset;         // Based on Reset signal
logic [3:0]     Total_Cycle_Count, Curr_Cycle, Next_Cycle,  // Keeps track of how many cycles are in the current instruction
                Addr_Cycle_Count,   // Addressing
                Op_Cycle_Count, Curr_Op_Cycle;  // Opcode
logic [4:0]     Reset_Seq;  // Reset Sequence
                
// Phase Two
assign M2 = Clk;

// Phase One
assign phi1 = ~Clk;
            
// Instantiating registers

// Program Counter (PC) - 16 bits
Register PC_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_PC), .A(PC_Reg_in), .Z(PC_Reg_out));

// Stack Pointer (SP) - 8 bits
Register #(.width(8)) SP_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_SP), .A(SP_Reg_in), .Z(SP_Reg_out));

// Accumulator (A) - 8 bits
Register #(.width(8)) A_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_A), .A(A_Reg_in), .Z(A_Reg_out));
    
// Index Register X (X) - 8 bits
Register #(.width(8)) X_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_X), .A(X_Reg_in), .Z(X_Reg_out));

// Index Register Y (Y) - 8 bits
Register #(.width(8)) Y_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_Y), .A(Y_Reg_in), .Z(Y_Reg_out));

// Status Register - 8 bits - NV_BDIZC
Register #(.width(8)) P_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_P), .A(P_Reg_in), .Z(P_Reg_out));

// Instruction Register - 8 bits
Register #(.width(8)) I_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_I), .A(DB_in), .Z(I_Reg_out));

// Register D - REPLACES INTERNAL DATA BUS - 8 bits
Register #(.width(8)) D_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_D), .A(DB_buff), .Z(D_Reg_out));


// Instantiating opcode states

enum logic [7:0] {  RESET,  
                    ERROR,  // Used for unknown op codes
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
                    }   Op_State, Next_Op_State;

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
                    }   Addr_State, Next_Addr_State;



// Instruction Decoder


// Phase Two

always_ff @ (posedge Clk) begin
    
    // Reset sequence
    if (Reset) begin
        Reset_Seq <= 5'd1;
        Halt_Reset = 1'b1;
    end
    else begin
        Reset_Seq <= 5'd0;
        Halt_Reset = 1'b0;
    end
    
    if (Reset_Seq > 5'd0) begin
        case (Reset_Seq)
            5'd1:       Reset_Seq <= 5'd2; 
            5'd2:       Reset_Seq <= 5'd3; 
            5'd3:       Reset_Seq <= 5'd4; 
            5'd4:       Reset_Seq <= 5'd5; 
            5'd5:       Reset_Seq <= 5'd6; 
            5'd6:       Reset_Seq <= 5'd7;
            5'd7:       Reset_Seq <= 5'd8;
            default:    Reset_Seq <= 5'd0;
        endcase 
    end
    
    // Data Bus buffer
    DB_buff <= DB_in;

end


always_comb begin

    // Set default controls

    // Addressing
    Address_Inc = 1'b1;
    AB_out = PC_Reg_out;
    RW = 1'b1;
    
    // Registers
    PC_Reg_in = PC_Reg_out;
    PC_Inc = 1'b1;      
    SP_Reg_in = 8'h00;
    A_Reg_in = 8'h00;
    X_Reg_in = 8'h00;
    Y_Reg_in = 8'h00;
    P_Reg_in = 8'h00;
    D_Reg_in = DB_buff;
            
     // Loads 
    LD_PC = 1'b0;
    LD_SP = 1'b0;
    LD_A = 1'b0;
    LD_X = 1'b0;
    LD_Y = 1'b0;
    LD_P = 1'b0;
    LD_I = 1'b0;
    LD_D = 1'b0;
    
    // SYNC
    if (SYNC) begin
        LD_I = 1'b1;
    end
    
    // Reset sequence
    if (Reset_Seq > 5'd0) begin
        case (Reset_Seq)
                5'd6:   begin
                            // Addressing
                            AB_out = 16'hFFFC;    
                            // Status Register
                            LD_P = 1'b1;
                            P_Reg_in = 8'b00000100;
                        end
                5'd7:   begin
                            // Addressing
                            AB_out = 16'hFFFD;
                            // Data
                            LD_D = 1'b1;
                            D_Reg_in = DB_buff;
                        end
                5'd8:   begin
                            // Addressing
                            AB_out = {DB_buff, D_Reg_out};
                            LD_PC = 1'b1;
                            PC_Reg_in = AB_out;
                            PC_Inc = 1'b0;
                        end
                default: ;  // Do nothing
        endcase 
    end
    // Halt
    else if (Curr_Cycle == 4'd0 || Halt_RDY || Halt_Reset)
        ;   // Do nothing
    // Halt unless it's an implied opcode (has no operand)
    else if (Curr_Cycle == 4'd1 && Addr_State != impl) begin
        ;   // Do nothing
    end
    // Impl Opcode Cycles
    else if (Addr_State == impl) begin
        unique case (Op_State)
            NOP:    unique case (Curr_Cycle)
                        4'd1:       PC_Inc = 1'b0;  // Stop PC for one cycle
                        default:    ;               // Do nothing
                    endcase
        endcase
    end
    // Addressing Cycles
    // Beware of this count changing... Check for additional special case opcodes that have funky cycle times
    else if (Curr_Cycle < Total_Cycle_Count) begin // Addressing
        Address_Inc = 1'b0;
        PC_Inc = 1'b0;
        unique case (Addr_State)
            X_ind:  unique case (Curr_Cycle)
                        4'd2:   begin
                                    LD_D = 1'b1; 
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:   begin
                                    AB_out = {8'h00, D_Reg_out + X_Reg_out};
                                end
                        4'd4:   begin
                                    AB_out = {8'h00, D_Reg_out + X_Reg_out + 4'd1};
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd5:   begin
                                    AB_out = {DB_buff, D_Reg_out};
                                end
                        default:    ;   // Do nothing
                    endcase
            abs:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    Address_Inc = 1'b1;
                                    PC_Inc = 1'b1;
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:       AB_out = {DB_buff, D_Reg_out};
                    endcase
            abs_Y:  unique case (Curr_Cycle)
                        4'd2:   begin
                                    Address_Inc = 1'b1;
                                    PC_Inc = 1'b1;
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:       AB_out = {DB_buff, D_Reg_out + Y_Reg_out};
                    endcase
            default:    ;  
        endcase
    end
    // Opcode Cycles
    else begin
        unique case (Op_State)
            ADC:    begin
                        LD_A = 1'b1;
                        A_Reg_in = A_Reg_out + DB_buff + P_Reg_out[0];
                        // Check how to set status registers! (for carry)
                    end
            ANDA:   begin
                        LD_A = 1'b1;
                        A_Reg_in = A_Reg_out & DB_buff;
                    end
            JMP:    begin
                        Address_Inc = 1'b0;
                        PC_Inc = 1'b0;
                        AB_out = {DB_buff, D_Reg_out};
                        LD_PC = 1'b1;
                        PC_Reg_in = AB_out;
                    end
            ORA:    begin
                        LD_A = 1'b1;
                        A_Reg_in = A_Reg_out | DB_buff;
                    end
            default:    ;
        endcase
    end
        
    // Increment PC value
    if (Reset_Seq == 5'd0 && ~Halt_RDY && ~Halt_Reset && PC_Inc) begin
        LD_PC = 1'b1;
        PC_Reg_in = PC_Reg_out + 16'd1;
    end
        
    // Addressing
    if (Reset_Seq == 5'd0 && ~Halt_RDY && ~Halt_Reset && Address_Inc) begin
        AB_out = PC_Reg_out + 16'd1;
    end
end



// Timing Control


// Phase One

always_ff @ (posedge phi1) begin

    // SYNC
    if (Reset_Seq == 5'd8 || Curr_Cycle == Total_Cycle_Count)
        SYNC = 1'b1;
    else
        SYNC = 1'b0;
    
    // Write states ignore RDY line being pulled down
    // DOUBLE CHECK IMPLEMENTATION OF HALT
    if (~RDY && RW)
        Halt_RDY = 1'b1;
    else
        Halt_RDY = 1'b0;

end


// Phase Two

always_ff @ (posedge Clk) begin
    Curr_Cycle <= Next_Cycle;
end


always_comb begin
    
    // If current operation is in reset sequence or in sync, start new operation next cycle
    if (Reset_Seq > 5'd0 && Reset_Seq != 5'd8)
        Next_Cycle = 4'd0;
    else if (SYNC || Reset_Seq == 5'd8)
        Next_Cycle = 4'd1;
    else
        Next_Cycle = Curr_Cycle + 4'd1;

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
        8'h4C:  begin   // LOOK INTO BUG FOR JMP
                    Op_State = JMP;
                    Addr_State = abs;
                end
        8'h79:  begin
                    Op_State = ADC;
                    Addr_State = abs_Y;
                end
        8'hEA:  begin
                    Op_State = NOP;
                    Addr_State = impl;
                end
        default:    begin   // Unknown opcode provided, throw error and restart
                        Op_State = ERROR;
                        Addr_State = imm;
                    end
    endcase
    
    unique case (Op_State)
        RESET:  Op_Cycle_Count = 4'd0;
        ORA:    Op_Cycle_Count = 4'd2;
        ANDA:   Op_Cycle_Count = 4'd2;
        JMP:    Op_Cycle_Count = 4'd1;
        ADC:    Op_Cycle_Count = 4'd2;
        NOP:    Op_Cycle_Count = 4'd2;
        default:    Op_Cycle_Count = 4'd0;
    endcase
    
    unique case (Addr_State)
        abs:    Addr_Cycle_Count = 4'd2;
        abs_Y:  Addr_Cycle_Count = 4'd2;
        imm:    Addr_Cycle_Count = 4'd0;
        impl:   Addr_Cycle_Count = 4'd0;
        X_ind:  Addr_Cycle_Count = 4'd4;
        default:    Op_Cycle_Count = 4'd0;
    endcase
    
    Total_Cycle_Count = Op_Cycle_Count + Addr_Cycle_Count;
end



// Interrupt Logic

assign Stack_Pointer = {8'h01, (8'hFF - SP_Reg_out)};
   
    
endmodule
