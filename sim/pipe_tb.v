//`timescale 1ns/1ps

//module dptb;

//reg Clk, Rst;
//wire [31:0] DataOut;

//DataPath uut (.Clk(Clk),.Rst(Rst),.DataOut(DataOut));

//// probing stalling issues. 
//wire [7:0] PCOut = uut.PC_RAddr;
//wire  Stall = uut.StallReq;
////wire  BT = uut.BranchTaken;
//wire  [31:0] Op1 = uut.MUX_ALU_DataOut1;
//wire  [31:0] Op2 = uut.MUX_ALU_DataOut2;
//wire  PCWen = uut.PC_WEn;
//wire  flush_ID = uut.ID_EX_Flush;
//wire  [31:0] IF_ID = uut.ID_IM_Instr;
//wire  [31:0] ID_EX = uut.EX_IM_Instr;



//initial begin
//Clk = 1;
//Rst = 1; 
//end

//always #5 Clk = ~Clk;

//task reset_PC_RB;
//begin
//    @(negedge Clk) begin
//        Rst = 1;
//        end
//    repeat (2) @(negedge Clk);
//end
//endtask

//task write_program;
//reg [31:0] prog [0:63];
//integer i;
//begin
//    $readmemh("program.mem",prog);
//    for (i = 0; i < 64; i = i + 1) begin
//        uut.IM.RAM0.mem[i] = prog[i][7:0];
//        uut.IM.RAM1.mem[i] = prog[i][15:8];
//        uut.IM.RAM2.mem[i] = prog[i][23:16];
//        uut.IM.RAM3.mem[i] = prog[i][31:24];
//    end
//end
//endtask

//task write_data;
//reg [31:0] data [0:63];
//integer i;
//begin
//    $readmemh("data.mem",data);
//    for (i = 0; i < 64; i = i + 1) begin
//        uut.DM.RAM0.mem[i] = data[i][7:0];
//        uut.DM.RAM1.mem[i] = data[i][15:8];
//        uut.DM.RAM2.mem[i] = data[i][23:16];
//        uut.DM.RAM3.mem[i] = data[i][31:24];
//    end
//end
//endtask

//task drop_reset_PC_RB;
//begin
//    @(negedge Clk) begin
//        Rst = 0;
//        end
//end
//endtask 



//task check_DM;
//reg [31:0] target [0:63];
//integer i;
//integer pass, fail;
//begin
//pass = 0;
//fail = 0;
//    $readmemh("target.mem",target);

//    for (i=0;i<64;i=i+1) begin
//        if ({uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]} == target[i]) begin
//                $display("PASS WA%0d = %h       |       Expected = %h",i,{uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]},target[i]);
//                pass = pass + 1;
//            end
//        else begin
//                $display("FAIL WA%0d = %h       |       Expected = %h",i,{uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]},target[i]);
//                fail = fail + 1;
//            end
//    end
//    $display("======================================================");
//    $display("PASS = %0d                  |       FAIL = %0d",pass,fail);
//    $display("======================================================");

//end
//endtask 


//initial begin
//    write_data();
//    write_program();      // LIGHTS!
//    reset_PC_RB();        // CAMERA!!
//    drop_reset_PC_RB();   // ACTION!!!
//    #500;
//    check_DM();
//    $finish;
//    end
//endmodule

//`timescale 1ns/1ps

//// Runs letters.s: the CPU pushes four 32x32 frames (A, B, C, D) from DM into the display FIFO,
//// and the display side prints each frame to the Tcl console as it completes.
//// Each printed frame is also compared against the DM copy it came from.
////
//// Files: program.mem (hex, $readmemh), data.mem (binary, $readmemb, 128 rows = 4 frames).

//module dptb;

//parameter N_FRAMES   = 4;
//parameter TIMEOUT_NS = 200000;

//reg Clk, Rst;
//reg rd_clk, rd_rst;
//wire [31:0] DataOut;

//DataPath uut (.Clk(Clk), .Rst(Rst),
//              .rd_clk(rd_clk), .rd_rst(rd_rst),
//              .DataOut(DataOut));

//// probing stalling issues.
//wire [9:0]  PCOut    = uut.PC_RAddr;
//wire        Stall    = uut.StallReq;
//wire [31:0] Op1      = uut.MUX_ALU_DataOut1;
//wire [31:0] Op2      = uut.MUX_ALU_DataOut2;
//wire        PCWen    = uut.PC_WEn;
//wire        flush_ID = uut.ID_EX_Flush;
//wire [31:0] IF_ID    = uut.ID_IM_Instr;
//wire [31:0] ID_EX    = uut.EX_IM_Instr;

//// MMIO / display probes
//wire        FifoPush = uut.fifo_wr_en;
//wire        FifoFull = uut.full_flag;
//wire        MmioSel  = uut.mmio_sel;

//// ---------------- clocks ----------------
//initial begin
//    Clk = 1;
//    Rst = 1;
//end
//always #5 Clk = ~Clk;                  // CPU: 10 ns

//initial begin
//    rd_clk = 1;
//    rd_rst = 1;
//end
//always #6.5 rd_clk = ~rd_clk;          // display: 13 ns, unrelated to Clk

//// ---------------- tasks ----------------
//task reset_PC_RB;
//begin
//    @(negedge Clk) begin
//        Rst = 1;
//        end
//    repeat (2) @(negedge Clk);
//end
//endtask

//task write_program;                    // zero-fill all 256 words first, so nothing fetched is X
//reg [31:0] prog [0:255];
//integer i;
//begin
//    for (i = 0; i < 256; i = i + 1) prog[i] = 32'h0000_0013;   // nop (addi x0,x0,0)
//    $readmemh("program.mem", prog);
//    for (i = 0; i < 256; i = i + 1) begin
//        uut.IM.RAM0.mem[i] = prog[i][7:0];
//        uut.IM.RAM1.mem[i] = prog[i][15:8];
//        uut.IM.RAM2.mem[i] = prog[i][23:16];
//        uut.IM.RAM3.mem[i] = prog[i][31:24];
//    end
//end
//endtask

//task write_data;                       // 4 frames x 32 rows, binary
//reg [31:0] data [0:255];
//integer i;
//begin
//    for (i = 0; i < 256; i = i + 1) data[i] = 32'b0;
//    $readmemb("data.mem", data);
//    for (i = 0; i < 256; i = i + 1) begin
//        uut.DM.RAM0.mem[i] = data[i][7:0];
//        uut.DM.RAM1.mem[i] = data[i][15:8];
//        uut.DM.RAM2.mem[i] = data[i][23:16];
//        uut.DM.RAM3.mem[i] = data[i][31:24];
//    end
//end
//endtask

//task drop_reset_PC_RB;
//begin
//    @(negedge Clk) begin
//        Rst = 0;
//        end
//end
//endtask

//task check_DM;                         // kept for other programs; not called for letters
//reg [31:0] target [0:63];
//integer i;
//integer pass, fail;
//begin
//pass = 0;
//fail = 0;
//    $readmemh("target.mem",target);

//    for (i=0;i<64;i=i+1) begin
//        if ({uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]} == target[i]) begin
//                $display("PASS WA%0d = %h       |       Expected = %h",i,{uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]},target[i]);
//                pass = pass + 1;
//            end
//        else begin
//                $display("FAIL WA%0d = %h       |       Expected = %h",i,{uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]},target[i]);
//                fail = fail + 1;
//            end
//    end
//    $display("======================================================");
//    $display("PASS = %0d                  |       FAIL = %0d",pass,fail);
//    $display("======================================================");

//end
//endtask

//// print the display model: bit 31 leftmost, '#' = 1, '.' = 0, 'X' = never written
//task print_display;
//integer r, c;
//reg [31:0] w;
//begin
//    for (r = 0; r < 32; r = r + 1) begin
//        w = uut.u_display_sub_sys.u_display_model.mem[r];
//        for (c = 31; c >= 0; c = c - 1) begin
//            if      (w[c] === 1'b1) $write("#");
//            else if (w[c] === 1'b0) $write(".");
//            else                    $write("X");
//        end
//        $write("\n");
//    end
//end
//endtask

//// compare the display against frame f in DM
//integer frame_errors = 0;
//task check_display(input integer f);
//integer r, bad;
//reg [31:0] dm_row;
//begin
//    bad = 0;
//    for (r = 0; r < 32; r = r + 1) begin
//        dm_row = {uut.DM.RAM3.mem[f*32+r], uut.DM.RAM2.mem[f*32+r],
//                  uut.DM.RAM1.mem[f*32+r], uut.DM.RAM0.mem[f*32+r]};
//        if (uut.u_display_sub_sys.u_display_model.mem[r] !== dm_row) bad = bad + 1;
//    end
//    if (bad == 0) $display("frame %0d matches DM", f);
//    else begin
//        $display("frame %0d: %0d rows differ from DM", f, bad);
//        frame_errors = frame_errors + 1;
//    end
//end
//endtask

//// ---------------- display monitor ----------------
//// A frame is complete when the display controller writes row 31.
//integer disp_frames = 0;
//always @(posedge rd_clk) begin
//    if (!rd_rst && uut.u_display_sub_sys.disp_wr_en &&
//        uut.u_display_sub_sys.disp_addr == 31) begin
//        @(negedge rd_clk);             // let row 31 land
//        $display("---- display frame %0d @%0t ----", disp_frames, $time);
//        print_display;
//        check_display(disp_frames);
//        disp_frames = disp_frames + 1;
//    end
//end

//// ---------------- main ----------------
//initial begin
//    write_data();
//    write_program();      // LIGHTS!
//    reset_PC_RB();        // CAMERA!!
//    drop_reset_PC_RB();   // ACTION!!!
//end

//initial begin                          // display side reset
//    repeat (5) @(negedge rd_clk);
//    rd_rst = 0;
//end

//initial begin
//    wait (disp_frames == N_FRAMES);
//    #100;
//    $display("======================================================");
//    $display("frames shown = %0d, frames wrong = %0d", disp_frames, frame_errors);
//    if (frame_errors == 0) $display("DISPLAY PASSED");
//    else                   $display("DISPLAY FAILED");
//    $display("======================================================");
//    $finish;
//end

//initial begin
//    #(TIMEOUT_NS);
//    $display("TIMEOUT: only %0d of %0d frames shown", disp_frames, N_FRAMES);
//    $finish;
//end

//endmodule



`timescale 1ns/1ps

// Runs life.s: the CPU computes Game of Life and pushes every generation through the display FIFO.
// The display side prints each frame to the Tcl console as it completes, and compares it against a
// reference Life computed here in the testbench from the same seed.
//
// Files: program.mem (hex, $readmemh), data.mem (binary, $readmemb, 32 rows = the seed).
// To change the starting pattern, just edit the 1s in data.mem.

//module dptb;

//parameter N_FRAMES   = 20;          // frame 0 = seed, frame k = generation k
//parameter TIMEOUT_NS = 3000000;

//reg Clk, Rst;
//reg rd_clk, rd_rst;
//wire [31:0] DataOut;

//DataPath uut (.Clk(Clk), .Rst(Rst),
//              .rd_clk(rd_clk), .rd_rst(rd_rst),
//              .DataOut(DataOut));

//// probing stalling issues.
//wire [9:0]  PCOut    = uut.PC_RAddr;
//wire        Stall    = uut.StallReq;
//wire [31:0] Op1      = uut.MUX_ALU_DataOut1;
//wire [31:0] Op2      = uut.MUX_ALU_DataOut2;
//wire        PCWen    = uut.PC_WEn;
//wire        flush_ID = uut.ID_EX_Flush;
//wire [31:0] IF_ID    = uut.ID_IM_Instr;
//wire [31:0] ID_EX    = uut.EX_IM_Instr;

//// MMIO / display probes
//wire        FifoPush = uut.fifo_wr_en;
//wire        FifoFull = uut.full_flag;
//wire        MmioSel  = uut.mmio_sel;

//// ---------------- clocks ----------------
//initial begin
//    Clk = 1;
//    Rst = 1;
//end
//always #5 Clk = ~Clk;                  // CPU: 10 ns

//initial begin
//    rd_clk = 1;
//    rd_rst = 1;
//end
//always #6.5 rd_clk = ~rd_clk;          // display: 13 ns, unrelated to Clk

//// ---------------- tasks ----------------
//task reset_PC_RB;
//begin
//    @(negedge Clk) begin
//        Rst = 1;
//        end
//    repeat (2) @(negedge Clk);
//end
//endtask

//task write_program;                    // zero-fill all 256 words first, so nothing fetched is X
//reg [31:0] prog [0:255];
//integer i;
//begin
//    for (i = 0; i < 256; i = i + 1) prog[i] = 32'h0000_0013;   // nop (addi x0,x0,0)
//    $readmemh("program.mem", prog);
//    for (i = 0; i < 256; i = i + 1) begin
//        uut.IM.RAM0.mem[i] = prog[i][7:0];
//        uut.IM.RAM1.mem[i] = prog[i][15:8];
//        uut.IM.RAM2.mem[i] = prog[i][23:16];
//        uut.IM.RAM3.mem[i] = prog[i][31:24];
//    end
//end
//endtask

//task write_data;                       // seed: 32 rows into grid A; grid B and the rest zeroed
//reg [31:0] data [0:255];
//integer i;
//begin
//    for (i = 0; i < 256; i = i + 1) data[i] = 32'b0;
//    $readmemb("data.mem", data);
//    for (i = 0; i < 256; i = i + 1) begin
//        uut.DM.RAM0.mem[i] = data[i][7:0];
//        uut.DM.RAM1.mem[i] = data[i][15:8];
//        uut.DM.RAM2.mem[i] = data[i][23:16];
//        uut.DM.RAM3.mem[i] = data[i][31:24];
//    end
//end
//endtask

//task drop_reset_PC_RB;
//begin
//    @(negedge Clk) begin
//        Rst = 0;
//        end
//end
//endtask

//task check_DM;                         // kept for other programs; not called for Life
//reg [31:0] target [0:63];
//integer i;
//integer pass, fail;
//begin
//pass = 0;
//fail = 0;
//    $readmemh("target.mem",target);

//    for (i=0;i<64;i=i+1) begin
//        if ({uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]} == target[i]) begin
//                $display("PASS WA%0d = %h       |       Expected = %h",i,{uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]},target[i]);
//                pass = pass + 1;
//            end
//        else begin
//                $display("FAIL WA%0d = %h       |       Expected = %h",i,{uut.DM.RAM3.mem[i],uut.DM.RAM2.mem[i],uut.DM.RAM1.mem[i],uut.DM.RAM0.mem[i]},target[i]);
//                fail = fail + 1;
//            end
//    end
//    $display("======================================================");
//    $display("PASS = %0d                  |       FAIL = %0d",pass,fail);
//    $display("======================================================");

//end
//endtask

//// print the display model: bit 31 leftmost, '#' = 1, '.' = 0, 'X' = never written
//task print_display;
//integer r, c;
//reg [31:0] w;
//begin
//    for (r = 0; r < 32; r = r + 1) begin
//        w = uut.u_display_sub_sys.u_display_model.mem[r];
//        for (c = 31; c >= 0; c = c - 1) begin
//            if      (w[c] === 1'b1) $write("#");
//            else if (w[c] === 1'b0) $write(".");
//            else                    $write("X");
//        end
//        $write("\n");
//    end
//end
//endtask

//// reference Life, computed in the testbench (wrap-around at all edges)
//reg [31:0] ref_grid [0:31];
//reg [31:0] ref_next [0:31];
//integer frame_errors = 0;

//task load_ref;
//reg [31:0] seed [0:255];
//integer i;
//begin
//    for (i = 0; i < 256; i = i + 1) seed[i] = 32'b0;
//    $readmemb("data.mem", seed);
//    for (i = 0; i < 32; i = i + 1) ref_grid[i] = seed[i];
//end
//endtask

//task step_ref;
//integer r, c, dr, dc, cnt;
//begin
//    for (r = 0; r < 32; r = r + 1) begin
//        ref_next[r] = 32'b0;
//        for (c = 0; c < 32; c = c + 1) begin
//            cnt = 0;
//            for (dr = -1; dr <= 1; dr = dr + 1)
//                for (dc = -1; dc <= 1; dc = dc + 1)
//                    if (dr != 0 || dc != 0)
//                        cnt = cnt + ref_grid[(r + dr + 32) % 32][(c + dc + 32) % 32];
//            ref_next[r][c] = (cnt == 3) || (cnt == 2 && ref_grid[r][c]);
//        end
//    end
//    for (r = 0; r < 32; r = r + 1) ref_grid[r] = ref_next[r];
//end
//endtask

//task check_display(input integer f);
//integer r, bad;
//begin
//    bad = 0;
//    for (r = 0; r < 32; r = r + 1)
//        if (uut.u_display_sub_sys.u_display_model.mem[r] !== ref_grid[r]) begin
//            bad = bad + 1;
//            if (bad <= 4)
//                $display("  row %0d: got %b, expected %b", r,
//                         uut.u_display_sub_sys.u_display_model.mem[r], ref_grid[r]);
//        end
//    if (bad == 0) $display("gen %0d matches reference", f);
//    else begin
//        $display("gen %0d: %0d rows differ from reference", f, bad);
//        frame_errors = frame_errors + 1;
//    end
//    step_ref;                           // advance the reference to the next generation
//end
//endtask

//// ---------------- display monitor ----------------
//// A frame is complete when the display controller writes row 31.
//integer disp_frames = 0;
//always @(posedge rd_clk) begin
//    if (!rd_rst && uut.u_display_sub_sys.disp_wr_en &&
//        uut.u_display_sub_sys.disp_addr == 31) begin
//        @(negedge rd_clk);             // let row 31 land
//        $display("---- gen %0d @%0t ----", disp_frames, $time);
//        print_display;
//        check_display(disp_frames);
//        disp_frames = disp_frames + 1;
//    end
//end

//// ---------------- main ----------------
//initial begin
//    load_ref();
//    write_data();
//    write_program();      // LIGHTS!
//    reset_PC_RB();        // CAMERA!!
//    drop_reset_PC_RB();   // ACTION!!!
//end

//initial begin                          // display side reset
//    repeat (5) @(negedge rd_clk);
//    rd_rst = 0;
//end

//initial begin
//    wait (disp_frames == N_FRAMES);
//    #100;
//    $display("======================================================");
//    $display("generations shown = %0d, wrong = %0d", disp_frames, frame_errors);
//    if (frame_errors == 0) $display("DISPLAY PASSED");
//    else                   $display("DISPLAY FAILED");
//    $display("======================================================");
//    $finish;
//end

//initial begin
//    #(TIMEOUT_NS);
//    $display("TIMEOUT: only %0d of %0d frames shown", disp_frames, N_FRAMES);
//    $finish;
//end

//endmodule


`timescale 1ns/1ps

module dptb;

parameter N_GEN = 20;               // frames to print: gen 0 (seed) to gen N_GEN-1

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