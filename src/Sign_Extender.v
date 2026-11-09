module SignExtender # (
    parameter DATA_WIDTH = 32,
    parameter BYTE = 2'b00,
    parameter HALF_WORD = 2'b01,
    parameter WORD = 2'b10
    )( input [DATA_WIDTH-1:0] DataIn,
       input [1:0] DataType,
       input SignExtd,
       output reg [DATA_WIDTH-1:0] DataOut
       );
     
     always @ (*) begin
        DataOut = 0;
        case (DataType)
            BYTE      : DataOut = SignExtd ? {{(DATA_WIDTH-8){DataIn[7]}},{DataIn[7:0]}}:
                                             {{(DATA_WIDTH-8){1'b0}},{DataIn[7:0]}};
            HALF_WORD : DataOut = SignExtd ? {{(DATA_WIDTH-16){DataIn[15]}}, DataIn[15:0]} :
                                             {{(DATA_WIDTH-16){1'b0}}, DataIn[15:0]};
            WORD      : DataOut = DataIn;
        endcase    
     end

endmodule