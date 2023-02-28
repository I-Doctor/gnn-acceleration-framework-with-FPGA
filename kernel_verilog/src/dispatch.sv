//////////////////////////////////////////////////////////////////////////////// 
// Author: Kai Zhong
// Mail  : zhongkai2020@sina.com
// Date  : 2023.02.01
// Info  : Module of dispatch unit of each type of instructions
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

// dependency register
module dispatch #(
    parameter integer INST_BIT_WIDTH      = 128,
    parameter integer FIFO_DEPTH          = 32,
    parameter integer FIFO_DATA_WIDTH     = 128,
    parameter integer FIFO_COUNT_WIDTH    = 6,
    parameter integer FIFO_READ_LATENCY   = 1,
    parameter integer a_BIT_ID            = 26,
    parameter integer b_BIT_ID            = 25,
    parameter integer c_BIT_ID            = 24,
    parameter integer d_BIT_ID            = 23,
    parameter integer e_BIT_ID            = 22
)
(
  // System Signals
  input  wire                                   clk                 ,
  input  wire                                   reset               ,
  // write fifo
  input  wire                                   A_fifo_wren         ,
  input  wire  [INST_BIT_WIDTH -1:0]            instruction         ,
  // fifo state output
  output wire                                   A_full              ,
  output wire                                   A_empty             ,
  // other register input
  input  wire [32 -1:0]                         A_after_a_r         ,
  input  wire [32 -1:0]                         A_after_b_r         ,
  input  wire [32 -1:0]                         A_after_c_r         ,
  input  wire [32 -1:0]                         A_after_d_r         ,
  input  wire [32 -1:0]                         A_after_e_r         ,
  output wire                                   A_ok                ,
  // dispatch output and feedback
  output wire                                   valid_to_A          ,
  output wire [INST_BIT_WIDTH -1:0]             instruction_to_A    ,
  input  wire                                   done_from_A         ,
  // FSM state output
  output reg  [3 -1:0]                          A_state_r
);

// dispatch FSM states
localparam IDL    = 3'b000;
localparam RDF    = 3'b001;
localparam DEP    = 3'b010;
localparam ISS    = 3'b011;
localparam RUN    = 3'b100;
localparam DON    = 3'b101;

// FSM state
logic [3 -1:0] A_next_state;

// control logic signals
logic   A_rd_en;
logic   rd_A_valid;     // output valid signal generated by fifo, can be use for check
logic   A_after_a_ok;
logic   A_after_b_ok;
logic   A_after_c_ok;
logic   A_after_d_ok;
logic   A_after_e_ok;

// dispatch logic of A moudule
// fifo
xpm_fifo_sync # (
    .FIFO_MEMORY_TYPE    ( "auto"            ) , // string; "auto", "block", "distributed", or "ultra";
    .ECC_MODE            ( "no_ecc"          ) , // string; "no_ecc" or "en_ecc";
    .FIFO_WRITE_DEPTH    ( FIFO_DEPTH        ) , // positive integer
    .WRITE_DATA_WIDTH    ( FIFO_DATA_WIDTH   ) , // positive integer
    .WR_DATA_COUNT_WIDTH ( FIFO_COUNT_WIDTH  ) , // positive integer, not used
    .PROG_FULL_THRESH    ( 10                ) , // positive integer
    .FULL_RESET_VALUE    ( 1                 ) , // positive integer; 0 or 1
    .USE_ADV_FEATURES    ( "1F1F"            ) , // string; "0000" to "1F1F";
    .READ_MODE           ( "std"             ) , // string; "std" or "fwft";
    .FIFO_READ_LATENCY   ( FIFO_READ_LATENCY ) , // positive integer;
    .READ_DATA_WIDTH     ( FIFO_DATA_WIDTH   ) , // positive integer
    .RD_DATA_COUNT_WIDTH ( FIFO_COUNT_WIDTH  ) , // positive integer, not used
    .PROG_EMPTY_THRESH   ( 10                ) , // positive integer, not used
    .DOUT_RESET_VALUE    ( "0"               ) , // string, don't care
    .WAKEUP_TIME         ( 0                 ) // positive integer; 0 or 2;
) inst_fifo_A (
    .sleep         ( 1'b0                   ) ,
    .rst           ( reset                  ) ,
    .wr_clk        ( clk                    ) ,
    .wr_en         ( A_fifo_wren            ) ,
    .din           ( instruction            ) ,
    .prog_full     ( A_full                 ) ,
    .rd_en         ( A_rd_en                ) ,
    .dout          ( instruction_to_A       ) ,
    .empty         ( A_empty                ) ,
    .data_valid    ( rd_A_valid             ) ,
    .injectsbiterr ( 1'b0                   ) ,
    .injectdbiterr ( 1'b0                   )
) ;

// FSM logic of A module
always @(posedge clk) begin
    if (reset) begin
        A_state_r <= 0;
    end else begin
        A_state_r <= A_next_state;
    end
end
always @(*) begin
    case (A_state_r) 
        IDL: begin
            A_next_state = (~A_empty) ? RDF : IDL;        // read fifo if idle and not empty 
        end
        RDF: begin
            A_next_state = DEP;                           // read fifo then come into dependency check state 
        end
        DEP: begin
            A_next_state = (A_ok) ? ISS : DEP;            // issue the instruction if ok
        end
        ISS: begin
            A_next_state = RUN;                           // running after issue
        end
        RUN: begin
            A_next_state = (done_from_A) ? DON : RUN;     // come to done state if return done signal
        end
        DON: begin
            A_next_state = (~A_empty) ? RDF : IDL;        // read fifo derectly if not empty or come to idle
        end
    endcase
end
// dispatch of A instruction
assign A_rd_en      = (A_state_r == RDF) ? 1'b1: 1'b0;  // only read fifo at RDF stage, instruction will show on dout next cycle (DEP state)
assign valid_to_A   = (A_state_r == ISS) ? 1'b1: 1'b0;  // issue instruction at ISS stage by valid signal
// check dependency for A; a,b,c,d,e are other five modules
assign A_after_a_ok = (~instruction_to_A[a_BIT_ID]) | (instruction_to_A[a_BIT_ID]&(A_after_a_r>0));
assign A_after_b_ok = (~instruction_to_A[b_BIT_ID]) | (instruction_to_A[b_BIT_ID]&(A_after_b_r>0));
assign A_after_c_ok = (~instruction_to_A[c_BIT_ID]) | (instruction_to_A[c_BIT_ID]&(A_after_c_r>0));
assign A_after_d_ok = (~instruction_to_A[d_BIT_ID]) | (instruction_to_A[d_BIT_ID]&(A_after_d_r>0));
assign A_after_e_ok = (~instruction_to_A[e_BIT_ID]) | (instruction_to_A[e_BIT_ID]&(A_after_e_r>0));
assign A_ok         = (A_after_a_ok)&(A_after_b_ok)&(A_after_c_ok)&(A_after_d_ok)&(A_after_e_ok)&(A_state_r == DEP);

endmodule