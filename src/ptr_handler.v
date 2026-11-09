module ptr_handler # (   
    parameter ADDR_WIDTH = 5
    )(
    input                     clk, rst, en,
    input      [ADDR_WIDTH:0] in_g_ptr,
    output reg [ADDR_WIDTH:0] b_ptr, g_ptr,
    output                    full_flag, empty_flag
    );
    
    wire [ADDR_WIDTH:0] in_b_ptr;
    wire [ADDR_WIDTH:0] b_ptr_next = b_ptr + en;
    
    
    
    always @ (posedge clk) begin
        if (rst) 
            b_ptr <= 0;
        else if (en)
            b_ptr <= b_ptr_next;
            g_ptr <= b_ptr_next ^ (b_ptr_next >> 1);   // done so that synchronisers only sample from a flop. 
    end
    
    assign in_b_ptr[ADDR_WIDTH] = in_g_ptr[ADDR_WIDTH];     // incoming gray to binary conversion
    
    genvar i;
    generate 
        for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1) begin : gray_to_bin
            assign in_b_ptr[i]  =  in_b_ptr[i+1] ^ in_g_ptr[i];
            end
    endgenerate
    
    assign full_flag = (in_b_ptr[ADDR_WIDTH] != b_ptr[ADDR_WIDTH]) & (in_b_ptr[ADDR_WIDTH-1:0] == b_ptr[ADDR_WIDTH-1:0]);
    assign empty_flag = (in_b_ptr[ADDR_WIDTH:0] == b_ptr[ADDR_WIDTH:0]);
    
   
endmodule