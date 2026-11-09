module Masker #(
    parameter DATA_WIDTH = 32
    )(input [DATA_WIDTH-1:0] ALUDataIn,
      input Mask,
      output [DATA_WIDTH-1:0] ALUDataOut
     );
     
     assign ALUDataOut = (Mask == 1)? {ALUDataIn[DATA_WIDTH-1:1],1'b0} : ALUDataIn;
     
endmodule