module conv1(clk_i, rst, WE ,A1, A2, A3, A4, A5, A6, A7, A8, A9, W1, W2, W3, W4, W5, W6, W7, W8, W9, and_control, cmp, sel);
    input  A1,A2,A3,A4,A5,A6,A7,A8,A9;
    input signed [7:0] W1,W2,W3,W4,W5,W6,W7,W8,W9;
    input [3:0] sel;
    input and_control;
    input clk_i, rst, WE;
    output signed [5:0] cmp;
    reg signed [7:0] mul[8:0];
    wire signed [7:0] W[8:0];
    wire A[8:0];
    reg signed [11:0] acc [8:0];
    wire signed [5:0] acc_out[8:0];
    wire signed [5:0] cmp1, cmp2, cmp3, cmp4, cmp5, cmp6, cmp7;
    assign A[0] = A1; assign A[1] = A2; assign A[2] = A3;
    assign A[3] = A4; assign A[4] = A5; assign A[5] = A6;
    assign A[6] = A7; assign A[7] = A8; assign A[8] = A9;
    assign W[0] = W1; assign W[1] = W2; assign W[2] = W3;
    assign W[3] = W4; assign W[4] = W5; assign W[5] = W6;
    assign W[6] = W7; assign W[7] = W8; assign W[8] = W9;
    //input * weight multiplication
    integer i;
    always @(*) begin
        for (i = 0; i < 9; i = i + 1) begin
            case(sel)
                4'd0: mul[i] = {8{A[i]}} & W[0];
                4'd1: mul[i] = {8{A[i]}} & W[1];
                4'd2: mul[i] = {8{A[i]}} & W[2];
                4'd3: mul[i] = {8{A[i]}} & W[3];
                4'd4: mul[i] = {8{A[i]}} & W[4];
                4'd5: mul[i] = {8{A[i]}} & W[5];
                4'd6: mul[i] = {8{A[i]}} & W[6];
                4'd7: mul[i] = {8{A[i]}} & W[7];
                4'd8: mul[i] = {8{A[i]}} & W[8];
                default: mul[i] = 8'd0;
        endcase
    end
end
    genvar j;
       generate
          for(j = 0; j < 9; j = j + 1) begin: genB
            always @(posedge clk_i) begin
                if (rst) begin
                    acc[j] <= 0;
                end else if (!WE) begin
                    acc[j] <= acc[j] + mul[j];
                end
            end
          end
        endgenerate
    genvar k;
       generate
        for(k = 0; k < 9; k = k + 1) begin: genC
            assign acc_out[k] = and_control ? acc[k] >>> 6 : 6'd0;
        end 
       endgenerate
    //maxpooling
    assign cmp1 = (acc_out[0] >= acc_out[1]) ? acc_out[0] : acc_out[1];
    assign cmp2 = (acc_out[2] >= acc_out[3]) ? acc_out[2] : acc_out[3];
    assign cmp3 = (acc_out[4] >= acc_out[5]) ? acc_out[4] : acc_out[5];
    assign cmp4 = (acc_out[6] >= acc_out[7]) ? acc_out[6] : acc_out[7];
    assign cmp5 = (cmp1 >= cmp2) ? cmp1 : cmp2;
    assign cmp6 = (cmp3 >= cmp4) ? cmp3 : cmp4;
    assign cmp7 = (cmp5 >= cmp6) ? cmp5 : cmp6;
    assign cmp = (cmp7 >= acc_out[8]) ? cmp7 : acc_out[8];
endmodule
