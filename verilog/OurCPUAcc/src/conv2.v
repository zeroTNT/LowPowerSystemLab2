module conv2(A1, A2, ,A3 ,A4, A5, A6, A7, A8, A9,
             W1, W2, W3, W4, W5, W6, W7, W8, W9,
             sel, and_control, acc);
    // 3x3 convolution module
    input signed [5:0] A1, A2, A3, A4, A5, A6, A7, A8, A9;
    input signed [7:0] W1, W2, W3, W4, W5, W6, W7, W8, W9;
    input [1:0] sel;
    //acc register control
    input  and_control;
    output signed [17:0] acc;

    wire signed [13:0] mul1, mul2, mul3, mul4, mul5, mul6, mul7, mul8, mul9;
    reg signed [5:0]  mulcand1, mulcand2, mulcand3, mulcand4, mulcand5, mulcand6, mulcand7, mulcand8, mulcand9;
    wire signed [14:0] add1, add2, add3, add4;
    wire signed [15:0] add5, add6;
    wire signed [16:0] add7;
    wire signed [5:0] and_out1, and_out2, and_out3, and_out4, and_out5, and_out6, and_out7, and_out8, and_out9;
    assign and_out1 = A1 & {6{and_control}};
    assign and_out2 = A2 & {6{and_control}};
    assign and_out3 = A3 & {6{and_control}};
    assign and_out4 = A4 & {6{and_control}};
    assign and_out5 = A5 & {6{and_control}};
    assign and_out6 = A6 & {6{and_control}};
    assign and_out7 = A7 & {6{and_control}};
    assign and_out8 = A8 & {6{and_control}};
    assign and_out9 = A9 & {6{and_control}};
    //input * weight multiplication
    always @(*) begin
        case (sel)
            2'b00: begin
                        mulcand1 = and_out1; 
                        mulcand4 = and_out4;
                        mulcand7 = and_out7;
                        mulcand2 = and_out2;
                        mulcand5 = and_out5;
                        mulcand8 = and_out8;
                        mulcand3 = and_out3;
                        mulcand6 = and_out6;
                        mulcand9 = and_out9;
            end
            2'b01: begin
                        mulcand1 = and_out2;
                        mulcand4 = and_out5;
                        mulcand7 = and_out8;
                        mulcand2 = and_out3;
                        mulcand5 = and_out6;
                        mulcand8 = and_out9;
                        mulcand3 = and_out1;
                        mulcand6 = and_out4;
                        mulcand9 = and_out7;
            end
            2'b10: begin
                        mulcand1 = and_out3;
                        mulcand4 = and_out6;
                        mulcand7 = and_out9;
                        mulcand2 = and_out1;
                        mulcand5 = and_out4;
                        mulcand8 = and_out7;
                        mulcand3 = and_out2;
                        mulcand6 = and_out5;
                        mulcand9 = and_out8;
            end
            2'b11: begin
                        mulcand1 = and_out1; 
                        mulcand2 = and_out4;
                        mulcand3 = and_out7;
                        mulcand4 = and_out2;
                        mulcand5 = and_out5;
                        mulcand6 = and_out8;
                        mulcand7 = and_out3;
                        mulcand8 = and_out6;
                        mulcand9 = and_out9;
            end
        endcase
    end
    assign mul1 = mulcand1 * W1;
    assign mul2 = mulcand2 * W2;
    assign mul3 = mulcand3 * W3;
    assign mul4 = mulcand4 * W4;
    assign mul5 = mulcand5 * W5;
    assign mul6 = mulcand6 * W6;
    assign mul7 = mulcand7 * W7;
    assign mul8 = mulcand8 * W8;
    assign mul9 = mulcand9 * W9;
    //addition
    assign add1 = mul1 + mul2;
    assign add2 = mul3 + mul4;
    assign add3 = mul5 + mul6;
    assign add4 = mul7 + mul8;
    assign add5 = add1 + add2;
    assign add6 = add3 + add4;
    assign add7 = add5 + add6;
    assign acc = add7 + mul9;

endmodule

/*module conv2(Ach1, Ach2, ,Ach3,
             Wch1, Wch2, Wch3,
             sel, CLK, CLR, WE, out, and_control);
    // 3x3x3(row x col x channel) convolution module
    input  [215:0] Ach1, Ach2, Ach3;
    input  [71:0] Wch1, Wch2, Wch3;
    input [1:0] sel;
    //acc register control
    input CLK, CLR, WE, and_control;
    output reg signed [10:0] out;
    //channel 1 weights
    wire signed [7:0] W1_1, W1_2, W1_3, W1_4, W1_5, W1_6, W1_7, W1_8, W1_9;
    //channel 2 weights
    wire signed [7:0] W2_1, W2_2, W2_3, W2_4, W2_5, W2_6, W2_7, W2_8, W2_9;
    //channel 3 weights
    wire signed [7:0] W3_1, W3_2, W3_3, W3_4, W3_5, W3_6, W3_7, W3_8, W3_9;
    //channel 1 input
    wire signed [7:0] A1_1, A1_2, A1_3, A1_4, A1_5, A1_6, A1_7, A1_8, A1_9;
    //channel 2 input
    wire signed [7:0] A2_1, A2_2, A2_3, A2_4, A2_5, A2_6, A2_7, A2_8, A2_9;
    //channel 3 input
    wire signed [7:0] A3_1, A3_2, A3_3, A3_4, A3_5, A3_6, A3_7, A3_8, A3_9;
    //multiplication between input and weight
    reg signed [13:0] mul1_1, mul1_2, mul1_3, mul1_4, mul1_5, mul1_6, mul1_7, mul1_8, mul1_9;
    reg signed [13:0] mul2_1, mul2_2, mul2_3, mul2_4, mul2_5, mul2_6, mul2_7, mul2_8, mul2_9;
    reg signed [13:0] mul3_1, mul3_2, mul3_3, mul3_4, mul3_5, mul3_6, mul3_7, mul3_8, mul3_9;

    wire signed [14:0] add1_1, add1_2, add1_3, add1_4,add1_5, add1_6, add1_7, add1_8, add1_9, add1_10, add1_11, add1_12, add1_13;
    wire signed [15:0] add5, add6;
    wire signed [16:0] add7;
    wire signed [17:0] acc;
    wire signed [10:0] scaled_acc;
    wire signed [5:0] and_out1, and_out2, and_out3, and_out4, and_out5, and_out6, and_out7, and_out8, and_out9;

    //and gate for input and and_control
    assign Ach1  = Ach1&{215{and_control}};
    assign Ach2  = Ach2&{215{and_control}};
    assign Ach3  = Ach3&{215{and_control}};
    
    //assign weights from channel 1
    assign W1_1 = Wch1[7:0]; assign W1_2 = Wch1[15:8]; assign W1_3 = Wch1[23:16];
    assign W1_4 = Wch1[31:24]; assign W1_5 = Wch1[39:32]; assign W1_6 = Wch1[47:40];
    assign W1_7 = Wch1[55:48]; assign W1_8 = Wch1[63:56]; assign W1_9 = Wch1[71:64];
    //assign weights from channel 2
    assign W2_1 = Wch2[7:0]; assign W2_2 = Wch2[15:8]; assign W2_3 = Wch2[23:16];
    assign W2_4 = Wch2[31:24]; assign W2_5 = Wch2[39:32]; assign W2_6 = Wch2[47:40];
    assign W2_7 = Wch2[55:48]; assign W2_8 = Wch2[63:56]; assign W2_9 = Wch2[71:64];
    //assign weights from channel 3
    assign W3_1 = Wch3[7:0]; assign W3_2 = Wch3[15:8]; assign W3_3 = Wch3[23:16];
    assign W3_4 = Wch3[31:24]; assign W3_5 = Wch3[39:32]; assign W3_6 = Wch3[47:40];
    assign W3_7 = Wch3[55:48]; assign W3_8 = Wch3[63:56]; assign W3_9 = Wch3[71:64];
    //assign input from channel 1
    assign A1_1 = Ach1[7:0]; assign A1_2 = Ach1[15:8]; assign A1_3 = Ach1[23:16];
    assign A1_4 = Ach1[31:24]; assign A1_5 = Ach1[39:32]; assign A1_6 = Ach1[47:40];
    assign A1_7 = Ach1[55:48]; assign A1_8 = Ach1[63:56]; assign A1_9 = Ach1[71:64];
    //assign input from channel 2
    assign A2_1 = Ach2[7:0]; assign A2_2 = Ach2[15:8]; assign A2_3 = Ach2[23:16];
    assign A2_4 = Ach2[31:24]; assign A2_5 = Ach2[39:32]; assign A2_6 = Ach2[47:40];
    assign A2_7 = Ach2[55:48]; assign A2_8 = Ach2[63:56]; assign A2_9 = Ach2[71:64];
    //assign input from channel 3
    assign A3_1 = Ach3[7:0]; assign A3_2 = Ach3[15:8]; assign A3_3 = Ach3[23:16];
    assign A3_4 = Ach3[31:24]; assign A3_5 = Ach3[39:32]; assign A3_6 = Ach3[47:40];
    assign A3_7 = Ach3[55:48]; assign A3_8 = Ach3[63:56]; assign A3_9 = Ach3[71:64];
     
    //multiplication between input and weight
    always @(*) begin
        case (sel)
            2'b00: begin
                        mul1_1 = A1_1 * W1_1;
                        mul1_2 = A1_4 * W1_4;
                        mul1_3 = A1_7 * W1_7;
                        mul1_4 = A1_2 * W1_2;
                        mul1_5 = A1_5 * W1_5;
                        mul1_6 = A1_8 * W1_8;
                        mul1_7 = A1_3 * W1_3;
                        mul1_8 = A1_6 * W1_6;
                        mul1_9 = A1_9 * W1_9;
                        mul2_1 = A2_1 * W2_1;
                        mul2_2 = A2_4 * W2_4;
                        mul2_3 = A2_7 * W2_7;
                        mul2_4 = A2_2 * W2_2;
                        mul2_5 = A2_5 * W2_5;
                        mul2_6 = A2_8 * W2_8;
                        mul2_7 = A2_3 * W2_3;
                        mul2_8 = A2_6 * W2_6;
                        mul2_9 = A2_9 * W2_9;
                        mul3_1 = A3_1 * W3_1;
                        mul3_2 = A3_4 * W3_4;
                        mul3_3 = A3_7 * W3_7;
                        mul3_4 = A3_2 * W3_2;
                        mul3_5 = A3_5 * W3_5;
                        mul3_6 = A3_8 * W3_8;
                        mul3_7 = A3_3 * W3_3;
                        mul3_8 = A3_6 * W3_6;
                        mul3_9 = A3_9 * W3_9;
            end
            2'b01: begin
                        mul1_1 = A1_2 * W1_1;
                        mul1_2 = A1_5 * W1_4;
                        mul1_3 = A1_8 * W1_7;
                        mul1_4 = A1_3 * W1_2;
                        mul1_5 = A1_6 * W1_5;
                        mul1_6 = A1_9 * W1_8;
                        mul1_7 = A1_1 * W1_3;
                        mul1_8 = A1_4 * W1_6;
                        mul1_9 = A1_7 * W1_9;
                        mul2_1 = A2_2 * W2_1;
                        mul2_2 = A2_5 * W2_4;
                        mul2_3 = A2_8 * W2_7;
                        mul2_4 = A2_3 * W2_2;
                        mul2_5 = A2_6 * W2_5;
                        mul2_6 = A2_9 * W2_8;
                        mul2_7 = A2_1 * W2_3;
                        mul2_8 = A2_4 * W2_6;
                        mul2_9 = A2_7 * W2_9;
                        mul3_1 = A3_2 * W3_1;
                        mul3_2 = A3_5 * W3_4;
                        mul3_3 = A3_8 * W3_7;
                        mul3_4 = A3_3 * W3_2;
                        mul3_5 = A3_6 * W3_5;
                        mul3_6 = A3_9 * W3_8;
                        mul3_7 = A3_1 * W3_3;
                        mul3_8 = A3_4 * W3_6;
                        mul3_9 = A3_7 * W3_9;
            end
            2'b10: begin
                        mul1_1 = A1_3 * W1_1;
                        mul1_2 = A1_6 * W1_4;
                        mul1_3 = A1_9 * W1_7;
                        mul1_4 = A1_1 * W1_2;
                        mul1_5 = A1_4 * W1_5;
                        mul1_6 = A1_7 * W1_8;
                        mul1_7 = A1_2 * W1_3;
                        mul1_8 = A1_5 * W1_6;
                        mul1_9 = A1_8 * W1_9;
                        mul2_1 = A2_3 * W2_1;
                        mul2_2 = A2_6 * W2_4;
                        mul2_3 = A2_9 * W2_7;
                        mul2_4 = A2_1 * W2_2;
                        mul2_5 = A2_4 * W2_5;
                        mul2_6 = A2_7 * W2_8;
                        mul2_7 = A2_2 * W2_3;
                        mul2_8 = A2_5 * W2_6;
                        mul2_9 = A2_8 * W2_9;
                        mul3_1 = A3_3 * W3_1;
                        mul3_2 = A3_6 * W3_4;
                        mul3_3 = A3_9 * W3_7;
                        mul3_4 = A3_1 * W3_2;
                        mul3_5 = A3_4 * W3_5;
                        mul3_6 = A3_7 * W3_8;
                        mul3_7 = A3_2 * W3_3;
                        mul3_8 = A3_5 * W3_6;
                        mul3_9 = A3_8 * W3_9;
            end
            default begin 
                    assign mul1_1 = 0; assign mul1_2 = 0; assign mul1_3 = 0;
                    assign mul1_4 = 0; assign mul1_5 = 0; assign mul1_6 = 0;
                    assign mul1_7 = 0; assign mul1_8 = 0; assign mul1_9 = 0;
                    assign mul2_1 = 0; assign mul2_2 = 0; assign mul2_3 = 0;
                    assign mul2_4 = 0; assign mul2_5 = 0; assign mul2_6 = 0;
                    assign mul2_7 = 0; assign mul2_8 = 0; assign mul2_9 = 0;
                    assign mul3_1 = 0; assign mul3_2 = 0; assign mul3_3 = 0;
                    assign mul3_4 = 0; assign mul3_5 = 0; assign mul3_6 = 0;
                    assign mul3_7 = 0; assign mul3_8 = 0; assign mul3_9 = 0;
            end
        endcase
    end
    assign 
    assign add1 = mul1 + mul2;
    assign add2 = mul3 + mul4;
    assign add3 = mul5 + mul6;
    assign add4 = mul7 + mul8;
    assign add5 = add1 + add2;
    assign add6 = add3 + add4;
    assign add7 = add5 + add6;
    assign acc = add7 + mul9;
    assign scaled_acc = acc>>>7; // shift right 7 bits to reduce the size of the output
    always @(posedge CLK) begin
        if (CLR) begin
            out <= 0;
        end else if (WE) begin
            out <= scaled_acc;
        end
    end

endmodule*/
