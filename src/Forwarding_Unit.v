module ForwardingUnit # (
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
    input [DATA_WIDTH-1:0] MEM_IM_Instr,
    input [DATA_WIDTH-1:0] WB_IM_Instr,

    output reg [1:0] SelOprd1,
    output reg [1:0] SelOprd2
    );

    wire [6:0] n_opcode, n_1_opcode, n_2_opcode;
    wire [4:0] n_rs1, n_rs2;
    wire [4:0] n_1_rd, n_2_rd;

    assign n_opcode   = EX_IM_Instr[6:0];
    assign n_1_opcode = MEM_IM_Instr[6:0];
    assign n_2_opcode = WB_IM_Instr[6:0];

    assign n_rs1 = EX_IM_Instr[19:15];
    assign n_rs2 = EX_IM_Instr[24:20];

    assign n_1_rd = MEM_IM_Instr[11:7];
    assign n_2_rd = WB_IM_Instr[11:7];

    always @ (*) begin

        // Defaults
        SelOprd1 = 2'b00;
        SelOprd2 = 2'b00;

        case (n_opcode)
            // Instructions using BOTH rs1 and rs2
            Rtype,Btype: begin
            // Operand 1 (rs1)
                if ((n_1_opcode == Rtype ||
                    n_1_opcode == R_Itype || n_1_opcode == LUI || n_1_opcode == AUIPC ||
                    n_1_opcode == Load_Itype ||
                    n_1_opcode == JALR_Itype ||
                    n_1_opcode == JAL_Jtype) &&
                    (n_1_rd != 5'd0) &&
                    (n_1_rd == n_rs1))
                        SelOprd1 = 2'b10;

                else if ((n_2_opcode == Rtype ||
                          n_2_opcode == R_Itype || n_2_opcode == LUI || n_2_opcode == AUIPC ||
                          n_2_opcode == Load_Itype ||
                          n_2_opcode == JALR_Itype ||
                          n_2_opcode == JAL_Jtype) &&
                         (n_2_rd != 5'd0) &&
                         (n_2_rd == n_rs1))
                            SelOprd1 = 2'b11;

            // Operand 2 (rs2)

                if ((n_1_opcode == Rtype ||
                    n_1_opcode == R_Itype || n_1_opcode == LUI || n_1_opcode == AUIPC ||
                    n_1_opcode == Load_Itype ||
                    n_1_opcode == JALR_Itype ||
                    n_1_opcode == JAL_Jtype) &&
                    (n_1_rd != 5'd0) &&
                    (n_1_rd == n_rs2))
                        SelOprd2 = 2'b10;

                else if ((n_2_opcode == Rtype ||
                    n_2_opcode == R_Itype || n_2_opcode == LUI || n_2_opcode == AUIPC ||
                    n_2_opcode == Load_Itype ||
                    n_2_opcode == JALR_Itype ||
                    n_2_opcode == JAL_Jtype) &&
                    (n_2_rd != 5'd0) &&
                    (n_2_rd == n_rs2))
                        SelOprd2 = 2'b11;

          end
    // Instructions using rs1 + Immediate

            R_Itype,
            Load_Itype,JALR_Itype,
            Stype: begin

                // Operand 2 is immediate
                SelOprd2 = 2'b01;

                // Operand 1 (rs1)

                if ((n_1_opcode == Rtype ||
                    n_1_opcode == R_Itype || n_1_opcode == LUI || n_1_opcode == AUIPC ||
                    n_1_opcode == Load_Itype ||
                    n_1_opcode == JALR_Itype ||
                    n_1_opcode == JAL_Jtype) &&
                    (n_1_rd != 5'd0) &&
                    (n_1_rd == n_rs1))
                        SelOprd1 = 2'b10;

                else if ((n_2_opcode == Rtype ||
                        n_2_opcode == R_Itype || n_2_opcode == LUI || n_2_opcode == AUIPC ||
                        n_2_opcode == Load_Itype ||
                        n_2_opcode == JALR_Itype ||
                        n_2_opcode == JAL_Jtype) &&
                        (n_2_rd != 5'd0) &&
                        (n_2_rd == n_rs1))
                       SelOprd1 = 2'b11;

            end
            
    /*new line*/    LUI : SelOprd2 = 2'b01;
                  AUIPC : begin SelOprd1 = 2'b01;
                          SelOprd2 = 2'b01; end
                

    default: begin
        SelOprd1 = 2'b00;
        SelOprd2 = 2'b00;
    end

    endcase

end

endmodule