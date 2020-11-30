//****************************
// Module: cmd_proc_SM
// Author: Harry Zhao
// Date 11/30/2020
//****************************
module cmd_proc(clk, rst_n, line_present, RX, go, err_opn_lp, BMPL_n, BMPR_n, buzz);
  parameter FAST_SIM=0;  //parameter used to speed up simulation
  input clk, rst_n, line_present, RX;
  input BMPL_n, BMPR_n;
  output go, buzz;
  output [15:0] err_opn_lp;



  wire [15:0] cmd;
  reg last_veer_rght;
  reg [15:0] cmd_reg;
  reg [25:0] tmr;
  
  UART_wrapper iWrapper(.clk(clk), .rst_n(rst_n), .clr_cmd_rdy(cap_cmd), .RX(RX), .cmd_rdy(cmd_rdy), .cmd(cmd));
  cmd_proc_SM #(FAST_SIM) iCmdProcSM(.clk(clk), .rst_n(rst_n), .last_veer_rght(last_veer_rght), .line_present(line_present), .cmd_rdy(cmd_rdy), 
                         .tmr(tmr), .cmd_reg(cmd_reg[1:0]), .nxt_cmd(nxt_cmd), .cap_cmd(cap_cmd), .err_opn_lp(err_opn_lp), .go(go));

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      last_veer_rght <= 1'b0;   //default
    else if (nxt_cmd)
      last_veer_rght <= cmd_reg[0]; 

  always_ff @(posedge clk)
    if(nxt_cmd)
      cmd_reg <= {2'b00,cmd[15:2]};  //Shift command
    else if (cap_cmd)
      cmd_reg <= cmd;

  always_ff @(posedge clk)
    if (go)      //clr signal
      tmr <= 26'h0000000;
    else
      tmr <= tmr +1;


endmodule
