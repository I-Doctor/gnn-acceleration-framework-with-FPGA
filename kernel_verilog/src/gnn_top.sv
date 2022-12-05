// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module gnn_0_example #(
  parameter integer C_INST_ADDR_WIDTH    = 64 ,
  parameter integer C_INST_DATA_WIDTH    = 512,
  parameter integer C_WEIGHT_ADDR_WIDTH  = 64 ,
  parameter integer C_WEIGHT_DATA_WIDTH  = 512,
  parameter integer C_FEATURE_ADDR_WIDTH = 64 ,
  parameter integer C_FEATURE_DATA_WIDTH = 512,
  parameter integer C_OUT_ADDR_WIDTH     = 64 ,
  parameter integer C_OUT_DATA_WIDTH     = 512
)
(
  // System Signals
  input  wire                              ap_clk         ,
  input  wire                              ap_rst_n       ,
  // AXI4 master interface inst
  output wire                              inst_awvalid   ,
  input  wire                              inst_awready   ,
  output wire [C_INST_ADDR_WIDTH-1:0]      inst_awaddr    ,
  output wire [8-1:0]                      inst_awlen     ,
  output wire                              inst_wvalid    ,
  input  wire                              inst_wready    ,
  output wire [C_INST_DATA_WIDTH-1:0]      inst_wdata     ,
  output wire [C_INST_DATA_WIDTH/8-1:0]    inst_wstrb     ,
  output wire                              inst_wlast     ,
  input  wire                              inst_bvalid    ,
  output wire                              inst_bready    ,
  output wire                              inst_arvalid   ,
  input  wire                              inst_arready   ,
  output wire [C_INST_ADDR_WIDTH-1:0]      inst_araddr    ,
  output wire [8-1:0]                      inst_arlen     ,
  input  wire                              inst_rvalid    ,
  output wire                              inst_rready    ,
  input  wire [C_INST_DATA_WIDTH-1:0]      inst_rdata     ,
  input  wire                              inst_rlast     ,
  // AXI4 master interface weight
  output wire                              weight_awvalid ,
  input  wire                              weight_awready ,
  output wire [C_WEIGHT_ADDR_WIDTH-1:0]    weight_awaddr  ,
  output wire [8-1:0]                      weight_awlen   ,
  output wire                              weight_wvalid  ,
  input  wire                              weight_wready  ,
  output wire [C_WEIGHT_DATA_WIDTH-1:0]    weight_wdata   ,
  output wire [C_WEIGHT_DATA_WIDTH/8-1:0]  weight_wstrb   ,
  output wire                              weight_wlast   ,
  input  wire                              weight_bvalid  ,
  output wire                              weight_bready  ,
  output wire                              weight_arvalid ,
  input  wire                              weight_arready ,
  output wire [C_WEIGHT_ADDR_WIDTH-1:0]    weight_araddr  ,
  output wire [8-1:0]                      weight_arlen   ,
  input  wire                              weight_rvalid  ,
  output wire                              weight_rready  ,
  input  wire [C_WEIGHT_DATA_WIDTH-1:0]    weight_rdata   ,
  input  wire                              weight_rlast   ,
  // AXI4 master interface feature
  output wire                              feature_awvalid,
  input  wire                              feature_awready,
  output wire [C_FEATURE_ADDR_WIDTH-1:0]   feature_awaddr ,
  output wire [8-1:0]                      feature_awlen  ,
  output wire                              feature_wvalid ,
  input  wire                              feature_wready ,
  output wire [C_FEATURE_DATA_WIDTH-1:0]   feature_wdata  ,
  output wire [C_FEATURE_DATA_WIDTH/8-1:0] feature_wstrb  ,
  output wire                              feature_wlast  ,
  input  wire                              feature_bvalid ,
  output wire                              feature_bready ,
  output wire                              feature_arvalid,
  input  wire                              feature_arready,
  output wire [C_FEATURE_ADDR_WIDTH-1:0]   feature_araddr ,
  output wire [8-1:0]                      feature_arlen  ,
  input  wire                              feature_rvalid ,
  output wire                              feature_rready ,
  input  wire [C_FEATURE_DATA_WIDTH-1:0]   feature_rdata  ,
  input  wire                              feature_rlast  ,
  // AXI4 master interface out
  output wire                              out_awvalid    ,
  input  wire                              out_awready    ,
  output wire [C_OUT_ADDR_WIDTH-1:0]       out_awaddr     ,
  output wire [8-1:0]                      out_awlen      ,
  output wire                              out_wvalid     ,
  input  wire                              out_wready     ,
  output wire [C_OUT_DATA_WIDTH-1:0]       out_wdata      ,
  output wire [C_OUT_DATA_WIDTH/8-1:0]     out_wstrb      ,
  output wire                              out_wlast      ,
  input  wire                              out_bvalid     ,
  output wire                              out_bready     ,
  output wire                              out_arvalid    ,
  input  wire                              out_arready    ,
  output wire [C_OUT_ADDR_WIDTH-1:0]       out_araddr     ,
  output wire [8-1:0]                      out_arlen      ,
  input  wire                              out_rvalid     ,
  output wire                              out_rready     ,
  input  wire [C_OUT_DATA_WIDTH-1:0]       out_rdata      ,
  input  wire                              out_rlast      ,
  // Control Signals
  input  wire                              ap_start       ,
  output wire                              ap_idle        ,
  output wire                              ap_done        ,
  output wire                              ap_ready       ,
  input  wire [32-1:0]                     scalar00       ,
  input  wire [32-1:0]                     scalar01       ,
  input  wire [32-1:0]                     scalar02       ,
  input  wire [32-1:0]                     scalar03       ,
  input  wire [64-1:0]                     inst_ptr0      ,
  input  wire [64-1:0]                     weight_ptr0    ,
  input  wire [64-1:0]                     feature_ptr0   ,
  input  wire [64-1:0]                     out_ptr0       
);


timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
// Large enough for interesting traffic.
localparam integer  LP_DEFAULT_LENGTH_IN_BYTES = 16384;
localparam integer  LP_NUM_EXAMPLES            = 4    ;
// added parameters about instruction length
localparam integer  LP_WEIT_INST_BIT_WIDTH     = 128  ;
localparam integer  LP_BIAS_INST_BIT_WIDTH     = 128  ;
localparam integer  LP_LOAD_INST_BIT_WIDTH     = 128  ;
localparam integer  LP_SAVE_INST_BIT_WIDTH     = 128  ;
localparam integer  LP_AGG_INST_BIT_WIDTH      = 128  ;
localparam integer  LP_MM_INST_BIT_WIDTH       = 128  ;
// added parameters about buffer width and depth
localparam integer  LP_BUFFER_WIDTH_BIT        = 512  ;
localparam integer  LP_BUFFER_DEPTH            = 2048 ;
// added parameters about parallisim
localparam integer  LP_AGG_MAC_NUM             = 16   ;
localparam integer  LP_MM_IN_CHANNEL           = 16   ;
localparam integer  LP_MM_OUT_CHANNEL          = 16   ;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* KEEP = "yes" *)
logic                                areset                         = 1'b0;
logic                                ap_start_r                     = 1'b0;
logic                                ap_idle_r                      = 1'b1;
logic                                ap_start_pulse                ;
logic                                ap_done_i                     ;
logic                                ap_done_r                      = 1'b0;
logic [32-1:0]                       ctrl_xfer_size_in_bytes        = LP_DEFAULT_LENGTH_IN_BYTES;
logic [32-1:0]                       ctrl_constant                  = 32'd1;
// added logic signal between inst module and other modules
logic [LP_LOAD_INST_BIT_WIDTH  -1:0]    instruction_to_load   ;
logic [LP_WEIT_INST_BIT_WIDTH  -1:0]    instruction_to_weight ;
logic [LP_BIAS_INST_BIT_WIDTH  -1:0]    instruction_to_bias   ;
logic [LP_AGG_INST_BIT_WIDTH   -1:0]    instruction_to_agg    ;
logic [LP_MM_INST_BIT_WIDTH    -1:0]    instruction_to_mm     ;
logic [LP_SAVE_INST_BIT_WIDTH  -1:0]    instruction_to_save   ;
logic                                   valid_to_load         ;
logic                                   valid_to_weight       ;
logic                                   valid_to_bias         ;
logic                                   valid_to_agg          ;
logic                                   valid_to_mm           ;
logic                                   valid_to_save         ;
logic                                   done_from_load        ;
logic                                   done_from_weight      ;
logic                                   done_from_bias        ;
logic                                   done_from_agg         ;
logic                                   done_from_mm          ;
logic                                   done_from_save        ;

// added logic signal between modules and buffers
// weight write buffer_w
logic [1     -1:0]      weight_write_buffer_w_valid;
logic [13    -1:0]      weight_write_buffer_w_addr;
logic [8192  -1:0]      weight_write_buffer_w_data;
// bias write buffer_b
logic [1     -1:0]      bias_write_buffer_b_valid;
logic [9     -1:0]      bias_write_buffer_b_addr;
logic [512   -1:0]      bias_write_buffer_b_data;
// load write buffer_0 1 2
logic [1     -1:0]      load_write_buffer_0_valid;
logic [11    -1:0]      load_write_buffer_0_addr;
logic [512   -1:0]      load_write_buffer_0_data;

logic [1     -1:0]      load_write_buffer_1_A_valid;
logic [11    -1:0]      load_write_buffer_1_A_addr;
logic [512   -1:0]      load_write_buffer_1_A_data;

logic [1     -1:0]      load_write_buffer_1_B_valid;
logic [11    -1:0]      load_write_buffer_1_B_addr;
logic [512   -1:0]      load_write_buffer_1_B_data;

logic [1     -1:0]      load_write_buffer_2_A_valid;
logic [11    -1:0]      load_write_buffer_2_A_addr;
logic [512   -1:0]      load_write_buffer_2_A_data;

logic [1     -1:0]      load_write_buffer_2_B_valid;
logic [11    -1:0]      load_write_buffer_2_B_addr;
logic [512   -1:0]      load_write_buffer_2_B_data;
// save read buffer_1 2
logic [1     -1:0]      save_read_buffer_1_A_avalid ;
logic [11    -1:0]      save_read_buffer_1_A_addr   ;
logic [1     -1:0]      save_read_buffer_1_A_valid  ;
logic [512   -1:0]      save_read_buffer_1_A_data   ;

logic [1     -1:0]      save_read_buffer_1_B_avalid ;
logic [11    -1:0]      save_read_buffer_1_B_addr   ;
logic [1     -1:0]      save_read_buffer_1_B_valid  ;
logic [512   -1:0]      save_read_buffer_1_B_data   ;

logic [1     -1:0]      save_read_buffer_2_A_avalid ;
logic [11    -1:0]      save_read_buffer_2_A_addr   ;
logic [1     -1:0]      save_read_buffer_2_A_valid  ;
logic [512   -1:0]      save_read_buffer_2_A_data   ;

logic [1     -1:0]      save_read_buffer_2_B_avalid ;
logic [11    -1:0]      save_read_buffer_2_B_addr   ;
logic [1     -1:0]      save_read_buffer_2_B_valid  ;
logic [512   -1:0]      save_read_buffer_2_B_data   ;
// agg read buffer_0 1 write buffer 1
logic [1     -1:0]      agg_read_buffer_0_avalid    ;
logic [11    -1:0]      agg_read_buffer_0_addr      ;
logic [1     -1:0]      agg_read_buffer_0_valid     ;
logic [512   -1:0]      agg_read_buffer_0_data      ;

logic [1     -1:0]      agg_read_buffer_1_A_avalid  ;
logic [11    -1:0]      agg_read_buffer_1_A_addr    ;
logic [1     -1:0]      agg_read_buffer_1_A_valid   ;
logic [512   -1:0]      agg_read_buffer_1_A_data    ;

logic [1     -1:0]      agg_read_buffer_1_B_avalid  ;
logic [11    -1:0]      agg_read_buffer_1_B_addr    ;
logic [1     -1:0]      agg_read_buffer_1_B_valid   ;
logic [512   -1:0]      agg_read_buffer_1_B_data    ;

logic [1     -1:0]      agg_write_buffer_1_A_valid  ;
logic [11    -1:0]      agg_write_buffer_1_A_addr   ;
logic [512   -1:0]      agg_write_buffer_1_A_data   ;

logic [1     -1:0]      agg_write_buffer_1_B_valid  ;
logic [11    -1:0]      agg_write_buffer_1_B_addr   ;
logic [512   -1:0]      agg_write_buffer_1_B_data   ;
// mm read buffer_1 2 write buffer 2
logic [1     -1:0]      mm_read_buffer_1_A_avalid;
logic [11    -1:0]      mm_read_buffer_1_A_addr;
logic [1     -1:0]      mm_read_buffer_1_A_valid;
logic [512   -1:0]      mm_read_buffer_1_A_data;

logic [1     -1:0]      mm_read_buffer_1_B_avalid;
logic [11    -1:0]      mm_read_buffer_1_B_addr;
logic [1     -1:0]      mm_read_buffer_1_B_valid;
logic [512   -1:0]      mm_read_buffer_1_B_data;

logic [1     -1:0]      mm_read_buffer_2_A_avalid;
logic [11    -1:0]      mm_read_buffer_2_A_addr;
logic [1     -1:0]      mm_read_buffer_2_A_valid;
logic [512   -1:0]      mm_read_buffer_2_A_data;

logic [1     -1:0]      mm_read_buffer_2_B_avalid;
logic [11    -1:0]      mm_read_buffer_2_B_addr;
logic [1     -1:0]      mm_read_buffer_2_B_valid;
logic [512   -1:0]      mm_read_buffer_2_B_data;

logic [1     -1:0]      mm_write_buffer_2_A_valid;
logic [11    -1:0]      mm_write_buffer_2_A_addr;
logic [512   -1:0]      mm_write_buffer_2_A_data;

logic [1     -1:0]      mm_write_buffer_2_B_valid;
logic [11    -1:0]      mm_write_buffer_2_B_addr;
logic [512   -1:0]      mm_write_buffer_2_B_data;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

// create pulse when ap_start transitions to 1
always @(posedge ap_clk) begin
  begin
    ap_start_r <= ap_start;
  end
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse
// is asserted
always @(posedge ap_clk) begin
  if (areset) begin
    ap_idle_r <= 1'b1;
  end
  else begin
    ap_idle_r <= ap_done ? 1'b1 :
      ap_start_pulse ? 1'b0 : ap_idle;
  end
end

assign ap_idle = ap_idle_r;

// Done logic
always @(posedge ap_clk) begin
  if (areset) begin
    ap_done_r <= '0;
  end
  else begin
    ap_done_r <= (ap_done) ? '0 : ap_done_r | ap_done_i;
  end
end

assign ap_done = ap_done_r;

// Ready Logic (non-pipelined case)
assign ap_ready = ap_done;

// inst module
gnn_0_example_inst #(
  // added parameters about inst length
  .WEIT_INST_BIT_WIDTH   ( LP_WEIT_INST_BIT_WIDTH),
  .BIAS_INST_BIT_WIDTH   ( LP_BIAS_INST_BIT_WIDTH),
  .LOAD_INST_BIT_WIDTH   ( LP_LOAD_INST_BIT_WIDTH),
  .SAVE_INST_BIT_WIDTH   ( LP_SAVE_INST_BIT_WIDTH),
  .AGG_INST_BIT_WIDTH    ( LP_AGG_INST_BIT_WIDTH ),
  .MM_INST_BIT_WIDTH     ( LP_MM_INST_BIT_WIDTH  ),
  // generated parameter 
  .C_M_AXI_ADDR_WIDTH ( C_INST_ADDR_WIDTH ),
  .C_M_AXI_DATA_WIDTH ( C_INST_DATA_WIDTH ),
  .C_ADDER_BIT_WIDTH  ( 32                ),
  .C_XFER_SIZE_WIDTH  ( 32                )
)
inst_example_inst (
  // generated cpu-fpga ctrl signal
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .kernel_clk              ( ap_clk                  ),
  .kernel_rst              ( areset                  ),
  // ctrl signals
  .ctrl_addr_offset        ( inst_ptr0               ),
  .ap_start                ( ap_start_pulse          ),
  .ap_done                 ( ap_done_i               ),
  // added inst module - other module ctrl signal
  .instruction_to_load     ( instruction_to_load     ),
  .instruction_to_weight   ( instruction_to_weight   ),
  .instruction_to_bias     ( instruction_to_bias     ),
  .instruction_to_agg      ( instruction_to_agg      ),
  .instruction_to_mm       ( instruction_to_mm       ),
  .instruction_to_save     ( instruction_to_save     ),
  .valid_to_load           ( valid_to_load           ),
  .valid_to_weight         ( valid_to_weight         ),
  .valid_to_bias           ( valid_to_bias           ),
  .valid_to_agg            ( valid_to_agg            ),
  .valid_to_mm             ( valid_to_mm             ),
  .valid_to_save           ( valid_to_save           ),
  .done_to_load            ( done_to_load            ),
  .done_to_weight          ( done_to_weight          ),
  .done_to_bias            ( done_to_bias            ),
  .done_to_agg             ( done_to_agg             ),
  .done_to_mm              ( done_to_mm              ),
  .done_to_save            ( done_to_save            ),
  // axi ports (don't change)
  .m_axi_awvalid           ( inst_awvalid            ),
  .m_axi_awready           ( inst_awready            ),
  .m_axi_awaddr            ( inst_awaddr             ),
  .m_axi_awlen             ( inst_awlen              ),
  .m_axi_wvalid            ( inst_wvalid             ),
  .m_axi_wready            ( inst_wready             ),
  .m_axi_wdata             ( inst_wdata              ),
  .m_axi_wstrb             ( inst_wstrb              ),
  .m_axi_wlast             ( inst_wlast              ),
  .m_axi_bvalid            ( inst_bvalid             ),
  .m_axi_bready            ( inst_bready             ),
  .m_axi_arvalid           ( inst_arvalid            ),
  .m_axi_arready           ( inst_arready            ),
  .m_axi_araddr            ( inst_araddr             ),
  .m_axi_arlen             ( inst_arlen              ),
  .m_axi_rvalid            ( inst_rvalid             ),
  .m_axi_rready            ( inst_rready             ),
  .m_axi_rdata             ( inst_rdata              ),
  .m_axi_rlast             ( inst_rlast              )
);


// weight module
gnn_0_example_weight #(
  // added parameters about inst length
  .WEIT_INST_BIT_WIDTH( LP_WEIT_INST_BIT_WIDTH ),
  .C_M_AXI_ADDR_WIDTH ( C_WEIGHT_ADDR_WIDTH    ),
  .C_M_AXI_DATA_WIDTH ( C_WEIGHT_DATA_WIDTH    ),
  .C_ADDER_BIT_WIDTH  ( 32                     ),
  .C_XFER_SIZE_WIDTH  ( 32                     )
)
inst_example_weight (
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .kernel_clk              ( ap_clk                  ),
  .kernel_rst              ( areset                  ),
  // ctrl signals
  .ctrl_addr_offset        ( weight_ptr0             ),
  .ctrl_instruction        ( instruction_to_weight   ),
  .ap_start                ( valid_to_weight         ),
  .ap_done                 ( done_from_weight        ),
  // weight buffer port
  .weight_write_buffer_w_valid (weight_write_buffer_w_valid),
  .weight_write_buffer_w_addr  (weight_write_buffer_w_addr ),
  .weight_write_buffer_w_data  (weight_write_buffer_w_data ),
  // weight (bias) axi port (don't change)
  .m_axi_arvalid           ( weight_arvalid          ),
  .m_axi_arready           ( weight_arready          ),
  .m_axi_araddr            ( weight_araddr           ),
  .m_axi_arlen             ( weight_arlen            ),
  .m_axi_rvalid            ( weight_rvalid           ),
  .m_axi_rready            ( weight_rready           ),
  .m_axi_rdata             ( weight_rdata            ),
  .m_axi_rlast             ( weight_rlast            )
);


// bias module
gnn_0_example_bias #(
  // added parameters about inst length
  .BIAS_INST_BIT_WIDTH( LP_BIAS_INST_BIT_WIDTH ),
  .C_M_AXI_ADDR_WIDTH ( C_WEIGHT_ADDR_WIDTH    ),
  .C_M_AXI_DATA_WIDTH ( C_WEIGHT_DATA_WIDTH    ),
  .C_ADDER_BIT_WIDTH  ( 32                     ),
  .C_XFER_SIZE_WIDTH  ( 32                     )
)
inst_example_bias (
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .kernel_clk              ( ap_clk                  ),
  .kernel_rst              ( areset                  ),
  // ctrl signals
  .ctrl_addr_offset        ( weight_ptr0             ),
  .ctrl_instruction        ( instruction_to_bias     ),
  .ap_start                ( valid_to_bias           ),
  .ap_done                 ( done_from_bias          ),
  // bias buffer port
  .bias_write_buffer_b_valid (bias_write_buffer_b_valid),
  .bias_write_buffer_b_addr  (bias_write_buffer_b_addr ),
  .bias_write_buffer_b_data  (bias_write_buffer_b_data ),
  // weight (bias) axi port (don't change)
  .m_axi_arvalid           ( weight_arvalid          ),
  .m_axi_arready           ( weight_arready          ),
  .m_axi_araddr            ( weight_araddr           ),
  .m_axi_arlen             ( weight_arlen            ),
  .m_axi_rvalid            ( weight_rvalid           ),
  .m_axi_rready            ( weight_rready           ),
  .m_axi_rdata             ( weight_rdata            ),
  .m_axi_rlast             ( weight_rlast            )
);


// load module
gnn_0_example_load #(
  // added parameters about inst length
  .LOAD_INST_BIT_WIDTH( LP_LOAD_INST_BIT_WIDTH  ),
  .C_M_AXI_ADDR_WIDTH ( C_FEATURE_ADDR_WIDTH    ),
  .C_M_AXI_DATA_WIDTH ( C_FEATURE_DATA_WIDTH    ),
  .C_ADDER_BIT_WIDTH  ( 32                      ),
  .C_XFER_SIZE_WIDTH  ( 32                      )
)
inst_example_load(
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .kernel_clk              ( ap_clk                  ),
  .kernel_rst              ( areset                  ),
  // ctrl signals
  .ctrl_addr_offset        ( feature_ptr0            ),
  .ctrl_instruction        ( instruction_to_load     ),
  .ap_start                ( valid_to_load           ),
  .ap_done                 ( done_from_load          ),
  // load buffer ports
  .load_write_buffer_0_valid   (load_write_buffer_0_valid  ),
  .load_write_buffer_0_addr    (load_write_buffer_0_addr   ),
  .load_write_buffer_0_data    (load_write_buffer_0_data   ),
  .load_write_buffer_1_A_valid (load_write_buffer_1_A_valid),
  .load_write_buffer_1_A_addr  (load_write_buffer_1_A_addr ),
  .load_write_buffer_1_A_data  (load_write_buffer_1_A_data ),
  .load_write_buffer_1_B_valid (load_write_buffer_1_B_valid),
  .load_write_buffer_1_B_addr  (load_write_buffer_1_B_addr ),
  .load_write_buffer_1_B_data  (load_write_buffer_1_B_data ),
  .load_write_buffer_2_A_valid (load_write_buffer_2_A_valid),
  .load_write_buffer_2_A_addr  (load_write_buffer_2_A_addr ),
  .load_write_buffer_2_A_data  (load_write_buffer_2_A_data ),
  .load_write_buffer_2_B_valid (load_write_buffer_2_B_valid),
  .load_write_buffer_2_B_addr  (load_write_buffer_2_B_addr ),
  .load_write_buffer_2_B_data  (load_write_buffer_2_B_data ),
  // feature axi port (don't change)
  .m_axi_arvalid           ( feature_arvalid         ),
  .m_axi_arready           ( feature_arready         ),
  .m_axi_araddr            ( feature_araddr          ),
  .m_axi_arlen             ( feature_arlen           ),
  .m_axi_rvalid            ( feature_rvalid          ),
  .m_axi_rready            ( feature_rready          ),
  .m_axi_rdata             ( feature_rdata           ),
  .m_axi_rlast             ( feature_rlast           )
);


// save module
gnn_0_example_save #(
  // added parameters about inst length
  .SAVE_INST_BIT_WIDTH( LP_SAVE_INST_BIT_WIDTH  ),
  .C_M_AXI_ADDR_WIDTH ( C_FEATURE_ADDR_WIDTH    ),
  .C_M_AXI_DATA_WIDTH ( C_FEATURE_DATA_WIDTH    ),
  .C_ADDER_BIT_WIDTH  ( 32                      ),
  .C_XFER_SIZE_WIDTH  ( 32                      )
)
inst_example_save(
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .kernel_clk              ( ap_clk                  ),
  .kernel_rst              ( areset                  ),
  // ctrl signals
  .ctrl_addr_offset        ( feature_ptr0            ),
  .ctrl_instruction        ( instruction_to_save     ),
  .ap_start                ( valid_to_save           ),
  .ap_done                 ( done_from_save          ),
  // load buffer ports
  .save_read_buffer_1_A_avalid (save_read_buffer_1_A_avalid),
  .save_read_buffer_1_A_addr   (save_read_buffer_1_A_addr  ),
  .save_read_buffer_1_A_valid  (save_read_buffer_1_A_valid ),
  .save_read_buffer_1_A_data   (save_read_buffer_1_A_data  ),
  .save_read_buffer_1_B_avalid (save_read_buffer_1_B_avalid),
  .save_read_buffer_1_B_addr   (save_read_buffer_1_B_addr  ),
  .save_read_buffer_1_B_valid  (save_read_buffer_1_B_valid ),
  .save_read_buffer_1_B_data   (save_read_buffer_1_B_data  ),
  .save_read_buffer_2_A_avalid (save_read_buffer_2_A_avalid),
  .save_read_buffer_2_A_addr   (save_read_buffer_2_A_addr  ),
  .save_read_buffer_2_A_valid  (save_read_buffer_2_A_valid ),
  .save_read_buffer_2_A_data   (save_read_buffer_2_A_data  ),
  .save_read_buffer_2_B_avalid (save_read_buffer_2_B_avalid),
  .save_read_buffer_2_B_addr   (save_read_buffer_2_B_addr  ),
  .save_read_buffer_2_B_valid  (save_read_buffer_2_B_valid ),
  .save_read_buffer_2_B_data   (save_read_buffer_2_B_data  ),
  // feature axi port (don't change)
  .m_axi_awvalid           ( feature_awvalid         ),
  .m_axi_awready           ( feature_awready         ),
  .m_axi_awaddr            ( feature_awaddr          ),
  .m_axi_awlen             ( feature_awlen           ),
  .m_axi_wvalid            ( feature_wvalid          ),
  .m_axi_wready            ( feature_wready          ),
  .m_axi_wdata             ( feature_wdata           ),
  .m_axi_wstrb             ( feature_wstrb           ),
  .m_axi_wlast             ( feature_wlast           ),
  .m_axi_bvalid            ( feature_bvalid          ),
  .m_axi_bready            ( feature_bready          )
);


// agg module
gnn_0_example_agg #(
  .AGG_INST_BIT_WIDTH ( LP_AGG_INST_BIT_WIDTH  ),
  .C_M_AXI_ADDR_WIDTH ( C_OUT_ADDR_WIDTH ),
  .C_M_AXI_DATA_WIDTH ( C_OUT_DATA_WIDTH ),
  .C_ADDER_BIT_WIDTH  ( 32               ),
  .C_XFER_SIZE_WIDTH  ( 32               )
)
inst_example_agg (
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .kernel_clk              ( ap_clk                  ),
  .kernel_rst              ( areset                  ),
  // ctrl signals
  .ctrl_addr_offset        ( out_ptr0                ),
  .ctrl_instruction        ( instruction_to_agg      ),
  .ap_start                ( valid_to_agg            ),
  .ap_done                 ( done_from_agg           ),
  // agg buffer ports
  .agg_read_buffer_0_avalid    (agg_read_buffer_0_avalid   ),
  .agg_read_buffer_0_addr      (agg_read_buffer_0_addr     ),
  .agg_read_buffer_0_valid     (agg_read_buffer_0_valid    ),
  .agg_read_buffer_0_data      (agg_read_buffer_0_data     ),
  .agg_read_buffer_1_A_avalid  (agg_read_buffer_1_A_avalid ),
  .agg_read_buffer_1_A_addr    (agg_read_buffer_1_A_addr   ),
  .agg_read_buffer_1_A_valid   (agg_read_buffer_1_A_valid  ),
  .agg_read_buffer_1_A_data    (agg_read_buffer_1_A_data   ),
  .agg_read_buffer_1_B_avalid  (agg_read_buffer_1_B_avalid ),
  .agg_read_buffer_1_B_addr    (agg_read_buffer_1_B_addr   ),
  .agg_read_buffer_1_B_valid   (agg_read_buffer_1_B_valid  ),
  .agg_read_buffer_1_B_data    (agg_read_buffer_1_B_data   ),
  .agg_write_buffer_1_A_valid  (agg_write_buffer_1_A_valid ),
  .agg_write_buffer_1_A_addr   (agg_write_buffer_1_A_addr  ),
  .agg_write_buffer_1_A_data   (agg_write_buffer_1_A_data  ),
  .agg_write_buffer_1_B_valid  (agg_write_buffer_1_B_valid ),
  .agg_write_buffer_1_B_addr   (agg_write_buffer_1_B_addr  ),
  .agg_write_buffer_1_B_data   (agg_write_buffer_1_B_data  ),
  // adj axi port (don't change)
  .m_axi_arvalid           ( out_arvalid             ),
  .m_axi_arready           ( out_arready             ),
  .m_axi_araddr            ( out_araddr              ),
  .m_axi_arlen             ( out_arlen               ),
  .m_axi_rvalid            ( out_rvalid              ),
  .m_axi_rready            ( out_rready              ),
  .m_axi_rdata             ( out_rdata               ),
  .m_axi_rlast             ( out_rlast               )
);


// mm module
gnn_0_example_mm #(
  .MM_INST_BIT_WIDTH  ( LP_MM_INST_BIT_WIDTH  ),
  .C_M_AXI_ADDR_WIDTH ( C_OUT_ADDR_WIDTH ),
  .C_M_AXI_DATA_WIDTH ( C_OUT_DATA_WIDTH ),
  .C_ADDER_BIT_WIDTH  ( 32               ),
  .C_XFER_SIZE_WIDTH  ( 32               )
)
inst_example_agg (
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .kernel_clk              ( ap_clk                  ),
  .kernel_rst              ( areset                  ),
  // ctrl signals
  .ctrl_instruction        ( instruction_to_mm       ),
  .ap_start                ( valid_to_mm             ),
  .ap_done                 ( done_from_mm            ),
  // mm buffer ports
  .mm_read_buffer_1_A_avalid  (mm_read_buffer_1_A_avalid ),
  .mm_read_buffer_1_A_addr    (mm_read_buffer_1_A_addr   ),
  .mm_read_buffer_1_A_valid   (mm_read_buffer_1_A_valid  ),
  .mm_read_buffer_1_A_data    (mm_read_buffer_1_A_data   ),
  .mm_read_buffer_1_B_avalid  (mm_read_buffer_1_B_avalid ),
  .mm_read_buffer_1_B_addr    (mm_read_buffer_1_B_addr   ),
  .mm_read_buffer_1_B_valid   (mm_read_buffer_1_B_valid  ),
  .mm_read_buffer_1_B_data    (mm_read_buffer_1_B_data   ),
  .mm_read_buffer_2_A_avalid  (mm_read_buffer_2_A_avalid ),
  .mm_read_buffer_2_A_addr    (mm_read_buffer_2_A_addr   ),
  .mm_read_buffer_2_A_valid   (mm_read_buffer_2_A_valid  ),
  .mm_read_buffer_2_A_data    (mm_read_buffer_2_A_data   ),
  .mm_read_buffer_2_B_avalid  (mm_read_buffer_2_B_avalid ),
  .mm_read_buffer_2_B_addr    (mm_read_buffer_2_B_addr   ),
  .mm_read_buffer_2_B_valid   (mm_read_buffer_2_B_valid  ),
  .mm_read_buffer_2_B_data    (mm_read_buffer_2_B_data   ),
  .mm_write_buffer_1_A_valid  (mm_write_buffer_1_A_valid ),
  .mm_write_buffer_1_A_addr   (mm_write_buffer_1_A_addr  ),
  .mm_write_buffer_1_A_data   (mm_write_buffer_1_A_data  ),
  .mm_write_buffer_1_B_valid  (mm_write_buffer_1_B_valid ),
  .mm_write_buffer_1_B_addr   (mm_write_buffer_1_B_addr  ),
  .mm_write_buffer_1_B_data   (mm_write_buffer_1_B_data  ),
  // adj axi port (don't change)
  .m_axi_arvalid           ( out_arvalid             ),
  .m_axi_arready           ( out_arready             ),
  .m_axi_araddr            ( out_araddr              ),
  .m_axi_arlen             ( out_arlen               ),
  .m_axi_rvalid            ( out_rvalid              ),
  .m_axi_rready            ( out_rready              ),
  .m_axi_rdata             ( out_rdata               ),
  .m_axi_rlast             ( out_rlast               )
);


endmodule : gnn_0_example
`default_nettype wire
