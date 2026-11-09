module WB_copy #(
    parameter DATA_WIDTH = 32
    )(
    input Clk, Rst,
    input      [DATA_WIDTH-1:0] wb_data_in,
    input      [6:0]            opcode_in,
    input      [4:0]            rd_in,
    output reg [DATA_WIDTH-1:0] wb_data_out,
    output reg [6:0]            opcode_out,
    output reg [4:0]            rd_out
    );
    
    always @ (posedge Clk) begin
        if (Rst) begin
            wb_data_out <= 0;
            opcode_out  <= 0;
            rd_out      <= 0;
           end
        else begin
            wb_data_out <= wb_data_in;
            opcode_out  <= opcode_in;
            rd_out      <= rd_in;
           end
        end
endmodule
    
    
    
