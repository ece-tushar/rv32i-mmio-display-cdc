module disp_ctrl # (
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 32
    )(
    input clk, rst, empty_flag,
    input [DATA_WIDTH-1:0] data_in,
    output wr_en, rd_en,
    output reg [$clog2(DEPTH)-1:0] disp_addr,
    output [DATA_WIDTH-1:0] data_out
    );
    
    reg intr_empty_flag;
    
    always @ (posedge clk)
        intr_empty_flag <= empty_flag;      // to compensate for sync read. 
    
    always @ (posedge clk) begin
        if (rst) 
            disp_addr <= {$clog2(DEPTH){1'b0}};
        else if (!intr_empty_flag) begin
            disp_addr <= disp_addr + 1;
        end
    end
    
    assign data_out = data_in;  
    assign wr_en    = !intr_empty_flag;
    assign rd_en    = 1'b1;
    
endmodule