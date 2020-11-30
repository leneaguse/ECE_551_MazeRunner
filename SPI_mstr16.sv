module SPI_mstr16(rd_data, done, SS_n, SCLK, MOSI, MISO, wrt, clk, rst_n, cmd);

	output reg [15:0] rd_data;
	output logic done, SS_n, SCLK, MOSI;
	input MISO, wrt, clk, rst_n;
	input [15:0] cmd;

	///////////////////////////////
	// Define state as enum type //
	///////////////////////////////
	typedef enum reg {IDLE, ACTIVE} state_t;
	state_t state, next_state;

	logic init, rst_cnt, shift, sample, MISO_smpl, set_done;
	logic [3:0] bit_cnt; 
	logic [5:0] sclk_div;
	logic [15:0] shift_reg;

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

	////////////////////////
	// Infer bit_cnt flop //
	////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n || init) begin
	    	bit_cnt <= 4'hF;						// Preset bit count to 15
	    end
		else if (shift) begin						// Keep track of number of bits shifted
	    	bit_cnt <= bit_cnt - 1;
	    end
	    else begin
	    	bit_cnt <= bit_cnt;
	    end
	end

	/////////////////////////
	// Infer sclk_div flop //
	/////////////////////////
	always_ff @(posedge clk) begin
	    if (rst_cnt) begin							// Reset clk count to create "Front Porch" lasting 16 clk cycles
	    	sclk_div <= 6'b101111;
	    end
		else begin
	    	sclk_div <= sclk_div + 1;				// 64 clk cycles per SCLK period
	    end
	end

	/////////////////////
	// Infer SS_n flop //
	/////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n || set_done) begin				// Preset/Reset SS_n to 1
	    	SS_n <= 1;
	  	end
	  	else if (wrt) begin							// Assert slave select
	    	SS_n <= 0;
	    end
	    else begin									// Hold until set_done
	    	SS_n <= SS_n;
	    end
	end

	/////////////////////
	// Infer SCLK flop //
	/////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n || sample || set_done) begin		// Preset SCLK / SCLK posedge after sclk_div = 6'b011111
			SCLK <= 1;
		end
		else if (init || shift) begin				// SCLK negedge after sclk_div = 6'b111111
		    SCLK <= 0;
		end
		else begin
			SCLK <= SCLK;
		end
	end

	/////////////////////
	// Infer MISO flop //
	/////////////////////
	always_ff @(posedge clk) begin
		if (sample) begin							// Store MISO data at rising edge of SCLK
		    MISO_smpl <= MISO;
		end
		else begin
		    MISO_smpl <= MISO_smpl;
		end
	end

	//////////////////////////
	// Infer shift_reg flop //
	//////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			shift_reg <= 16'hxxxx;
		end
		else if (wrt) begin								// Write command to shift_register
		    shift_reg <= cmd;
		end
		else if (shift) begin
		    shift_reg <= {shift_reg[14:0], MISO_smpl};
		end
		else begin
		    shift_reg <= shift_reg;
		end
	end

	assign MOSI = done ? 1'bx : shift_reg[15];			// Set MOSI to msb of shift register

	/////////////////////
	// Infer done flop //
	/////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n || wrt) begin						// Reset / clear done signal
	    	done <= 0;
	  	end
	  	else if (set_done) begin
	    	done <= 1;
	    end
	    else begin
	    	done <= done;
	    end
	end

	assign rd_data = done ? shift_reg : 16'hxxxx;		// Read data only valid when done is asserted

	/////////////////////////
	// State machine logic //
	/////////////////////////
	always_comb begin
	
		// Default assign all output of SM
		init = 0;
		rst_cnt = 0;
		shift = 0;
		sample = 0;		
		set_done = 0;
		next_state = state;

		case (state)
			IDLE: 		if (wrt) begin
							rst_cnt = 1;
						end
						else if (sclk_div == 6'h3F) begin					// Idle until end of "Front Porch"
							init = 1;
							next_state = ACTIVE;
						end
			default:	if (bit_cnt == 4'h0 && sclk_div == 6'h3F) begin		// Next clk posedge: shift once more and assert done
							shift = 1;
							set_done = 1;
							next_state = IDLE;
						end
						else if (sclk_div == 6'h3F) begin					// Next clk posedge: SCLK has negedge, shift register
							shift = 1;
						end
						else if (sclk_div == 6'h1F) begin					// Next clk posedge: SCLK has posedge, sample MISO
							sample = 1;
						end
		endcase
	end

endmodule