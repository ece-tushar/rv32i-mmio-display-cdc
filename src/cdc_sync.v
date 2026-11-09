module two_flop # (
    parameter DATA_WIDTH = 32
    )(
    input                       clk, rst,
    input      [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
    );
    
    reg [DATA_WIDTH-1:0] temp_data_in;
    
    always @ (posedge clk) begin
        if (rst) 
            temp_data_in <= {DATA_WIDTH{1'b0}};
        else
            temp_data_in <= data_in;
            
    end
    
    always @ (posedge clk) begin
        if (rst)
            data_out <= {DATA_WIDTH{1'b0}};
        else 
            data_out <= temp_data_in;
    end

endmodule