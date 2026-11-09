module ImmGen #(
    parameter DATA_WIDTH = 32,
    
    parameter [6:0]
             Rtype      = 7'b0110011,
             R_Itype    = 7'b0010011,
             Load_Itype = 7'b0000011,
             Stype      = 7'b0100011,
             Btype      = 7'b1100011,
             LUI        = 7'b0110111,
             AUIPC      = 7'b0010111,
             JAL_Jtype  = 7'b1101111,
             JALR_Itype = 7'b1100111,
             Envi_Itype = 7'b1110011
    )(
    input [24:0] ImmIn, // [24:0]ImmIn
    input [6:0] ImmInstrType,
    output reg [DATA_WIDTH-1:0] ImmOut
    );
    
    always @ (*) begin
        ImmOut = 0;
        case (ImmInstrType)
            R_Itype     : ImmOut = {{20{ImmIn[24]}},ImmIn[24:13]};
            Stype       : ImmOut = {{20{ImmIn[24]}},ImmIn[24:18],ImmIn[4:0]};
            Btype       : ImmOut = {{19{ImmIn[24]}},ImmIn[24],ImmIn[0],ImmIn[23:18],ImmIn[4:1],1'b0};
            JAL_Jtype   : ImmOut = {{11{ImmIn[24]}},ImmIn[24],ImmIn[12:5],ImmIn[13],ImmIn[23:14],1'b0};
            LUI         : ImmOut = {ImmIn[24:5],12'b0};
        endcase
        end
endmodule