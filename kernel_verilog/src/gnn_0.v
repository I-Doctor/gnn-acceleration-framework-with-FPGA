// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module gnn_0 #(
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12 ,
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32 ,
  parameter integer C_INST_ADDR_WIDTH          = 64 ,
  parameter integer C_INST_DATA_WIDTH          = 512,
  parameter integer C_WEIGHT_ADDR_WIDTH        = 64 ,
  parameter integer C_WEIGHT_DATA_WIDTH        = 512,
  parameter integer C_FEATURE_ADDR_WIDTH       = 64 ,
  parameter integer C_FEATURE_DATA_WIDTH       = 512,
  parameter integer C_OUT_ADDR_WIDTH           = 64 ,
  parameter integer C_OUT_DATA_WIDTH           = 512
)
(
  // System Signals
  input  wire                                    ap_clk               ,
  input  wire                                    ap_rst_n             ,
  //  Note: A minimum subset of AXI4 memory mapped signals are declared.  AXI
  // signals omitted from these interfaces are automatically inferred with the
  // optimal values for Xilinx accleration platforms.  This allows Xilinx AXI4 Interconnects
  // within the system to be optimized by removing logic for AXI4 protocol
  // features that are not necessary. When adapting AXI4 masters within the RTL
  // kernel that have signals not declared below, it is suitable to add the
  // signals to the declarations below to connect them to the AXI4 Master.
  // 
  // List of ommited signals - effect
  // -------------------------------
  // ID - Transaction ID are used for multithreading and out of order
  // transactions.  This increases complexity. This saves logic and increases Fmax
  // in the system when ommited.
  // SIZE - Default value is log2(data width in bytes). Needed for subsize bursts.
  // This saves logic and increases Fmax in the system when ommited.
  // BURST - Default value (0b01) is incremental.  Wrap and fixed bursts are not
  // recommended. This saves logic and increases Fmax in the system when ommited.
  // LOCK - Not supported in AXI4
  // CACHE - Default value (0b0011) allows modifiable transactions. No benefit to
  // changing this.
  // PROT - Has no effect in current acceleration platforms.
  // QOS - Has no effect in current acceleration platforms.
  // REGION - Has no effect in current acceleration platforms.
  // USER - Has no effect in current acceleration platforms.
  // RESP - Not useful in most acceleration platforms.
  // 
  // AXI4 master interface inst
  output wire                                    inst_awvalid         ,
  input  wire                                    inst_awready         ,
  output wire [C_INST_ADDR_WIDTH-1:0]            inst_awaddr          ,
  output wire [8-1:0]                            inst_awlen           ,
  output wire                                    inst_wvalid          ,
  input  wire                                    inst_wready          ,
  output wire [C_INST_DATA_WIDTH-1:0]            inst_wdata           ,
  output wire [C_INST_DATA_WIDTH/8-1:0]          inst_wstrb           ,
  output wire                                    inst_wlast           ,
  input  wire                                    inst_bvalid          ,
  output wire                                    inst_bready          ,
  output wire                                    inst_arvalid         ,
  input  wire                                    inst_arready         ,
  output wire [C_INST_ADDR_WIDTH-1:0]            inst_araddr          ,
  output wire [8-1:0]                            inst_arlen           ,
  input  wire                                    inst_rvalid          ,
  output wire                                    inst_rready          ,
  input  wire [C_INST_DATA_WIDTH-1:0]            inst_rdata           ,
  input  wire                                    inst_rlast           ,
  // AXI4 master interface weight
  output wire                                    weight_awvalid       ,
  input  wire                                    weight_awready       ,
  output wire [C_WEIGHT_ADDR_WIDTH-1:0]          weight_awaddr        ,
  output wire [8-1:0]                            weight_awlen         ,
  output wire                                    weight_wvalid        ,
  input  wire                                    weight_wready        ,
  output wire [C_WEIGHT_DATA_WIDTH-1:0]          weight_wdata         ,
  output wire [C_WEIGHT_DATA_WIDTH/8-1:0]        weight_wstrb         ,
  output wire                                    weight_wlast         ,
  input  wire                                    weight_bvalid        ,
  output wire                                    weight_bready        ,
  output wire                                    weight_arvalid       ,
  input  wire                                    weight_arready       ,
  output wire [C_WEIGHT_ADDR_WIDTH-1:0]          weight_araddr        ,
  output wire [8-1:0]                            weight_arlen         ,
  input  wire                                    weight_rvalid        ,
  output wire                                    weight_rready        ,
  input  wire [C_WEIGHT_DATA_WIDTH-1:0]          weight_rdata         ,
  input  wire                                    weight_rlast         ,
  // AXI4 master interface feature
  output wire                                    feature_awvalid      ,
  input  wire                                    feature_awready      ,
  output wire [C_FEATURE_ADDR_WIDTH-1:0]         feature_awaddr       ,
  output wire [8-1:0]                            feature_awlen        ,
  output wire                                    feature_wvalid       ,
  input  wire                                    feature_wready       ,
  output wire [C_FEATURE_DATA_WIDTH-1:0]         feature_wdata        ,
  output wire [C_FEATURE_DATA_WIDTH/8-1:0]       feature_wstrb        ,
  output wire                                    feature_wlast        ,
  input  wire                                    feature_bvalid       ,
  output wire                                    feature_bready       ,
  output wire                                    feature_arvalid      ,
  input  wire                                    feature_arready      ,
  output wire [C_FEATURE_ADDR_WIDTH-1:0]         feature_araddr       ,
  output wire [8-1:0]                            feature_arlen        ,
  input  wire                                    feature_rvalid       ,
  output wire                                    feature_rready       ,
  input  wire [C_FEATURE_DATA_WIDTH-1:0]         feature_rdata        ,
  input  wire                                    feature_rlast        ,
  // AXI4 master interface out
  output wire                                    out_awvalid          ,
  input  wire                                    out_awready          ,
  output wire [C_OUT_ADDR_WIDTH-1:0]             out_awaddr           ,
  output wire [8-1:0]                            out_awlen            ,
  output wire                                    out_wvalid           ,
  input  wire                                    out_wready           ,
  output wire [C_OUT_DATA_WIDTH-1:0]             out_wdata            ,
  output wire [C_OUT_DATA_WIDTH/8-1:0]           out_wstrb            ,
  output wire                                    out_wlast            ,
  input  wire                                    out_bvalid           ,
  output wire                                    out_bready           ,
  output wire                                    out_arvalid          ,
  input  wire                                    out_arready          ,
  output wire [C_OUT_ADDR_WIDTH-1:0]             out_araddr           ,
  output wire [8-1:0]                            out_arlen            ,
  input  wire                                    out_rvalid           ,
  output wire                                    out_rready           ,
  input  wire [C_OUT_DATA_WIDTH-1:0]             out_rdata            ,
  input  wire                                    out_rlast            ,
  // AXI4-Lite slave interface
  input  wire                                    s_axi_control_awvalid,
  output wire                                    s_axi_control_awready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr ,
  input  wire                                    s_axi_control_wvalid ,
  output wire                                    s_axi_control_wready ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata  ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb  ,
  input  wire                                    s_axi_control_arvalid,
  output wire                                    s_axi_control_arready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr ,
  output wire                                    s_axi_control_rvalid ,
  input  wire                                    s_axi_control_rready ,
  output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata  ,
  output wire [2-1:0]                            s_axi_control_rresp  ,
  output wire                                    s_axi_control_bvalid ,
  input  wire                                    s_axi_control_bready ,
  output wire [2-1:0]                            s_axi_control_bresp  ,
  output wire                                    interrupt            
);

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* DONT_TOUCH = "yes" *)
reg                                 areset                         = 1'b0;
wire                                ap_start                      ;
wire                                ap_idle                       ;
wire                                ap_done                       ;
wire                                ap_ready                      ;
wire [32-1:0]                       scalar00                      ;
wire [32-1:0]                       scalar01                      ;
wire [32-1:0]                       scalar02                      ;
wire [32-1:0]                       scalar03                      ;
wire [64-1:0]                       inst_ptr0                     ;
wire [64-1:0]                       weight_ptr0                   ;
wire [64-1:0]                       feature_ptr0                  ;
wire [64-1:0]                       out_ptr0                      ;

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

///////////////////////////////////////////////////////////////////////////////
// Begin control interface RTL.  Modifying not recommended.
///////////////////////////////////////////////////////////////////////////////


// AXI4-Lite slave interface
gnn_0_control_s_axi #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .ACLK         ( ap_clk                ),
  .ARESET       ( areset                ),
  .ACLK_EN      ( 1'b1                  ),
  .AWVALID      ( s_axi_control_awvalid ),
  .AWREADY      ( s_axi_control_awready ),
  .AWADDR       ( s_axi_control_awaddr  ),
  .WVALID       ( s_axi_control_wvalid  ),
  .WREADY       ( s_axi_control_wready  ),
  .WDATA        ( s_axi_control_wdata   ),
  .WSTRB        ( s_axi_control_wstrb   ),
  .ARVALID      ( s_axi_control_arvalid ),
  .ARREADY      ( s_axi_control_arready ),
  .ARADDR       ( s_axi_control_araddr  ),
  .RVALID       ( s_axi_control_rvalid  ),
  .RREADY       ( s_axi_control_rready  ),
  .RDATA        ( s_axi_control_rdata   ),
  .RRESP        ( s_axi_control_rresp   ),
  .BVALID       ( s_axi_control_bvalid  ),
  .BREADY       ( s_axi_control_bready  ),
  .BRESP        ( s_axi_control_bresp   ),
  .interrupt    ( interrupt             ),
  .ap_start     ( ap_start              ),
  .ap_done      ( ap_done               ),
  .ap_ready     ( ap_ready              ),
  .ap_idle      ( ap_idle               ),
  .scalar00     ( scalar00              ),
  .scalar01     ( scalar01              ),
  .scalar02     ( scalar02              ),
  .scalar03     ( scalar03              ),
  .inst_ptr0    ( inst_ptr0             ),
  .weight_ptr0  ( weight_ptr0           ),
  .feature_ptr0 ( feature_ptr0          ),
  .out_ptr0     ( out_ptr0              )
);

///////////////////////////////////////////////////////////////////////////////
// Add kernel logic here.  Modify/remove example code as necessary.
///////////////////////////////////////////////////////////////////////////////

// Example RTL block.  Remove to insert custom logic.
gnn_0_example #(
  .C_INST_ADDR_WIDTH    ( C_INST_ADDR_WIDTH    ),
  .C_INST_DATA_WIDTH    ( C_INST_DATA_WIDTH    ),
  .C_WEIGHT_ADDR_WIDTH  ( C_WEIGHT_ADDR_WIDTH  ),
  .C_WEIGHT_DATA_WIDTH  ( C_WEIGHT_DATA_WIDTH  ),
  .C_FEATURE_ADDR_WIDTH ( C_FEATURE_ADDR_WIDTH ),
  .C_FEATURE_DATA_WIDTH ( C_FEATURE_DATA_WIDTH ),
  .C_OUT_ADDR_WIDTH     ( C_OUT_ADDR_WIDTH     ),
  .C_OUT_DATA_WIDTH     ( C_OUT_DATA_WIDTH     )
)
inst_example (
  .ap_clk          ( ap_clk          ),
  .ap_rst_n        ( ap_rst_n        ),
  .inst_awvalid    ( inst_awvalid    ),
  .inst_awready    ( inst_awready    ),
  .inst_awaddr     ( inst_awaddr     ),
  .inst_awlen      ( inst_awlen      ),
  .inst_wvalid     ( inst_wvalid     ),
  .inst_wready     ( inst_wready     ),
  .inst_wdata      ( inst_wdata      ),
  .inst_wstrb      ( inst_wstrb      ),
  .inst_wlast      ( inst_wlast      ),
  .inst_bvalid     ( inst_bvalid     ),
  .inst_bready     ( inst_bready     ),
  .inst_arvalid    ( inst_arvalid    ),
  .inst_arready    ( inst_arready    ),
  .inst_araddr     ( inst_araddr     ),
  .inst_arlen      ( inst_arlen      ),
  .inst_rvalid     ( inst_rvalid     ),
  .inst_rready     ( inst_rready     ),
  .inst_rdata      ( inst_rdata      ),
  .inst_rlast      ( inst_rlast      ),
  .weight_awvalid  ( weight_awvalid  ),
  .weight_awready  ( weight_awready  ),
  .weight_awaddr   ( weight_awaddr   ),
  .weight_awlen    ( weight_awlen    ),
  .weight_wvalid   ( weight_wvalid   ),
  .weight_wready   ( weight_wready   ),
  .weight_wdata    ( weight_wdata    ),
  .weight_wstrb    ( weight_wstrb    ),
  .weight_wlast    ( weight_wlast    ),
  .weight_bvalid   ( weight_bvalid   ),
  .weight_bready   ( weight_bready   ),
  .weight_arvalid  ( weight_arvalid  ),
  .weight_arready  ( weight_arready  ),
  .weight_araddr   ( weight_araddr   ),
  .weight_arlen    ( weight_arlen    ),
  .weight_rvalid   ( weight_rvalid   ),
  .weight_rready   ( weight_rready   ),
  .weight_rdata    ( weight_rdata    ),
  .weight_rlast    ( weight_rlast    ),
  .feature_awvalid ( feature_awvalid ),
  .feature_awready ( feature_awready ),
  .feature_awaddr  ( feature_awaddr  ),
  .feature_awlen   ( feature_awlen   ),
  .feature_wvalid  ( feature_wvalid  ),
  .feature_wready  ( feature_wready  ),
  .feature_wdata   ( feature_wdata   ),
  .feature_wstrb   ( feature_wstrb   ),
  .feature_wlast   ( feature_wlast   ),
  .feature_bvalid  ( feature_bvalid  ),
  .feature_bready  ( feature_bready  ),
  .feature_arvalid ( feature_arvalid ),
  .feature_arready ( feature_arready ),
  .feature_araddr  ( feature_araddr  ),
  .feature_arlen   ( feature_arlen   ),
  .feature_rvalid  ( feature_rvalid  ),
  .feature_rready  ( feature_rready  ),
  .feature_rdata   ( feature_rdata   ),
  .feature_rlast   ( feature_rlast   ),
  .out_awvalid     ( out_awvalid     ),
  .out_awready     ( out_awready     ),
  .out_awaddr      ( out_awaddr      ),
  .out_awlen       ( out_awlen       ),
  .out_wvalid      ( out_wvalid      ),
  .out_wready      ( out_wready      ),
  .out_wdata       ( out_wdata       ),
  .out_wstrb       ( out_wstrb       ),
  .out_wlast       ( out_wlast       ),
  .out_bvalid      ( out_bvalid      ),
  .out_bready      ( out_bready      ),
  .out_arvalid     ( out_arvalid     ),
  .out_arready     ( out_arready     ),
  .out_araddr      ( out_araddr      ),
  .out_arlen       ( out_arlen       ),
  .out_rvalid      ( out_rvalid      ),
  .out_rready      ( out_rready      ),
  .out_rdata       ( out_rdata       ),
  .out_rlast       ( out_rlast       ),
  .ap_start        ( ap_start        ),
  .ap_done         ( ap_done         ),
  .ap_idle         ( ap_idle         ),
  .ap_ready        ( ap_ready        ),
  .scalar00        ( scalar00        ),
  .scalar01        ( scalar01        ),
  .scalar02        ( scalar02        ),
  .scalar03        ( scalar03        ),
  .inst_ptr0       ( inst_ptr0       ),
  .weight_ptr0     ( weight_ptr0     ),
  .feature_ptr0    ( feature_ptr0    ),
  .out_ptr0        ( out_ptr0        )
);

endmodule
`default_nettype wire

