// Verilog test fixture created from schematic D:\FPGA_HW_1\CPU\CPU.sch - Sun Nov 14 04:04:13 2021

`timescale 1ns / 1ps
`define auto_init

module Single_Cycle_CPU_tb();

parameter clk_period = 20;
parameter delay_factor = 2;

// Inputs
	reg          clk_i;
	reg          rst_n;

	reg          ex_iwe;
	reg [16-1:0] ex_iaddr;
	reg [16-1:0] ex_idata;
	reg          ex_dwe;
	reg [16-1:0] ex_daddr;
	reg [16-1:0] ex_ddata;

// Output
	wire [15:0] Out_R;
	wire flag_done;

// New for Model
	reg [15:0] predict;
	wire [15:0] Rm;
	wire [15:0] Rn;

// Bidirs

	/*****************************************************/
	/*                                                   */
	/*                Instantiate the UUT                */
	/*                                                   */
	/*****************************************************/

	Single_Cycle_CPU u_Single_Cycle_CPU(
		.clk_i     (clk_i     ),
		.rst_n     (rst_n     ),
		.Out_R     (Out_R     ),
		.flag_done (flag_done ),
		.ex_iwe    (ex_iwe    ),
		.ex_iaddr  (ex_iaddr  ),
		.ex_idata  (ex_idata  ),
		.ex_dwe    (ex_dwe    ),
		.ex_daddr  (ex_daddr  ),
		.ex_ddata  (ex_ddata  ),
		// New for Model
		.predict   (predict   ),
		.Rm        (Rm  	  ),
		.Rn        (Rn  	  )
	);
	
	
	/*****************************************************/
	/*                                                   */
	/*                 Initialize Inputs                 */
	/*                                                   */
	/*****************************************************/

	`ifdef auto_init
		initial begin
			clk_i    = 1'b0;   
			rst_n    = 1'b0;
			ex_iwe   = 1'b0;
			ex_dwe   = 1'b0;
			ex_iaddr = 16'd0;
			ex_idata = 16'd0;
			ex_daddr = 16'd0;
			ex_ddata = 16'd0;

			predict  = 4'h5;
		end
	`endif

	/*****************************************************/
	/*                                                   */
	/*             Generate the clock signal             */
	/*                                                   */
	/*****************************************************/

	always begin
		#(clk_period/2) clk_i <= 1'b0;
		#(clk_period/2) clk_i <= 1'b1;
	end

	/*****************************************************/
	/*                                                   */
	/*                   Main Program                    */
	/*                                                   */
	/*****************************************************/
	initial begin
        $dumpfile("./vcd/Single_Cycle_CPU.vcd");
        $dumpvars(0,Single_Cycle_CPU_tb);
    end
	initial begin	
		
		///////////////////////////////////////////////////////////////////////////////////
		//                                                                               //
		//             Find the minimum and maximum from two numbers in memory.          //
		//                                                                               // 
		///////////////////////////////////////////////////////////////////////////////////	
		
		// $readmemb("max_min_test.txt", UUT.u_Instruction_Memory.memory);

		//----- Test new instruction -----//
		write_imem(16'h0009, {8'b00010_001, 8'h66}) ; 	 //LLI  R1, 66H
		write_imem(16'h000A, {8'b00010_010, 8'h77}) ; 	 //LLI  R2, 77H
		write_imem(16'h000B, {8'b00010_011, 8'h88}) ; 	 //LLI  R3, 88H
		write_imem(16'h000C, 16'b11111_011_010_001_00) ; //MVM  R1, R2
		write_imem(16'h000D, 16'b11110_010_000_000_00) ; //DIC  R2
		write_imem(16'h000E, 16'b11100_000_010_000_00) ; //OUTR R2 (77H)
		//----- End of test -----//
		
		write_dmem(16'h0025, 16'h20 ) ;                  // DMEM[25h] = 20h
		write_dmem(16'h0026, 16'h10 ) ;                  // DMEM[26h] = 10h

		//start
		#(clk_period) ex_iwe = 1'b0;
		#(clk_period) ex_dwe = 1'b0;
		#(clk_period) rst_n = 1'b1;

		wait(flag_done);
		
		#(clk_period) rst_n = 1'b0;
		
		#100 $finish;
	end

	/*****************************************************/
	/*                                                   */
	/*            Write Instrucion to Memoery            */
	/*                                                   */
	/*****************************************************/
	
	task write_imem;
		input [15:0] addr;
		input [15:0] data;
		begin
			@(posedge clk_i) #(clk_period/delay_factor) begin
				ex_iwe = 1'b1;
				ex_iaddr = addr;
				ex_idata = data;
			end
		end
	endtask

	/*****************************************************/
	/*                                                   */
	/*               Write Data to Memoery               */
	/*                                                   */
	/*****************************************************/
	
	task write_dmem;
		input [15:0] addr;
		input [15:0] data;
		begin
			@(posedge clk_i) #(clk_period/delay_factor) begin
				ex_dwe = 1'b1;
				ex_daddr = addr;
				ex_ddata = data;
			end
		end
	endtask

	/*****************************************************/
	/*                                                   */
	/*                      Monitor                      */
	/*                                                   */
	/*****************************************************/
	
	initial #100000 $finish;
	initial
	$monitor($realtime,"ns %h %h %h \n", clk_i, rst_n, Out_R, flag_done);
	
endmodule

