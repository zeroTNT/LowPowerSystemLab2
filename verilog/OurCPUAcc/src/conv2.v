module conv2(A1, A2 ,A3 ,A4, A5, A6, A7, A8, A9,
             W1, W2, W3, W4, W5, W6, W7, W8, W9,
             sel, and_control, counter, clk_i, acc_rst, WE ,acc);
    input signed [5:0] A1, A2, A3, A4, A5, A6, A7, A8, A9;
    input signed [7:0] W1, W2, W3, W4, W5, W6, W7, W8, W9;
    input clk_i, and_control, acc_rst, WE;
    output reg signed  [17:0] acc;

    input [3:0] counter;
    input [1:0] sel;
    wire signed [5:0] A[8:0];
    wire signed [7:0] W[8:0];


    wire signed [13:0] mul;
    reg signed [5:0] mulcand [8:0];

    assign A[0] = A1; assign A[1] = A4; assign A[2] = A7;
    assign A[3] = A2; assign A[4] = A5; assign A[5] = A8;
    assign A[6] = A3; assign A[7] = A6; assign A[8] = A9;

    assign W[0] = W1; assign W[1] = W4; assign W[2] = W7;
    assign W[3] = W2; assign W[4] = W5; assign W[5] = W8;
    assign W[6] = W3; assign W[7] = W6; assign W[8] = W9;

    always@(*) begin
        case(sel)
            2'b00: begin
                        mulcand[0]= A[0];
                        mulcand[1]= A[1];
                        mulcand[2]= A[2];
                        mulcand[3]= A[3];
                        mulcand[4]= A[4];
                        mulcand[5]= A[5];
                        mulcand[6]= A[6];
                        mulcand[7]= A[7];
                        mulcand[8]= A[8];
            end
            2'b01: begin
                        mulcand[0] = A[3]; 
                        mulcand[1] = A[4];
                        mulcand[2] = A[5];
                        mulcand[3] = A[6];
                        mulcand[4] = A[7];
                        mulcand[5] = A[8];
                        mulcand[6] = A[0];
                        mulcand[7] = A[1];
                        mulcand[8] = A[2];
            end
            2'b10: begin
                        mulcand[0] = A[6]; 
                        mulcand[1] = A[7];
                        mulcand[2] = A[8];
                        mulcand[3] = A[0];
                        mulcand[4] = A[1];
                        mulcand[5] = A[2];
                        mulcand[6] = A[3];
                        mulcand[7] = A[4];
                        mulcand[8] = A[5];
            end
            2'b11: begin
                        mulcand[0]= A[0];
                        mulcand[1]= A[1];
                        mulcand[2]= A[2];
                        mulcand[3]= A[3];
                        mulcand[4]= A[4];
                        mulcand[5]= A[5];
                        mulcand[6]= A[6];
                        mulcand[7]= A[7];
                        mulcand[8]= A[8];
                    end
        endcase
    end
    
  
    assign   mul =  and_control ? mulcand[counter] * W[counter]:0;

    always@(posedge clk_i) begin
        if (!acc_rst) begin
            acc <= 0;
        end else if (WE) begin
            acc <= acc +  mul;
        end
    end       

endmodule
