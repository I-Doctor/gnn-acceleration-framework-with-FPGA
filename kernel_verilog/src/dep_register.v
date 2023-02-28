//////////////////////////////////////////////////////////////////////////////// 
// Author: Kai Zhong
// Mail  : zhongkai2020@sina.com
// Date  : 2023.02.01
// Info  : Module of dependency register, P V are 'consume' and 'produce'
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

// dependency register
module dep_register (
  // System Signals
  input wire                                    clk                 ,
  input wire                                    reset               ,
  input wire                                    A_ok                ,
  input wire                                    inst_A_wait_B       ,
  input wire                                    B_state_done        ,
  input wire                                    inst_B_release_A    ,
  output reg [32 -1:0]                          A_after_B_r  
);

wire            A_after_B_P;
wire            A_after_B_V;

assign A_after_B_P  = A_ok & inst_A_wait_B; 
assign A_after_B_V  = B_state_done & inst_B_release_A;

always @(posedge clk) begin
    if (reset) begin
        A_after_B_r <= 0;
    end else if (A_after_B_P & A_after_B_V) begin // must check P and V condition first !
        A_after_B_r <= A_after_B_r;
    end else if (A_after_B_P) begin     // P
        A_after_B_r <= A_after_B_r - 1;
    end else if (A_after_B_V) begin     // V
        A_after_B_r <= A_after_B_r + 1;
    end else begin
        A_after_B_r <= A_after_B_r;
    end
end

endmodule
