module PipelineControl(
    input  StallReq,
    input  BranchTaken,

    output reg PC_WEn,
    output reg IF_ID_WEn,
    output reg ID_EX_Flush,
    output reg IF_ID_Flush
);

    // PC_WEn = 1
    // IF_ID_WEn = 1
    // ID_EX_Flush = 0
    // IF_ID_Flush = 0

    always @ (*) begin
    
        PC_WEn      = 1;
        IF_ID_WEn   = 1;
        IF_ID_Flush = 0;
        ID_EX_Flush = 0;
    
        if (StallReq) begin
            PC_WEn      = 0;
            IF_ID_WEn   = 0;
            ID_EX_Flush = 1;
        end
    
        else if (BranchTaken) begin
            IF_ID_Flush = 1;
            ID_EX_Flush = 1;
        end
    
    end


endmodule
