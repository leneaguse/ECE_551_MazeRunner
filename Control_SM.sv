module Control_SM(frm_cmplt, trmt, sel, tx_done, snd_frm, clk, rst_n);

	output reg frm_cmplt, trmt, sel;
	input tx_done, snd_frm, clk, rst_n;

	reg tx_count;
	logic start, sent, set_cmplt;

	///////////////////////////////
	// Define state as enum type //
	///////////////////////////////
	typedef enum reg {IDLE, TRANS} state_t;
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
	// Infer tx_count flop //
	/////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n || start) begin
	    		tx_count <= 0;
	  	end
	  	else if (sent) begin
	  		tx_count <= 1;
	  	end
	  	else begin
	    		tx_count <= tx_count;
	    end
	end

	/////////////////////
	// Infer trmt flop //
	/////////////////////
	always_ff @(posedge clk) begin
		if (start) begin
	    		trmt <= 1;
	  	end
	  	else begin
	  		trmt <= 0;
	  	end
	end

	////////////////////
	// Infer sel flop //
	////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
    	if (!rst_n || start) begin
    		sel <= 1;
    	end 
    	else if (sent) begin
    		sel <= 0;
    	end
    	else begin
    		sel <= sel;
    	end
    end

    //assign sel = sent ? 1'b0 : 1'b1;

	//////////////////////////
	// Infer frm_cmplt flop //
	//////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n || start) begin
	    		frm_cmplt <= 0;
	  	end
	  	else if (set_cmplt) begin
	  		frm_cmplt <= 1;
	  	end
	  	else begin
	    		frm_cmplt <= frm_cmplt;
	    	end
	end

	/////////////////////////
	// State machine logic //
	/////////////////////////
	always_comb begin
		start = 0;
		sent = 0;
		set_cmplt = 0;
		next_state = state;

		case (state)
			IDLE:		if (snd_frm) begin
							start = 1;
							next_state = TRANS;
						end
			default: 	if (tx_done & tx_count) begin
							set_cmplt = 1;
							next_state = IDLE;	
						end
						else if (tx_done) begin
							sent = 1;
						end
		endcase
	end
endmodule
