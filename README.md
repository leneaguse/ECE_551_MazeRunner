# ECE_551_MazeRunner
Project Team Latches - Group members:
  Harry Zhao, Kritarth Vyas, Lenea Guse, and Nathan Husemoller

## Action Items:
  * Commit missing files: mtr_drv.sv, PID.sv (and dependent files if any)
  * Complete sub-modules
    * cmd_proc:
      1. Write cmd_proc_tb.sv
      11. Validate simulation
      111. Successfully synthesize module
    * CommMaster:
      1. Complete CommTB.sv
      11. Validate simulation
      111. Successfully synthesize module
    * SPI_mstr16:
      1. Successfully synthesize module
  * Validate project
    1. Complete MazeRunner_tb.sv
    11. Validate simulation
    111. Write synthesis script and successfully synthesize project
  
## Control Flow:
  _file_ -> _dependent files_
  MazeRunner_tb.sv -> MazeRunner.sv MazePhysics.sv CommMaster.sv -> Control_SM.sv UART_tx.sv
                      MazeRunner.sv -> mtr_drv.sv IR_intf.sv err_compute.sv PID.sv cmd_proc.sv
                                       mtr_drv.sv -> PWM11.sv
                                                  IR_intf.sv -> A2D_intf.sv -> SPI_mstr16.sv
                                                             err_compute.sv -> err_compute_SM.sv err_compute_DP.sv
                                                                                   cmd_proc.sv -> UART_wrapper.sv cmd_proc_SM.sv
                                                                                                  UART_wrapper.sv -> UART_rcv.sv UART_wrapper_SM.sv
