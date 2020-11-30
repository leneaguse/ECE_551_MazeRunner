module UART();

	output TX, tx_done, rdy;
	output [7:0] rx_data;
	input RX, clr_rdy, clk, rst_n, trmt;
	input [7:0] tx_data;

	// Instantiate UART transmitter //
	UART_tx iDUT1(.TX(TX), .tx_done(tx_done), .clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data));

	// Instantiate UART receiver //
	UART_rcv iDUT2(.rx_data(rx_data), .rdy(rdy), .clr_rdy(clr_rdy), .RX(TX), .clk(clk), .rst_n(rst_n));

endmodule