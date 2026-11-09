module ALU #(
    parameter DATA_WIDTH = 32,
    parameter FN_COUNT = 4, // 13 operations in ALU
                            // 4 bits can fit upto 16.  
    
    /*new line*/ parameter PASSB = 4'b1110,
    parameter ADD = 4'b0000, SUB = 4'b0001,     // Arithmetic 
    parameter XOR = 4'b0010, OR = 4'b0011, AND = 4'b0100,  // Logical
    parameter SLL = 4'b0101, SRL = 4'b0110, SRA = 4'b0111, // Shifts
    parameter S_LT = 4'b1000, U_LT = 4'b1001,   // Signed/Unsigned Less than
    parameter B_EQ = 4'b1010, B_NEQ = 4'b1011,  B_GEQU = 4'b1100,B_GEQ = 4'b1101 // Boolean == | != | >= 
                                          
    )( input [DATA_WIDTH-1:0] DataIn1, DataIn2,
       input [FN_COUNT-1:0] SelFunc,
       output reg [DATA_WIDTH-1:0] DataOut
       );
       
    always @ (*) begin
        DataOut = 0;
        case(SelFunc)  
            
            PASSB    :  DataOut = DataIn2;
            
            ADD      :  DataOut = DataIn1 + DataIn2;
            SUB      :  DataOut = DataIn1 - DataIn2;
            
            XOR      :  DataOut = DataIn1 ^ DataIn2;
            OR       :  DataOut = DataIn1 | DataIn2;
            AND      :  DataOut = DataIn1 & DataIn2;
            
            SLL      :  DataOut = DataIn1 << DataIn2[4:0];    // RV32I spec: shift amount is only lower 5 bits
            SRL      :  DataOut = DataIn1 >> DataIn2[4:0];
            SRA      :  DataOut = $signed(DataIn1) >>> DataIn2[4:0]; // $signed ensures MSB is copied. 
            
            S_LT     :  DataOut = {31'b0,$signed(DataIn1) < $signed(DataIn2)};
            U_LT     :  DataOut = {31'b0,DataIn1 < DataIn2};
            
            B_EQ     :  DataOut = {31'b0,(DataIn1 == DataIn2)}; // i think these o/p would act as control signals
            B_NEQ    :  DataOut = {31'b0,(DataIn1 != DataIn2)}; // in the PC = PC + imm mux select in PC Block
            B_GEQU   :  DataOut = {31'b0,(DataIn1 >= DataIn2)}; //
            B_GEQ    :  DataOut = {31'b0,($signed(DataIn1) >= $signed(DataIn2))}; //
            

        endcase
        end      
endmodule
