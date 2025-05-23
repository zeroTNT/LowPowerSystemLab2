module conv(clk_i, rst, Rm, Rn, max_index, done);
    input  clk_i, rst;
    input [15:0] Rm, Rn;
    wire signed [5:0] cmp1, cmp2, cmp3;
    //IN & weights
    wire IN;
    wire  [6:0] Wen;
    wire  [8:0] input_data;
    reg [7:0] W [160:0];
    //conv1 signal
    wire WE1_n;
    reg conv1_and;
    wire conv1_reset;
    wire [3:0] sel1;
    reg [3:0] counter1; //計算第幾次input (0~8)
    //conv2 signal
    reg [3:0] cnt; //計算第幾次conv1 output (0~8)
    reg [3:0] cnt_d;
    reg [3:0] write_cnt;//計算寫入到哪個conv2 input
    reg cmp_2_conv2; //conv1 to conv2 input valid
    wire [3:0] counter2; //計算第幾次input (0~8)
    reg [1:0] sel_control2; //conv2 input select
    reg signed [53:0] conv2_A1, conv2_A2, conv2_A3; // conv2 channel input
    reg [1:0] sel2;
    reg [1:0] sel2_d;
    reg and_control2;
    wire acc_reset_n;
    wire WE2;
    wire signed [12:0] conv2_out1, conv2_out2; 
    //conv3 signal
    wire [1:0] sel3;
    reg [1:0] sel3_d;
    reg [3:0] WE2_cnt;
    reg [4:0] counter3; //計算第幾次input (1~16)
    reg [2:0] cnt3;
    wire  signed [27:0] conv3_out1, conv3_out2, conv3_out3, conv3_out4, conv3_out5, conv3_out6, conv3_out7, conv3_out8, conv3_out9, conv3_out10;
    reg signed [20:0] conv3_out_shift1 , conv3_out_shift2, conv3_out_shift3, conv3_out_shift4, conv3_out_shift5, conv3_out_shift6, conv3_out_shift7, conv3_out_shift8, conv3_out_shift9, conv3_out_shift10;
    reg conv_end_signal;
    reg WE3;
    reg signed [20:0] max_val;
    reg [3:0] k;
    output reg [3:0] max_index;
    output reg done;
    assign {input_data[0], input_data[1], input_data[2], input_data[3], input_data[4], input_data[5], input_data[6], input_data[7], input_data[8]} = IN ? Rm[8:0]: 0; //image input
    assign IN = Rn[0]; //input data valid
    assign Wen = Rn[7:1]; //weight 
    // weight mapping
    integer i;
    always@(posedge clk_i)begin
        if(rst)
            for (i = 0; i <= 160; i = i + 1)
                W[i] <= 8'd0;
        else if (Wen != 0 && !IN) begin
            W[(Wen<<1)-2] <= Rm[7:0];
            W[(Wen<<1)-1] <= Rm[15:8];
        end
    end
    //conv1
    assign conv1_reset = rst || ((counter1==0)&&~IN); // reset conv1 when IN=0
    assign WE1_n =  IN  ? 0 : 1;

    always@(posedge clk_i)begin
        if(rst) begin
            counter1 <= 0;
            conv1_and <= 0;
        end
        else if (IN)
            if (counter1 == 8) begin
                counter1 <= 0;
                conv1_and <= 1;         //9th input conv1_and  <= 1
            end
            else if (counter1 < 8) begin
                counter1 <= counter1 + 1;
                conv1_and <= 0;
            end
        else begin
            counter1 <= counter1;
            conv1_and <= 0;
        end
    end

    assign sel1 = counter1;
    conv1 conv1_filter1(.clk_i(clk_i), .rst(conv1_reset), .WE(WE1_n) , 
    .A1(input_data[0]), .A2(input_data[1]), .A3(input_data[2]), .A4(input_data[3]), .A5(input_data[4]), .A6(input_data[5]), .A7(input_data[6]), .A8(input_data[7]), .A9(input_data[8]), 
    .W1(W[0]), .W2(W[1]), .W3(W[2]), .W4(W[3]), .W5(W[4]), .W6(W[5]), .W7(W[6]), .W8(W[7]), .W9(W[8]), .and_control(conv1_and), .cmp(cmp1), .sel(sel1));

    conv1 conv1_filter2(.clk_i(clk_i), .rst(conv1_reset), .WE(WE1_n) , 
    .A1(input_data[0]), .A2(input_data[1]), .A3(input_data[2]), .A4(input_data[3]), .A5(input_data[4]), .A6(input_data[5]), .A7(input_data[6]), .A8(input_data[7]), .A9(input_data[8]), 
    .W1(W[9]), .W2(W[10]), .W3(W[11]), .W4(W[12]), .W5(W[13]), .W6(W[14]), .W7(W[15]), .W8(W[16]), .W9(W[17]), .and_control(conv1_and), .cmp(cmp2), .sel(sel1));

    conv1 conv1_filter3(.clk_i(clk_i), .rst(conv1_reset), .WE(WE1_n) , 
    .A1(input_data[0]), .A2(input_data[1]), .A3(input_data[2]), .A4(input_data[3]), .A5(input_data[4]), .A6(input_data[5]), .A7(input_data[6]), .A8(input_data[7]), .A9(input_data[8]), 
    .W1(W[18]), .W2(W[19]), .W3(W[20]), .W4(W[21]), .W5(W[22]), .W6(W[23]), .W7(W[24]), .W8(W[25]), .W9(W[26]), .and_control(conv1_and), .cmp(cmp3), .sel(sel1));

    //conv2
    assign counter2 = sel1;

    always@(posedge clk_i) begin
        sel2_d <= sel2;
    end

    always@(posedge clk_i) begin
        if(rst) begin
            and_control2 <= 0;
        end else if(sel2_d != sel2) begin
            and_control2 <= 1;
        end else if(sel1 == 8&&IN) begin
            and_control2 <= 0;
        end else begin
            and_control2 <= and_control2;
        end
    end

    assign WE2 = and_control2&&IN ? 1 : 0;

    always@(posedge clk_i) begin
        if(rst) begin
            cnt <= 0;
        end else if(counter1 == 8&&IN)begin
            if(cnt <8)
                cnt <= cnt + 1;
            else
                cnt <= 0;
        end
    end
    always@(posedge clk_i) begin
        if(rst) begin
            cnt_d <= 0;
        end else begin
            cnt_d <= cnt;
        end
    end
    always@(posedge clk_i) begin
        if(rst) begin
            write_cnt <= 0;
        end else if (conv1_and&&IN) begin
            if(write_cnt < 8)
                write_cnt <= write_cnt + 1;
            else
                write_cnt <= 0;    
        end 
    end

    
   
    always@(posedge clk_i) begin
        if(counter1 == 8&&IN) begin
            cmp_2_conv2 <= 1;
        end else begin
            cmp_2_conv2 <= 0;
        end
    end
    assign acc_reset_n = and_control2;

    always@(posedge clk_i) begin
        if(rst) begin
            sel_control2 <= 0;
        end else if (sel_control2 <1) begin
            if (write_cnt==8&&cmp_2_conv2) begin
                sel_control2 <= sel_control2 + 1;
            end
        end else if(((cnt_d-cnt) != 0)&&(write_cnt == 2||write_cnt == 5||write_cnt == 8)) begin
            sel_control2 <= sel_control2 + 1;
        end
    end
    always@(*) begin
        case(sel_control2)
            2'b01: sel2 = 2'b00;
            2'b10: sel2 = 2'b01;
            2'b11: sel2 = 2'b10;
            default: sel2 = 2'b11;
        endcase              
    end
    always@(posedge clk_i) begin
        if(rst) begin
            conv2_A1 <= 0;
            conv2_A2 <= 0;
            conv2_A3 <= 0;
        end else if(cmp_2_conv2) begin
            case (write_cnt)
                4'd0: begin conv2_A1[5:0]    <= cmp1; conv2_A2[5:0]    <= cmp2; conv2_A3[5:0]    <= cmp3; end
                4'd1: begin conv2_A1[23:18]  <= cmp1; conv2_A2[23:18]  <= cmp2; conv2_A3[23:18]  <= cmp3; end
                4'd2: begin conv2_A1[41:36]  <= cmp1; conv2_A2[41:36]  <= cmp2; conv2_A3[41:36]  <= cmp3; end
                4'd3: begin conv2_A1[11:6]   <= cmp1; conv2_A2[11:6]   <= cmp2; conv2_A3[11:6]   <= cmp3; end
                4'd4: begin conv2_A1[29:24]  <= cmp1; conv2_A2[29:24]  <= cmp2; conv2_A3[29:24]  <= cmp3; end
                4'd5: begin conv2_A1[47:42]  <= cmp1; conv2_A2[47:42]  <= cmp2; conv2_A3[47:42]  <= cmp3; end
                4'd6: begin conv2_A1[17:12]  <= cmp1; conv2_A2[17:12]  <= cmp2; conv2_A3[17:12]  <= cmp3; end
                4'd7: begin conv2_A1[35:30]  <= cmp1; conv2_A2[35:30]  <= cmp2; conv2_A3[35:30]  <= cmp3; end
                4'd8: begin conv2_A1[53:48]  <= cmp1; conv2_A2[53:48]  <= cmp2; conv2_A3[53:48]  <= cmp3; end
                default: begin conv2_A1 <= 0; conv2_A2 <= 0; conv2_A3 <= 0; end
            endcase
        end
    end
    conv2_filter conv2_filter1(.clk_i(clk_i), .rst(rst), .WE(WE2), .A1(conv2_A1), .A2(conv2_A2) , .A3(conv2_A3),.W1({W[35],W[34],W[33],W[32],W[31],W[30],W[29],W[28],W[27]}),
     .W2({W[44], W[43], W[42], W[41], W[40], W[39], W[38], W[37], W[36]}), .W3({W[53], W[52], W[51], W[50], W[49], W[48], W[47], W[46], W[45]}), .sel(sel2), .and_control(and_control2), .acc_reset(acc_reset_n), .counter(counter2), .out(conv2_out1));

    conv2_filter conv2_filter2(.clk_i(clk_i), .rst(rst), .WE(WE2), .A1(conv2_A1), .A2(conv2_A2), .A3(conv2_A3),.W1({W[62],W[61],W[60],W[59],W[58],W[57],W[56],W[55],W[54]}),
     .W2({W[71], W[70], W[69], W[68], W[67], W[66], W[65], W[64], W[63]}), .W3({W[80], W[79], W[78], W[77], W[76], W[75], W[74], W[73], W[72]}), .sel(sel2), .and_control(and_control2), .acc_reset(acc_reset_n), .counter(counter2), .out(conv2_out2));
     //conv3
    assign sel3 = (sel1 < 4) ? sel1 : 0;
    
    always@(posedge clk_i) begin
        if(rst) begin
            WE2_cnt <= 0;
        end else if (WE2) begin
            if(WE2_cnt < 8)
                WE2_cnt <= WE2_cnt + 1;
            else
                WE2_cnt <= 0;    
        end 
    end

    always@(posedge clk_i) begin
        if(rst) begin
            counter3 <= 0;
        end else if (WE2_cnt == 8&&IN) begin
            if(counter3 < 17)
                counter3 <= counter3 + 1;
            else
                counter3 <= 0;    
        end
    end
    
    always@(posedge clk_i) begin
        sel3_d <= sel3;
    end
    always@(posedge clk_i) begin
        if(rst) begin
            cnt3 <= 4;
        end else if (WE2_cnt == 8&&IN) begin
            cnt3 <= 0;
        end else if (sel3_d != sel3) begin 
             if (cnt3 < 4) begin
                cnt3 <= cnt3 + 1;
            end 
        end
    end

    always@(*) begin
        case ({counter3,cnt3,IN})
            {5'd1, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd2, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd2, 3'd1, 1'b1}: begin WE3 = 1  ;end
            {5'd3, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd3, 3'd1, 1'b1}: begin WE3 = 1  ;end
            {5'd4, 3'd1, 1'b1}: begin WE3 = 1  ;end
            {5'd5, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd5, 3'd2, 1'b1}: begin WE3 = 1  ;end
            {5'd6, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd6, 3'd1, 1'b1}: begin WE3 = 1  ;end
            {5'd6, 3'd2, 1'b1}: begin WE3 = 1  ;end
            {5'd6, 3'd3, 1'b1}: begin WE3 = 1  ;end
            {5'd7, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd7, 3'd1, 1'b1}: begin WE3 = 1  ;end
            {5'd7, 3'd2, 1'b1}: begin WE3 = 1  ;end
            {5'd7, 3'd3, 1'b1}: begin WE3 = 1  ;end
            {5'd8, 3'd1, 1'b1}: begin WE3 = 1  ;end
            {5'd8, 3'd3, 1'b1}: begin WE3 = 1  ;end
            {5'd9, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd9, 3'd2, 1'b1}: begin WE3 = 1  ;end
            {5'd10, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd10, 3'd1, 1'b1}: begin WE3 = 1  ;end
            {5'd10, 3'd2, 1'b1}: begin WE3 = 1  ;end
            {5'd10, 3'd3, 1'b1}: begin WE3 = 1  ;end
            {5'd11, 3'd0, 1'b1}: begin WE3 = 1  ;end
            {5'd11, 3'd1, 1'b1}: begin WE3 = 1  ;end
            {5'd11, 3'd2, 1'b1}: begin WE3 = 1  ;end
            {5'd11, 3'd3, 1'b1}: begin WE3 = 1  ;end
            {5'd12, 3'd1, 1'b1}: begin WE3 = 1 ;end
            {5'd12, 3'd3, 1'b1}: begin WE3 = 1 ;end
            {5'd13, 3'd2, 1'b1}: begin WE3 = 1 ;end
            {5'd14, 3'd2, 1'b1}: begin WE3 = 1 ;end
            {5'd14, 3'd3, 1'b1}: begin WE3 = 1 ;end
            {5'd15, 3'd2, 1'b1}: begin WE3 = 1 ;end
            {5'd15, 3'd3, 1'b1}: begin WE3 = 1 ;end
            {5'd16, 3'd3, 1'b1}: begin WE3 = 1 ;end
            default: begin
                WE3 = 0;
            end
        endcase
    end

    conv3_filter conv3_filter1(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[84],W[83],W[82],W[81]}), .WB1({W[88],W[87],W[86],W[85]}), .sel(cnt3[1:0]), .acc(conv3_out1));
    conv3_filter conv3_filter2(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[92],W[91],W[90],W[89]}), .WB1({W[96],W[95],W[94],W[93]}), .sel(cnt3[1:0]), .acc(conv3_out2));
    conv3_filter conv3_filter3(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[100],W[99],W[98],W[97]}), .WB1({W[104],W[103],W[102],W[101]}), .sel(cnt3[1:0]), .acc(conv3_out3));
    conv3_filter conv3_filter4(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[108],W[107],W[106],W[105]}), .WB1({W[112],W[111],W[110],W[109]}), .sel(cnt3[1:0]), .acc(conv3_out4));
    conv3_filter conv3_filter5(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[116],W[115],W[114],W[113]}), .WB1({W[120],W[119],W[118],W[117]}), .sel(cnt3[1:0]), .acc(conv3_out5));
    conv3_filter conv3_filter6(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[124],W[123],W[122],W[121]}), .WB1({W[128],W[127],W[126],W[125]}), .sel(cnt3[1:0]), .acc(conv3_out6));   
    conv3_filter conv3_filter7(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[132],W[131],W[130],W[129]}), .WB1({W[136],W[135],W[134],W[133]}), .sel(cnt3[1:0]), .acc(conv3_out7));
    conv3_filter conv3_filter8(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[140],W[139],W[138],W[137]}), .WB1({W[144],W[143],W[142],W[141]}), .sel(cnt3[1:0]), .acc(conv3_out8));
    conv3_filter conv3_filter9(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[148],W[147],W[146],W[145]}), .WB1({W[152],W[151],W[150],W[149]}), .sel(cnt3[1:0]), .acc(conv3_out9));
    conv3_filter conv3_filter10(.clk_i(clk_i), .rst(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[156],W[155],W[154],W[153]}), .WB1({W[160],W[159],W[158],W[157]}), .sel(cnt3[1:0]), .acc(conv3_out10));
    assign last_conv3_out_signal = (counter3 == 5'd16) && (cnt3 == 4'd3) && (IN == 1'b1);
    always@(posedge clk_i)begin
        if(rst) begin
            conv_end_signal <=0 ;
        end else if (last_conv3_out_signal) begin
            conv_end_signal <= 1;
        end else 
            conv_end_signal <= conv_end_signal;
    end
    
    always@(posedge clk_i) begin
        if(rst) begin          
            conv3_out_shift1 <= 0;
            conv3_out_shift2 <= 0;
            conv3_out_shift3 <= 0;
            conv3_out_shift4 <= 0;
            conv3_out_shift5 <= 0;
            conv3_out_shift6 <= 0;
            conv3_out_shift7 <= 0;
            conv3_out_shift8 <= 0;
            conv3_out_shift9 <= 0;
            conv3_out_shift10 <= 0;
        end else if (conv_end_signal) begin
            conv3_out_shift1 <= conv3_out1 >>> 7;
            conv3_out_shift2 <= conv3_out2 >>> 7;
            conv3_out_shift3 <= conv3_out3 >>> 7;
            conv3_out_shift4 <= conv3_out4 >>> 7;
            conv3_out_shift5 <= conv3_out5 >>> 7;
            conv3_out_shift6 <= conv3_out6 >>> 7;
            conv3_out_shift7 <= conv3_out7 >>> 7;
            conv3_out_shift8 <= conv3_out8 >>> 7;
            conv3_out_shift9 <= conv3_out9 >>> 7;
            conv3_out_shift10 <= conv3_out10 >>> 7;
        end
    end

    //output
    always@(posedge clk_i) begin
        if(rst) begin
            max_val <= 0;
            k <=0;
            max_index <= 0;
       end else if (counter3 == 17) begin
         case (k)
            4'd0: begin
                max_val    <= conv3_out_shift1;
                max_index  <= 4'd0;
            end
            4'd1: if (max_val < conv3_out_shift2) begin
                max_val    <= conv3_out_shift2;
                max_index  <= 4'd1;
            end
            4'd2: if (max_val < conv3_out_shift3) begin
                max_val    <= conv3_out_shift3;
                max_index  <= 4'd2;
            end
            4'd3: if (max_val < conv3_out_shift4) begin
                max_val    <= conv3_out_shift4;
                max_index  <= 4'd3;
            end
            4'd4: if (max_val < conv3_out_shift5) begin
                max_val    <= conv3_out_shift5;
                max_index  <= 4'd4;
            end
            4'd5: if (max_val < conv3_out_shift6) begin
                max_val    <= conv3_out_shift6;
                max_index  <= 4'd5;
            end
            4'd6: if (max_val < conv3_out_shift7) begin
                max_val    <= conv3_out_shift7;
                max_index  <= 4'd6;
            end
            4'd7: if (max_val < conv3_out_shift8) begin
                max_val    <= conv3_out_shift8;
                max_index  <= 4'd7;
            end
            4'd8: if (max_val < conv3_out_shift9) begin
                max_val    <= conv3_out_shift9;
                max_index  <= 4'd8;
            end
            4'd9: if (max_val < conv3_out_shift10) begin
                max_val    <= conv3_out_shift10;
                max_index  <= 4'd9;
            end
         endcase
         if(k<9)
             k <= k +1;
       end
       if(k == 9) begin
            done <= 1;
       end else begin
            done <= 0;
       end
    end
    

endmodule
