module display_model #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 32
    )(
    input                          clk, wr_en,
    input [$clog2(DEPTH)-1:0]      wr_addr,
    input [DATA_WIDTH-1:0]         data_in
    );

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];  

    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= data_in;
    end

endmodule