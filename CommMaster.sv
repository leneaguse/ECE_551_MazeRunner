module CommMaster(clk, rst_n, TX, snd_cmd, cmd, cmd_cmplt);

	output cmd_cmplt, TX;
	input [15:0] cmd;
	input snd_cmd, clk, rst_n;

	logic [7:0] tx_data, mux_in;
	logic sel, trmt, tx_done;

	// Instantiate SM = State Machine //
	Control_SM iSM(.frm_cmplt(cmd_cmplt), .trmt(trmt), .sel(sel), .tx_done(tx_done), .snd_frm(snd_cmd), .clk(clk), .rst_n(rst_n));

	// Instantiate DP = Data Path //
	UART_tx iDP(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));


	// Initialize SM & DP Stimulus //

	///////////////////////
	// Infer mux_in flop //
	///////////////////////
	always_ff @(posedge clk) begin
		if (snd_cmd) begin
	    		mux_in <= cmd[7:0];
	  	end
	  	else begin
	    		mux_in <= mux_in;
	    	end
	end

	//////////////////////////////////////
	// Set tx_data based on flop output //
	//////////////////////////////////////
	assign tx_data[7:0] = sel ? cmd[15:8] : mux_in[7:0];

endmodule
