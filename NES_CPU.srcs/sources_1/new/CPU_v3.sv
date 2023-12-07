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

(* DONT_TOUCH = "yes" *)
module CPU_v3(input logic      Clk, 
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

logic [31:0]    Interrupt_Vector;
logic [15:0]    PC_Reg_out,
                PC_Reg_in,
                ADDR_Reg_out,
                ADDR_Reg_in,
                Stack_Pointer,
                Next_Addr,
                temp;       // Used as a temp variable for various operations
logic [7:0]     DB_buff,    // Data Bus buffer
                SP_Reg_out, 
                A_Reg_out,
                X_Reg_out,
                Y_Reg_out,
                P_Reg_out,
                I_Reg_out,
                D_Reg_out,
                D2_Reg_out,
                SP_Reg_in, 
                A_Reg_in,
                X_Reg_in,
                Y_Reg_in,
                P_Reg_in,
                D_Reg_in,
                D2_Reg_in,
                Add_Rel;
logic           phi1,
                LD_PC,
                LD_ADDR,
                LD_SP, 
                LD_A,
                LD_X,
                LD_Y,
                LD_P,
                LD_I,
                LD_D,
                LD_D2,
                IRQ_Start, IRQ_Halt, IRQ_Hijack,
                NMI_Start, NMI_Halt, NMI_Hijack, NMI_Start_D, NMI_dly, NMI_punished, NMI_pe,
                In_Interrupt,
                Address_Inc,        // Address Increment  
                PC_Inc,             // PC Increment
                RDY_Halt,           // Based on RDY signal
                Reset_Halt,         // Based on Reset signal
                Stop_Op,            // Tracks if current operation should be stopped based on cycle count and extra cycles
                Jump_Op,            // Shows if the current state will jump to another address
                Write_Op,           // Shows if the current opcode requires writing to memory
                Addr_Overflow;      // Shows if the addressing overflowed during operation
logic [3:0]     Total_Cycle_Count, Curr_Cycle, Next_Cycle,  // Keeps track of how many cycles are in the current instruction
                Addr_Cycle_Count,               // Addressing
                Op_Cycle_Count, Curr_Op_Cycle,  // Opcode
                Add_Cycle, Sub_Cycle,           // Indicate if more or less cycles are required
                Add_Cycle_Control, Sub_Cycle_Control;
logic [4:0]     Reset_Seq,  // Reset Sequence
                IRQ_Seq,    // IRQ Sequence
                NMI_Seq;    // NMI Sequence
                
// Phase Two
assign M2 = Clk;

// Phase One
assign phi1 = ~Clk;

// Stack Pointer
assign Stack_Pointer = {8'h01, SP_Reg_out};
            
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

// Register D - 8 bits
Register #(.width(8)) D_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_D), .A(D_Reg_in), .Z(D_Reg_out));

// Register D2 - 8 bits
Register #(.width(8)) D2_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_D2), .A(D2_Reg_in), .Z(D2_Reg_out));

// Register ADDR - 16 bits
Register #(.width(16)) ADDR_Reg(.Clk(Clk), .Reset(Reset), .LD(LD_ADDR), .A(ADDR_Reg_in), .Z(ADDR_Reg_out));

// Instantiating opcode states

enum logic [7:0] {  FETCH,
                    RESET,  
                    ERROR,  // Used for unknown op codes
                    NMIS,   // NMIS stands for NMI state
                    ADC,    
                    ANDA,   // AND replaced with ANDA
                    ASLA,   // ASL on accumulator
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
                    LSRA,
                    LSR,
                    NOP,
                    ORA,
                    PHA,
                    PHP,
                    PLA,
                    PLP,
                    ROLA,
                    ROL,
                    RORA,
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
                    zpg_Y,  // Zeropage, Y-indexed
                    NA      // None
                    }   Addr_State;



// Instruction Decoder


// Phase Two

always_ff @ (posedge Clk) begin
    // Data Bus buffer
    DB_buff <= DB_in;
end


always_comb begin

    // Set default controls

    // Addressing and Cycling
    RW = 1'b1;
    Address_Inc = 1'b1;
    Next_Addr = PC_Reg_out;
    Add_Cycle = Add_Cycle_Control;
    Sub_Cycle = Sub_Cycle_Control;
    
    // Registers
    PC_Reg_in = PC_Reg_out;
    PC_Inc = 1'b1;      
    ADDR_Reg_in = 16'd0;
    SP_Reg_in = SP_Reg_out;
    A_Reg_in = 8'h00;
    X_Reg_in = 8'h00;
    Y_Reg_in = 8'h00;
    P_Reg_in = P_Reg_out;
    D_Reg_in = DB_buff;
    D2_Reg_in = 8'h00;
    DB_out = 8'hzz;
            
     // Loads 
    LD_PC = 1'b0;
    LD_ADDR = 1'b0;
    LD_SP = 1'b0;
    LD_A = 1'b0;
    LD_X = 1'b0;
    LD_Y = 1'b0;
    LD_P = 1'b0;
    LD_I = 1'b0;
    LD_D = 1'b0;
    LD_D2 = 1'b0;
    
    // Other
    temp = 16'h0000;
    Interrupt_Vector = 16'h0000;
    
    // Halt incrementation
    if (Reset_Halt || Reset_Seq != 5'd0 || IRQ_Seq > 5'd1 || Op_State == BRK || NMI_Seq > 5'd1 || RDY_Halt) begin
        Address_Inc = 1'b0;
        PC_Inc = 1'b0;
    end
    
    // Reset cycles
    if (Reset_Seq != 5'd0) begin
        Add_Cycle = 4'd0;
        Sub_Cycle = 4'd0;
    end
    
    // SYNC
    if (SYNC) begin
        LD_I = 1'b1;
    end
    
    
    // Interrupts
    // Reset sequence
    if (Reset_Seq > 5'd0) begin
        unique case (Reset_Seq)
            5'd6:   begin
                        // Addressing
                        Next_Addr = 16'hFFFC;    
                        // Status Register
                        LD_P = 1'b1;
                        P_Reg_in = 8'h34;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = 8'hFD; // Stack_Pointer = 0xFD
                    end
            5'd7:   begin
                        // Addressing
                        Next_Addr = 16'hFFFD;
                        // Data
                        LD_D = 1'b1;
                        D_Reg_in = DB_buff;
                    end
            5'd8:   begin
                        // Addressing
                        Next_Addr = {DB_buff, D_Reg_out};
                        LD_PC = 1'b1;
                        PC_Reg_in = Next_Addr;
                        PC_Inc = 1'b0;
                    end
            default: ;  // Do nothing
        endcase 
    end
    // Halt
    else if (RDY_Halt)
        ;   // Do nothing
    // NMI sequence
    else if (NMI_Seq > 5'd1) begin
        unique case (NMI_Seq)
            5'd3:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = PC_Reg_out[15:8];
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd4:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = PC_Reg_out[7:0];
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd5:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = P_Reg_out;
                        DB_out[5] = 1'b1;
                        DB_out[4] = 1'b0;
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd6:   begin
                        // Addressing
                        RW = 1'b1;
                        Next_Addr = 16'hfffa;
                        // Status Register
                        LD_P = 1'b1;
                        P_Reg_in[2] = 1'b1;
                    end
            5'd7:   begin
                        // Addressing
                        Next_Addr = 16'hfffb;
                        LD_D = 1'b1;
                        D_Reg_in = DB_buff;
                    end
            5'd8:   begin
                        // Addressing
                        Next_Addr = {DB_buff, D_Reg_out};
                        LD_PC = 1'b1;
                        PC_Reg_in = Next_Addr;
                    end
            default:    ;  // Do nothing
        endcase 
    end
    // IRQ sequence
    else if (IRQ_Seq > 5'd1) begin
        if (NMI_Hijack)
            Interrupt_Vector = 32'hfffbfffa;
        else
            Interrupt_Vector = 32'hfffffffe;
        unique case (IRQ_Seq)
            5'd3:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = PC_Reg_out[15:8];
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd4:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = PC_Reg_out[7:0];
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd5:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = P_Reg_out;
                        DB_out[5] = 1'b1;
                        DB_out[4] = 1'b0;
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd6:   begin
                        // Addressing
                        RW = 1'b1;
                        Next_Addr = Interrupt_Vector[15:0];
                        // Status Register
                        LD_P = 1'b1;
                        P_Reg_in[2] = 1'b1;
                    end
            5'd7:   begin
                        // Addressing
                        Next_Addr = Interrupt_Vector[31:16];
                        LD_D = 1'b1;
                        D_Reg_in = DB_buff;
                    end
            5'd8:   begin
                        // Addressing
                        Next_Addr = {DB_buff, D_Reg_out};
                        LD_PC = 1'b1;
                        PC_Reg_in = Next_Addr;
                    end
            default:    ;  // Do nothing
        endcase 
    end
    // BRK sequence
    else if (Op_State == BRK) begin
        if (NMI_Hijack)
            Interrupt_Vector = 32'hfffbfffa;
        else
            Interrupt_Vector = 32'hfffffffe;
        unique case (Curr_Cycle)
            5'd1:   begin
                        // Increment PC
                        LD_PC = 1'b1;
                        PC_Reg_in = PC_Reg_out + 16'd2;
                    end
            5'd2:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = PC_Reg_out[15:8];
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd3:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = PC_Reg_out[7:0];
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd4:   begin
                        // Addressing
                        Next_Addr = Stack_Pointer;
                        DB_out = P_Reg_out;
                        DB_out[5] = 1'b1;
                        DB_out[4] = 1'b1;
                        RW = 1'b0;
                        // Decrementing SP
                        LD_SP = 1'b1;
                        SP_Reg_in = SP_Reg_out - 8'd1;
                    end
            5'd5:   begin
                        // Addressing
                        RW = 1'b1;
                        Next_Addr = Interrupt_Vector[15:0];
                        // Status Register
                        LD_P = 1'b1;
                        P_Reg_in[2] = 1'b1;
                    end
            5'd6:   begin
                        // Addressing
                        Next_Addr = Interrupt_Vector[31:16];
                        LD_D = 1'b1;
                        D_Reg_in = DB_buff;
                    end
            5'd7:   begin
                        // Addressing
                        Next_Addr = {DB_buff, D_Reg_out};
                        LD_PC = 1'b1;
                        PC_Reg_in = Next_Addr;
                    end
            default:    ;  // Do nothing
        endcase 
    end
    else if (Curr_Cycle == 4'd1) begin
        if (Addr_State == impl) begin
            Address_Inc = 1'b0;
            PC_Inc = 1'b0;
        end
    end
    // Impl Opcode Cycles
    else if (Addr_State == impl) begin
        Address_Inc = 1'b0;
        PC_Inc = 1'b0;
        unique case (Op_State)
            // Transfer Instructions
            TAX:    begin
                        LD_X = 1'b1;
                        X_Reg_in = A_Reg_out;
                        // Status Register
                        LD_P = 1'b1;
                        if (X_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (X_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            TAY:    begin
                        LD_Y = 1'b1;
                        Y_Reg_in = A_Reg_out;
                        // Status Register
                        LD_P = 1'b1;
                        if (Y_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (Y_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            TSX:    begin
                        LD_X = 1'b1;
                        X_Reg_in = SP_Reg_out;
                        // Status Register
                        LD_P = 1'b1;
                        if (X_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (X_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            TXA:    begin
                        LD_A = 1'b1;
                        A_Reg_in = X_Reg_out;
                        // Status Register
                        LD_P = 1'b1;
                        if (A_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (A_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            TXS:    begin
                        LD_SP = 1'b1;
                        SP_Reg_in = X_Reg_out;
                    end
            TYA:    begin
                        LD_A = 1'b1;
                        A_Reg_in = Y_Reg_out;
                        // Status Register
                        LD_P = 1'b1;
                        if (A_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (A_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
                        
            // Stack Instructions
            PHA:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    Next_Addr = Stack_Pointer;
                                    DB_out = A_Reg_out;
                                    RW = 1'b0;
                                end
                        4'd3:   begin
                                    // Decrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out - 8'd1;
                                end
                        default:    ;   // Do nothing
                    endcase
            PHP:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    Next_Addr = Stack_Pointer;
                                    DB_out = P_Reg_out;
                                    DB_out[5] = 1'b1;
                                    DB_out[4] = 1'b1;
                                    RW = 1'b0;
                                end
                        4'd3:   begin
                                    // Decrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out - 8'd1;
                                end
                        default:    ;   // Do nothing
                    endcase
            PLA:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    // Incrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out + 8'd1;
                                end
                        4'd3:   begin
                                    Next_Addr = Stack_Pointer;
                                end
                        4'd4:   begin
                                    LD_A = 1'b1;
                                    A_Reg_in = DB_buff;
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (A_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (A_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            PLP:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out + 8'd1;
                                end
                        4'd3:   begin
                                    Next_Addr = Stack_Pointer;
                                end
                        4'd4:   begin
                                    LD_P = 1'b1;
                                    P_Reg_in = DB_buff;
                                    P_Reg_in[5] = 1'b0;
                                    P_Reg_in[4] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase

            // Decrements and Increments
            DEX:    begin
                        LD_X = 1'b1;
                        X_Reg_in = X_Reg_out - 8'd1;
                        // Status Register
                        LD_P = 1'b1;
                        if (X_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (X_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            DEY:    begin
                        LD_Y = 1'b1;
                        Y_Reg_in = Y_Reg_out - 8'd1;
                        // Status Register
                        LD_P = 1'b1;
                        if (Y_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (Y_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            INX:    begin
                        LD_X = 1'b1;
                        X_Reg_in = X_Reg_out + 8'd1;
                        // Status Register
                        LD_P = 1'b1;
                        if (X_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (X_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            INY:    begin
                        LD_Y = 1'b1;
                        Y_Reg_in = Y_Reg_out + 8'd1;
                        // Status Register
                        LD_P = 1'b1;
                        if (Y_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (Y_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end

            // Shift & Rotate Instructions
            ASLA:   begin
                        LD_P = 1'b1;
                        P_Reg_in[0] = A_Reg_out[7];
                        LD_A = 1'b1;
                        A_Reg_in = {A_Reg_out[6:0], 1'b0};
                        // Status Register
                        if (A_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (A_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            LSRA:   begin
                        LD_P = 1'b1;
                        P_Reg_in[0] = A_Reg_out[0];
                        LD_A = 1'b1;
                        A_Reg_in = {1'b0, A_Reg_out[7:1]};
                        // Status Register
                        if (A_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (A_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            ROLA:   begin
                        LD_P = 1'b1;
                        P_Reg_in[0] = A_Reg_out[7];
                        LD_A = 1'b1;
                        A_Reg_in = {A_Reg_out[6:0], P_Reg_out[0]};
                        // Status Register
                        if (A_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (A_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            RORA:   begin
                        LD_P = 1'b1;
                        P_Reg_in[0] = A_Reg_out[0];
                        LD_A = 1'b1;
                        A_Reg_in = {P_Reg_out[0], A_Reg_out[7:1]};
                        // Status Register
                        if (A_Reg_in == 8'd0)
                            P_Reg_in[1] = 1'b1;
                        else
                            P_Reg_in[1] = 1'b0;
                        if (A_Reg_in[7] == 1'b1)
                            P_Reg_in[7] = 1'b1;
                        else
                            P_Reg_in[7] = 1'b0;
                    end
            
            // Flag Instructions
            CLC:    begin
                        LD_P = 1'b1;
                        P_Reg_in[0] = 1'b0;
                    end
            CLD:    begin
                        LD_P = 1'b1;
                        P_Reg_in[3] = 1'b0;
                    end
            CLI:    begin
                        LD_P = 1'b1;
                        P_Reg_in[2] = 1'b0;
                    end
            CLV:    begin
                        LD_P = 1'b1;
                        P_Reg_in[6] = 1'b0;
                    end
            SEC:    begin
                        LD_P = 1'b1;
                        P_Reg_in[0] = 1'b1;
                    end
            SED:    begin
                        LD_P = 1'b1;
                        P_Reg_in[3] = 1'b1;
                    end
            SEI:    begin
                        LD_P = 1'b1;
                        P_Reg_in[2] = 1'b1;
                    end

            // Jumps & Subroutines
            RTS:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    // Incrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out + 8'd1;
                                end
                        4'd3:   begin
                                    // Addressing
                                    Next_Addr = Stack_Pointer;
                                    // Incrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out + 8'd1;
                                end
                        4'd4:   begin
                                    // Addressing
                                    Next_Addr = Stack_Pointer;
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd5:   begin
                                    // Addressing
                                    Next_Addr = Stack_Pointer;
                                end
                        4'd6:   begin
                                    Next_Addr = {DB_buff, D_Reg_out};
                                    LD_PC = 1'b1;
                                    PC_Reg_in = Next_Addr;
                                end
                        default:    ;   // Do nothing
                    endcase   

            // Interrupts
            RTI:    unique case (Curr_Cycle)
                        5'd2:   begin
                                    // Incrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out + 8'd1;
                                end
                        5'd3:   begin
                                    // Addressing
                                    Next_Addr = Stack_Pointer;
                                    // Incrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out + 8'd1;
                                end
                        5'd4:   begin
                                    // Addressing
                                    Next_Addr = Stack_Pointer;
                                    LD_P = 1'b1;
                                    P_Reg_in = DB_buff;
                                    P_Reg_in[5] = 1'b0;
                                    P_Reg_in[4] = 1'b0;
                                    // Incrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out + 8'd1;
                                end
                        5'd5:   begin
                                    // Addressing
                                    Next_Addr = Stack_Pointer;
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        5'd6:   begin
                                    // Addressing
                                    Next_Addr = {DB_buff, D_Reg_out};
                                    LD_PC = 1'b1;
                                    PC_Reg_in = Next_Addr;
                                end
                        default:    ;  // Do nothing
                    endcase 
            
            // Other
            NOP:    ;   // Do nothing
                    
            default:    ;   // Do nothing
        endcase
    end
    // Addressing Modes
    else if (Curr_Cycle <= Total_Cycle_Count) begin 
        Address_Inc = 1'b0;
        PC_Inc = 1'b0;
        unique case (Addr_State)
            A:      ;   // NOT USED, SAME AS IMPL
            abs:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    Address_Inc = 1'b1;
                                    PC_Inc = 1'b1;
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:   begin
                                    Next_Addr = {DB_buff, D_Reg_out};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end 
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            abs_X:  unique case (Curr_Cycle)
                        4'd2:   begin
                                    Address_Inc = 1'b1;
                                    PC_Inc = 1'b1;
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:   begin
                                    Next_Addr = {DB_buff, D_Reg_out + X_Reg_out};
                                    temp = D_Reg_out + X_Reg_out;
                                    if (temp[15:8] != 8'h00)
                                        Addr_Overflow = 1'b1;
                                    else
                                        Addr_Overflow = 1'b0;
                                    if (Addr_Overflow || Write_Op) begin    // If overflow occurs or write op is enabled, add extra cycle
                                        Next_Addr = PC_Reg_out;
                                        Add_Cycle = 4'd1;
                                    end
                                end
                        4'd4:   begin
                                    if (Addr_Overflow)
                                        Next_Addr = {DB_buff + 8'd1, D_Reg_out + X_Reg_out};
                                    else
                                        Next_Addr = {DB_buff, D_Reg_out + X_Reg_out};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            abs_Y:  unique case (Curr_Cycle)
                        4'd2:   begin
                                    Address_Inc = 1'b1;
                                    PC_Inc = 1'b1;
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:   begin
                                    Next_Addr = {DB_buff, D_Reg_out + Y_Reg_out};
                                    temp = D_Reg_out + Y_Reg_out;
                                    if (temp[15:8] != 8'h00)
                                        Addr_Overflow = 1'b1;
                                    else
                                        Addr_Overflow = 1'b0;
                                    if (Addr_Overflow || Write_Op) begin    // If overflow occurs or write op is enabled, add extra cycle
                                        Next_Addr = PC_Reg_out;
                                        Add_Cycle = 4'd1;
                                    end
                                end
                        4'd4:   begin
                                    if (Addr_Overflow)
                                        Next_Addr = {DB_buff + 8'd1, D_Reg_out + Y_Reg_out};
                                    else
                                        Next_Addr = {DB_buff, D_Reg_out + Y_Reg_out};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            imm:    ;
            impl:   ;
            ind:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    Address_Inc = 1'b1;
                                    PC_Inc = 1'b1;
                                    LD_D = 1'b1; 
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:   begin
                                    Next_Addr = {DB_buff, D_Reg_out};
                                    LD_D2 = 1'b1;
                                    D2_Reg_in = DB_buff;
                                end
                        4'd4:   begin
                                    Next_Addr = {D2_Reg_out, D_Reg_out + 8'd1};
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd5:   begin
                                    Next_Addr = {DB_buff, D_Reg_out};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            X_ind:  unique case (Curr_Cycle)
                        4'd2:   begin
                                    LD_D = 1'b1; 
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:   begin
                                    Next_Addr = {8'h00, D_Reg_out + X_Reg_out};
                                end
                        4'd4:   begin
                                    Next_Addr = {8'h00, D_Reg_out + X_Reg_out + 8'd1};
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff;
                                end
                        4'd5:   begin
                                    Next_Addr = {DB_buff, D_Reg_out};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            ind_Y:  unique case (Curr_Cycle)
                        4'd2:   begin
                                    Next_Addr = {8'h00, DB_buff};
                                    LD_D = 1'b1; 
                                    D_Reg_in = DB_buff;
                                end
                        4'd3:   begin
                                    Next_Addr = {8'h00, D_Reg_out + 8'd1};
                                    LD_D = 1'b1;
                                    D_Reg_in = DB_buff + Y_Reg_out;
                                    temp = DB_buff + Y_Reg_out;
                                    if (temp[15:8] != 8'h00)
                                        Addr_Overflow = 1'b1;
                                    else
                                        Addr_Overflow = 1'b0;
                                    if (Addr_Overflow || Write_Op) begin    // If overflow occurs or write op is enabled, add extra cycle
                                        Next_Addr = {8'h00, D_Reg_out};
                                        LD_D = 1'b0;
                                        Add_Cycle = 4'd1;
                                    end
                                end
                        4'd4:   begin
                                    if (Add_Cycle_Control == 4'd1) begin
                                        Next_Addr = {8'h00, D_Reg_out + 8'd1};
                                        LD_D = 1'b1;
                                        D_Reg_in = DB_buff + Y_Reg_out;
                                    end
                                    else begin
                                        Next_Addr = {DB_buff, D_Reg_out};
                                    end
                                end
                        4'd5:   begin
                                    if (Addr_Overflow)
                                        Next_Addr = {DB_buff + 8'd1, D_Reg_out};
                                    else
                                        Next_Addr = {DB_buff, D_Reg_out};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            rel:    ;  
            zpg:    unique case (Curr_Cycle)
                        4'd2:   begin
                                    Next_Addr = {8'h00, DB_buff};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            zpg_X:  unique case (Curr_Cycle)
                        4'd2:   ;   // Do nothing
                        4'd3:   begin
                                    Next_Addr = {8'h00, DB_buff + X_Reg_out};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            zpg_Y:  unique case (Curr_Cycle)
                        4'd2:   ;   // Do nothing
                        4'd3:   begin
                                    Next_Addr = {8'h00, DB_buff + Y_Reg_out};
                                    LD_ADDR = 1'b1;
                                    ADDR_Reg_in = Next_Addr;
                                end
                        default:    Next_Addr = ADDR_Reg_out;
                    endcase
            default:    ;   // Do nothing
        endcase
        temp = 16'h0000;
        // Opcode Cycles
        unique case (Op_State)
        
            // Transfer Instructions
            LDA:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_A = 1'b1;
                                    A_Reg_in = DB_buff; 
                                    // Status Register - NV_BDIZC
                                    LD_P = 1'b1;
                                    if (A_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (A_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            LDX:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_X = 1'b1;
                                    X_Reg_in = DB_buff;
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (X_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (X_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            LDY:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_Y = 1'b1;
                                    Y_Reg_in = DB_buff;
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (Y_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (Y_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            STA:    if (~(Add_Cycle != 4'd0 && Add_Cycle_Control == 4'd0)) begin
                        unique case (Curr_Op_Cycle)
                            4'd0:   begin
                                        DB_out = A_Reg_out;
                                        RW = 1'b0;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            STX:    if (~(Add_Cycle != 4'd0 && Add_Cycle_Control == 4'd0)) begin
                        unique case (Curr_Op_Cycle)
                            4'd0:   begin
                                        DB_out = X_Reg_out;
                                        RW = 1'b0;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            STY:    if (~(Add_Cycle != 4'd0 && Add_Cycle_Control == 4'd0)) begin
                        unique case (Curr_Op_Cycle)
                            4'd0:   begin
                                        DB_out = Y_Reg_out;
                                        RW = 1'b0;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
                      
            // Decrements and Increments
            DEC:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    DB_out = DB_buff - 8'd1;
                                    RW = 1'b0;
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (DB_out == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (DB_out[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end 
                        default:    ;   // Do nothing
                    endcase
            INC:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    DB_out = DB_buff + 8'd1;
                                    RW = 1'b0;
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (DB_out == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (DB_out[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
                        
            // Arithmetic Operations
            ADC:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_A = 1'b1;
                                    A_Reg_in = A_Reg_out + DB_buff + P_Reg_out[0];
                                    temp = A_Reg_out + DB_buff + P_Reg_out[0];
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (temp > 16'd255)
                                        P_Reg_in[0] = 1'b1;
                                    else
                                        P_Reg_in[0] = 1'b0;
                                    if (A_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    P_Reg_in[6] = (A_Reg_out[7] ^ A_Reg_in[7]) && ~(A_Reg_out[7] ^ DB_buff[7]);
                                    if (A_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            SBC:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_A = 1'b1;
                                    D2_Reg_in = ~DB_buff;
                                    A_Reg_in = A_Reg_out + D2_Reg_in + P_Reg_out[0];
                                    temp = A_Reg_out + D2_Reg_in + P_Reg_out[0];
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (temp > 16'd255)
                                        P_Reg_in[0] = 1'b1;
                                    else
                                        P_Reg_in[0] = 1'b0;
                                    if (A_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    P_Reg_in[6] = (A_Reg_out[7] ^ A_Reg_in[7]) && ~(A_Reg_out[7] ^ ~DB_buff[7]);
                                    if (A_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
                    
            // Logical Operations
            ANDA:   unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_A = 1'b1;
                                    A_Reg_in = A_Reg_out & DB_buff;
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (A_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (A_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            EOR:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_A = 1'b1;
                                    A_Reg_in = A_Reg_out ^ DB_buff;
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (A_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (A_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            ORA:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_A = 1'b1;
                                    A_Reg_in = A_Reg_out | DB_buff;
                                    // Status Register
                                    LD_P = 1'b1;
                                    if (A_Reg_in == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (A_Reg_in[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
                    
            // Shift & Rotate Instructions
            ASL:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_P = 1'b1;
                                    P_Reg_in[0] = DB_buff[7];
                                    DB_out = {DB_buff[6:0], 1'b0};
                                    RW = 1'b0;
                                    // Status Register
                                    if (DB_out == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (DB_out[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            LSR:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_P = 1'b1;
                                    P_Reg_in[0] = DB_buff[0];
                                    DB_out = {1'b0, DB_buff[7:1]};
                                    RW = 1'b0;
                                    // Status Register
                                    if (DB_out == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (DB_out[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            ROL:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_P = 1'b1;
                                    P_Reg_in[0] = DB_buff[7];
                                    DB_out = {DB_buff[6:0], P_Reg_out[0]};
                                    RW = 1'b0;
                                    // Status Register
                                    if (DB_out == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (DB_out[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
            ROR:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_P = 1'b1;
                                    P_Reg_in[0] = DB_buff[0];
                                    DB_out = {P_Reg_out[0], DB_buff[7:1]};
                                    RW = 1'b0;
                                    // Status Register
                                    if (DB_out == 8'd0)
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                    if (DB_out[7] == 1'b1)
                                        P_Reg_in[7] = 1'b1;
                                    else
                                        P_Reg_in[7] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase         
        
            // Comparisons
            CMP:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_P = 1'b1;
                                    if (A_Reg_out < DB_buff) begin
                                        P_Reg_in[0] = 1'b0;
                                        P_Reg_in[1] = 1'b0;
                                    end
                                    else if (A_Reg_out > DB_buff) begin
                                        P_Reg_in[0] = 1'b1;
                                        P_Reg_in[1] = 1'b0;
                                    end
                                    else begin
                                        P_Reg_in[0] = 1'b1;
                                        P_Reg_in[1] = 1'b1;
                                    end
                                    temp = A_Reg_out - DB_buff;
                                    P_Reg_in[7] = temp[7];
                                end
                        default:    ;   // Do nothing
                    endcase   
            CPX:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_P = 1'b1;
                                    if (X_Reg_out < DB_buff) begin
                                        P_Reg_in[0] = 1'b0;
                                        P_Reg_in[1] = 1'b0;
                                    end
                                    else if (X_Reg_out > DB_buff) begin
                                        P_Reg_in[0] = 1'b1;
                                        P_Reg_in[1] = 1'b0;
                                    end
                                    else begin
                                        P_Reg_in[0] = 1'b1;
                                        P_Reg_in[1] = 1'b1;
                                    end
                                    temp = X_Reg_out - DB_buff;
                                    P_Reg_in[7] = temp[7];
                                end
                        default:    ;   // Do nothing
                    endcase   
            CPY:    unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    LD_P = 1'b1;
                                    if (Y_Reg_out < DB_buff) begin
                                        P_Reg_in[0] = 1'b0;
                                        P_Reg_in[1] = 1'b0;
                                    end
                                    else if (Y_Reg_out > DB_buff) begin
                                        P_Reg_in[0] = 1'b1;
                                        P_Reg_in[1] = 1'b0;
                                    end
                                    else begin
                                        P_Reg_in[0] = 1'b1;
                                        P_Reg_in[1] = 1'b1;
                                    end
                                    temp = Y_Reg_out - DB_buff;
                                    P_Reg_in[7] = temp[7];
                                end
                        default:    ;   // Do nothing
                    endcase   

            // Conditional Branch Instructions
            BCC:    begin
                        temp = ~(DB_buff);
                        if (DB_buff[7] == 1'b0)     // Addition
                            PC_Reg_in = PC_Reg_out + DB_buff + 16'd1;
                        else                        // Subtraction
                            PC_Reg_in = PC_Reg_out - temp[7:0];
                        unique case (Curr_Cycle)
                            4'd2:   begin
                                        if (P_Reg_out[0] == 1'b0) begin
                                            if (PC_Reg_in[15:8] != PC_Reg_out[15:8])   // Branch occurs on different page
                                                Add_Cycle = 4'd2;
                                            else    // Branch occurs on same page
                                                Add_Cycle = 4'd1;
                                        end 
                                        else begin
                                            Address_Inc = 1'b1;
                                            PC_Inc = 1'b1;
                                        end
                                    end
                            4'd3:   begin
                                        if (Add_Cycle_Control == 4'd1) begin
                                            Next_Addr = PC_Reg_in;
                                            LD_PC = 1'b1;
                                        end
                                    end
                            4'd4:   begin
                                        Next_Addr = PC_Reg_in;
                                        LD_PC = 1'b1;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            BCS:    begin
                        temp = ~(DB_buff);
                        if (DB_buff[7] == 1'b0)     // Addition
                            PC_Reg_in = PC_Reg_out + DB_buff + 16'd1;
                        else                        // Subtraction
                            PC_Reg_in = PC_Reg_out - temp[7:0];
                        unique case (Curr_Cycle)
                            4'd2:   begin
                                        if (P_Reg_out[0] == 1'b1) begin
                                            if (PC_Reg_in[15:8] != PC_Reg_out[15:8])   // Branch occurs on different page
                                                Add_Cycle = 4'd2;
                                            else    // Branch occurs on same page
                                                Add_Cycle = 4'd1;
                                        end 
                                        else begin
                                            Address_Inc = 1'b1;
                                            PC_Inc = 1'b1;
                                        end
                                    end
                            4'd3:   begin
                                        if (Add_Cycle_Control == 4'd1) begin
                                            Next_Addr = PC_Reg_in;
                                            LD_PC = 1'b1;
                                        end
                                    end
                            4'd4:   begin
                                        Next_Addr = PC_Reg_in;
                                        LD_PC = 1'b1;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            BEQ:    begin
                        temp = ~(DB_buff);
                        if (DB_buff[7] == 1'b0)     // Addition
                            PC_Reg_in = PC_Reg_out + DB_buff + 16'd1;
                        else                        // Subtraction
                            PC_Reg_in = PC_Reg_out - temp[7:0];
                        unique case (Curr_Cycle)
                            4'd2:   begin
                                        if (P_Reg_out[1] == 1'b1) begin
                                            if (PC_Reg_in[15:8] != PC_Reg_out[15:8])   // Branch occurs on different page
                                                Add_Cycle = 4'd2;
                                            else    // Branch occurs on same page
                                                Add_Cycle = 4'd1;
                                        end 
                                        else begin
                                            Address_Inc = 1'b1;
                                            PC_Inc = 1'b1;
                                        end
                                    end
                            4'd3:   begin
                                        if (Add_Cycle_Control == 4'd1) begin
                                            Next_Addr = PC_Reg_in;
                                            LD_PC = 1'b1;
                                        end
                                    end
                            4'd4:   begin
                                        Next_Addr = PC_Reg_in;
                                        LD_PC = 1'b1;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            BMI:    begin
                        temp = ~(DB_buff);
                        if (DB_buff[7] == 1'b0)     // Addition
                            PC_Reg_in = PC_Reg_out + DB_buff + 16'd1;
                        else                        // Subtraction
                            PC_Reg_in = PC_Reg_out - temp[7:0];
                        unique case (Curr_Cycle)
                            4'd2:   begin
                                        if (P_Reg_out[7] == 1'b1) begin
                                            if (PC_Reg_in[15:8] != PC_Reg_out[15:8])   // Branch occurs on different page
                                                Add_Cycle = 4'd2;
                                            else    // Branch occurs on same page
                                                Add_Cycle = 4'd1;
                                        end 
                                        else begin
                                            Address_Inc = 1'b1;
                                            PC_Inc = 1'b1;
                                        end
                                    end
                            4'd3:   begin
                                        if (Add_Cycle_Control == 4'd1) begin
                                            Next_Addr = PC_Reg_in;
                                            LD_PC = 1'b1;
                                        end
                                    end
                            4'd4:   begin
                                        Next_Addr = PC_Reg_in;
                                        LD_PC = 1'b1;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            BNE:    begin
                        temp = ~(DB_buff);
                        if (DB_buff[7] == 1'b0)     // Addition
                            PC_Reg_in = PC_Reg_out + DB_buff + 16'd1;
                        else                        // Subtraction
                            PC_Reg_in = PC_Reg_out - temp[7:0];
                        unique case (Curr_Cycle)
                            4'd2:   begin
                                        if (P_Reg_out[1] == 1'b0) begin
                                            if (PC_Reg_in[15:8] != PC_Reg_out[15:8])   // Branch occurs on different page
                                                Add_Cycle = 4'd2;
                                            else    // Branch occurs on same page
                                                Add_Cycle = 4'd1;
                                        end 
                                        else begin
                                            Address_Inc = 1'b1;
                                            PC_Inc = 1'b1;
                                        end
                                    end
                            4'd3:   begin
                                        if (Add_Cycle_Control == 4'd1) begin
                                            Next_Addr = PC_Reg_in;
                                            LD_PC = 1'b1;
                                        end
                                    end
                            4'd4:   begin
                                        Next_Addr = PC_Reg_in;
                                        LD_PC = 1'b1;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            BPL:    begin
                        temp = ~(DB_buff);
                        if (DB_buff[7] == 1'b0)     // Addition
                            PC_Reg_in = PC_Reg_out + DB_buff + 16'd1;
                        else                        // Subtraction
                            PC_Reg_in = PC_Reg_out - temp[7:0];
                        unique case (Curr_Cycle)
                            4'd2:   begin
                                        if (P_Reg_out[7] == 1'b0) begin
                                            if (PC_Reg_in[15:8] != PC_Reg_out[15:8])   // Branch occurs on different page
                                                Add_Cycle = 4'd2;
                                            else    // Branch occurs on same page
                                                Add_Cycle = 4'd1;
                                        end 
                                        else begin
                                            Address_Inc = 1'b1;
                                            PC_Inc = 1'b1;
                                        end
                                    end
                            4'd3:   begin
                                        if (Add_Cycle_Control == 4'd1) begin
                                            Next_Addr = PC_Reg_in;
                                            LD_PC = 1'b1;
                                        end
                                    end
                            4'd4:   begin
                                        Next_Addr = PC_Reg_in;
                                        LD_PC = 1'b1;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            BVC:    begin
                        temp = ~(DB_buff);
                        if (DB_buff[7] == 1'b0)     // Addition
                            PC_Reg_in = PC_Reg_out + DB_buff + 16'd1;
                        else                        // Subtraction
                            PC_Reg_in = PC_Reg_out - temp[7:0];
                        unique case (Curr_Cycle)
                            4'd2:   begin
                                        if (P_Reg_out[6] == 1'b0) begin
                                            if (PC_Reg_in[15:8] != PC_Reg_out[15:8])   // Branch occurs on different page
                                                Add_Cycle = 4'd2;
                                            else    // Branch occurs on same page
                                                Add_Cycle = 4'd1;
                                        end 
                                        else begin
                                            Address_Inc = 1'b1;
                                            PC_Inc = 1'b1;
                                        end
                                    end
                            4'd3:   begin
                                        if (Add_Cycle_Control == 4'd1) begin
                                            Next_Addr = PC_Reg_in;
                                            LD_PC = 1'b1;
                                        end
                                    end
                            4'd4:   begin
                                        Next_Addr = PC_Reg_in;
                                        LD_PC = 1'b1;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end
            BVS:    begin
                        temp = ~(DB_buff);
                        if (DB_buff[7] == 1'b0)     // Addition
                            PC_Reg_in = PC_Reg_out + DB_buff + 16'd1;
                        else                        // Subtraction
                            PC_Reg_in = PC_Reg_out - temp[7:0];
                        unique case (Curr_Cycle)
                            4'd2:   begin
                                        if (P_Reg_out[6] == 1'b1) begin
                                            if (PC_Reg_in[15:8] != PC_Reg_out[15:8])   // Branch occurs on different page
                                                Add_Cycle = 4'd2;
                                            else    // Branch occurs on same page
                                                Add_Cycle = 4'd1;
                                        end 
                                        else begin
                                            Address_Inc = 1'b1;
                                            PC_Inc = 1'b1;
                                        end
                                    end
                            4'd3:   begin
                                        if (Add_Cycle_Control == 4'd1) begin
                                            Next_Addr = PC_Reg_in;
                                            LD_PC = 1'b1;
                                        end
                                    end
                            4'd4:   begin
                                        Next_Addr = PC_Reg_in;
                                        LD_PC = 1'b1;
                                    end
                            default:    ;   // Do nothing
                        endcase
                    end

            // Jumps & Subroutines
            JMP:    unique case (Curr_Op_Cycle)
                        4'd0:   begin
                                    Address_Inc = 1'b0;
                                    PC_Inc = 1'b0;
                                    Next_Addr = {DB_buff, D_Reg_out};
                                    LD_PC = 1'b1;
                                    PC_Reg_in = Next_Addr;
                                end
                        default:    ;   // Do nothing
                    endcase   
            JSR:    unique case (Curr_Op_Cycle)
                        4'd1:   begin    
                                    // Addressing
                                    Next_Addr = Stack_Pointer;
                                    D_Reg_in = PC_Reg_out[15:8] + 8'd1;
                                    if (PC_Reg_out[7:0] == 8'hff)
                                        DB_out = D_Reg_in;
                                    else
                                        DB_out = PC_Reg_out[15:8];
                                    RW = 1'b0;
                                    // Decrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out - 8'd1;
                                end
                        4'd2:   begin
                                    // Addressing
                                    Next_Addr = Stack_Pointer;
                                    D_Reg_in = PC_Reg_out[7:0] + 8'd1;
                                    DB_out = D_Reg_in;
                                    RW = 1'b0;
                                    // Decrementing SP
                                    LD_SP = 1'b1;
                                    SP_Reg_in = SP_Reg_out - 8'd1;
                                end
                        4'd3:   begin
                                    // Addressing
                                    Next_Addr = ADDR_Reg_out;
                                    LD_PC = 1'b1;
                                    PC_Reg_in = Next_Addr;
                                end
                        default:    ;   // Do nothing
                    endcase   

            // Other
            BITT:   unique case (Curr_Op_Cycle)
                        4'd1:   begin
                                    // Transfer Status Register bits
                                    LD_P = 1'b1;
                                    P_Reg_in = P_Reg_out;
                                    P_Reg_in[7] = DB_buff[7];
                                    P_Reg_in[6] = DB_buff[6];
                                    if ( (DB_buff & A_Reg_out) == 8'h00 )
                                        P_Reg_in[1] = 1'b1;
                                    else
                                        P_Reg_in[1] = 1'b0;
                                end
                        default:    ;   // Do nothing
                    endcase
        
            default:    ;   // Do nothing
            
        endcase
        
    end 
    
    // Reset cycle control and addressing
    if (Stop_Op) begin
        Add_Cycle = 4'd0;
        Sub_Cycle = 4'd0;
        if (~Jump_Op) begin
            Address_Inc = 1'b1;
            PC_Inc = 1'b1;
        end
    end  
       
    // Increment PC value
    if (PC_Inc) begin
        LD_PC = 1'b1;
        PC_Reg_in = PC_Reg_out + 16'd1;
    end
end

// Addressing
always_comb begin
    if (Address_Inc)
        AB_out = PC_Reg_out + 16'd1;
    else
        AB_out = Next_Addr;
end



// Timing Control


// Phase One

always_ff @ (posedge phi1) begin

    // SYNC
    if (Stop_Op)
        SYNC = 1'b1;
    else
        SYNC = 1'b0;
    
    // Write states ignore RDY line being pulled down
    if (~RDY && RW && Reset_Seq == 5'd0)
        RDY_Halt = 1'b1;
    else
        RDY_Halt = 1'b0;

end


// Phase Two

always_ff @ (posedge Clk) begin
    Curr_Cycle <= Next_Cycle;
    Add_Cycle_Control <= Add_Cycle;
    Sub_Cycle_Control <= Sub_Cycle;
end


always_comb begin

    // Set defaults
    Op_State = FETCH;
    Addr_State = NA;
    Write_Op = 1'b0;
    Jump_Op = 1'b0;
    
    // If current operation is at reset sequence end or in sync, start new operation next cycle
    if (RDY_Halt)
        Next_Cycle = Curr_Cycle;
    else if (SYNC)
        Next_Cycle = 4'd1;
    else
        Next_Cycle = Curr_Cycle + 4'd1;

    // Assign next state
    unique case (I_Reg_out)
        // Pick out a few states for now so we can test before we move forward with others
        
        8'h69:      begin
                        Op_State = ADC;
                        Addr_State = imm;
                    end
        8'h65:      begin
                        Op_State = ADC;
                        Addr_State = zpg;
                    end
        8'h75:      begin
                        Op_State = ADC;
                        Addr_State = zpg_X;
                    end
        8'h6D:      begin
                        Op_State = ADC;
                        Addr_State = abs;
                    end
        8'h7D:      begin
                        Op_State = ADC;
                        Addr_State = abs_X;
                    end
        8'h79:      begin
                        Op_State = ADC;
                        Addr_State = abs_Y;
                    end
        8'h61:      begin
                        Op_State = ADC;
                        Addr_State = X_ind;
                    end
        8'h71:      begin
                        Op_State = ADC;
                        Addr_State = ind_Y;
                    end
        
        8'h29:      begin
                        Op_State = ANDA;
                        Addr_State = imm;
                    end
        8'h25:      begin
                        Op_State = ANDA;
                        Addr_State = zpg;
                    end
        8'h35:      begin
                        Op_State = ANDA;
                        Addr_State = zpg_X;
                    end
        8'h2D:      begin
                        Op_State = ANDA;
                        Addr_State = abs;
                    end
        8'h3D:      begin
                        Op_State = ANDA;
                        Addr_State = abs_X;
                    end
        8'h39:      begin
                        Op_State = ANDA;
                        Addr_State = abs_Y;
                    end
        8'h21:      begin
                        Op_State = ANDA;
                        Addr_State = X_ind;
                    end
        8'h31:      begin
                        Op_State = ANDA;
                        Addr_State = ind_Y;
                    end
                    
        8'h0A:      begin
                        Op_State = ASLA;
                        Addr_State = impl;
                    end
        8'h06:      begin
                        Op_State = ASL;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end
        8'h16:      begin
                        Op_State = ASL;
                        Addr_State = zpg_X;
                        Write_Op = 1'b1;
                    end
        8'h0E:      begin
                        Op_State = ASL;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end
        8'h1E:      begin
                        Op_State = ASL;
                        Addr_State = abs_X;
                        Write_Op = 1'b1;
                    end
            
        8'h90:      begin
                        Op_State = BCC;
                        Addr_State = rel;
                        Jump_Op = 1'b1;
                    end  
                    
        8'hB0:      begin
                        Op_State = BCS;
                        Addr_State = rel;
                        Jump_Op = 1'b1;
                    end    
                    
        8'hF0:      begin
                        Op_State = BEQ;
                        Addr_State = rel;
                        Jump_Op = 1'b1;
                    end  
                    
        8'h24:      begin
                        Op_State = BITT;
                        Addr_State = zpg;
                    end     
        8'h2C:      begin
                        Op_State = BITT;
                        Addr_State = abs;
                    end 
                    
        8'h30:      begin
                        Op_State = BMI;
                        Addr_State = rel;
                        Jump_Op = 1'b1;
                    end        
                    
        8'hD0:      begin
                        Op_State = BNE;
                        Addr_State = rel;
                        Jump_Op = 1'b1;
                    end   
                    
        8'h10:      begin
                        Op_State = BPL;
                        Addr_State = rel;
                        Jump_Op = 1'b1;
                    end      
                    
        8'h00:      begin
                        Op_State = BRK;
                        Addr_State = impl;
                        Jump_Op = 1'b1;
                    end      
                    
        8'h50:      begin
                        Op_State = BVC;
                        Addr_State = rel;
                        Jump_Op = 1'b1;
                    end    
                    
        8'h70:      begin
                        Op_State = BVS;
                        Addr_State = rel;
                        Jump_Op = 1'b1;
                    end     
                    
        8'h18:      begin
                        Op_State = CLC;
                        Addr_State = impl;
                    end              
                    
        8'hD8:      begin
                        Op_State = CLD;
                        Addr_State = impl;
                    end     
                    
        8'h58:      begin
                        Op_State = CLI;
                        Addr_State = impl;
                    end    
                   
        8'hB8:      begin
                        Op_State = CLV;
                        Addr_State = impl;
                    end 
                    
        8'hC9:      begin
                        Op_State = CMP;
                        Addr_State = imm;
                    end 
        8'hC5:      begin
                        Op_State = CMP;
                        Addr_State = zpg;
                    end 
        8'hD5:      begin
                        Op_State = CMP;
                        Addr_State = zpg_X;
                    end 
        8'hCD:      begin
                        Op_State = CMP;
                        Addr_State = abs;
                    end 
        8'hDD:      begin
                        Op_State = CMP;
                        Addr_State = abs_X;
                    end 
        8'hD9:      begin
                        Op_State = CMP;
                        Addr_State = abs_Y;
                    end 
        8'hC1:      begin
                        Op_State = CMP;
                        Addr_State = X_ind;
                    end 
        8'hD1:      begin
                        Op_State = CMP;
                        Addr_State = ind_Y;
                    end 
                    
        8'hE0:      begin
                        Op_State = CPX;
                        Addr_State = imm;
                    end 
        8'hE4:      begin
                        Op_State = CPX;
                        Addr_State = zpg;
                    end 
        8'hEC:      begin
                        Op_State = CPX;
                        Addr_State = abs;
                    end 
                    
        8'hC0:      begin
                        Op_State = CPY;
                        Addr_State = imm;
                    end 
        8'hC4:      begin
                        Op_State = CPY;
                        Addr_State = zpg;
                    end 
        8'hCC:      begin
                        Op_State = CPY;
                        Addr_State = abs;
                    end
                    
        8'hC6:      begin
                        Op_State = DEC;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end  
        8'hD6:      begin
                        Op_State = DEC;
                        Addr_State = zpg_X;
                        Write_Op = 1'b1;
                    end  
        8'hCE:      begin
                        Op_State = DEC;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end  
        8'hDE:      begin
                        Op_State = DEC;
                        Addr_State = abs_X;
                        Write_Op = 1'b1;
                    end  
                    
        8'hCA:      begin
                        Op_State = DEX;
                        Addr_State = impl;
                    end  
                    
        8'h88:      begin
                        Op_State = DEY;
                        Addr_State = impl;
                    end  
                    
        8'h49:      begin
                        Op_State = EOR;
                        Addr_State = imm;
                    end  
        8'h45:      begin
                        Op_State = EOR;
                        Addr_State = zpg;
                    end  
        8'h55:      begin
                        Op_State = EOR;
                        Addr_State = zpg_X;
                    end  
        8'h4D:      begin
                        Op_State = EOR;
                        Addr_State = abs;
                    end  
        8'h5D:      begin
                        Op_State = EOR;
                        Addr_State = abs_X;
                    end  
        8'h59:      begin
                        Op_State = EOR;
                        Addr_State = abs_Y;
                    end  
        8'h41:      begin
                        Op_State = EOR;
                        Addr_State = X_ind;
                    end  
        8'h51:      begin
                        Op_State = EOR;
                        Addr_State = ind_Y;
                    end  
                    
        8'hE6:      begin
                        Op_State = INC;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end  
        8'hF6:      begin
                        Op_State = INC;
                        Addr_State = zpg_X;
                        Write_Op = 1'b1;
                    end  
        8'hEE:      begin
                        Op_State = INC;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end  
        8'hFE:      begin
                        Op_State = INC;
                        Addr_State = abs_X;
                        Write_Op = 1'b1;
                    end  
                    
        8'hE8:      begin
                        Op_State = INX;
                        Addr_State = impl;
                    end  
                    
        8'hC8:      begin
                        Op_State = INY;
                        Addr_State = impl;
                    end  
                   
        8'h4C:      begin
                        Op_State = JMP;
                        Addr_State = abs;
                        Jump_Op = 1'b1;
                    end
        8'h6C:      begin
                        Op_State = JMP;
                        Addr_State = ind;
                        Jump_Op = 1'b1;
                    end  
                    
        8'h20:      begin
                        Op_State = JSR;
                        Addr_State = abs;
                        Jump_Op = 1'b1;
                    end        
                    
        8'hA9:      begin
                        Op_State = LDA;
                        Addr_State = imm;
                    end     
        8'hA5:      begin
                        Op_State = LDA;
                        Addr_State = zpg;
                    end       
        8'hB5:      begin
                        Op_State = LDA;
                        Addr_State = zpg_X;
                    end        
        8'hAD:      begin
                        Op_State = LDA;
                        Addr_State = abs;
                    end
        8'hBD:      begin
                        Op_State = LDA;
                        Addr_State = abs_X;
                    end    
        8'hB9:      begin
                        Op_State = LDA;
                        Addr_State = abs_Y;
                    end      
        8'hA1:      begin
                        Op_State = LDA;
                        Addr_State = X_ind;
                    end  
        8'hB1:      begin
                        Op_State = LDA;
                        Addr_State = ind_Y;
                    end   
                    
        8'hA2:      begin
                        Op_State = LDX;
                        Addr_State = imm;
                    end   
        8'hA6:      begin
                        Op_State = LDX;
                        Addr_State = zpg;
                    end  
        8'hB6:      begin
                        Op_State = LDX;
                        Addr_State = zpg_Y;
                    end    
        8'hAE:      begin
                        Op_State = LDX;
                        Addr_State = abs;
                    end   
        8'hBE:      begin
                        Op_State = LDX;
                        Addr_State = abs_Y;
                    end   
                    
        8'hA0:      begin
                        Op_State = LDY;
                        Addr_State = imm;
                    end   
        8'hA4:      begin
                        Op_State = LDY;
                        Addr_State = zpg;
                    end
        8'hB4:      begin
                        Op_State = LDY;
                        Addr_State = zpg_X;
                    end   
        8'hAC:      begin
                        Op_State = LDY;
                        Addr_State = abs;
                    end   
        8'hBC:      begin
                        Op_State = LDY;
                        Addr_State = abs_X;
                    end 
                    
        8'h4A:      begin
                        Op_State = LSRA;
                        Addr_State = impl;
                    end     
        8'h46:      begin
                        Op_State = LSR;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end  
        8'h56:      begin
                        Op_State = LSR;
                        Addr_State = zpg_X;
                        Write_Op = 1'b1;
                    end     
        8'h4E:      begin
                        Op_State = LSR;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end        
        8'h5E:      begin
                        Op_State = LSR;
                        Addr_State = abs_X;
                        Write_Op = 1'b1;
                    end     
                                         
        8'hEA:      begin
                        Op_State = NOP;
                        Addr_State = impl;
                    end
                    
        8'h09:      begin
                        Op_State = ORA;
                        Addr_State = imm;
                    end
        8'h05:      begin
                        Op_State = ORA;
                        Addr_State = zpg;
                    end
        8'h15:      begin
                        Op_State = ORA;
                        Addr_State = zpg_X;
                    end
        8'h0D:      begin
                        Op_State = ORA;
                        Addr_State = abs;
                    end
        8'h1D:      begin
                        Op_State = ORA;
                        Addr_State = abs_X;
                    end
        8'h19:      begin
                        Op_State = ORA;
                        Addr_State = abs_Y;
                    end
        8'h01:      begin
                        Op_State = ORA;
                        Addr_State = X_ind;
                    end
        8'h11:      begin
                        Op_State = ORA;
                        Addr_State = ind_Y;
                    end
                    
        8'h48:      begin
                        Op_State = PHA;
                        Addr_State = impl;
                        Write_Op = 1'b1;
                    end
                    
        8'h08:      begin
                        Op_State = PHP;
                        Addr_State = impl;
                        Write_Op = 1'b1;
                    end
                    
        8'h68:      begin
                        Op_State = PLA;
                        Addr_State = impl;
                        Write_Op = 1'b1;
                    end
                    
        8'h28:      begin
                        Op_State = PLP;
                        Addr_State = impl;
                        Write_Op = 1'b1;
                    end
                    
        8'h2A:      begin
                        Op_State = ROLA;
                        Addr_State = impl;
                    end
        8'h26:      begin
                        Op_State = ROL;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end
        8'h36:      begin
                        Op_State = ROL;
                        Addr_State = zpg_X;
                        Write_Op = 1'b1;
                    end
        8'h2E:      begin
                        Op_State = ROL;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end
        8'h3E:      begin
                        Op_State = ROL;
                        Addr_State = abs_X;
                        Write_Op = 1'b1;
                    end
                    
        8'h6A:      begin
                        Op_State = RORA;
                        Addr_State = impl;
                    end
        8'h66:      begin
                        Op_State = ROR;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end
        8'h76:      begin
                        Op_State = ROR;
                        Addr_State = zpg_X;
                        Write_Op = 1'b1;
                    end
        8'h6E:      begin
                        Op_State = ROR;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end
        8'h7E:      begin
                        Op_State = ROR;
                        Addr_State = abs_X;
                        Write_Op = 1'b1;
                    end
                    
        8'h40:      begin
                        Op_State = RTI;
                        Addr_State = impl;
                        Jump_Op = 1'b1;
                    end
                    
        8'h60:      begin
                        Op_State = RTS;
                        Addr_State = impl;
                        Jump_Op = 1'b1;
                    end
                    
        8'hE9:      begin
                        Op_State = SBC;
                        Addr_State = imm;
                    end
        8'hE5:      begin
                        Op_State = SBC;
                        Addr_State = zpg;
                    end
        8'hF5:      begin
                        Op_State = SBC;
                        Addr_State = zpg_X;
                    end
        8'hED:      begin
                        Op_State = SBC;
                        Addr_State = abs;
                    end
        8'hFD:      begin
                        Op_State = SBC;
                        Addr_State = abs_X;
                    end
        8'hF9:      begin
                        Op_State = SBC;
                        Addr_State = abs_Y;
                    end
        8'hE1:      begin
                        Op_State = SBC;
                        Addr_State = X_ind;
                    end
        8'hF1:      begin
                        Op_State = SBC;
                        Addr_State = ind_Y;
                    end
                    
        8'h38:      begin
                        Op_State = SEC;
                        Addr_State = impl;
                    end
                    
        8'hF8:      begin
                        Op_State = SED;
                        Addr_State = impl;
                    end
                    
        8'h78:      begin
                        Op_State = SEI;
                        Addr_State = impl;
                    end
                    
        8'h85:      begin
                        Op_State = STA;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end
        8'h95:      begin
                        Op_State = STA;
                        Addr_State = zpg_X;
                        Write_Op = 1'b1;
                    end
        8'h8D:      begin
                        Op_State = STA;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end
        8'h9D:      begin
                        Op_State = STA;
                        Addr_State = abs_X;
                        Write_Op = 1'b1;
                    end
        8'h99:      begin
                        Op_State = STA;
                        Addr_State = abs_Y;
                        Write_Op = 1'b1;
                    end
        8'h81:      begin
                        Op_State = STA;
                        Addr_State = X_ind;
                        Write_Op = 1'b1;
                    end
        8'h91:      begin
                        Op_State = STA;
                        Addr_State = ind_Y;
                        Write_Op = 1'b1;
                    end
                    
        8'h86:      begin
                        Op_State = STX;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end
        8'h96:      begin
                        Op_State = STX;
                        Addr_State = zpg_Y;
                        Write_Op = 1'b1;
                    end
        8'h8E:      begin
                        Op_State = STX;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end
                    
        8'h84:      begin
                        Op_State = STY;
                        Addr_State = zpg;
                        Write_Op = 1'b1;
                    end
        8'h94:      begin
                        Op_State = STY;
                        Addr_State = zpg_X;
                        Write_Op = 1'b1;
                    end
        8'h8C:      begin
                        Op_State = STY;
                        Addr_State = abs;
                        Write_Op = 1'b1;
                    end
                    
        8'hAA:      begin
                        Op_State = TAX;
                        Addr_State = impl;
                    end
                    
        8'hA8:      begin
                        Op_State = TAY;
                        Addr_State = impl;
                    end
                    
        8'hBA:      begin
                        Op_State = TSX;
                        Addr_State = impl;
                    end
                    
        8'h8A:      begin
                        Op_State = TXA;
                        Addr_State = impl;
                    end
                    
        8'h9A:      begin
                        Op_State = TXS;
                        Addr_State = impl;
                    end
                    
        8'h98:      begin
                        Op_State = TYA;
                        Addr_State = impl;
                    end
        
        default:    begin   // Unknown opcode provided, throw error and restart
                        Op_State = ERROR;
                        Addr_State = imm;
                    end
                    
    endcase
    
    // Reset state
    if (Reset_Seq > 5'd0) begin
        Op_State = RESET;
        Addr_State = NA;
        Jump_Op = 1'b1;
        if (Reset_Seq == 5'd1)
            Next_Cycle = 4'd1;
    end
    
    // IRQ state
    if (IRQ_Seq > 5'd1) begin
        Op_State = BRK;
        Addr_State = NA;
        Jump_Op = 1'b1;
    end
    
    // NMI state
    if (NMI_Seq > 5'd1) begin
        Op_State = NMIS;
        Addr_State = NA;
        Jump_Op = 1'b1;
    end
    
    unique case (Op_State)
    
        // Transfer Instructions
        LDA:        Op_Cycle_Count = 4'd1;
        LDX:        Op_Cycle_Count = 4'd1;
        LDY:        Op_Cycle_Count = 4'd1;
        STA:        Op_Cycle_Count = 4'd1;
        STX:        Op_Cycle_Count = 4'd1;
        STY:        Op_Cycle_Count = 4'd1;
        TAX:        Op_Cycle_Count = 4'd1;
        TAY:        Op_Cycle_Count = 4'd1;
        TSX:        Op_Cycle_Count = 4'd1;
        TXA:        Op_Cycle_Count = 4'd1;
        TXS:        Op_Cycle_Count = 4'd1;
        TYA:        Op_Cycle_Count = 4'd1;
        
        // Stack Instructions
        PHA:        Op_Cycle_Count = 4'd2;
        PHP:        Op_Cycle_Count = 4'd2;
        PLA:        Op_Cycle_Count = 4'd3;
        PLP:        Op_Cycle_Count = 4'd3;
        
        // Decrements and Increments
        DEC:        Op_Cycle_Count = 4'd3;
        DEX:        Op_Cycle_Count = 4'd1;
        DEY:        Op_Cycle_Count = 4'd1;
        INC:        Op_Cycle_Count = 4'd3;
        INX:        Op_Cycle_Count = 4'd1;
        INY:        Op_Cycle_Count = 4'd1;
        
        // Arithmetic Operations
        ADC:        Op_Cycle_Count = 4'd1;
        SBC:        Op_Cycle_Count = 4'd1;
        
        // Logical Operations
        ANDA:       Op_Cycle_Count = 4'd1;
        EOR:        Op_Cycle_Count = 4'd1;
        ORA:        Op_Cycle_Count = 4'd1;
        
        // Shift & Rotate Instructions
        ASLA:       Op_Cycle_Count = 4'd1;
        LSRA:       Op_Cycle_Count = 4'd1;
        ROLA:       Op_Cycle_Count = 4'd1;
        RORA:       Op_Cycle_Count = 4'd1;
        ASL:        Op_Cycle_Count = 4'd3;
        LSR:        Op_Cycle_Count = 4'd3;
        ROL:        Op_Cycle_Count = 4'd3;
        ROR:        Op_Cycle_Count = 4'd3;
        
        // Flag Instructions
        CLC:        Op_Cycle_Count = 4'd1;
        CLD:        Op_Cycle_Count = 4'd1;
        CLI:        Op_Cycle_Count = 4'd1;
        CLV:        Op_Cycle_Count = 4'd1;
        SEC:        Op_Cycle_Count = 4'd1;
        SED:        Op_Cycle_Count = 4'd1;
        SEI:        Op_Cycle_Count = 4'd1;
        
        // Comparisons
        CMP:        Op_Cycle_Count = 4'd1;
        CPX:        Op_Cycle_Count = 4'd1;
        CPY:        Op_Cycle_Count = 4'd1;
        
        // Conditional Branch Instructions
        BCC:        Op_Cycle_Count = 4'd0;
        BCS:        Op_Cycle_Count = 4'd0;
        BEQ:        Op_Cycle_Count = 4'd0;
        BMI:        Op_Cycle_Count = 4'd0;
        BNE:        Op_Cycle_Count = 4'd0;
        BPL:        Op_Cycle_Count = 4'd0;
        BVC:        Op_Cycle_Count = 4'd0;
        BVS:        Op_Cycle_Count = 4'd0;
        
        // Jumps & Subroutines
        JMP:        Op_Cycle_Count = 4'd0;
        JSR:        Op_Cycle_Count = 4'd3;
        RTS:        Op_Cycle_Count = 4'd5;
        
        // Interrupts
        BRK:        Op_Cycle_Count = 4'd6;
        RTI:        Op_Cycle_Count = 4'd5;
        
        // Other
        BITT:       Op_Cycle_Count = 4'd1;
        NOP:        Op_Cycle_Count = 4'd1;
        NMIS:       Op_Cycle_Count = 4'd6;
        FETCH:      Op_Cycle_Count = 4'd0;
        RESET:      Op_Cycle_Count = 4'd6;
        
        default:    Op_Cycle_Count = 4'd0;
        
    endcase
    
    unique case (Addr_State)
        abs:        Addr_Cycle_Count = 4'd2;    
        abs_X:      Addr_Cycle_Count = 4'd2;    
        abs_Y:      Addr_Cycle_Count = 4'd2;
        imm:        Addr_Cycle_Count = 4'd0;
        impl:       Addr_Cycle_Count = 4'd0;    
        ind:        Addr_Cycle_Count = 4'd4;
        X_ind:      Addr_Cycle_Count = 4'd4;
        ind_Y:      Addr_Cycle_Count = 4'd3;
        rel:        Addr_Cycle_Count = 4'd1;
        zpg:        Addr_Cycle_Count = 4'd1;
        zpg_X:      Addr_Cycle_Count = 4'd2;
        zpg_Y:      Addr_Cycle_Count = 4'd2;
        default:    Addr_Cycle_Count = 4'd0;
    endcase

end

always_comb begin
    Total_Cycle_Count = Op_Cycle_Count + Addr_Cycle_Count + Add_Cycle_Control + 4'd1;
    Curr_Op_Cycle = Curr_Cycle - (Addr_Cycle_Count + Add_Cycle_Control + 4'd1);
    Stop_Op = ( (Curr_Cycle == Total_Cycle_Count) && ~(Add_Cycle != 4'd0 && Add_Cycle_Control == 4'd0) );
    In_Interrupt = (Op_State == BRK) || (Op_State == NMIS);
end



// Interrupt Logic

// Phase Two

always @ (posedge Clk, posedge Reset) begin
    
    // Set defaults
    Reset_Halt = 1'b0;
    
    // Reset sequence
    if (Reset) begin
        Reset_Halt = 1'b1;
        Reset_Seq <= 5'd1;
    end
    else if (Reset_Seq > 5'd0) begin
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

end

// NMI Edge Detector

always_ff @ (posedge Clk) begin
    NMI_dly <= NMI;
end

assign NMI_pe = NMI & ~NMI_dly;

always @ (posedge Clk) begin
    
    // Set defaults
    IRQ_Start = 1'b0;
    
    if (Reset_Seq > 5'd0) begin
        NMI_Hijack <= 1'b0;
        NMI_Seq <= 5'd0;
        IRQ_Seq <= 5'd0;
    end
        
    if (IRQ_Seq > 5'd1) begin
        case (IRQ_Seq)
            5'd2:       IRQ_Seq <= 5'd3; 
            5'd3:       IRQ_Seq <= 5'd4; 
            5'd4:       IRQ_Seq <= 5'd5; 
            5'd5:       IRQ_Seq <= 5'd6; 
            5'd6:       IRQ_Seq <= 5'd7;
            5'd7:       IRQ_Seq <= 5'd8;
            default:    IRQ_Seq <= 5'd0;
        endcase 
    end
        
    if (NMI_Seq > 5'd1) begin
        case (NMI_Seq)
            5'd2:       NMI_Seq <= 5'd3; 
            5'd3:       NMI_Seq <= 5'd4; 
            5'd4:       NMI_Seq <= 5'd5; 
            5'd5:       NMI_Seq <= 5'd6; 
            5'd6:       NMI_Seq <= 5'd7;
            5'd7:       NMI_Seq <= 5'd8;
            default:    NMI_Seq <= 5'd0;
        endcase 
    end
    
    // Initiate interrupt sequences
    if (NMI_pe)
        NMI_Start <= 1'b1;
    
    // We don't want interrupts to happen after an interrupt
    if (In_Interrupt)
        ;   // Do nothing
    else if (NMI_Start) begin
        NMI_Start <= 1'b0;
        NMI_Seq <= 5'd1;
    end
    else if ( IRQ && (P_Reg_out[3] == 0 || Op_State == RTI) && NMI_Seq == 5'd0 ) begin
        IRQ_Start = 1'b1;
        IRQ_Seq <= 5'd1;
    end
    
    // Interrupt sequence
    if ( (NMI_Start || NMI_Seq == 5'd1) && Stop_Op ) begin
        NMI_Start <= 1'b0;
        NMI_Seq <= 5'd2;
    end
    else if ( (IRQ_Start || IRQ_Seq == 5'd1) && Stop_Op )
        IRQ_Seq <= 5'd2;
    
    // Hijacking
    
    // NMI
    if ( NMI && ( (IRQ_Seq > 4'd0 && IRQ_Seq < 5'd7) || (Op_State == BRK && Curr_Cycle < 4'd6) ) )
        NMI_Hijack <= 1'b1;
        
    // Reset Hijack
    if ( Reset_Seq == 5'd8 || IRQ_Seq == 5'd8 || NMI_Seq == 5'd8 || (Op_State == BRK && Stop_Op) )
        NMI_Hijack <= 1'b0;

end


endmodule
