module RegBank32 #(
    parameter DATA_WIDTH = 32
    )(
    input  [DATA_WIDTH-1:0] DataIn,
    input  Clk, Rst, WEn,
    input  [4:0] RAddr1, RAddr2, WAddr,
    output [DATA_WIDTH-1:0] DataOut1, DataOut2
    );
    
    
    reg [DATA_WIDTH-1:0] mem [0:31];

    integer i;

    always @(posedge Clk) begin
        if (Rst) begin
            for (i = 0; i < 32; i = i + 1)
                mem[i] <= 32'b0;
        end
        else if (WEn && (WAddr != 5'd0)) begin
            mem[WAddr] <= DataIn;
        end
    end

//    initial begin
//        $readmemh("regdata.mem", mem);
//    end

    // Write-first read ports
    assign DataOut1 =
        (WEn && (WAddr != 5'd0) && (WAddr == RAddr1))
            ? DataIn
            : mem[RAddr1];

    assign DataOut2 =
        (WEn && (WAddr != 5'd0) && (WAddr == RAddr2))
            ? DataIn
            : mem[RAddr2];

endmodule     
