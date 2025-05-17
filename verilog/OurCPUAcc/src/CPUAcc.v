`include "./src/Single_Cycle_CPU.v"
`include "./src/conv.v"
module CPUAcc #(
    parameter DATAWIDTH = 16
) (
    // I/O Ports Declaration
    input           clk_i,         // System clock
    input           rst_n,         // All reset
    output [16-1:0] Out_R,
    output          flag_done,

    input           ex_iwe,
    input  [16-1:0] ex_iaddr,
    input  [16-1:0] ex_idata,
    input           ex_dwe,
    input  [16-1:0] ex_daddr,
    input  [16-1:0] ex_ddata
);
    // New for Dot Product
    wire signed [3:0] predict;
    wire signed [16-1:0] Rn;
    wire signed [16-1:0] Rm;
    wire                 rst = ~rst_n;
    wire acc_done;

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
        .predict(predict),
        .acc_done(acc_done),
        .Rm(Rm),
        .Rn(Rn)
	);
	
	conv u_Acc(
		.clk_i(clk_i),
		.rst(rst),
		.Rm(Rm),
		.Rn(Rn),
		.max_index(predict),
        .done(acc_done)
	);


endmodule