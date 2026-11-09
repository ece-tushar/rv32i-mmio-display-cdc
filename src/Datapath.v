// Current limitations:
// No exception or trap handling.
// loads of full flag stall the pipeline. 

module DataPath #(
    parameter DATA_WIDTH=32,
    parameter BYTE_DEPTH = 1024,
    
    parameter BYTE = 2'b00,
    parameter HALF_WORD = 2'b01,
    parameter WORD = 2'b10
    )(
    input Clk, Rst, rd_clk, rd_rst,
    output [DATA_WIDTH-1:0] DataOut
    );
    
    localparam PC_WIDTH=$clog2(BYTE_DEPTH);
    localparam FUNC_WIDTH = 17;

    wire [PC_WIDTH-1:0]   PC_RAddr;  // Into IF_ID
    wire [PC_WIDTH-1:0]   PC_PCnext;
    wire [DATA_WIDTH-1:0] IM_Instr; // the entire instruction
    
    wire [PC_WIDTH-1:0]   ID_PC_RAddr;  // Out of IF_ID
    wire [DATA_WIDTH-1:0] ID_IM_Instr;
    wire [FUNC_WIDTH-1:0] ID_ControlKey;

    wire [PC_WIDTH-1:0]   EX_PC_RAddr; // Out of ID_EX 
    wire [DATA_WIDTH-1:0] EX_IM_Instr;
    wire [DATA_WIDTH-1:0] EX_RB_DataOut1;
    wire [DATA_WIDTH-1:0] EX_RB_DataOut2;
    wire [DATA_WIDTH-1:0] EX_IG_ImmOut;
    
    wire [PC_WIDTH-1:0]   MEM_PC_RAddr; // Out of EX_MEM 
    wire [DATA_WIDTH-1:0] MEM_IM_Instr;
    wire [DATA_WIDTH-1:0] MEM_ALU_DataOut;
    wire [DATA_WIDTH-1:0] MEM_RB_DataOut2;
    
    wire [PC_WIDTH-1:0]   WB_PC_RAddr; // Out of MEM_WB 
    wire [DATA_WIDTH-1:0] WB_SE_DataOut;
    wire [DATA_WIDTH-1:0] WB_ALU_DataOut;
    wire [DATA_WIDTH-1:0] WB_IM_Instr;




    wire [1:0] Fwd_EX_out_SelOprd1;
    wire [1:0] Fwd_EX_out_SelOprd2;
    wire [3:0] Ctrl_EX_out_ALUSelFunc;
    wire       Ctrl_EX_out_Mask;
    wire       Brch_EX_out_SelAdderPC;
    wire       Brch_EX_out_SelDataInPC;

    wire       Ctrl_MEM_out_DataMemWEn;
    wire [1:0] Ctrl_MEM_out_DataMemWDataType;
    wire [1:0] Ctrl_MEM_out_DataMemRDataType;
    wire       Ctrl_MEM_out_SignExtd;

    wire       Ctrl_WB_out_RegBankWEn;
    wire [1:0] Ctrl_WB_out_SelRegBankDataIn;

    wire [6:0] Ctrl_ID_out_ImmInstrType;




    wire IF_ID_Flush;
    wire ID_EX_Flush;
    wire EX_MEM_Flush;
    wire MEM_WB_Flush;
    
    wire StallReq;  // pipeline controller
    wire PC_WEn;
    wire IF_ID_WEn;
    
    wire BranchTaken;
    
    wire full_flag;
    wire fifo_wr_en;
    
    wire [1:0] StrFwd;
    
    wire [PC_WIDTH-1:0]   WB_PCPlus4;  
    
    wire [DATA_WIDTH-1:0] ALU_DataOut;
    wire [DATA_WIDTH-1:0] Mask_ALU_DataOut;

    wire [DATA_WIDTH-1:0] RB_DataOut1;
    wire [DATA_WIDTH-1:0] RB_DataOut2;

    wire [DATA_WIDTH-1:0] IG_ImmOut;

    wire [DATA_WIDTH-1:0] MUX_ALU_DataOut2;
    wire [DATA_WIDTH-1:0] MUX_ALU_DataOut1;
    
    wire [DATA_WIDTH-1:0] mmio_data_out;
    wire                  mmio_sel;
    
    wire [DATA_WIDTH-1:0] WB_copy_data;
    wire [6:0]            WB_copy_opcode;
    wire [4:0]            WB_copy_rd;

    wire [DATA_WIDTH-1:0] DM_DataIn;
    wire [DATA_WIDTH-1:0] DM_DataOut;

    wire [DATA_WIDTH-1:0] SE_DataOut;

    wire [DATA_WIDTH-1:0] MUX_RB_DataOut;
 
 
//----------PIPELINE CONTROLLER---------------
 
 PipelineControl PCtrl (
        .StallReq(StallReq),
        .BranchTaken(BranchTaken),
        
        .PC_WEn(PC_WEn),
        .IF_ID_WEn(IF_ID_WEn),
        .ID_EX_Flush(ID_EX_Flush),
        .IF_ID_Flush(IF_ID_Flush)
    );    
    
//============================================================
// I N S T R U C T I O N     F E T C H
//============================================================



PCBlock #(.PC_WIDTH(PC_WIDTH))
    PC (.SelAdderPC(Brch_EX_out_SelAdderPC),
        .SelDataInPC(Brch_EX_out_SelDataInPC),
        .Clk(Clk),
        .Rst(Rst),
        .PC_WEn(PC_WEn),
        .Immediate(EX_IG_ImmOut[PC_WIDTH-1:0]),
        .PCnext(PC_PCnext),
        .MainALUData(ALU_DataOut[PC_WIDTH-1:0]),
        .BranchPC(EX_PC_RAddr),
        .AddrOutPC(PC_RAddr));
    


ByteAdrRAM #(
    .DATA_WIDTH(DATA_WIDTH),
    .BYTE_DEPTH(BYTE_DEPTH),
    .BYTE(BYTE),
    .HALF_WORD(HALF_WORD),
    .WORD(WORD)
) IM (
    .DataIn(),
    .Clk(Clk),
    .WEn(0),
    .WDataType(),
    .RDataType(WORD),
    .WAddr(),
    .RAddr(PC_RAddr),
    .DataOut(IM_Instr)
);
     

pipe_IF_ID #(
    .PC_WIDTH(PC_WIDTH),
    .INSTR_WIDTH(DATA_WIDTH)
) IF_ID (
    .Clk(Clk),
    .Rst(Rst),
    .Flush(IF_ID_Flush),
    .WEn(IF_ID_WEn),

    .PC_in(PC_RAddr),
    .IM_in(IM_Instr),

    .PC_out(ID_PC_RAddr),
    .IM_out(ID_IM_Instr)
);

//============================================================
// I N S T R U C T I O N     D E C O D E
//============================================================
     
     ImmGen #(
    .DATA_WIDTH(DATA_WIDTH)
) IG (
    .ImmIn(ID_IM_Instr[31:7]),
    .ImmInstrType(Ctrl_ID_out_ImmInstrType),
    .ImmOut(IG_ImmOut)
);
 
     LoadHazardUnit LHU (
                     .EX_IM_Instr(EX_IM_Instr),
                     .ID_IM_Instr(ID_IM_Instr),
                     .StallReq(StallReq)
                 );
                 
     ControlUnit CUID (
                     .InstrCodes({
                         ID_IM_Instr[31:25],   // funct7
                         ID_IM_Instr[14:12],   // funct3
                         ID_IM_Instr[6:0]      // opcode
                     }),
                 
                     .ALUOutLSB(),
                     // ID
                     .ImmInstrType(Ctrl_ID_out_ImmInstrType),
                     // EX
                     .SelAdderPC(),
                     .SelDataInPC(),
                     .SelMuxALU(),
                     .SelMuxALU0(),
                     .ALUSelFunc(),
                     // MEM
                     .SignExtd(),
                     .DataMemWEn(),
                     .DataMemRDataType(),
                     .DataMemWDataType(),
                     // WB
                     .RegBankWEn(),
                     .SelRegBankDataIn()
                 );


RegBank32 #(
    .DATA_WIDTH(DATA_WIDTH)
) RB (
    .DataIn(MUX_RB_DataOut),
    .Clk(Clk),
    .Rst(Rst), 
    .WEn(Ctrl_WB_out_RegBankWEn),
    .RAddr1(ID_IM_Instr[19:15]),
    .RAddr2(ID_IM_Instr[24:20]),
    .WAddr(WB_IM_Instr[11:7]),
    .DataOut1(RB_DataOut1),
    .DataOut2(RB_DataOut2)
);
                

pipe_ID_EX #(
    .PC_WIDTH(PC_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .INSTR_WIDTH(DATA_WIDTH)
) ID_EX (
    .Clk(Clk),
    .Rst(Rst),
    .Flush(ID_EX_Flush),

    .PC_in(ID_PC_RAddr),
    .Rs1_in(RB_DataOut1),
    .Rs2_in(RB_DataOut2),
    .Imm_in(IG_ImmOut),
    .IM_in(ID_IM_Instr),

    .PC_out(EX_PC_RAddr),
    .Rs1_out(EX_RB_DataOut1),
    .Rs2_out(EX_RB_DataOut2),
    .Imm_out(EX_IG_ImmOut),
    .IM_out(EX_IM_Instr)
);


//==================================================
// E X E C U T E 
//==================================================

        BranchController BC (
                .EX_IM_Instr(EX_IM_Instr),
                .ALU_LSB(ALU_DataOut[0]),
                
                .SelAdderPC(Brch_EX_out_SelAdderPC),
                .SelDataInPC(Brch_EX_out_SelDataInPC),
                .BranchTaken(BranchTaken)
                );


   
       mux4to1 #(.DATA_WIDTH(32)) 
       MUX_ALU1 (.DataIn0(EX_RB_DataOut1),
               .DataIn1({{(DATA_WIDTH-PC_WIDTH){1'b0}},EX_PC_RAddr}),
               .DataIn2(MEM_ALU_DataOut),
               .DataIn3(MUX_RB_DataOut),
               .Sel(Fwd_EX_out_SelOprd1),
               .DataOut(MUX_ALU_DataOut1));

       mux4to1 #(.DATA_WIDTH(32)) 
       MUX_ALU2 (.DataIn0(EX_RB_DataOut2),
               .DataIn1(EX_IG_ImmOut),
               .DataIn2(MEM_ALU_DataOut),
               .DataIn3(MUX_RB_DataOut),
               .Sel(Fwd_EX_out_SelOprd2),
               .DataOut(MUX_ALU_DataOut2));                      

    

     ALU ALU_UUT (.DataIn1(MUX_ALU_DataOut1),
                  .DataIn2(MUX_ALU_DataOut2),
                  .SelFunc(Ctrl_EX_out_ALUSelFunc),
                  .DataOut(Mask_ALU_DataOut));
     
    Masker #(
    .DATA_WIDTH(DATA_WIDTH)
) MSK (
    .ALUDataIn(Mask_ALU_DataOut),
    .Mask(Ctrl_EX_out_Mask),
    .ALUDataOut(ALU_DataOut)
);
                  
     ControlUnit CUEX (
                        .InstrCodes({
                            EX_IM_Instr[31:25],   // funct7
                            EX_IM_Instr[14:12],   // funct3
                            EX_IM_Instr[6:0]      // opcode
                                  }),
                              
                        .ALUOutLSB(),
                        // ID
                        .ImmInstrType(),
                        // EX
                        .Mask(Ctrl_EX_out_Mask),
                        .SelAdderPC(),
                        .SelDataInPC(),
                        .SelMuxALU(),
                        .SelMuxALU0(),
                        .ALUSelFunc(Ctrl_EX_out_ALUSelFunc),
                        // MEM
                        .SignExtd(),
                        .DataMemWEn(),
                        .DataMemRDataType(),
                        .DataMemWDataType(),
                        // WB
                        .RegBankWEn(),
                        .SelRegBankDataIn()
                              );
                              
            ForwardingUnit FU (
                         .EX_IM_Instr (EX_IM_Instr),
                         .MEM_IM_Instr(MEM_IM_Instr),
                         .WB_IM_Instr (WB_IM_Instr),
                              
                         .SelOprd1(Fwd_EX_out_SelOprd1),
                         .SelOprd2(Fwd_EX_out_SelOprd2)
                              );

pipe_EX_MEM #(
    .PC_WIDTH(PC_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .INSTR_WIDTH(DATA_WIDTH)
) EX_MEM (
    .Clk(Clk),
    .Rst(Rst),
    .Flush(1'b0),

    .PC_in(EX_PC_RAddr),
    .Rs2_in(EX_RB_DataOut2),
    .ALU_in(ALU_DataOut),
    .IM_in(EX_IM_Instr),

    .PC_out(MEM_PC_RAddr),
    .Rs2_out(MEM_RB_DataOut2),
    .ALU_out(MEM_ALU_DataOut),
    .IM_out(MEM_IM_Instr)
);
    
//==================================================
// M E M O R Y    A C C E S S  
//==================================================      
StoreForwardUnit SFU (
               .MEM_IM_Instr(MEM_IM_Instr),
               .WB_IM_Instr(WB_IM_Instr),
               .WB_copy_opcode(WB_copy_opcode),
               .WB_copy_rd(WB_copy_rd),
               .StrFwd(StrFwd)
                         );
                         
//      mux2to1 # (.DATA_WIDTH(32)) 
//            MUX_DM (.DataIn0(MEM_RB_DataOut2),
//                    .DataIn1(MUX_RB_DataOut),
//                    .Sel(StrFwd),
//                    .DataOut(DM_DataIn));
                    
         mux4to1 #(.DATA_WIDTH(DATA_WIDTH)) 
            MUX_DM (.DataIn0(MEM_RB_DataOut2),
                     .DataIn1(MUX_RB_DataOut),
                     .DataIn2(WB_copy_data),
                     .DataIn3(),
                     .Sel(StrFwd),
                     .DataOut(DM_DataIn));      // this goes into DSS as well
                      
           


ByteAdrRAM #(
    .DATA_WIDTH(DATA_WIDTH),
    .BYTE_DEPTH(BYTE_DEPTH),
    .BYTE(BYTE),
    .HALF_WORD(HALF_WORD),
    .WORD(WORD)
) DM (
    .DataIn(DM_DataIn),
    .Clk(Clk),
    .WEn(Ctrl_MEM_out_DataMemWEn),
    .WDataType(Ctrl_MEM_out_DataMemWDataType),
    .RDataType(Ctrl_MEM_out_DataMemRDataType),
    .WAddr(MEM_ALU_DataOut[PC_WIDTH-1:0]),
    .RAddr(MEM_ALU_DataOut[PC_WIDTH-1:0]),
    .DataOut(DM_DataOut)
);


SignExtender #(
    .DATA_WIDTH(DATA_WIDTH),
    .BYTE(BYTE),
    .HALF_WORD(HALF_WORD),
    .WORD(WORD)
) SE (
    .DataIn(DM_DataOut),
    .DataType(Ctrl_MEM_out_DataMemRDataType),
    .SignExtd(Ctrl_MEM_out_SignExtd),
    .DataOut(SE_DataOut)
);

     ControlUnit #(.BYTE_DEPTH(BYTE_DEPTH),
                   .DATA_WIDTH(DATA_WIDTH)) 
                   CUMEM (
                     .InstrCodes({
                         MEM_IM_Instr[31:25],   // funct7
                         MEM_IM_Instr[14:12],   // funct3
                         MEM_IM_Instr[6:0]      // opcode
                     }),
                     .alu_data_out(MEM_ALU_DataOut),
                     .ALUOutLSB(),
                     // ID
                     .ImmInstrType(),
                     // EX
                     .SelAdderPC(),
                     .SelDataInPC(),
                     .SelMuxALU(),
                     .SelMuxALU0(),
                     .ALUSelFunc(),
                      // MEM
                     .fifo_wr_en(fifo_wr_en),
                     .mmio_sel(mmio_sel),
                     .SignExtd(Ctrl_MEM_out_SignExtd),
                     .DataMemWEn(Ctrl_MEM_out_DataMemWEn),
                     .DataMemRDataType(Ctrl_MEM_out_DataMemRDataType),
                     .DataMemWDataType(Ctrl_MEM_out_DataMemWDataType),
                     // WB
                     .RegBankWEn(),
                     .SelRegBankDataIn()
                 );
                 
//---------DISPLAY SUB-SYSTEM----------
display_sub_sys #(
    .DATA_WIDTH (32),
    .DEPTH      (32)
) u_display_sub_sys (
    .wr_clk    (Clk),
    .wr_en     (fifo_wr_en),      
    .wr_rst    (Rst),
    .rd_clk    (rd_clk),
    .rd_rst    (rd_rst),
    .data_in   (DM_DataIn),
    .full_flag (full_flag)
);
//----------------------------------------

    mux2to1 #(.DATA_WIDTH(DATA_WIDTH)) mmio_mux
             (.DataIn0(SE_DataOut),
             .DataIn1({{(DATA_WIDTH-1){1'b0}},full_flag}),
              .Sel(mmio_sel),
              .DataOut(mmio_data_out)
              );

pipe_MEM_WB #(
    .PC_WIDTH(PC_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .INSTR_WIDTH(DATA_WIDTH)
) MEM_WB (
    .Clk(Clk),
    .Rst(Rst),
    .Flush(1'b0),

    .PC_in(MEM_PC_RAddr),
    .ALU_in(MEM_ALU_DataOut),
    .DM_in(mmio_data_out),         // rename
    .IM_in(MEM_IM_Instr),

    .PC_out(WB_PC_RAddr),
    .ALU_out(WB_ALU_DataOut),
    .DM_out(WB_SE_DataOut),     // rename
    .IM_out(WB_IM_Instr)
);              
//==================================================
// W R I T E   B A C K
//==================================================

     ControlUnit CUWB (
                 .InstrCodes({
                    WB_IM_Instr[31:25],   // funct7
                    WB_IM_Instr[14:12],   // funct3
                    WB_IM_Instr[6:0]      // opcode
                  }),
                 
                 .ALUOutLSB(),
                 // ID
                 .ImmInstrType(),
                     // EX
                     .SelAdderPC(),
                     .SelDataInPC(),
                     .SelMuxALU(),
                     .SelMuxALU0(),
                     .ALUSelFunc(),
                      // MEM
                     .SignExtd(),
                     .DataMemWEn(),
                     .DataMemRDataType(),
                     .DataMemWDataType(),
                     // WB
                     .RegBankWEn(Ctrl_WB_out_RegBankWEn),
                     .SelRegBankDataIn(Ctrl_WB_out_SelRegBankDataIn)
                 );

    PCAdder #(.DATA_WIDTH(PC_WIDTH)) 
        WB_ADD4 (.DataIn0(WB_PC_RAddr),
                 .DataIn1(4),
                 .AddrOutPC(WB_PCPlus4)
                );
    
          
    mux4to1 #(.DATA_WIDTH(DATA_WIDTH)) 
            MUX_RB (.DataIn0(WB_ALU_DataOut),
                     .DataIn1(WB_SE_DataOut),
                     .DataIn2({{(DATA_WIDTH-PC_WIDTH){1'b0}},WB_PCPlus4}),
                     .DataIn3(EX_IG_ImmOut),
                     .Sel(Ctrl_WB_out_SelRegBankDataIn),
                     .DataOut(MUX_RB_DataOut));
    WB_copy #(
    .DATA_WIDTH (DATA_WIDTH)
) WB_copy_reg (
    .Clk(Clk),
    .Rst(Rst),
    .wb_data_in(MUX_RB_DataOut),
    .opcode_in(WB_IM_Instr[6:0]),
    .rd_in(WB_IM_Instr[11:7]),
    .wb_data_out(WB_copy_data),
    .opcode_out(WB_copy_opcode),
    .rd_out(WB_copy_rd));
                

    assign DataOut = MUX_RB_DataOut; // to generate RTL schematic
    
endmodule


