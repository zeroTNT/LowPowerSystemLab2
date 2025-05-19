`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:45:06 05/15/2025
// Design Name:   acc
// Module Name:   C:/ISE_project/test/conv/acc_tb.v
// Project Name:  conv
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: acc
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module conv_tb;

	// Inputs
	reg clk_i;
	reg rst;
	reg [15:0] Rm;
	reg [15:0] Rn;

	// Outputs
	wire [3:0] max_index;

	// Instantiate the Unit Under Test (UUT)
	conv uut (
		.clk_i(clk_i), 
		.rst(rst), 
		.Rm(Rm), 
		.Rn(Rn), 
		.max_index(max_index)
	);

	// 50 MHz clock
    always #10 clk_i = ~clk_i;
	 integer j;
	 integer i;
	 integer group_id;
    initial begin
		group_id = 1;
        clk_i = 0;
        rst = 1;
        Rm = 16'd0;
        Rn = 16'd0;
			
        // reset
        #40;
        rst = 0;

        // Write W[0] ~ W[71] via 36 write cycles (Wen = 1 ~ 36)
		for (i = 1; i <= 81; i = i + 1) begin
			 Rm = {8'b01111111,i[5:0],2'b11}; // Rm[15:8], Rm[7:0] 都保證最高 bit 為 0
			Rn = {6'd0, i[6:0], 1'b0};   // IN=0, Wen=i
			@(posedge clk_i);
		end

		// Clear Wen
		Rn = 0;
		Rm = 0;
		#40;

		// 4 conv1 blocks (每次餵 9 筆 IN=1 資料)
		repeat (200) begin
			for (j = 0; j < 10; j = j + 1) begin
				@(posedge clk_i);
				Rm = group_id * 10 + j;   // 每組的 Rm 不同，且內部也不同
				Rn = 16'b0_0000000_1;     // IN = 1
			end
			// Padding (IN = 0)
			Rn = 0;
			Rm = 0;
			group_id = group_id + 1;
			#40;
		end

		// 結束模擬
		#500;
		$finish;
	end
	initial begin
        $dumpfile("./vcd/conv.vcd");
        $dumpvars(0,conv_tb);
    end
      
endmodule

