module BranchController # (
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
    input [DATA_WIDTH-1:0] EX_IM_Instr,
    input ALU_LSB,
    
    output reg SelAdderPC,
    output reg SelDataInPC,
    output reg BranchTaken   // which is a FlushReq for pipeline controller. 
    );
    
    wire [6:0] opcode;
    
    assign opcode = EX_IM_Instr[6:0];
    
    always @(*) begin
 
        SelAdderPC = 0;
        SelDataInPC = 0;
        BranchTaken = 0;
        
        case (opcode)
    
            Btype:
            if (ALU_LSB) begin
                SelAdderPC  = 1;
                BranchTaken = 1;
            end
            JAL_Jtype:
             begin
                SelAdderPC  = 1;
                BranchTaken = 1;
            end
            JALR_Itype:
             begin
                SelDataInPC  = 1;
                BranchTaken = 1;
            end
 
    
        endcase
    end
endmodule