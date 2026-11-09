module StoreForwardUnit # (parameter DATA_WIDTH = 32,

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
input      [DATA_WIDTH-1:0] MEM_IM_Instr,
input      [DATA_WIDTH-1:0] WB_IM_Instr,
input      [6:0]            WB_copy_opcode,
input      [4:0]            WB_copy_rd,
output reg [1:0]            StrFwd
);

wire [6:0] n_opcode, n_1_opcode,n_2_opcode;
wire [4:0] n_rs2;
wire [4:0] n_1_rd,n_2_rd;

assign n_opcode = MEM_IM_Instr[6:0];
assign n_rs2 = MEM_IM_Instr[24:20];

assign n_1_opcode = WB_IM_Instr[6:0];
assign n_2_opcode = WB_copy_opcode;
assign n_1_rd = WB_IM_Instr[11:7];
assign n_2_rd = WB_copy_rd;

always @(*) begin
StrFwd = 0;

    case (n_opcode)

    Stype : begin
        if (((n_1_opcode == Load_Itype) || 
             (n_1_opcode == Rtype) || (n_1_opcode == LUI) ||
             ( n_1_opcode == AUIPC) ||
            (n_1_opcode == R_Itype) || 
            (n_1_opcode == JALR_Itype) ||
            (n_1_opcode == JAL_Jtype)) &&
            (n_1_rd != 5'd0) &&
            (n_1_rd == n_rs2))
            StrFwd = 1; 
               
        else if (((n_2_opcode == Load_Itype) || 
             (n_2_opcode == Rtype) || (n_2_opcode == LUI) ||
             ( n_2_opcode == AUIPC) ||
            (n_2_opcode == R_Itype) || 
            (n_2_opcode == JALR_Itype) ||
            (n_2_opcode == JAL_Jtype)) &&
            (n_2_rd != 5'd0) &&
            (n_2_rd == n_rs2))
            StrFwd = 2;
    end

    endcase
end
endmodule
