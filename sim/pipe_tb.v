`timescale 1ns/1ps

module dptb;

parameter N_GEN = 40;               // frames to print: gen 0 (seed) to gen N_GEN-1

reg Clk, Rst;
reg rd_clk, rd_rst;
wire [31:0] DataOut;

DataPath uut (.Clk(Clk), .Rst(Rst),
              .rd_clk(rd_clk), .rd_rst(rd_rst),
              .DataOut(DataOut));

// probing stalling issues.
wire [9:0]  PCOut    = uut.PC_RAddr;
wire        Stall    = uut.StallReq;
wire [31:0] Op1      = uut.MUX_ALU_DataOut1;
wire [31:0] Op2      = uut.MUX_ALU_DataOut2;
wire        PCWen    = uut.PC_WEn;
wire        flush_ID = uut.ID_EX_Flush;
wire [31:0] IF_ID    = uut.ID_IM_Instr;
wire [31:0] ID_EX    = uut.EX_IM_Instr;

initial begin
Clk    = 1;
rd_clk = 1;
Rst    = 1;
rd_rst = 1;
end

always #5   Clk    = ~Clk;          // CPU clock:     10 ns
always #6.5 rd_clk = ~rd_clk;       // display clock: 13 ns

task write_program;
reg [31:0] prog [0:255];
integer i;
begin
    for (i = 0; i < 256; i = i + 1) prog[i] = 32'h0000_0013;   // nop
    $readmemh("program.mem",prog);
    for (i = 0; i < 256; i = i + 1) begin
        uut.IM.RAM0.mem[i] = prog[i][7:0];
        uut.IM.RAM1.mem[i] = prog[i][15:8];
        uut.IM.RAM2.mem[i] = prog[i][23:16];
        uut.IM.RAM3.mem[i] = prog[i][31:24];
    end
end
endtask

task write_data;
reg [31:0] data [0:255];
integer i;
begin
    for (i = 0; i < 256; i = i + 1) data[i] = 32'b0;
    $readmemb("data.mem",data);                                 // 32-row Life seed
    for (i = 0; i < 256; i = i + 1) begin
        uut.DM.RAM0.mem[i] = data[i][7:0];
        uut.DM.RAM1.mem[i] = data[i][15:8];
        uut.DM.RAM2.mem[i] = data[i][23:16];
        uut.DM.RAM3.mem[i] = data[i][31:24];
    end
end
endtask

task reset_all;                     // hold both domains in reset, then release each on its own clock
begin
    Rst    = 1;
    rd_rst = 1;
    repeat (3) @(negedge Clk);
    repeat (3) @(negedge rd_clk);
    @(negedge rd_clk) rd_rst = 0;
    @(negedge Clk)    Rst    = 0;
end
endtask

task sample_display;                // wait until the display writes row 31, then print the frame
input integer gen;
integer r, c;
reg [31:0] w;
begin
    @(posedge rd_clk);
    while (!(uut.u_display_sub_sys.disp_wr_en && uut.u_display_sub_sys.disp_addr == 31))
        @(posedge rd_clk);
    @(negedge rd_clk);              // let row 31 land
    $display("---- gen %0d ----", gen);
    for (r = 0; r < 32; r = r + 1) begin
        w = uut.u_display_sub_sys.u_display_model.mem[r];
        for (c = 31; c >= 0; c = c - 1)
            $write("%s", w[c] ? "#" : ".");
        $write("\n");
    end
end
endtask

integer g;
initial begin
    write_data();
    write_program();      // LIGHTS!
    reset_all();          // CAMERA!!
                          // ACTION!!!
    for (g = 0; g < N_GEN; g = g + 1)
        sample_display(g);
    $finish;
    end
endmodule
