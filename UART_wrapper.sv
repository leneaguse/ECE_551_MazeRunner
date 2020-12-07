module UART_wrapper(clk, rst_n, clr_cmd_rdy, RX, cmd_rdy, cmd);
  input clk, rst_n;
  input clr_cmd_rdy, RX;
  output reg cmd_rdy;
  output [15:0] cmd;

  reg [7:0] rx_data;

  //Initialize varibles to store values
  reg sel;
  reg [7:0] upper_data;

  UART_rcv  iReceiver(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_cmd_rdy), .rx_data(rx_data), .rdy(rx_rdy));

  //Define states
  typedef enum logic [1:0] {IDLE, LOWER_BYTE, UPPER_BYTE} state_t;

  //Initialize the current state the next state
  state_t state, nxt_state;


  assign cmd = {upper_data,rx_data};

  //infer state flops
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end

  always_comb begin         
    cmd_rdy = 0;
    sel = 0;
    nxt_state = state;

    case(state)
      IDLE:
        if (rx_rdy) begin
	  sel = 1;
          nxt_state = UPPER_BYTE;
        end
      UPPER_BYTE: //rx_rdy is still being held high and there isn't a chance for the second set of data to come in
        if (rx_rdy) begin
	  sel = 1; 
          cmd_rdy = 1;
          nxt_state = LOWER_BYTE;
        end 
      default: begin
        nxt_state = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk)
    if (sel)
      upper_data <= rx_data;

endmodule 
