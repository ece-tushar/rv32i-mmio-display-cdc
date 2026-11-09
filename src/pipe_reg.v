module pipe_IF_ID #(
    parameter PC_WIDTH = 8,
    parameter INSTR_WIDTH = 32
    )(
       input Clk, Rst, Flush, WEn,

       input [PC_WIDTH-1:0] PC_in,
       input [INSTR_WIDTH-1:0] IM_in,

       output [PC_WIDTH-1:0] PC_out,
       output [INSTR_WIDTH-1:0] IM_out
       );


   
   reg [PC_WIDTH-1:0] IF_ID_PC;
   reg [INSTR_WIDTH-1:0] IF_ID_IM;

   always @(posedge Clk) begin
        if (Rst) begin
            IF_ID_PC <= 0;
            IF_ID_IM <= 0;
        end
        else if (Flush) begin
            IF_ID_IM  <= 32'h0000_0013;   // Canonical NOP
            IF_ID_PC  <= 0;
        end
        else if (WEn) begin
            IF_ID_PC  <= PC_in;
            IF_ID_IM  <= IM_in;
        end
        // else - hold previous data
   end

   assign PC_out  = IF_ID_PC;
   assign IM_out  = IF_ID_IM;

endmodule




module pipe_ID_EX #(
    parameter PC_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter INSTR_WIDTH = 32
)(
    input Clk, Rst, Flush,

    input [PC_WIDTH-1:0] PC_in,
    input [DATA_WIDTH-1:0] Rs1_in,
    input [DATA_WIDTH-1:0] Rs2_in,
    input [DATA_WIDTH-1:0] Imm_in,
    input [INSTR_WIDTH-1:0] IM_in,

    output [PC_WIDTH-1:0] PC_out,
    output [DATA_WIDTH-1:0] Rs1_out,
    output [DATA_WIDTH-1:0] Rs2_out,
    output [DATA_WIDTH-1:0] Imm_out,
    output [INSTR_WIDTH-1:0] IM_out
);

reg [PC_WIDTH-1:0] PC;
reg [DATA_WIDTH-1:0] RS1;
reg [DATA_WIDTH-1:0] RS2;
reg [DATA_WIDTH-1:0] IMM;
reg [INSTR_WIDTH-1:0] IM;

always @(posedge Clk) begin
    if (Rst) begin
        PC  <= 0;
        RS1 <= 0;
        RS2 <= 0;
        IMM <= 0;
        IM  <= 0;
    end
    else if (Flush) begin
        PC  <= 0;
        RS1 <= 0;
        RS2 <= 0;
        IMM <= 0;
        IM  <= {{(INSTR_WIDTH-32){1'b0}},32'h0000_0013};
    end
    else begin
        PC  <= PC_in;
        RS1 <= Rs1_in;
        RS2 <= Rs2_in;
        IMM <= Imm_in;
        IM  <= IM_in;
    end
end

assign PC_out  = PC;
assign Rs1_out = RS1;
assign Rs2_out = RS2;
assign Imm_out = IMM;
assign IM_out  = IM;

endmodule


module pipe_EX_MEM #(
    parameter PC_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter INSTR_WIDTH = 32
)(
    input Clk, Rst, Flush,

    input [PC_WIDTH-1:0] PC_in,
    input [DATA_WIDTH-1:0] Rs2_in,
    input [DATA_WIDTH-1:0] ALU_in,
    input [INSTR_WIDTH-1:0] IM_in,

    output [PC_WIDTH-1:0] PC_out,
    output [DATA_WIDTH-1:0] Rs2_out,
    output [DATA_WIDTH-1:0] ALU_out,
    output [INSTR_WIDTH-1:0] IM_out
);

reg [PC_WIDTH-1:0] PC;
reg [DATA_WIDTH-1:0] RS2;
reg [DATA_WIDTH-1:0] ALU;
reg [INSTR_WIDTH-1:0] IM;

always @(posedge Clk) begin
    if (Rst) begin
        PC  <= 0;
        RS2 <= 0;
        ALU <= 0;
        IM  <= 0;
    end
    else if (Flush) begin
        PC  <= 0;
        RS2 <= 0;
        ALU <= 0;
        IM  <= 32'h0000_0013;
    end
    else begin
        PC  <= PC_in;
        RS2 <= Rs2_in;
        ALU <= ALU_in;
        IM  <= IM_in;
    end
end

assign PC_out  = PC;
assign Rs2_out = RS2;
assign ALU_out = ALU;
assign IM_out  = IM;

endmodule


module pipe_MEM_WB #(
    parameter PC_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter INSTR_WIDTH = 32
)(
    input Clk, Rst, Flush,

    input [PC_WIDTH-1:0] PC_in,
    input [DATA_WIDTH-1:0] ALU_in,
    input [DATA_WIDTH-1:0] DM_in,
    input [INSTR_WIDTH-1:0] IM_in,

    output [PC_WIDTH-1:0] PC_out,
    output [DATA_WIDTH-1:0] ALU_out,
    output [DATA_WIDTH-1:0] DM_out,
    output [INSTR_WIDTH-1:0] IM_out
);

reg [PC_WIDTH-1:0] PC;
reg [DATA_WIDTH-1:0] DM;
reg [DATA_WIDTH-1:0] ALU;
reg [INSTR_WIDTH-1:0] IM;

always @(posedge Clk) begin
    if (Rst) begin
        PC  <= 0;
        DM  <= 0;
        ALU <= 0;
        IM  <= 0;
    end
    else if (Flush) begin
        PC  <= 0;
        DM  <= 0;
        ALU <= 0;
        IM  <= 32'h0000_0013;
    end
    else begin
        PC  <= PC_in;
        DM  <= DM_in;
        ALU <= ALU_in;
        IM  <= IM_in;
    end
end

assign PC_out  = PC;
assign DM_out  = DM;
assign ALU_out = ALU;
assign IM_out  = IM;

endmodule