//****************************
// Module: cmd_proc_SM
// Author: Harry Zhao
// Date 11/30/2020
//****************************
module cmd_proc_SM(clk, rst_n, last_veer_rght, line_present, cmd_rdy, tmr, cmd_reg, nxt_cmd, cap_cmd, err_opn_lp, go, BMPL_n, BMPR_n, buzz);
  parameter FAST_SIM=0;  //parameter used to speed up simulation
  input clk, rst_n;
  input last_veer_rght,cmd_rdy, line_present, BMPL_n, BMPR_n;
  input [1:0] cmd_reg;
  input [25:0] tmr;
  output reg nxt_cmd, cap_cmd, go, buzz;
  output [15:0] err_opn_lp;

  wire REV_tmr1, REV_tmr2, BMP_DBNC_tmr;
  reg turn90_en, turn270_en, turn_en;
  //Generate difference assignment statements to accelerate simulation
  generate
    if (FAST_SIM) begin
      assign REV_tmr1 = tmr[20:16] == 5'h0A;
      assign REV_tmr2 = tmr[20:16] == 5'h10;
      assign BMP_DBNC_tmr = &tmr[16:0];
    end else begin
      assign REV_tmr1 = tmr[20:16] == 5'h16;
      assign REV_tmr2 = tmr[20:16] == 5'h1F;
      assign BMP_DBNC_tmr = &tmr[21:0];
    end
  endgenerate

  //negative is turning left
  assign err_opn_lp = (turn_en && cmd_reg == 2'b10) ? -16'h0340 :
                      (turn_en && cmd_reg == 2'b01) ? 16'h0340  :
                      (turn90_en && last_veer_rght) ? -16'h01E0:
                      (turn90_en) ? 16'h01E0                    :
                      (turn270_en && last_veer_rght) ? 16'h0380:
                      (turn270_en) ? -16'h0380                  : 16'h0000;

  //Define states
  typedef enum logic [3:0] {IDLE, WAIT, TURN90, TURN270, WAITLINE, TURN,SHIFT, BUZZWAIT, BUZZ} state_t;

  //Initialize the current state the next state
  state_t state, nxt_state;

  //infer state flops
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end

  always_comb begin
    nxt_state = state;
    go = 1;
    turn90_en = 0;
    turn270_en = 0;
    nxt_cmd = 0;
    turn_en = 0;
    buzz = 1;
    case(state)
      IDLE:
        if(cmd_rdy && line_present)begin
          nxt_state =  WAIT;  //wait for break
        end else go =0;
      WAIT: begin
        if(!line_present)
          if (cmd_reg==2'b11) begin
            go = 0;
            nxt_state = TURN90;
          end else if(|cmd_reg) begin
            go = 1;
            nxt_state = TURN;
          end
        else if (!BMPL_n || !BMPR_n) begin//Execute A here
          go=0;
          nxt_state = BUZZ;
          buzz = 1;
        end
      end
      TURN90:
        if(REV_tmr1)begin
          go = 0;
          nxt_state = TURN270;
        end else turn90_en =1;
      TURN270:
        if(REV_tmr2)
          nxt_state = WAITLINE;
        else turn270_en = 1;
      WAITLINE:
        if(line_present)
          nxt_state = SHIFT;
      SHIFT: begin
        nxt_cmd =1;
        nxt_state = WAIT;
      end
      TURN:begin
        if(line_present)
          nxt_state = SHIFT;
        else
          turn_en = 1;
      end
      BUZZWAIT: begin
        buzz =1;
        if (BMP_DBNC_tmr) 
          nxt_state = BUZZ;
      end
      default:     //BUZZ state
        if (BMPL_n && BMPR_n)
          nxt_state = WAIT;
        else
          buzz = 1;
    endcase
  end


endmodule
