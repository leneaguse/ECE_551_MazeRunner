module err_compute(error, err_vld, IR_R0, IR_R1, IR_R2, IR_R3, IR_L0, IR_L1, IR_L2, IR_L3, clk, rst_n, IR_vld);

	output [15:0] error;
	output err_vld;
	input [11:0] IR_R0, IR_R1, IR_R2, IR_R3;
	input [11:0] IR_L0, IR_L1, IR_L2, IR_L3;
	input clk, rst_n, IR_vld;

	logic en_accum, clr_accum;
	logic [2:0] sel;

	// Instantiate SM = State Machine //
    err_compute_SM iSM(.err_vld(err_vld), .en_accum(en_accum), .clr_accum(clr_accum),
    					.sel(sel), .clk(clk), .rst_n(rst_n), .IR_vld(IR_vld));
	
	// Instantiate DP = Data Path //
	err_compute_DP iDP(.clk(clk), .en_accum(en_accum), .clr_accum(clr_accum), .sub(sel[0]),
                    	.sel(sel), .IR_R0(IR_R0), .IR_R1(IR_R1), .IR_R2(IR_R2), .IR_R3(IR_R3),
                    	.IR_L0(IR_L0), .IR_L1(IR_L1), .IR_L2(IR_L2), .IR_L3(IR_L3), .error(error));

    

endmodule