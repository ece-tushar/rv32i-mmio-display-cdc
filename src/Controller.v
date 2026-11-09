module ControlUnit #(
    parameter FUNC_WIDTH = 17, 
    parameter DATA_WIDTH = 32,
    parameter BYTE_DEPTH = 1024
)(
    // funct7[16:10] | funct3[9:7] | opcode[6:0]
    input [FUNC_WIDTH-1:0] InstrCodes,
    input [DATA_WIDTH-1:0] alu_data_out,               
    input                  ALUOutLSB,

    // Outputs to Datapath
    output reg [6:0] ImmInstrType,

    output reg Mask, SelAdderPC, SelDataInPC, RegBankWEn,
               SelMuxALU, SelMuxALU0, SignExtd, DataMemWEn,
               fifo_wr_en,mmio_sel,

    output reg [1:0] DataMemWDataType,
    output reg [1:0] SelRegBankDataIn,
    output reg [1:0] DataMemRDataType,

    output reg [3:0] ALUSelFunc
);
    // ALU Parameters
    localparam PASSB = 4'b1110;
    localparam ADD = 4'b0000, SUB = 4'b0001;     // Arithmetic
    localparam XOR = 4'b0010, OR = 4'b0011, AND = 4'b0100;  // Logical
    localparam SLL = 4'b0101, SRL = 4'b0110, SRA = 4'b0111; // Shifts
    localparam S_LT = 4'b1000, U_LT = 4'b1001;   // Signed/Unsigned Less than
    localparam B_EQ = 4'b1010, B_NEQ = 4'b1011,  B_GEQU = 4'b1100, B_GEQ = 4'b1101;  // Boolean == | != | >=

    //Data Length parameters
    localparam BYTE = 2'b00;
    localparam HALF_WORD = 2'b01;
    localparam WORD = 2'b10;

    // OPCODE parameters
    localparam [6:0]
             Rtype      = 7'b0110011,
             R_Itype    = 7'b0010011,
             Load_Itype = 7'b0000011,
             Stype      = 7'b0100011,
             Btype      = 7'b1100011,
             LUI        = 7'b0110111,
             AUIPC      = 7'b0010111,
             JAL_Jtype  = 7'b1101111,
             JALR_Itype = 7'b1100111,
             Envi_Itype = 7'b1110011;

    localparam [6:0]
             SUB_SRA = 7'b0100000,    //funct7 parameters R type

             R_I_SRL = 7'b0000000,  // funct7 parameters for R_I type
             R_I_SRA = 7'b0100000,

             ZERO = 7'b0;

    // funct 3 code below R-type and R_I type   //These are for Load_Itype      // These are for Stype
    localparam [2:0]
             F3_ADD_SUB = 3'b000,               F3_LB  = 3'b000,                F3_SB  = 3'b000,
             F3_XOR     = 3'b100, /*logical*/   F3_LH  = 3'b001,                F3_SH  = 3'b001,
             F3_OR      = 3'b110,               F3_LW  = 3'b010,                F3_SW  = 3'b010,
             F3_AND     = 3'b111,               F3_LBU = 3'b100,
             F3_SLL     = 3'b001, /*shifts*/    F3_LHU = 3'b101,
             F3_SRL_SRA = 3'b101,
             F3_SLT     = 3'b010, // comparison
             F3_SLTU    = 3'b011,
             // funct 3 codes for branch
             F3_BEQ = 3'b000, F3_BNE = 3'b001, F3_BLT = 3'b100,
             F3_BGE = 3'b101, F3_BLTU = 3'b110, F3_BGEU = 3'b111;

    wire [6:0] funct7;
    wire [2:0] funct3;
    wire [6:0] opcode;

    // Decoded directly from InstrCodes, no separate InstrDecoder stage needed. 
    // since funct7,funct3 are only ever consumed below for the opcodes
    // Rtype, R_Itype where they are genuinely valid fields.
    assign {funct7,funct3,opcode} = InstrCodes;

    always @ (*) begin
        fifo_wr_en  = 1'b0;
        mmio_sel    = 1'b0;
        Mask        = 1'b0;
        SelAdderPC  = 1'b0;
        SelDataInPC = 1'b0;
        RegBankWEn  = 1'b0;
        SelMuxALU   = 1'b0;
        SelMuxALU0  = 1'b0;
        SignExtd    = 1'b0;
        SelRegBankDataIn = 2'b0;
        DataMemWEn = 1'b0;
        DataMemRDataType = 2'b0;
        DataMemWDataType = 2'b0;
        ALUSelFunc  = 4'b0000;
        ImmInstrType = 7'b0;
        case (opcode)
           Rtype : begin RegBankWEn = 1'b1;
                    case(funct7)
                          SUB_SRA : case (funct3)
                                        F3_SRL_SRA : ALUSelFunc = SRA;
                                        F3_ADD_SUB : ALUSelFunc = SUB;
                                        default    : ALUSelFunc = 4'b1111;
                                    endcase
                          ZERO    : case (funct3)
                                         F3_ADD_SUB : ALUSelFunc = ADD;
                                         F3_XOR     : ALUSelFunc = XOR;
                                         F3_OR      : ALUSelFunc = OR;
                                         F3_AND     : ALUSelFunc = AND;
                                         F3_SLL     : ALUSelFunc = SLL;
                                         F3_SRL_SRA : ALUSelFunc = SRL;
                                         F3_SLT     : ALUSelFunc = S_LT;
                                         F3_SLTU    : ALUSelFunc = U_LT;
                                        default    : ALUSelFunc = 4'b1111;
                                    endcase
                          default : ALUSelFunc = 4'b1111; // illegal funct7
                    endcase
                    end

           R_Itype : begin RegBankWEn = 1'b1; SelMuxALU = 1'b1; ImmInstrType = R_Itype;
                    case(funct3)
                       F3_ADD_SUB : ALUSelFunc = ADD;
                       F3_XOR     : ALUSelFunc = XOR;
                       F3_OR      : ALUSelFunc = OR;
                       F3_AND     : ALUSelFunc = AND;
                       F3_SLL     : ALUSelFunc = SLL;
                       F3_SRL_SRA : case (funct7)
                                        R_I_SRL : ALUSelFunc = SRL;
                                        R_I_SRA : ALUSelFunc = SRA;
                                        default : ALUSelFunc = 4'b1111;
                                    endcase
                       F3_SLT     : ALUSelFunc = S_LT;
                       F3_SLTU    : ALUSelFunc = U_LT;
                       default    : ALUSelFunc = 4'b1111;
                     endcase
                     end
        Load_Itype : begin RegBankWEn = 1'b1; SelMuxALU = 1'b1;
                     ImmInstrType = R_Itype; SelRegBankDataIn=2'b01;
                     ALUSelFunc = ADD;
                     if (alu_data_out == BYTE_DEPTH)  mmio_sel = 1'b1;
                    case(funct3)
                           F3_LB  :begin SignExtd = 1'b1 ; DataMemRDataType = BYTE; end
                           F3_LH  :begin SignExtd = 1'b1 ; DataMemRDataType = HALF_WORD; end
                           F3_LW  :begin SignExtd = 1'b1 ; DataMemRDataType = WORD; end
                           F3_LBU :begin SignExtd = 1'b0 ; DataMemRDataType = BYTE; end
                           F3_LHU :begin SignExtd = 1'b0 ; DataMemRDataType = HALF_WORD; end
                     endcase
                    end
        Stype : begin SelMuxALU = 1'b1; /*DataMemWEn = 1'b1;*/
                     ImmInstrType = Stype;
                     ALUSelFunc = ADD;
                    if (alu_data_out < BYTE_DEPTH)  DataMemWEn = 1'b1;
                    else if (alu_data_out == BYTE_DEPTH) fifo_wr_en = 1'b1; 
                    case(funct3)
                           F3_SB  :begin DataMemWDataType = BYTE; end
                           F3_SH  :begin DataMemWDataType = HALF_WORD; end
                           F3_SW  :begin DataMemWDataType = WORD; end
                     endcase
                    end
        Btype : begin ImmInstrType = Btype;
                    case(funct3)
                           F3_BEQ   :begin ALUSelFunc = B_EQ; end
                           F3_BNE   :begin ALUSelFunc = B_NEQ; end
                           F3_BLT   :begin ALUSelFunc = S_LT; end
                           F3_BGE   :begin ALUSelFunc = B_GEQ; end
                           F3_BLTU  :begin ALUSelFunc = U_LT; end
                           F3_BGEU   :begin ALUSelFunc = B_GEQU; end
                     endcase
                    SelAdderPC = (ALUOutLSB == 1)? 1'b1 : 1'b0;
                    end
        JAL_Jtype : begin RegBankWEn = 1'b1; ImmInstrType = JAL_Jtype;
                          SelRegBankDataIn = 2'b10; SelAdderPC = 1'b1;
                    end
        JALR_Itype : begin Mask = 1; RegBankWEn = 1'b1; ImmInstrType = R_Itype;    //JALR target alignment masking and exception handling have not been implemented.
                          SelRegBankDataIn = 2'b10; SelDataInPC = 1'b1;  //The processor assumes software generates aligned jump targets.
                          ALUSelFunc = ADD; SelMuxALU = 1'b1;
                    end
        LUI : begin ALUSelFunc = PASSB; 
                    RegBankWEn = 1'b1; ImmInstrType = LUI;
                          SelRegBankDataIn = 2'b00;
                    end
        AUIPC : begin ImmInstrType = LUI;  SelMuxALU0=1'b1;
                      RegBankWEn = 1'b1; SelRegBankDataIn = 2'b00;
                      ALUSelFunc = ADD; SelMuxALU = 1'b1;
                    end
       endcase
    end

endmodule