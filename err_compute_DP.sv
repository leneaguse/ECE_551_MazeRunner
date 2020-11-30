module err_compute_DP(clk,en_accum,clr_accum,sub,sel,IR_R0,IR_R1,IR_R2,IR_R3,IR_L0,IR_L1,IR_L2,IR_L3,error);
  
  input clk;					               		// 50MHz clock
  input en_accum,clr_accum;             // accumulator control signals
  input sub;                  					// If asserted we subtract IR reading
  input [2:0] sel;						          // mux select for operand
  input [11:0] IR_R0,IR_R1,IR_R2,IR_R3; // Right IR readings from inside out
  input [11:0] IR_L0,IR_L1,IR_L2,IR_L3; // Left IR reading from inside out
  output reg signed [15:0] error;     	// Error in line following, goes to PID
  
  reg signed [15:0] next_error;
  logic [15:0] op_in;
  logic [15:0] mux_out;

  assign mux_out = sel[2] ? (sel[1] ? (sel[0] ? {1'b0, IR_L3, 3'h0} : {1'b0, IR_R3, 3'h0}) :      // sel = 7 or 6
                                      (sel[0] ? {2'h0, IR_L2, 2'h0} : {2'h0, IR_R2, 2'h0})) :     // sel = 5 or 4
                            (sel[1] ? (sel[0] ? {3'h0, IR_L1, 1'b0} : {3'h0, IR_R1, 1'b0}) :      // sel = 3 or 2
                                      (sel[0] ? {4'h0, IR_L0} : {4'h0, IR_R0}));                  // sel = 1 or 0

  assign op_in = sub ? {16{sub}}^mux_out : mux_out;
  assign next_error = error + op_in + sub;

  /////////////////////////////////
  // Implement error accumulator //
  /////////////////////////////////
  always_ff @(posedge clk)
    if (clr_accum)
	  error <= 16'h0000;
	else if (en_accum)
	  error <= next_error; 

endmodule