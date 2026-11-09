module ram #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 32
    )(
    input      wr_clk, wr_en,                   // write side ports
    input      [$clog2(DEPTH)-1:0] wr_addr,
    input      [DATA_WIDTH-1:0]    data_in,
    
    input      rd_clk,rd_en,                    // read side ports
    input      [$clog2(DEPTH)-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0]   data_out
    );
    
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    always @ (posedge wr_clk) begin             // writing mechanism
        if (wr_en) begin
            mem[wr_addr] <= data_in;
            end
    end
    
    always @ (posedge rd_clk) begin             // reading mechanism
        if (rd_en) begin
            data_out <= mem[rd_addr];
            end
    end
    
endmodule