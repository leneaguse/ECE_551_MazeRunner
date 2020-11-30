module UART_wrapper_SM(cmd_rdy, clr_rdy, sel, clr_cmd_rdy, rx_rdy, clk, rst_n);

	output reg cmd_rdy, clr_rdy, sel;
	input clr_cmd_rdy, rx_rdy, clk, rst_n;

	reg rx_count;
	logic start, received, set_rdy;

	///////////////////////////////
	// Define state as enum type //
	///////////////////////////////
	typedef enum reg {IDLE, RECEIVE} state_t;
	state_t state, next_state;

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

	/////////////////////////
	// Infer rx_count flop //
	/////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n || start) begin
	    	rx_count <= 0;
	  	end
	  	else if (received) begin
	  		rx_count <= 1;
	  	end
	  	else begin
	    	rx_count <= rx_count;
	    end
	end

	//////////////////////////////////
	// Set sel based on state logic //
	//////////////////////////////////
    assign sel = received ? 1'b0 : 1'b1;	// Creates a 1 clk cycle delay so cmd_rdy is asserted at the same time as cmd is updated

	/////////////////////////
	// Infer cmd_rdy flop //
	/////////////////////////
	always_ff @(posedge clk) begin
		if (start) begin
	    	cmd_rdy <= 0;
	  	end
	  	else if (set_rdy) begin
	  		cmd_rdy <= 1;
	  	end
	  	else begin
	    	cmd_rdy <= cmd_rdy;
	    end
	end

	/////////////////////////
	// State machine logic //
	/////////////////////////
	always_comb begin
		start = 0;
		received = 0;
		set_rdy = 0;

		case (state)
			IDLE:		if (clr_cmd_rdy) begin
							start = 1;
							next_state = RECEIVE;
						end
			default: 	if (rx_rdy && rx_count == 1) begin
							received = 1;
							set_rdy = 1;
							next_state = IDLE;	
						end
						else if (rx_rdy) begin
							received = 1;
						end
		endcase
	end
endmodule