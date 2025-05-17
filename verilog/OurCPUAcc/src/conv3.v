module conv3(A, B, sel, WA0, WA1, WA2, WA3, WB0, WB1, WB2, WB3, acc);  
    // 2x2 convolution module
    input signed [12:0] A, B;
    input [1:0] sel;
    //weight register
    input signed [7:0] WA0, WA1, WA2, WA3;
    input signed [7:0] WB0, WB1, WB2, WB3;
    output  reg signed [21:0] acc;
    reg signed [7:0] WA, WB ;
    reg signed [19:0] mulA, mulB;
    always@(*) begin
        case (sel)
            2'b00: begin
                       WA =  WA0; 
                       WB =  WB0;
            end
            2'b01: begin
                       WA =  WA1; 
                       WB =  WB1;
            end
            2'b10: begin
                       WA =  WA2; 
                       WB =  WB2;
            end
            2'b11: begin
                       WA =  WA3;
                       WB =  WB3;
            end
        endcase
        mulA = A * WA;
        mulB = B * WB;
        acc = mulA + mulB;
    end
    
    
endmodule