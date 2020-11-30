module err_compute_SM(err_vld, en_accum, clr_accum, sel, clk, rst_n, IR_vld);

	output logic err_vld, en_accum, clr_accum;
	output [2:0] sel;
	input clk, rst_n, IR_vld;

	reg [3:0] count;
	logic set_done, en, clr;
	
	typedef enum reg {IDLE, COMPUTE} state_t;
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

	//////////////////////
	// Infer count flop //
	//////////////////////
	always_ff @(posedge clk) begin
		if (clr) begin
			count <= 3'b000;
		end
		else if (en) begin
			count <= count + 1'b1;
		end
		else begin
			count <= count;
		end
	end

	//////////////////////////////////////
	// Set outputs based on state logic //
	//////////////////////////////////////
	assign sel[2:0] = count;
	assign clr_accum = clr;
	assign en_accum = en;
	assign err_vld = set_done;

	/////////////////////////
	// State machine logic //
	/////////////////////////
	always_comb begin
		set_done = 0;
		en = 0;
		clr = 0;
		next_state = state;

		case (state)
			IDLE:		if (IR_vld) begin
							clr = 1;
							next_state = COMPUTE;
						end
			default: 	if (count == 8) begin
							set_done = 1;
							next_state = IDLE;	
						end
						else begin 
							en = 1;
						end
		endcase
	end

endmodule