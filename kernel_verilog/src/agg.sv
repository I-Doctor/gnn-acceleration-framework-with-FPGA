// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module agg #(
  parameter integer AGG_INST_LENGTH          = 128,
  parameter integer C_M_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_M_AXI_DATA_WIDTH       = 512,
  parameter integer C_XFER_SIZE_WIDTH        = 32,
  parameter integer C_ADDER_BIT_WIDTH        = 32
)
(
  // System Signals (don't change)
  input wire                                    aclk               ,
  input wire                                    areset             ,
  // Extra clocks (don't change)
  input wire                                    kernel_clk         ,
  input wire                                    kernel_rst         ,
  // AXI4 master interface (don't change)
  output wire                                   m_axi_arvalid      ,
  input wire                                    m_axi_arready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_axi_araddr       ,
  output wire [8-1:0]                           m_axi_arlen        ,
  input wire                                    m_axi_rvalid       ,
  output wire                                   m_axi_rready       ,
  input wire [C_M_AXI_DATA_WIDTH-1:0]           m_axi_rdata        ,
  input wire                                    m_axi_rlast        ,
  // write to buffer port commected with buffer, use it
  output reg                                    agg_write_buffer_1_A_valid ,
  output reg  [11               -1:0]           agg_write_buffer_1_A_addr  ,
  output reg  [512              -1:0]           agg_write_buffer_1_A_data  ,
  output reg                                    agg_write_buffer_1_B_valid ,
  output reg  [11               -1:0]           agg_write_buffer_1_B_addr  ,
  output reg  [512              -1:0]           agg_write_buffer_1_B_data  ,
  // read from buffer b port
  output reg                                    agg_read_buffer_b_avalid   ,
  output reg  [9                -1:0]           agg_read_buffer_b_addr     ,
  input wire                                    agg_read_buffer_b_valid    ,
  input wire  [512              -1:0]           agg_read_buffer_b_data     ,
  // read from buffer port
  output reg                                    agg_read_buffer_0_avalid   ,
  output reg  [11               -1:0]           agg_read_buffer_0_addr     ,
  input wire                                    agg_read_buffer_0_valid    ,
  input wire  [512              -1:0]           agg_read_buffer_0_data     ,
  output reg                                    agg_read_buffer_1_A_avalid ,
  output reg  [11               -1:0]           agg_read_buffer_1_A_addr   ,
  input wire                                    agg_read_buffer_1_A_valid  ,
  input wire  [512              -1:0]           agg_read_buffer_1_A_data   ,
  output reg                                    agg_read_buffer_1_B_avalid ,
  output reg  [11               -1:0]           agg_read_buffer_1_B_addr   ,
  input wire                                    agg_read_buffer_1_B_valid  ,
  input wire  [512              -1:0]           agg_read_buffer_1_B_data   ,
  // ctrl signals connected with ctrl module, use it
  input wire                                    ap_start           ,
  output reg                                    ap_done            ,
  input wire [C_M_AXI_ADDR_WIDTH-1:0]           ctrl_addr_offset   ,
  input wire [AGG_INST_LENGTH  -1:0]            ctrl_instruction
);

timeunit 1ns;
timeprecision 10ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES             = C_M_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN        = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN        = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_BRAM_DEPTH           = 512;
localparam integer LP_RD_MAX_OUTSTANDING   = LP_BRAM_DEPTH / LP_AXI_BURST_LEN;
localparam integer LP_WR_MAX_OUTSTANDING   = 320;
//localparam integer BUFFER_ADDR_WIDTH       = 11;
//localparam integer BUFFER_DATA_WIDTH       = 512;

///////////////////////////////////////////////////////////////////////////////
// Wires
///////////////////////////////////////////////////////////////////////////////
// DRAM
// reading ctrl port, use it
logic [C_M_AXI_ADDR_WIDTH-1:0] dram_xfer_start_addr;
logic [C_XFER_SIZE_WIDTH -1:0] dram_xfer_size_in_bytes;
// AXI read master stage, use it
logic                          read_start;
logic                          read_done;
// receiving data port stage, use it
logic                          data_tvalid;
logic                          data_tready;
logic                          data_tlast;
logic [C_M_AXI_DATA_WIDTH-1:0] data_tdata;

///////////////////////////////////////////////////////////////////////////////
// Control Regs
///////////////////////////////////////////////////////////////////////////////
// Instruction
reg [5:0] in_group;                 // inst[5:0]
reg [5:0] out_group;                // inst[11:6]
reg [0:0] reduce_type;              // inst[15]
reg b,e,r;                          // inst[14:12]
reg [15:0] input_start_address;     // inst[47:32]
reg [11:0] bias_start_address;      // inst[55:48]
reg [15:0] address_per_feature;     // inst[63:56]
reg [15:0] output_start_address;   // inst[79:64]
reg [15:0] edge_number;             // inst[95:80]
reg [31:0] adj_dram_start_address;  // inst[127:96]
reg [C_M_AXI_ADDR_WIDTH-1:0] dram_offset;

// Edge
reg [511:0] edge_512;
reg [63:0] edge_64;

// Counting
reg [12:0] dram_read_count; // 0~(edge_number>>3)-1
reg [12:0] dram_read_num;
reg [2:0] edge_count; // 0~7
reg [15:0] buffer_addr_count; // 0~addr_per_feature-1
reg [3:0] pipeline_count; // 0~5

// State
reg processing; // agg processing inst
reg hold; // hold for one cycle
reg processing_dram; // process 512 bit from dram
reg processing_edge; // process 64 bit edge
reg waiting_pipeline; // wait for pipeline to finish computing
reg read_AXI4; // start read dram
reg receive_ready; //ready to receive data

///////////////////////////////////////////////////////////////////////////////
// Pipeline Wires & Regs
///////////////////////////////////////////////////////////////////////////////
// read_0
reg                         read_0_valid;
reg                         read_0_first;
reg                         read_0_finish;
reg [11               -1:0] read_0_in_addr;
reg [11               -1:0] read_0_out_addr;
reg [32-1:0]                read_0_value;
// read_1
reg                         read_1_valid;
reg                         read_1_first;
reg                         read_1_finish;
reg [11               -1:0] read_1_out_addr;
reg [32-1:0]                read_1_value;
// read_2
reg                         read_2_valid;
reg                         read_2_first;
reg                         read_2_finish;
reg [11               -1:0] read_2_out_addr;
reg [32-1:0]                read_2_value;
// read_3
reg                         read_3_valid;
reg                         read_3_first;
reg                         read_3_finish;
reg [11               -1:0] read_3_out_addr;
reg [32-1:0]                read_3_value;
// read_4
reg                         read_4_valid;
reg                         read_4_first;
reg                         read_4_finish;
reg [11               -1:0] read_4_out_addr;
reg [32-1:0]                read_4_value;
wire [512-1:0]              read_4_in_data;
wire [512-1:0]              read_4_out_data;
// multi
reg                         mul_valid;
reg                         mul_first;
reg                         mul_finish;
reg [11               -1:0] mul_out_addr;
reg [512-1:0]               mul_out_data;
wire [512-1:0]              mul_result;
wire [15:0]                 mul_result_valid;
// add
reg                         add_valid;
reg                         add_finish;
reg [11               -1:0] add_out_addr;
wire [512-1:0]              add_result;
wire [15:0]                 add_result_valid;
// write back
reg wb_finish;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// AXI4 Read Master, output format is an AXI4-Stream master, one stream per thread.
gnn_0_example_axi_read_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH     ) ,
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING ) ,
  .C_INCLUDE_DATA_FIFO ( 1                     )
)
inst_axi_read_master (
  .aclk                    ( aclk                    ) ,
  .areset                  ( areset                  ) ,
  // ctrl signals of read master module
  // send addr_offset and xfer_size first at the posedge of read_start
  // than return data with receiving from data port
  .ctrl_start              ( read_start              ) , 
  .ctrl_done               ( read_done               ) ,
  .ctrl_addr_offset        ( dram_xfer_start_addr    ) , 
  .ctrl_xfer_size_in_bytes ( dram_xfer_size_in_bytes ) , 
  // axi port (don't change)
  .m_axi_arvalid           ( m_axi_arvalid           ) ,
  .m_axi_arready           ( m_axi_arready           ) ,
  .m_axi_araddr            ( m_axi_araddr            ) ,
  .m_axi_arlen             ( m_axi_arlen             ) ,
  .m_axi_rvalid            ( m_axi_rvalid            ) ,
  .m_axi_rready            ( m_axi_rready            ) ,
  .m_axi_rdata             ( m_axi_rdata             ) ,
  .m_axi_rlast             ( m_axi_rlast             ) ,
  .m_axis_aclk             ( kernel_clk              ) ,
  .m_axis_areset           ( kernel_rst              ) ,
  // receiving data port, use it
  .m_axis_tvalid           ( data_tvalid             ) ,
  .m_axis_tready           ( data_tready             ) ,
  .m_axis_tlast            ( data_tlast              ) ,
  .m_axis_tdata            ( data_tdata              ) 
);

// Wire connection
assign read_start = read_AXI4;
assign data_tready = receive_ready;
assign dram_xfer_start_addr = dram_offset + adj_dram_start_address;
assign dram_xfer_size_in_bytes = edge_number<<3;

// Controlling
reg read_0_last;
always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        // state
        processing <= 0;
        hold <= 0;
        processing_dram <= 0;
        ap_done <= 1'b1;
        // read
        read_AXI4 <= 0;
        receive_ready <= 0;
        // edge data
        edge_512 <= 0;
        edge_64 <= 0;
        // count
        dram_read_count <= 0;
        dram_read_num <= 0;
        edge_count <= 0;
        buffer_addr_count <= 0;
        pipeline_count <= 0;
        // Instruction
        in_group <= 0;
        out_group <= 0;
        b <= 0;
        e <= 0;
        r <= 0;
        input_start_address <= 0;
        address_per_feature <= 0;
        output_start_address <= 0;
        reduce_type <= 0;
        bias_start_address <= 0;
        adj_dram_start_address <= 0;
        edge_number <= 0;
        dram_offset <= 0;
        // read and delay register 
        read_0_valid  <= 0;
        read_0_first  <= 0;
        read_0_last   <= 0;
        read_0_finish <= 0;
        read_0_in_addr  <= 0;
        read_0_out_addr <= 0;
        read_0_value    <= 0;
    end
    else begin
        // reading
        if(processing) begin
            // reset read_AXI4
            if(read_AXI4) read_AXI4<=0; 
            // processing dram data
            if(processing_dram) begin                
                // wait for pipeline computing
                if(waiting_pipeline) begin
                    // reset valid
                    read_0_valid <= 0;
                    // finish 1 edge pipeline, else waiting
                    if(wb_finish) begin
                        waiting_pipeline <= 0;
                        buffer_addr_count <= 0;
                        // finish 8 edges, else continue next edge
                        if(edge_count==3'b111) begin
                            processing_dram <= 0;
                            // finish 1 inst, else continue next dram reading
                            if(dram_read_count==dram_read_num-1) begin
                                processing <= 0;
                                ap_done <= 1;
                            end
                            // finish 1 inst, else continue next dram reading
                            else begin
                                dram_read_count <= dram_read_count + 1;
                                receive_ready <= 1; // start receiving
                            end       
                        end
                        // finish 8 edges, else continue next edge
                        else begin
                            edge_count <= edge_count + 1;
                            edge_64 <= edge_512[63:0];
                            edge_512 <= edge_512 >> 64;
                        end
                    end
                end
                // send edges to pipeline
                else begin
                    // send 1 edge to read_0
                    read_0_valid <= 1;
                    read_0_first <= edge_64[63];
                    read_0_last  <= edge_64[47];
                    read_0_in_addr <= input_start_address + address_per_feature*edge_64[46:32] + buffer_addr_count;
                    read_0_out_addr <= output_start_address + address_per_feature*edge_64[62:48] + buffer_addr_count;
                    read_0_value <= edge_64[31:0];
                    // finish sending
                    if(buffer_addr_count==address_per_feature-1) begin
                        waiting_pipeline <= 1;
                        read_0_finish <= 1;
                    end
                    else begin
                        buffer_addr_count <= buffer_addr_count + 1;
                        read_0_finish <= 0;
                    end
                end
            end
            // if reading dram
            else begin
                // if data is valid
                if(data_tvalid) begin
                    // set up for processing dram data
                    processing_dram <= 1;
                    edge_512 <= data_tdata >> 64;
                    edge_64 <= data_tdata[63:0];
                    edge_count <= 0;
                    // stop receiving dram data
                    receive_ready <= 0;
                end
            end
        end
        // idle
        else begin
            // reset done
            if(ap_done) ap_done <= 0;
            // start reading
            if(hold) begin
                // set up for reading
                dram_read_count <= 0;
                dram_read_num <= edge_number >>3;
                read_AXI4 <= 1;
                receive_ready <= 1;
                // change state
                hold <= 0;
                processing <= 1;
                processing_dram <= 0;
            end
            else if(ap_start) begin
                // decode inst
                dram_offset <= ctrl_addr_offset;
                in_group <= ctrl_instruction[5:0];
                out_group <= ctrl_instruction[11:6];
                {reduce_type,b,e,r} <= ctrl_instruction[15:12];
                address_per_feature <= ctrl_instruction[63:56];
                bias_start_address <= ctrl_instruction[55:48];
                input_start_address <= ctrl_instruction[47:32];
                output_start_address <= ctrl_instruction[79:64];
                //reduce_type <= ctrl_instruction[83:80];
                edge_number <= ctrl_instruction[95:80];
                adj_dram_start_address <= ctrl_instruction[127:96];
                // hold for next cycle
                hold <= 1;
            end
        end
    end
end

///////////////////////////////////////////////////////////////////////////////
// Pipeline
///////////////////////////////////////////////////////////////////////////////

// agg_read_buffer* should be same with read_0_valid but not enalbled by read_0_valid
always@(*) begin
    if(read_0_valid) begin
        // read input & output buffer
        agg_read_buffer_b_addr    <=  read_0_out_addr - address_per_feature*edge_64[62:48] - output_start_address + bias_start_address;
        agg_read_buffer_b_avalid  <=  1'b1;
        agg_read_buffer_0_addr    <=  ((in_group==6'b000001)?read_0_in_addr:0)+((out_group==6'b000001)?read_0_out_addr:0);
        agg_read_buffer_0_avalid  <=  ((in_group==6'b000001)?1:0)             +((out_group==6'b000001)?1:0);
        agg_read_buffer_1_A_addr  <=  ((in_group==6'b000010)?read_0_in_addr:0)+((out_group==6'b000010)?read_0_out_addr:0);
        agg_read_buffer_1_A_avalid<=  ((in_group==6'b000010)?1:0)             +((out_group==6'b000010)?1:0);
        agg_read_buffer_1_B_addr  <=  ((in_group==6'b000100)?read_0_in_addr:0)+((out_group==6'b000100)?read_0_out_addr:0);
        agg_read_buffer_1_B_avalid<=  ((in_group==6'b000100)?1:0)             +((out_group==6'b000100)?1:0);
    end else begin
        agg_read_buffer_b_addr    <=0;
        agg_read_buffer_b_avalid  <=0;
        agg_read_buffer_0_addr    <=0;
        agg_read_buffer_0_avalid  <=0;
        agg_read_buffer_1_A_addr  <=0;
        agg_read_buffer_1_A_avalid<=0;
        agg_read_buffer_1_B_addr  <=0;
        agg_read_buffer_1_B_avalid<=0;
    end
end

// read_1
reg read_1_last;
always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        read_1_valid <= 0;
        read_1_first <= 0;
        read_1_last <= 0;
        read_1_finish <= 0;
        read_1_out_addr <= 0;
        read_1_value <= 0;
    end
    else begin
        if(read_0_valid) begin
            // reg
            read_1_valid <= read_0_valid;
            read_1_first <= read_0_first;
            read_1_last <= read_0_last;
            read_1_finish <= read_0_finish;
            read_1_out_addr <= read_0_out_addr;
            read_1_value <= read_0_value;
        end
        else begin
            read_1_valid <= 0;
            read_1_first <= 0;
            read_1_last  <= 0;
            read_1_finish <= 0;
            read_1_out_addr <= 0;
            read_1_value <= 0;
        end
    end
end

// read_2
reg read_2_last;
always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        read_2_valid <= 0;
        read_2_first <= 0;
        read_2_last  <= 0;
        read_2_finish <= 0;
        read_2_out_addr <= 0;
        read_2_value <= 0;
    end
    else begin
        if(read_1_valid) begin
            read_2_valid <= read_1_valid;
            read_2_first <= read_1_first;
            read_2_last  <= read_1_last;
            read_2_finish <= read_1_finish;
            read_2_out_addr <= read_1_out_addr;
            read_2_value <= read_1_value;
        end
        else begin
            read_2_valid <= 0;
            read_2_first <= 0;
            read_2_last  <= 0;
            read_2_finish <= 0;
            read_2_out_addr <= 0;
            read_2_value <= 0;
        end
    end
end

// read_3
reg read_3_last;
always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        read_3_valid <= 0;
        read_3_first <= 0;
        read_3_finish <= 0;
        read_3_last  <= 0;
        read_3_out_addr <= 0;
        read_3_value <= 0;
    end
    else begin
        if(read_2_valid) begin
            read_3_valid <= read_2_valid;
            read_3_first <= read_2_first;
            read_3_last  <= read_2_last;
            read_3_finish <= read_2_finish;
            read_3_out_addr <= read_2_out_addr;
            read_3_value <= read_2_value;
        end
        else begin
            read_3_valid <= 0;
            read_3_first <= 0;
            read_3_last  <= 0;
            read_3_finish <= 0;
            read_3_out_addr <= 0;
            read_3_value <= 0;
        end
    end
end

// read_4
reg read_4_last;
always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        read_4_valid <= 0;
        read_4_first <= 0;
        read_4_last <= 0;
        read_4_finish <= 0;
        read_4_out_addr <= 0;
        read_4_value <= 0;
    end
    else begin
        if(read_3_valid) begin
            read_4_valid <= read_3_valid;
            read_4_first <= read_3_first;
            read_4_last <= read_3_last;
            read_4_finish <= read_3_finish;
            read_4_out_addr <= read_3_out_addr;
            read_4_value <= read_3_value;
        end
        else begin
            read_4_valid <= 0;
            read_4_first <= 0;
            read_4_last <= 0;
            read_4_finish <= 0;
            read_4_out_addr <= 0;
            read_4_value <= 0;
        end
    end
end

wire  [512 -1:0] read_4_bias_data;
assign read_4_in_data  = (in_group == 6'b000001) ? (agg_read_buffer_0_data)   :
                         (in_group == 6'b000010) ? (agg_read_buffer_1_A_data) : agg_read_buffer_1_B_data;   // read result
assign read_4_out_data = (out_group == 6'b000001) ? (agg_read_buffer_0_data)   :
                         (out_group == 6'b000010) ? (agg_read_buffer_1_A_data) : agg_read_buffer_1_B_data;
assign read_4_bias_data = agg_read_buffer_b_data;
                         
// mul
reg [512 -1:0] mul_bias_data;
reg mul_last;
genvar i;
generate
    for(i=0;i<16;i=i+1) begin
        floating_point_multiply u_floating_point_multiply(
          .aclk(aclk),
          .s_axis_a_tvalid(read_4_valid),
          .s_axis_a_tdata(read_4_value),
          .s_axis_b_tvalid(read_4_valid),
          .s_axis_b_tdata(read_4_in_data[(i+1)*32-1:i*32]),
          .m_axis_result_tvalid(mul_result_valid[i]),
          .m_axis_result_tdata(mul_result[(i+1)*32-1:i*32])
        );
    end
endgenerate
always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        mul_valid <= 0;
        mul_first <= 0;
        mul_last <= 0;
        mul_finish <= 0;
        mul_out_addr <= 0;
        mul_out_data <= 0;
        mul_bias_data <= 0;
    end
    else begin
        if(read_4_valid) begin
            mul_valid <= read_4_valid;
            mul_first <= read_4_first;
            mul_last <= read_4_last;
            mul_finish <= read_4_finish;
            mul_out_addr <= read_4_out_addr;
            mul_out_data <= read_4_out_data;
            mul_bias_data <= read_4_bias_data;
        end
        else begin
            mul_valid <= 0;
            mul_first <= 0;
            mul_last <= 0;
            mul_finish <= 0;
            mul_out_addr <= 0;
            mul_out_data <= 0;
            mul_bias_data <= 0;
        end
    end
end

// add
reg [512 -1:0] add_bias_data;
reg add_last;
generate
    for(i=0;i<16;i=i+1) begin
        floating_point_add u_floating_point_add(
          .aclk(aclk),
          .s_axis_a_tvalid(mul_valid),
          .s_axis_a_tdata(mul_result[(i+1)*32-1:i*32]),
          .s_axis_b_tvalid(mul_valid),
          .s_axis_b_tdata(mul_first?0:mul_out_data[(i+1)*32-1:i*32]),
          .m_axis_result_tvalid(add_result_valid[i]),
          .m_axis_result_tdata(add_result[(i+1)*32-1:i*32])
        );
    end
endgenerate

always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        add_valid <= 0;
        add_last <= 0;
        add_finish <= 0;
        add_out_addr <= 0;
        add_bias_data <= 0;
    end
    else begin
        if(mul_valid) begin
            add_valid <= mul_valid;
            add_last <= mul_last;
            add_finish <= mul_finish;
            add_out_addr <= mul_out_addr;
            add_bias_data <= mul_bias_data;
        end
        else begin
            add_valid <= 0;
            add_last <= 0;
            add_finish <= 0;
            add_out_addr <= 0;
            add_bias_data <= 0;
        end
    end
end

// bias
wire [16  -1:0] bias_result_valid;
wire [512 -1:0] bias_result;
reg             bias_valid;
reg             bias_last;
reg             bias_finish;
reg  [11  -1:0] bias_out_addr;

generate
    for(i=0;i<16;i=i+1) begin
        floating_point_add u_floating_point_bias(
          .aclk(aclk),
          .s_axis_a_tvalid(add_valid),
          .s_axis_a_tdata(add_result[(i+1)*32-1:i*32]),
          .s_axis_b_tvalid(add_valid),
          .s_axis_b_tdata((b&add_last)?add_bias_data[(i+1)*32-1:i*32]:0),
          .m_axis_result_tvalid(bias_result_valid[i]),
          .m_axis_result_tdata(bias_result[(i+1)*32-1:i*32])
        );
    end
endgenerate

always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        bias_valid <= 0;
        bias_last <= 0;
        bias_finish <= 0;
        bias_out_addr <= 0;
    end
    else begin
        if(add_valid) begin
            bias_valid    <= add_valid;
            bias_last    <= add_last;
            bias_finish   <= add_finish;
            bias_out_addr <= add_out_addr;
        end
        else begin
            bias_valid    <= 0;
            bias_last   <= 0;
            bias_out_addr <= 0;
        end
    end
end

// relu
wire [512-1:0] output_data;
generate
    for(i=0;i<16;i=i+1)begin
        assign output_data[((i+1)*32)-1:i*32] = (bias_result[((i+1)*32)-1]&r&bias_last)==1'b1 ?  32'b0 : bias_result[((i+1)*32)-1:i*32];
    end  
endgenerate

// wb
always@(*) begin
    if(bias_valid) begin
        // read output buffer
        case(out_group)
            6'b000010: begin
                agg_write_buffer_1_A_addr <= bias_out_addr;
                agg_write_buffer_1_A_data <= output_data;
                agg_write_buffer_1_A_valid <= 1;
                agg_write_buffer_1_B_addr <= 0;
                agg_write_buffer_1_B_data <= 0;
                agg_write_buffer_1_B_valid <= 0;
            end
            6'b000100: begin
                agg_write_buffer_1_A_addr <= 0;
                agg_write_buffer_1_A_data <= 0;
                agg_write_buffer_1_A_valid <= 0;
                agg_write_buffer_1_B_addr <= bias_out_addr;
                agg_write_buffer_1_B_data <= output_data;
                agg_write_buffer_1_B_valid <= 1;
            end
        endcase
        wb_finish <= bias_finish;
    end else begin
        wb_finish                   <= 0;
        agg_write_buffer_1_A_addr   <= 0;
        agg_write_buffer_1_A_data   <= 0;
        agg_write_buffer_1_A_valid  <= 0;
        agg_write_buffer_1_B_addr   <= 0;
        agg_write_buffer_1_B_data   <= 0;
        agg_write_buffer_1_B_valid  <= 0;
    end
end

// temp
//always@(posedge kernel_clk) begin
//    // reset
//    if(kernel_rst) begin
//        agg_read_buffer_b_addr   <= 9'b0;
//        agg_read_buffer_b_avalid <= 0;
//    end else begin
//        agg_read_buffer_b_addr   <= 9'b0;
//        agg_read_buffer_b_avalid <= 0;
//    end
//end


endmodule