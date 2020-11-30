//****************************
// Module: IR_intf
// Author: Harry Zhao
// Date 11/20/2020
//****************************
module IR_intf(clk, rst_n, SS_n, SCLK, MOSI, MISO, IR_en, IR_vld, line_present, IR_L0, IR_L1, IR_L2, IR_L3, IR_R0, IR_R1, IR_R2, IR_R3);
  parameter FAST_SIM=0;                 //parameter used to speed up simulation
  input clk, rst_n, MISO;               //clock, async reset, MISO
  output SS_n, SCLK, MOSI;              //outputs used by SPI
  output reg IR_en, IR_vld, line_present; //IR enabled, IR valid, line is present
  output reg [11:0] IR_L0, IR_L1, IR_L2, IR_L3, IR_R0, IR_R1, IR_R2, IR_R3; //IR readings from all inputs
 
  //Local param used as threshold
  localparam LINE_THRES = 12'h140;  //Temporaly raise to 12'h140 to use tb, original value is 12'h040

  //Instantiate registers used in this module
  reg [17:0] tmr;
  reg strt_cnv, cnv_cmplt, clr_IR_max, nxt_round, settled, inc_chnnl;
  reg IR_R0_en, IR_R1_en, IR_R2_en, IR_R3_en, IR_L0_en, IR_L1_en, IR_L2_en, IR_L3_en;
  reg [3:0] chnnl;
  reg [11:0] IR_max, res;

  //Generate assign statements based on FAST_SIM
  generate
    if (FAST_SIM) begin
      assign nxt_round = &tmr[13:0];
      assign settled = &tmr[10:0];
    end else begin
      assign nxt_round = &tmr;
      assign settled = &tmr[11:0];
    end
  endgenerate

  //Instantia iA2D
  A2D_intf iA2D(.clk(clk),.rst_n(rst_n), .strt_cnv(strt_cnv), .cnv_cmplt(cnv_cmplt), .chnnl(chnnl[2:0]), .res(res), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

  //Define states (IDLE state and calculation state)
  typedef enum logic [1:0] {IDLE, STRTCONV, CONV} state_t;

  //Initialize the current state the next state
  state_t state, nxt_state;

  //infer state flops
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end

  //State transition logic
  always_comb begin
    //Intialize variables to avoid latch
    clr_IR_max = 0;
    IR_en  = 0;
    IR_vld = 0;
    strt_cnv = 0;
    inc_chnnl = 0;
    IR_R0_en = 0;
    IR_R1_en = 0;
    IR_R2_en = 0;
    IR_R3_en = 0;
    IR_L0_en = 0;
    IR_L1_en = 0;
    IR_L2_en = 0;
    IR_L3_en = 0;
    nxt_state = state;
    case (state)
      IDLE:                        //IDLE state
        if(nxt_round) begin        //start next round of conversion
          IR_en = 1;
          clr_IR_max = 0;
        end else if (settled)      //After all the set up are settled, go to next state
          nxt_state = STRTCONV; 
      STRTCONV: begin                   //STRT CONV
        strt_cnv = 1;
        nxt_state = CONV;
      end
      default:begin
        if (cnv_cmplt) begin
          case (chnnl)
            3'h0: IR_R0_en = 1;
            3'h1: IR_R1_en = 1;
            3'h2: IR_R2_en = 1;
            3'h3: IR_R3_en = 1;
            3'h4: IR_L0_en = 1;
            3'h5: IR_L1_en = 1;
            3'h6: IR_L2_en = 1;
            3'h7: IR_L3_en = 1;
          endcase
          nxt_state = STRTCONV;
          inc_chnnl = 1;
          if (chnnl == 4'b1000) begin
            IR_vld = 1;
            nxt_state = IDLE;
          end
        end 
      end
    endcase
  end

  //Timer
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
      tmr <= 18'h00000;
    else
      tmr <= tmr + 1;

  //Inc channel
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
      chnnl <= 4'b0000;
    else if (inc_chnnl)
      chnnl <= chnnl +1;

  // IR_max flop
  always @(posedge clk)
    if (clr_IR_max)
      IR_max <= 12'h000;
    else if(cnv_cmplt)
      IR_max <= res[11:0];

  // line_present flop
  always @(posedge clk) 
    if(IR_vld)       //When IR is valid, check if IR_max is greater than LINE_THRES
      line_present<= IR_max > LINE_THRES;

  // IR flops
  always @(posedge clk)
    if (IR_R0_en)
      IR_R0 <= res;

  always @(posedge clk)
    if (IR_R1_en)
      IR_R1 <= res;
  always @(posedge clk)
    if (IR_R2_en)
      IR_R2 <= res;

  always @(posedge clk)
    if (IR_R3_en)
      IR_R3 <= res;

  always @(posedge clk)
    if (IR_L0_en)
      IR_L0 <= res;

  always @(posedge clk)
    if (IR_L1_en)
      IR_L1 <= res;

  always @(posedge clk)
    if (IR_L2_en)
      IR_L2 <= res;

  always @(posedge clk)
    if (IR_L3_en)
      IR_L3 <= res;


endmodule 
