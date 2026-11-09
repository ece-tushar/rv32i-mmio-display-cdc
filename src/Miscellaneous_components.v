module mux2to1 #(
    parameter DATA_WIDTH = 8
    )(input [DATA_WIDTH-1:0] DataIn0,
      input [DATA_WIDTH-1:0] DataIn1,
      input Sel,
      output reg [DATA_WIDTH-1:0] DataOut
      );
      
      always @ (*)begin
      if (Sel)
        DataOut = DataIn1;
      else 
        DataOut = DataIn0;
      end
endmodule

module mux4to1 #(
    parameter DATA_WIDTH = 8
    )(input [DATA_WIDTH-1:0] DataIn0,
      input [DATA_WIDTH-1:0] DataIn1,
      input [DATA_WIDTH-1:0] DataIn2,
      input [DATA_WIDTH-1:0] DataIn3,
      input [1:0] Sel,
      output reg [DATA_WIDTH-1:0] DataOut
      );
      
      always @ (*)begin
        case(Sel)
            2'b00 :DataOut = DataIn0;
            2'b01 :DataOut = DataIn1;
            2'b10 :DataOut = DataIn2;
            2'b11 :DataOut = DataIn3;
        endcase
        end
endmodule