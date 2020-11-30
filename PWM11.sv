module PWM11(PWM_sig, duty, rst_n, clk);

	output reg PWM_sig;
	input [10:0] duty;
	input rst_n, clk;

	reg [11:0] cnt;

	always_ff @(posedge clk, negedge rst_n) begin
	
		if (!rst_n) begin
			cnt <= 11'h000;
			PWM_sig <= 1'b0;
		end
		else if (cnt == 2048) begin
			cnt <= 12'h000;
			PWM_sig <= 1'b0;
		end
		else begin
			cnt <= cnt + 1;
			PWM_sig <= (cnt < duty) ? 1'b1 : 1'b0;
		end
	end

endmodule