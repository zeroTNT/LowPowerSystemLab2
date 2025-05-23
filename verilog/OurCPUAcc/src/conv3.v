module conv3(A, B, sel, WA0, WA1, WA2, WA3, WB0, WB1, WB2, WB3, mul_plus);
    input signed [12:0] A, B;
    input [1:0] sel;
    input signed [7:0] WA0, WA1, WA2, WA3;
    input signed [7:0] WB0, WB1, WB2, WB3;
    output signed [21:0] mul_plus;
    reg signed [7:0] WA, WB;
    wire signed [19:0] mulA, mulB;

    always@(*) begin
        case(sel)
            2'b00: begin
                        WA = WA0; 
                        WB = WB0;
                    end
            2'b01: begin
                        WA = WA1; 
                        WB = WB1;
                    end
            2'b10: begin
                        WA = WA2; 
                        WB = WB2;
                    end
            2'b11: begin
                        WA = WA3;
                        WB = WB3;
                    end   
            default: begin
                    WA = 8'd0;
                    WB = 8'd0;
            end 
        endcase
    end
    assign mulA = A * WA;
    assign mulB = B * WB;
    assign mul_plus = mulA + mulB;
endmodule