module conv3_filter(CLK, CLR, WE, A1, B1, WA1, WB1, sel, out);
    input CLK, CLR, WE;
    input  [12:0] A1, B1;
    input [31:0] WA1,  WB1;
    input [1:0] sel;
    output reg signed [27:0] out;
    wire signed [21:0] acc;

   
    conv3 conv3_filter1(.A(A1), .B(B1), .sel(sel), .WA0(WA1[7:0]), .WA1(WA1[15:8]), .WA2(WA1[23:16]), .WA3(WA1[31:24]), .WB0(WB1[7:0]), .WB1(WB1[15:8]), .WB2(WB1[23:16]), .WB3(WB1[31:24]), .acc(acc));

    always@(posedge CLK) begin
        if (CLR) begin
            out <= 0;
        end else if (WE) begin
            out <= acc +out; 
        end
    end
endmodule
//conv3(A, B, sel, WA0, WA1, WA2, WA3, WB0, WB1, WB2, WB3, acc)