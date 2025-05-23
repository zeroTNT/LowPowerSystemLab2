module conv3_filter(clk_i, rst, WE, A1, B1, WA1, WB1, sel ,acc);
    input clk_i, rst, WE;
    input signed [12:0] A1, B1;
    input [31:0] WA1,  WB1;
    input [1:0] sel;
    output reg signed [27:0] acc;

    wire signed [21:0] mul_plus;

    conv3 conv3_channel(.A(A1), .B(B1), .sel(sel), .WA0(WA1[7:0]), .WA1(WA1[15:8]), .WA2(WA1[23:16]), .WA3(WA1[31:24]), .WB0(WB1[7:0]), .WB1(WB1[15:8]), .WB2(WB1[23:16]), .WB3(WB1[31:24]), .mul_plus(mul_plus));

    always@(posedge clk_i) begin
        if (rst) begin
            acc <= 0;
        end else if (WE) begin
            acc <= mul_plus + acc; 
        end
    end

endmodule