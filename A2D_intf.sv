module A2D_intf(res, cnv_cmplt, SS_n, SCLK, MOSI, MISO, strt_cnv, clk, rst_n, chnnl);

	output [11:0] res;
	output SS_n, SCLK, MOSI;
	output reg cnv_cmplt;
	input MISO, strt_cnv, clk, rst_n;
	input [2:0] chnnl;

	///////////////////////////////
	// Define state as enum type //
	///////////////////////////////
	typedef enum reg [3:0] {IDLE, SEND, WAIT, RECEIVE} state_t;
	state_t state, next_state;

	logic done, wrt, set_cnv_cmplt, write_SPI;
	logic [15:0] rd_data, cmd;

	// Instantiate DP = Data Path //
	SPI_mstr16 iDP(.rd_data(rd_data), .done(done), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .clk(clk), .rst_n(rst_n), .cmd(cmd));

	//////////////////////
	// Infer state flop //
	//////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
	    	state <= IDLE;
	  	end
	  	else begin
	    	state <= next_state;
	    end
	end

	////////////////////
	// Infer wrt flop //
	////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
	    	wrt <= 1'b0;
	  	end
	  	else if (write_SPI) begin
	    	wrt <= 1'b1;
	    end
	    else begin
	    	wrt <= 1'b0;
	    end
	end

	//////////////////////////
	// Infer cnv_cmplt flop //
	//////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
	    	cnv_cmplt <= 1'b0;
	  	end
	  	else if (strt_cnv) begin
			cnv_cmplt <= 1'b0;
		end
		else if (set_cnv_cmplt) begin
			cnv_cmplt <= 1'b1;
		end
	end

	assign cmd[15:0] = {2'b00, chnnl[2:0], 11'h000};
	assign res[11:0] = {12{1'b1}}^{rd_data[11:0]};

	/////////////////////////
	// State machine logic //
	/////////////////////////
	always_comb begin
	
		// Default assign all output of SM
		write_SPI = 0;
		set_cnv_cmplt = 0;
		next_state = state;

		case (state)
			IDLE: 		if (strt_cnv) begin
							write_SPI = 1;
							next_state = SEND;
						end
			SEND: 		if (done && wrt == 1'b0) begin
							next_state = WAIT;
						end
			WAIT: 		begin
							write_SPI = 1;
							next_state = RECEIVE;
						end
			default:	if (done && wrt == 1'b0) begin
							set_cnv_cmplt = 1;
							next_state = IDLE;
						end
		endcase
	end
endmodule