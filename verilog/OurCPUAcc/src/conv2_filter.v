module conv2_filter(clk_i, rst, WE, A1, A2 ,A3, W1, W2, W3, sel, and_control, acc_reset, counter,out);
input [53:0] A1, A2, A3;
input [71:0] W1, W2, W3;
input [3:0] counter; //0~8 代表 input * w1~w9
input [1:0] sel;
input clk_i, rst, WE, and_control, acc_reset;
output  signed [12:0] out;
wire signed [17:0] scaled_acc1, scaled_acc2, scaled_acc3;
reg signed [19:0] acc;
reg WE_d;
always@(posedge clk_i) begin
    WE_d <= WE;   
end
conv2 channel_1(.A1(A1[5:0]), .A2(A1[11:6]), .A3(A1[17:12]), .A4(A1[23:18]), .A5(A1[29:24]), .A6(A1[35:30]), .A7(A1[41:36]), .A8(A1[47:42]), .A9(A1[53:48]),
                .W1(W1[7:0]), .W2(W1[15:8]), .W3(W1[23:16]), .W4(W1[31:24]), .W5(W1[39:32]), .W6(W1[47:40]), .W7(W1[55:48]), .W8(W1[63:56]), .W9(W1[71:64]),
                .sel(sel), .and_control(and_control), .counter(counter),.clk_i(clk_i), .acc_rst(acc_reset), .WE(WE), .acc(scaled_acc1));

conv2 channel_2(.A1(A2[5:0]), .A2(A2[11:6]), .A3(A2[17:12]), .A4(A2[23:18]), .A5(A2[29:24]), .A6(A2[35:30]), .A7(A2[41:36]), .A8(A2[47:42]), .A9(A2[53:48]),
                .W1(W2[7:0]), .W2(W2[15:8]), .W3(W2[23:16]), .W4(W2[31:24]), .W5(W2[39:32]), .W6(W2[47:40]), .W7(W2[55:48]), .W8(W2[63:56]), .W9(W2[71:64]),
                .sel(sel), .and_control(and_control), .counter(counter),.clk_i(clk_i), .acc_rst(acc_reset), .WE(WE), .acc(scaled_acc2));

conv2 channel_3(.A1(A3[5:0]), .A2(A3[11:6]), .A3(A3[17:12]), .A4(A3[23:18]), .A5(A3[29:24]), .A6(A3[35:30]), .A7(A3[41:36]), .A8(A3[47:42]), .A9(A3[53:48]),
                .W1(W3[7:0]), .W2(W3[15:8]), .W3(W3[23:16]), .W4(W3[31:24]), .W5(W3[39:32]), .W6(W3[47:40]), .W7(W3[55:48]), .W8(W3[63:56]), .W9(W3[71:64]),
                .sel(sel), .and_control(and_control),.counter(counter),.clk_i(clk_i), .acc_rst(acc_reset), .WE(WE), .acc(scaled_acc3));

always@(posedge clk_i) begin
    if(rst) begin
        acc <= 0;
    end else if (WE_d) begin
        acc <= (scaled_acc1 + scaled_acc2) + scaled_acc3;
    end
end
assign  out = acc >>> 7; // shift right by 7 bits to scale down the value         
endmodule

