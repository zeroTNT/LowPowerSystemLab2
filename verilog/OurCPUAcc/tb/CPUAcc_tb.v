`timescale 1ns / 1ps
`define auto_init
module CPUAcc_tb();
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

	parameter clk_period = 20;
	parameter delay_factor = 2;

    // New for Model
    reg [15:0] Acc_Wmem [0:80];  //Accelerator Weight
    reg [15:0] Acc_Amem [0:647]; //Accelerator Activation
    reg [15:0] Acc_Cmem [0:81];  //Accelerator Control

    //----- Instantiate Modules -----//
	CPUAcc u_CPUAcc(
		.clk_i     (clk_i     ),
		.rst_n     (rst_n     ),
		.Out_R     (Out_R     ),
		.flag_done (flag_done ),
		.ex_iwe    (ex_iwe    ),
		.ex_iaddr  (ex_iaddr  ),
		.ex_idata  (ex_idata  ),
		.ex_dwe    (ex_dwe    ),
		.ex_daddr  (ex_daddr  ),
		.ex_ddata  (ex_ddata  )
	);
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
		end
	`endif
	
	//----- Generate the clock signal -----//
	always begin
		#(clk_period/2) clk_i <= 1'b0;
		#(clk_period/2) clk_i <= 1'b1;
	end

	//----- Waveform -----//
	initial begin
        $dumpfile("./vcd/CPUAcc.vcd");
        $dumpvars(0,CPUAcc_tb);
    end

	//----- Write Instrucion to Memoery -----//
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

	//----- Write Data to Memoery -----//
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

	//----- CPU Assemble language -----//
    reg [15:0] global_iaddr;
    reg [15:0] global_daddr;
    task LHI; // Load High Immediate: LHI Rd, Imm8
        input [2:0] Rd;
        input [7:0] Imm;
        begin
            write_imem(global_iaddr, {5'b00001, Rd, Imm});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task LLI; // Load Low Immediate: LLI Rd, Imm8
        input [2:0] Rd;
        input [7:0] Imm;
        begin
            write_imem(global_iaddr, {5'b00010, Rd, Imm});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task LDR; // Load Register: LDR Rd, Rm, Imm5
        input [2:0] Rd;
        input [2:0] Rm;
        input [4:0] Imm;
        begin
            write_imem(global_iaddr, {5'b00011, Rd, Rs, Imm});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task STR; // Store Register: STR Rd, Rm, Imm5
        input [2:0] Rd;
        input [2:0] Rm;
        input [4:0] Imm;
        begin
            write_imem(global_iaddr, {5'b00101, Rd, Rs, Imm});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task ADD; // Add: ADD Rd, Rm, Rs
        input [2:0] Rd;
        input [2:0] Rm;
        input [2:0] Rs;
        begin
            write_imem(global_iaddr, {5'b00000, Rd, Rm, Rn, 2'b00});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task ADC; // Add with Carry: ADC Rd, Rm, Rs
        input [2:0] Rd;
        input [2:0] Rm;
        input [2:0] Rs;
        begin
            write_imem(global_iaddr, {5'b00000, Rd, Rm, Rn, 2'b01});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task SBB; // Subtract with Borrow: SBB Rd, Rm, Rs
        input [2:0] Rd;
        input [2:0] Rm;
        input [2:0] Rs;
        begin
            write_imem(global_iaddr, {5'b00000, Rd, Rm, Rn, 2'b10});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task SUB; // Subtract: SUB Rd, Rm, Rs
        input [2:0] Rd;
        input [2:0] Rm;
        input [2:0] Rs;
        begin
            write_imem(global_iaddr, {5'b00000, Rd, Rm, Rn, 2'b11});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task CMP; // Compare: CMP Rm, Rs
        input [2:0] Rm;
        input [2:0] Rn;
        begin
            write_imem(global_iaddr, {5'b00110, 3'bxxx, Rm, Rn, 2'b01});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task ADDI;// Add Immediate: ADDI Rd, Rm, Imm5
        input [2:0] Rd;
        input [2:0] Rm;
        input [4:0] Imm5;
        begin
            write_imem(global_iaddr, {5'b00111, Rd, Rm, Imm5});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task SUBI;// Substract Immediate: SUBI Rd, Rm, Imm5
        input [2:0] Rd;
        input [2:0] Rm;
        input [4:0] Imm5;
        begin
            write_imem(global_iaddr, {5'b01000, Rd, Rm, Imm5});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task MOV; // Move: MOV Rd, Rm
        input [2:0] Rd;
        input [2:0] Rm;
        begin
            write_imem(global_iaddr, {5'b01011, Rd, Rm, 5'bxxxxx});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task BCC; // Branch if Carry Clear: BCC disp8
        input [7:0] disp8;
        begin
            write_imem(global_iaddr, {6'b110000, 2'b11, disp8});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task BCS; // Branch if Carry Set: BCS disp8
        input [7:0] disp8;
        begin
            write_imem(global_iaddr, {6'b110000, 2'b10, disp8});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task BNE; // Branch if Not Equal: BNE disp8
        input [7:0] disp8;
        begin
            write_imem(global_iaddr, {6'b110000, 2'b01, disp8});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task BEQ; // Branch if Equal: BEQ disp8
        input [7:0] disp8;
        begin
            write_imem(global_iaddr, {6'b110000, 2'b00, disp8});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task BAL; // Branch Always: BAL disp8
        input [7:0] disp8;
        begin
            write_imem(global_iaddr, {6'b110011, 2'b10, disp8});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task JMP; // Jump: JMP label11
        input [10:0] label11;
        begin
            write_imem(global_iaddr, {5'b10000, label11});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task JAL; // Jump and Link: JAL Rd, disp8
        input [2:0] Rd;
        input [7:0] disp8;
        begin
            write_imem(global_iaddr, {5'b10001, Rd, disp8});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task JALR;// Jump and Link Register: JALR Rd, Rm
        input [2:0] Rd;
        input [2:0] Rm;
        begin
            write_imem(global_iaddr, {5'b10010, Rd, Rm, 5'bxxxxx});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task JR;  // Jump Register: JR Rm
        input [2:0] Rd;
        begin
            write_imem(global_iaddr, {5'b10011, Rd, 8'bxxxxxxx});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task OUT; // Output: OUT Rd
        input [2:0] Rm;
        begin
            write_imem(global_iaddr, {5'b11100, 3'bx, Rm, 3'bx, 2'b00});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task HLT; // Halt: HLT
        begin
            write_imem(global_iaddr, {5'b11100, 9'bx, 2'b01});
            global_iaddr = global_iaddr + 1;
        end
    endtask

    //----- Accelerator Assemble language -----//
    task MVM; // Move to Model: MW Rm, Rn (Rm: data, Rn: Acc control)
        input [2:0] Rm;
        input [2:0] Rn;
        begin
            write_imem(global_iaddr, {5'b11111, 3'bxxx, Rm, Rn, 2'bxx});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task DIC; // Read Acc predition: DIC Rd (Rd: reg address)
        input [2:0] Rd;
        begin
            write_imem(global_iaddr, {5'b11110, Rd, 6'bx, 2'bx});
            global_iaddr = global_iaddr + 1;
        end
    endtask
    task NOP; // No Operation: NOP
        begin
            write_imem(global_iaddr, {5'b11101, 11'b0});
            global_iaddr = global_iaddr + 1;
        end
    endtask

	//----- Monitor -----//
	//initial $monitor($realtime,"ns %h %h %h \n", clk_i, rst_n, Out_R, flag_done);
	initial begin
		#500000 $display($realtime,"ns, finish in breakout"); $finish;
	end
	
    //----- Testbench -----//
	initial begin
		//----- CPU Instruction -----//
        global_iaddr = 16'h0000;
        global_daddr = 16'h0000;
        //----- Read Accelerator Instruction, Weight, Activation -----//
        $readmemb("./AccResource/Weight.txt", Acc_Wmem);
        $readmemb("./AccResource/Activation.txt", Acc_Amem);
        $readmemb("./AccResource/Control.txt", Acc_Cmem);
        //----- Load CPU Data Memory -----//
        // DMEM[0:80] = W
        // DMEM[81:728] = A
        // DMEM[729:809] = Control for W
        // DMEM[810] = Control for A
        for (global_daddr = 0; global_daddr < 81; global_daddr = global_daddr + 1) begin
            write_dmem(global_daddr, Acc_Wmem[global_daddr]);
        end
        for (global_daddr = 81; global_daddr < 729; global_daddr = global_daddr + 1) begin
            write_dmem(global_daddr, Acc_Amem[global_daddr - 81]);
        end
        for (global_daddr = 729; global_daddr < 811; global_daddr = global_daddr + 1) begin
            write_dmem(global_daddr, Acc_Cmem[global_daddr - 729]);
        end

        //----- Load CPU Instruction Memory -----//
        // R0: Zero register
        // R1: Weight & Activation address
        // R2: Control address
        // R3: Accelerator Weight & Activation data
        // R4: Accelerator Control data
        // R5: Counter
        // R7: Output register
        LLI(3'd1, 8'b1101_1001);// Load Immediate: LI R1, 729d(Control address)
        LHI(3'd1, 8'b0000_0010);
        LLI(3'd2, 8'b0000_0000);// Load Immediate: LI R2, 0d(Weight address)
        LLI(3'd5, 8'b0101_0000);// Load Immediate: LI R5, 80d(Weight counter)
        
        // Load weight loop body
        LDR(3'd3, 3'd1, 5'd0);  // Load Register: LDR R3, R1, 0d
        LDR(3'd4, 3'd2, 5'd0);  // Load Register: LDR R4, R2, 0d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd1);  // Load Register: LDR R3, R1, 1d
        LDR(3'd4, 3'd2, 5'd1);  // Load Register: LDR R4, R2, 1d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd2);  // Load Register: LDR R3, R1, 2d
        LDR(3'd4, 3'd2, 5'd2);  // Load Register: LDR R4, R2, 2d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd3);  // Load Register: LDR R3, R1, 3d
        LDR(3'd4, 3'd2, 5'd3);  // Load Register: LDR R4, R2, 3d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd4);  // Load Register: LDR R3, R1, 4d
        LDR(3'd4, 3'd2, 5'd4);  // Load Register: LDR R4, R2, 4d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd5);  // Load Register: LDR R3, R1, 5d
        LDR(3'd4, 3'd2, 5'd5);  // Load Register: LDR R4, R2, 5d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd6);  // Load Register: LDR R3, R1, 6d
        LDR(3'd4, 3'd2, 5'd6);  // Load Register: LDR R4, R2, 6d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd7);  // Load Register: LDR R3, R1, 7d
        LDR(3'd4, 3'd2, 5'd7);  // Load Register: LDR R4, R2, 7d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd8);  // Load Register: LDR R3, R1, 8d
        LDR(3'd4, 3'd2, 5'd8);  // Load Register: LDR R4, R2, 8d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd9);  // Load Register: LDR R3, R1, 9d
        LDR(3'd4, 3'd2, 5'd9);  // Load Register: LDR R4, R2, 9d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd10); // Load Register: LDR R3, R1, 10d
        LDR(3'd4, 3'd2, 5'd10); // Load Register: LDR R4, R2, 10d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd11); // Load Register: LDR R3, R1, 11d
        LDR(3'd4, 3'd2, 5'd11); // Load Register: LDR R4, R2, 11d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd12); // Load Register: LDR R3, R1, 12d
        LDR(3'd4, 3'd2, 5'd12); // Load Register: LDR R4, R2, 12d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd13); // Load Register: LDR R3, R1, 13d
        LDR(3'd4, 3'd2, 5'd13); // Load Register: LDR R4, R2, 13d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd14); // Load Register: LDR R3, R1, 14d
        LDR(3'd4, 3'd2, 5'd14); // Load Register: LDR R4, R2, 14d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4
        LDR(3'd3, 3'd1, 5'd15); // Load Register: LDR R3, R1, 15d
        LDR(3'd4, 3'd2, 5'd15); // Load Register: LDR R4, R2, 15d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4

        ADDI(3'd1, 3'd1, 5'd16);// Add Immediate: ADDI R1, R1, 16d
        ADDI(3'd2, 3'd2, 5'd16);// Add Immediate: ADDI R2, R2, 16d
        // Load weight loop condition
        CMP(3'd5, 3'd1);        // Compare: CMP R5, R1
        BNQ(8'b1100_1100);      // Branch NOT Equal: BNQ -52d(Branch to weight loop body)
        // Load the final weight (80th weight)
        LDR(3'd3, 3'd1, 5'd0);  // Load Register: LDR R3, R1, 0d
        LDR(3'd4, 3'd2, 5'd0);  // Load Register: LDR R4, R2, 0d
        MVM(3'd3, 3'd4);        // Move to Model: MW R3, R4

        // Load activation loop condition
        LDR(3'd4, 3'd2, 5'd1);  // Load Register: LDR R4, R2, 1d(control data)
        
        LLI(3'd5, 8'b1101_0001);// Load Immediate: LI R5, 721d(Activation counter)
        LHI(3'd5, 8'b0000_0010);
        LLI(3'd1, 8'd81);       // Load Immediate: LI R1, 81d(Activation address)
        
        LDR(3'd3, 3'd1, 5'd0);  // Load Register: LDR R3, R1, 0d(Activation data)
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd1);  // Load Register: LDR R3, R1, 1d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd2);  // Load Register: LDR R3, R1, 2d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd3);  // Load Register: LDR R3, R1, 3d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd4);  // Load Register: LDR R3, R1, 4d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd5);  // Load Register: LDR R3, R1, 5d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd6);  // Load Register: LDR R3, R1, 6d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd7);  // Load Register: LDR R3, R1, 7d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd8);  // Load Register: LDR R3, R1, 8d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd9);  // Load Register: LDR R3, R1, 9d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd10); // Load Register: LDR R3, R1, 10d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd11); // Load Register: LDR R3, R1, 11d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd12); // Load Register: LDR R3, R1, 12d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd13); // Load Register: LDR R3, R1, 13d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd14); // Load Register: LDR R3, R1, 14d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd15); // Load Register: LDR R3, R1, 15d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4

        ADDI(3'd1, 3'd1, 5'd16);// Add Immediate: ADDI R1, R1, 16d
        // Load weight loop condition
        CMP(3'd5, 3'd1);        // Compare: CMP R5, R1
        BNQ(8'b1101_1101);      // Branch NOT Equal: BNQ -35d(Branch to activation loop body)
        
        // Load the final activation (721~728th activation)
        LDR(3'd3, 3'd1, 5'd0);  // Load Register: LDR R3, R1, 0d(activation data)
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd1);  // Load Register: LDR R3, R1, 1d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd2);  // Load Register: LDR R3, R1, 2d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd3);  // Load Register: LDR R3, R1, 3d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd4);  // Load Register: LDR R3, R1, 4d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd5);  // Load Register: LDR R3, R1, 5d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd6);  // Load Register: LDR R3, R1, 6d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        LDR(3'd3, 3'd1, 5'd7);  // Load Register: LDR R3, R1, 7d
        MVM(3'd3, 3'd4);        // Move to Model: MA R3, R4
        
        // Bubble for prediction
        LLI(3'd5, 8'b0000_0000);// Load Immediate: LI R5, 0d(Bubble cycles)
        LHI(3'd5, 8'b0000_0000);
        NOP;                    // No Operation: NOP
        SUBI(3'd5, 3'd5, 5'd1); // Substrate Immediate: SUBI R5, R5, 1d
        CMP(3'd5, 3'd0);        // Compare: CMP R5, R0
        BNE(8'b1111_1101);      // Branch Not Equal: BNE -3d(Branch to bubble)

        // Read prediction
        DIC(3'd7);              // Read Acc prediction: DIC R7
        OUT(3'd7);              // Output: OUT R7
        HLT;                    // Halt: HLT

		//start
		#(clk_period) ex_iwe = 1'b0;
		#(clk_period) ex_dwe = 1'b0;
		#(clk_period) rst_n = 1'b1;

		wait(flag_done);
		#100 $finish;
	end
endmodule