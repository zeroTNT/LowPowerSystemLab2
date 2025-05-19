module conv(clk_i, rst, Rm, Rn, max_index, done); //conv1 module
    input  clk_i, rst;
    input [15:0] Rm, Rn;
    wire IN;
    wire  [6:0] Wen;
    wire  [8:0] input_data; //image input
    //reg  [7:0] weight [160:0];//weight input
    reg [7:0] W [160:0];//weight input
    wire signed [5:0] cmp1, cmp2, cmp3; //conv1 output
    reg [3:0]cnt; //counter
    reg [3:0] cnt1;
    wire WE1; //conv1 write enable
    reg conv1_reset; //conv1 reset
    reg [3:0] sel1;
    wire conv1_control;
    //CONV2
    wire WE2; //conv2 write enable
    reg signed [53:0] conv2_A1, conv2_A2, conv2_A3;
    reg [1:0] conv2_group_cnt; //conv2 group counter
    reg [1:0] conv2_group_cnt1;
    reg [1:0]sel2;
    reg [3:0] write_cnt;
    wire conv2_and_control;
    wire signed [12:0] conv2_out1, conv2_out2; //conv2 output
    //assign image input
    //assign input_data = Rm[0:8]; 
    assign {input_data[0], input_data[1], input_data[2], input_data[3], input_data[4], input_data[5], input_data[6], input_data[7], input_data[8]} = Rm[8:0]; //image input
    assign IN = Rn[0]; //input data valid
    assign Wen = Rn[7:1]; //weight enable
    //CONV3
    reg [1:0] sel2_d;
    wire conv3_signal;
    reg [1:0] sel3;
    reg [4:0] counter3;
    reg [3:0] cycle_count;
    reg [4:0] counter3_reg;
    reg WE3; //conv3 write enable
    wire signed [27:0] conv3_out1, conv3_out2, conv3_out3, conv3_out4, conv3_out5, conv3_out6, conv3_out7, conv3_out8, conv3_out9, conv3_out10; //conv3 output
    reg signed [20:0] conv3_shift1, conv3_shift2, conv3_shift3, conv3_shift4, conv3_shift5, conv3_shift6, conv3_shift7, conv3_shift8, conv3_shift9, conv3_shift10;
    reg signed [20:0] max_val;
    reg [3:0] k;
    output reg [3:0] max_index;
    output reg done;
    //assign weight input
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

    //counter
    always@(posedge clk_i)begin
        if(rst) begin
            cnt <= 0;
            sel1 <= 0;
        end else if (IN) begin
                if (cnt == 9) begin
                    cnt <= 0;
						  sel1 <= sel1 + 1;
                end
                else begin
                    cnt <= cnt + 1;
                    sel1 <= sel1 + 1;
                end
        end
        else begin
            if (cnt == 8) begin
                cnt <= cnt + 1;
                sel1 <= 0;
            end
        end
		  if(cnt == 8)
			 sel1 <= 0;
    end
	 
    //conv1 WE
    assign WE1 =  IN  ? 0 : 1;
    assign conv1_control = cnt == 9 ? 1 : 0;
    always@(negedge clk_i)
        if (cnt == 9&&IN == 0)
            conv1_reset <= 1|rst;
        else
            conv1_reset <= 0|rst;
    
    always@(posedge clk_i)begin
        cnt1 <= cnt;
    end

    //conv1

    conv1 conv1_filter1(.CLK(clk_i), .CLR(conv1_reset), .WE(WE1) , 
    .A1(input_data[0]), .A2(input_data[1]), .A3(input_data[2]), .A4(input_data[3]), .A5(input_data[4]), .A6(input_data[5]), .A7(input_data[6]), .A8(input_data[7]), .A9(input_data[8]), 
    .W1(W[0]), .W2(W[1]), .W3(W[2]), .W4(W[3]), .W5(W[4]), .W6(W[5]), .W7(W[6]), .W8(W[7]), .W9(W[8]), .acc_con(conv1_control), .cmp(cmp1), .sel(sel1));

    conv1 conv1_filter2(.CLK(clk_i), .CLR(conv1_reset), .WE(WE1) , 
    .A1(input_data[0]), .A2(input_data[1]), .A3(input_data[2]), .A4(input_data[3]), .A5(input_data[4]), .A6(input_data[5]), .A7(input_data[6]), .A8(input_data[7]), .A9(input_data[8]), 
    .W1(W[9]), .W2(W[10]), .W3(W[11]), .W4(W[12]), .W5(W[13]), .W6(W[14]), .W7(W[15]), .W8(W[16]), .W9(W[17]), .acc_con(conv1_control), .cmp(cmp2), .sel(sel1));

    conv1 conv1_filter3(.CLK(clk_i), .CLR(conv1_reset), .WE(WE1) , 
    .A1(input_data[0]), .A2(input_data[1]), .A3(input_data[2]), .A4(input_data[3]), .A5(input_data[4]), .A6(input_data[5]), .A7(input_data[6]), .A8(input_data[7]), .A9(input_data[8]), 
    .W1(W[18]), .W2(W[19]), .W3(W[20]), .W4(W[21]), .W5(W[22]), .W6(W[23]), .W7(W[24]), .W8(W[25]), .W9(W[26]), .acc_con(conv1_control), .cmp(cmp3), .sel(sel1));
    //conv2
    
            
    always @(posedge clk_i) begin
        if (rst) begin
            conv2_A1 <= 0;
            conv2_A2 <= 0;
            conv2_A3 <= 0;
            write_cnt <= 0;
            sel2 <= 0;
            conv2_group_cnt <= 0;
        end else if (cnt == 9&&cnt!=cnt1) begin
            case (write_cnt)
                4'd0: begin conv2_A1[5:0]    <= cmp1; conv2_A2[5:0]    <= cmp2; conv2_A3[5:0]    <= cmp3; end
                4'd1: begin conv2_A1[11:6]   <= cmp1; conv2_A2[11:6]   <= cmp2; conv2_A3[11:6]   <= cmp3; end
                4'd2: begin conv2_A1[17:12]  <= cmp1; conv2_A2[17:12]  <= cmp2; conv2_A3[17:12]  <= cmp3; end
                4'd3: begin conv2_A1[23:18]  <= cmp1; conv2_A2[23:18]  <= cmp2; conv2_A3[23:18]  <= cmp3; end
                4'd4: begin conv2_A1[29:24]  <= cmp1; conv2_A2[29:24]  <= cmp2; conv2_A3[29:24]  <= cmp3; end
                4'd5: begin conv2_A1[35:30]  <= cmp1; conv2_A2[35:30]  <= cmp2; conv2_A3[35:30]  <= cmp3; end
                4'd6: begin conv2_A1[41:36]  <= cmp1; conv2_A2[41:36]  <= cmp2; conv2_A3[41:36]  <= cmp3; end
                4'd7: begin conv2_A1[47:42]  <= cmp1; conv2_A2[47:42]  <= cmp2; conv2_A3[47:42]  <= cmp3; end
                4'd8: begin conv2_A1[53:48]  <= cmp1; conv2_A2[53:48]  <= cmp2; conv2_A3[53:48]  <= cmp3; end
                4'd9: begin conv2_A1[5:0]    <= cmp1; conv2_A2[5:0]    <= cmp2; conv2_A3[5:0]    <= cmp3; end
            endcase
        end
        if (cnt == 9) begin
            if (write_cnt == 9)
                write_cnt <= 0;
            else if (IN == 1)
                write_cnt <= write_cnt + 1;

        // 狀態轉移：在觸發點時更新 group_cnt
            if (conv2_and_control) begin
                if (conv2_group_cnt == 3) begin
                    conv2_group_cnt <= 0;
                    sel2 <= 0;
                end else begin
                    conv2_group_cnt <= conv2_group_cnt + 1;
                    sel2 <= sel2 + 1;
                end
            end
        end
    end
    always@(posedge clk_i)begin
        conv2_group_cnt1 <= conv2_group_cnt;
    end
    assign conv2_and_control = 
       (conv2_group_cnt == 0 && write_cnt == 9) || 
       (conv2_group_cnt != 0 && (write_cnt == 3||write_cnt == 6||write_cnt == 9)&&conv2_group_cnt1 == conv2_group_cnt);
    
    
    conv2_filter conv2_filter1(.CLK(clk_i), .CLR(rst), .WE(conv1_reset) , .A1(conv2_A1) , .A2(conv2_A2), .A3(conv2_A3), .W1({W[35],W[34],W[33],W[32],W[31],W[30],W[29],W[28],W[27]}), 
                               .W2({W[44], W[43], W[42], W[41], W[40], W[39], W[38], W[37], W[36]}), .W3({W[53], W[52], W[51], W[50], W[49], W[48], W[47], W[46], W[45]}), .sel(sel2), .and_control(conv2_and_control), .out(conv2_out1));

    conv2_filter conv2_filter2(.CLK(clk_i), .CLR(rst), .WE(conv1_reset) , .A1(conv2_A1) , .A2(conv2_A2), .A3(conv2_A3), .W1({W[62],W[61],W[60],W[59],W[58],W[57],W[56],W[55],W[54]}),
                               .W2({W[71], W[70], W[69], W[68], W[67], W[66], W[65], W[64], W[63]}), .W3({W[80], W[79], W[78], W[77], W[76], W[75], W[74], W[73], W[72]}), .sel(sel2), .and_control(conv2_and_control), .out(conv2_out2));
    
    //conv3
    
    always @(posedge clk_i) begin
        if(rst) begin
            sel2_d <= 0;
        end
        else
            sel2_d <= sel2;
    end

    always @(posedge clk_i) begin
        if(rst) begin
            counter3 <= 0;
        end else if (sel2 !=sel2_d &&counter3<=16)begin
            counter3 <= counter3 +1;
        end else
            counter3 <= counter3;
    end

    always@(posedge clk_i)begin
        if (rst) begin
            cycle_count <= 0;
            counter3_reg <= 0;
            sel3 <= 0;
            WE3 <= 0;
 
        end
        else begin
            
            if(cycle_count == 0) begin
                counter3_reg <= counter3;
            end

            case (counter3_reg)
                4'd1: begin if(cycle_count == 0) begin
                            sel3 <= 0;
                            WE3 <= 1;
                        end else begin
                            WE3 <= 0;
                            sel3 <= sel3;
                        end
                end
                4'd2: begin
                    if(cycle_count == 0) begin
                        sel3 <= 0;
                        WE3 <= 1;
                    end else if(cycle_count == 1)begin
                        sel3 <= 1;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd3: begin
                    /*if(cycle_count == 1) begin
                        sel3 <= 0;
                        WE3 <= 1;
                    end else */if (cycle_count == 2) begin
                        sel3 <= 1;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd4: begin
                    if(cycle_count == 1) begin
                        sel3 <= 1;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd5: begin
                    if(cycle_count == 1) begin
                        sel3 <= 0;
                        WE3 <= 1;
                    end else if(cycle_count == 2) begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd6: begin
                    if(cycle_count == 1) begin
                        sel3 <= 0;
                        WE3 <= 1;
                    end else if(cycle_count == 2) begin
                        sel3 <= 1;
                        WE3 <= 1;
                    end else if (cycle_count == 3) begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else if(cycle_count == 4)begin
                        sel3 <= 3;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd7: begin
                    if(cycle_count == 1) begin
                        sel3 <= 0;
                        WE3 <= 1;
                    end else if(cycle_count == 2) begin
                        sel3 <= 1;
                        WE3 <= 1;
                    end else if (cycle_count == 3) begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else if(cycle_count == 4) begin
                        sel3 <= 3;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd8: begin
                    if(cycle_count == 1) begin
                        sel3 <= 1;
                        WE3 <= 1;
                    end else if (cycle_count == 2)begin
                        sel3 <= 3;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd9: begin
                    if(cycle_count == 1) begin
                        sel3 <= 0;
                        WE3 <= 1;
                    end else if(cycle_count == 2)begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd10: begin
                    if(cycle_count == 1) begin
                        sel3 <= 1;
                        WE3 <= 1;
                    end else if(cycle_count == 2) begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else if (cycle_count == 3) begin
                        sel3 <= 3;
                        WE3 <= 1;
                    end else if (cycle_count == 4) begin
                        sel3 <= 4;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0; 
                        sel3 <= sel3;
                    end
                end
                
                4'd11: begin
                    if(cycle_count == 1) begin
                        sel3 <= 1;
                        WE3 <= 1;
                    end else if(cycle_count == 2) begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else if (cycle_count == 3) begin
                        sel3 <= 3;
                        WE3 <= 1;
                    end else if (cycle_count == 4) begin
                        sel3 <= 4;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd12: begin
                    if(cycle_count == 1) begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else if (cycle_count == 2) begin
                        sel3 <= 4;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd13: begin
                    if(cycle_count == 1) begin
                        sel3 <= 2;
								WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd14: begin
                    if(cycle_count == 1) begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else  if (cycle_count == 2)begin
                        sel3 <= 3;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                4'd15: begin
                    if(cycle_count == 1) begin
                        sel3 <= 2;
                        WE3 <= 1;
                    end else if (cycle_count == 2) begin
                        sel3 <= 3;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                5'd16: begin
                    if(cycle_count == 1) begin
                        sel3 <= 3;
                        WE3 <= 1;
                    end else begin
                        WE3 <= 0;
                        sel3 <= sel3;
                    end
                end
                default: begin
                    sel3 <= 0;
                    WE3 <= 0;
                end
            endcase

            if (counter3_reg != 0 && cycle_count < 5) begin
                cycle_count <= cycle_count + 1;
            end else if(sel2 != sel2_d)begin
                cycle_count <= 0;
                WE3 <= 0;
            end else
                WE3 <= 0;
        end
    end

    
    conv3_filter conv3_filter1(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[84],W[83],W[82],W[81]}), .WB1({W[88],W[87],W[86],W[85]}), .sel(sel3), .out(conv3_out1));
    conv3_filter conv3_filter2(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[92],W[91],W[90],W[89]}), .WB1({W[96],W[95],W[94],W[93]}), .sel(sel3), .out(conv3_out2));
    conv3_filter conv3_filter3(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[100],W[99],W[98],W[97]}), .WB1({W[104],W[103],W[102],W[101]}), .sel(sel3), .out(conv3_out3));
    conv3_filter conv3_filter4(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[108],W[107],W[106],W[105]}), .WB1({W[112],W[111],W[110],W[109]}), .sel(sel3), .out(conv3_out4));
    conv3_filter conv3_filter5(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[116],W[115],W[114],W[113]}), .WB1({W[120],W[119],W[118],W[117]}), .sel(sel3), .out(conv3_out5));
    conv3_filter conv3_filter6(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[124],W[123],W[122],W[121]}), .WB1({W[128],W[127],W[126],W[125]}), .sel(sel3), .out(conv3_out6));
    conv3_filter conv3_filter7(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[132],W[131],W[130],W[129]}), .WB1({W[136],W[135],W[134],W[133]}), .sel(sel3), .out(conv3_out7));
    conv3_filter conv3_filter8(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[140],W[139],W[138],W[137]}), .WB1({W[144],W[143],W[142],W[141]}), .sel(sel3), .out(conv3_out8));
    conv3_filter conv3_filter9(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[148],W[147],W[146],W[145]}), .WB1({W[152],W[151],W[150],W[149]}), .sel(sel3), .out(conv3_out9));
    conv3_filter conv3_filter10(.CLK(clk_i), .CLR(rst), .WE(WE3), .A1(conv2_out1), .B1(conv2_out2), .WA1({W[156],W[155],W[154],W[153]}), .WB1({W[160],W[159],W[158],W[157]}), .sel(sel3), .out(conv3_out10));

    always@(posedge clk_i) begin
        if(rst||counter3<17) begin
            conv3_shift1 <= 0;
            conv3_shift2 <= 0;
            conv3_shift3 <= 0;
            conv3_shift4 <= 0;
            conv3_shift5 <= 0;
            conv3_shift6 <= 0;
            conv3_shift7 <= 0;
            conv3_shift8 <= 0;
            conv3_shift9 <= 0;
            conv3_shift10 <= 0;
        end else begin
            conv3_shift1 <= conv3_out1 >>> 7;
            conv3_shift2 <= conv3_out2 >>> 7;
            conv3_shift3 <= conv3_out3 >>> 7;
            conv3_shift4 <= conv3_out4 >>> 7;
            conv3_shift5 <= conv3_out5 >>> 7;
            conv3_shift6 <= conv3_out6 >>> 7;
            conv3_shift7 <= conv3_out7 >>> 7;
            conv3_shift8 <= conv3_out8 >>> 7;
            conv3_shift9 <= conv3_out9 >>> 7;
            conv3_shift10 <= conv3_out10 >>> 7;
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
                max_val    <= conv3_shift1;
                max_index  <= 4'd0;
            end
            4'd1: if (max_val < conv3_shift2) begin
                max_val    <= conv3_shift2;
                max_index  <= 4'd1;
            end
            4'd2: if (max_val < conv3_shift3) begin
                max_val    <= conv3_shift3;
                max_index  <= 4'd2;
            end
            4'd3: if (max_val < conv3_shift4) begin
                max_val    <= conv3_shift4;
                max_index  <= 4'd3;
            end
            4'd4: if (max_val < conv3_shift5) begin
                max_val    <= conv3_shift5;
                max_index  <= 4'd4;
            end
            4'd5: if (max_val < conv3_shift6) begin
                max_val    <= conv3_shift6;
                max_index  <= 4'd5;
            end
            4'd6: if (max_val < conv3_shift7) begin
                max_val    <= conv3_shift7;
                max_index  <= 4'd6;
            end
            4'd7: if (max_val < conv3_shift8) begin
                max_val    <= conv3_shift8;
                max_index  <= 4'd7;
            end
            4'd8: if (max_val < conv3_shift9) begin
                max_val    <= conv3_shift9;
                max_index  <= 4'd8;
            end
            4'd9: if (max_val < conv3_shift10) begin
                max_val    <= conv3_shift10;
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
