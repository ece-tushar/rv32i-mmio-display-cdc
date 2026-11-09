module LoadHazardUnit # (
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
    input [DATA_WIDTH-1:0] ID_IM_Instr,
    
    output reg StallReq
    );
    
    wire [6:0] n_opcode, n_1_opcode;
    wire [4:0] n_rs1, n_rs2;
    wire [4:0] n_1_rd;
    
    assign n_opcode = ID_IM_Instr[6:0];
    assign n_rs1 = ID_IM_Instr[19:15];
    assign n_rs2 = ID_IM_Instr[24:20];
    
    assign n_1_opcode = EX_IM_Instr[6:0];
    assign n_1_rd = EX_IM_Instr[11:7];

    always @(*) begin
    StallReq = 0;
    
        case (n_opcode)
    
        Rtype,Btype: begin
            if ((n_1_opcode == Load_Itype) &&
                (n_1_rd != 5'd0) &&
                ((n_1_rd == n_rs1) || (n_1_rd == n_rs2)))
                StallReq = 1;
        end
    
        R_Itype,Stype,JALR_Itype: begin
            if ((n_1_opcode == Load_Itype) &&
                (n_1_rd != 5'd0) &&
                (n_1_rd == n_rs1))
                StallReq = 1;
        end
    
        endcase
    end
    

endmodule