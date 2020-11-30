module UART_wrapper(cmd, cmd_rdy, clr_cmd_rdy, RX, clk, rst_n);

	output [15:0] cmd;
	output cmd_rdy;
	input clr_cmd_rdy, RX, clk, rst_n;

	logic sel, rx_rdy, clr_rdy;
	logic [7:0] rx_data, d, q;

	// Instantiate SM = State Machine //
	UART_wrapper_SM iSM(.cmd_rdy(cmd_rdy), .clr_rdy(clr_rdy), .sel(sel), .clr_cmd_rdy(clr_cmd_rdy), .rx_rdy(rx_rdy), .clk(clk), .rst_n(rst_n));

	// Instantiate DP = Data Path //
	UART_rcv iDP(.clk(clk), .rst_n(rst_n), .RX(RX), .rdy(rx_rdy), .rx_data(rx_data), .clr_rdy(clr_rdy));

	assign d[7:0] = sel ? rx_data[7:0] : q[7:0];
	
	//////////////////////////
	// Infer cmd[15:8] flop //
	//////////////////////////
	always_ff @(posedge clk) begin
		q <= d;
	end

	//////////////////////////////////
	// Set cmd based on flop output //
	//////////////////////////////////
	assign cmd[15:0] = {q[7:0], rx_data[7:0]};

endmodule