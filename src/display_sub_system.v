module display_sub_sys #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 32
    )(
    input                   wr_clk, wr_en, wr_rst,
    input                   rd_clk, rd_rst,
    input  [DATA_WIDTH-1:0] data_in,
    output                  full_flag              
    );

    wire                     empty_flag;
    wire                     fifo_rd_en;
    wire [DATA_WIDTH-1:0]    fifo_data;
    wire                     disp_wr_en;
    wire [$clog2(DEPTH)-1:0] disp_addr;
    wire [DATA_WIDTH-1:0]    disp_data;

    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) u_async_fifo (
        .wr_clk     (wr_clk),
        .wr_en      (wr_en),
        .wr_rst     (wr_rst),
        .data_in    (data_in),
        .rd_clk     (rd_clk),
        .rd_en      (fifo_rd_en),
        .rd_rst     (rd_rst),
        .full_flag  (full_flag),
        .empty_flag (empty_flag),
        .data_out   (fifo_data)
    );

    disp_ctrl #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) u_disp_ctrl (
        .clk        (rd_clk),
        .rst        (rd_rst),
        .empty_flag (empty_flag),
        .data_in    (fifo_data),
        .wr_en      (disp_wr_en),
        .rd_en      (fifo_rd_en),
        .disp_addr  (disp_addr),
        .data_out   (disp_data)
    );

    display_model #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) u_display_model (
        .clk        (rd_clk),
        .wr_en      (disp_wr_en),
        .wr_addr    (disp_addr),
        .data_in    (disp_data)
    );

endmodule