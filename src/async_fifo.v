module async_fifo # (
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 32
    )(
    input                   wr_clk, wr_en, wr_rst,
    input  [DATA_WIDTH-1:0] data_in,
    input                   rd_clk, rd_en, rd_rst,
    output                  full_flag, empty_flag,
    output [DATA_WIDTH-1:0] data_out
    );
    
    wire [$clog2(DEPTH):0] wr_addr;
    wire [$clog2(DEPTH):0] g_wr_addr;
    wire [$clog2(DEPTH):0] s_g_wr_addr;
    wire [$clog2(DEPTH):0] rd_addr;
    wire [$clog2(DEPTH):0] g_rd_addr;
    wire [$clog2(DEPTH):0] s_g_rd_addr;
    wire                   intr_full_flag;
    wire                   intr_empty_flag;
    
    ram #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) u_ram (
        .wr_clk   (wr_clk),
        .wr_en    (wr_en & (~intr_full_flag)),
        .wr_addr  (wr_addr[$clog2(DEPTH)-1:0]),
        .data_in  (data_in),
        .rd_clk   (rd_clk),
        .rd_en    (rd_en & (~intr_empty_flag)),
        .rd_addr  (rd_addr[$clog2(DEPTH)-1:0]),
        .data_out (data_out)
    );
    
    ptr_handler #(
        .ADDR_WIDTH ($clog2(DEPTH))
    ) wr_ptr_handler (
        .clk        (wr_clk),
        .rst        (wr_rst),
        .en         (wr_en & (~intr_full_flag)),
        .in_g_ptr   (s_g_rd_addr),
        .b_ptr      (wr_addr),
        .g_ptr      (g_wr_addr),
        .full_flag  (intr_full_flag),
        .empty_flag ()
    );
    
    ptr_handler #(
        .ADDR_WIDTH ($clog2(DEPTH))
    ) rd_ptr_handler (
        .clk        (rd_clk),
        .rst        (rd_rst),
        .en         (rd_en & (~intr_empty_flag)),
        .in_g_ptr   (s_g_wr_addr),
        .b_ptr      (rd_addr),
        .g_ptr      (g_rd_addr),
        .full_flag  (),
        .empty_flag (intr_empty_flag)
    );
    
    two_flop #(
        .DATA_WIDTH ($clog2(DEPTH)+1)
    ) wr_two_flop (
        .clk      (wr_clk),
        .rst      (wr_rst),
        .data_in  (g_rd_addr),
        .data_out (s_g_rd_addr)
    );
    
    two_flop #(
        .DATA_WIDTH ($clog2(DEPTH)+1)
    ) rd_two_flop (
        .clk      (rd_clk),
        .rst      (rd_rst),
        .data_in  (g_wr_addr),
        .data_out (s_g_wr_addr)
    );
    
    assign full_flag  = intr_full_flag;
    assign empty_flag = intr_empty_flag;
    
endmodule