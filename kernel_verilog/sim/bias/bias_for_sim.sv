// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module gnn_0_example_bias #(
  parameter integer BIAS_INST_LENGTH         = 96,
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
  output wire                                   bias_write_buffer_b_valid   , 
  output wire [9-1:0]                           bias_write_buffer_b_addr    ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          bias_write_buffer_b_data      ,
  // ctrl signals connected with ctrl module, use it
  input wire                                    ap_start           ,
  output wire                                   ap_done            ,
  input wire [C_M_AXI_ADDR_WIDTH-1:0]           ctrl_addr_offset   ,
  input wire [BIAS_INST_LENGTH  -1:0]           ctrl_instruction   ,
  // AXI4 Ports for simulation
  // reading ctrl port, use it
  output wire [C_M_AXI_ADDR_WIDTH-1:0] dram_xfer_start_addr        ,
  output wire [C_XFER_SIZE_WIDTH -1:0] dram_xfer_size_in_bytes,
  // AXI read master stage, use it
  output wire                    read_start,
  input wire                     read_done,
  // receiving data port stage, use it
  input wire                          data_tvalid,
  output wire                         data_tready,
  input wire                          data_tlast,
  input wire [C_M_AXI_DATA_WIDTH-1:0] data_tdata
);

timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES             = C_M_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN        = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN        = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_BRAM_DEPTH           = 512;
localparam integer LP_RD_MAX_OUTSTANDING   = LP_BRAM_DEPTH / LP_AXI_BURST_LEN;
localparam integer LP_WR_MAX_OUTSTANDING   = 32;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////

// inst
reg [15:0] buffer_start_address; // inst[47:32]
reg [15:0] buffer_address_length; // inst[63:48]
reg [15:0] dram_start_address; // inst[79:64]
reg [15:0] dram_byte_length; // inst[95:80]
reg [C_M_AXI_ADDR_WIDTH-1:0] dram_offset;
// states
reg processing; // working state
reg hold; // hold for 1 cycle
reg done;
reg pre_done;
reg read_AXI4;
// counts
reg [9-1:0] count; // read times
reg [9-1:0] target_count; // target read times
// buffer write
reg write_valid;
reg [9-1:0] write_addr;
reg [C_M_AXI_DATA_WIDTH-1:0] write_data;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// dram read addr
assign dram_xfer_start_addr = dram_offset + dram_start_address;
assign dram_xfer_size_in_bytes = dram_byte_length;
// wire connection
assign read_start = read_AXI4;
assign ap_done = done;
assign bias_write_buffer_b_valid = write_valid;
assign bias_write_buffer_b_addr = write_addr;
assign bias_write_buffer_b_data = write_data;

always@(posedge kernel_rst or posedge kernel_clk) begin
    // reset
    if(kernel_rst) begin
        // state
        processing <= 0;
        hold <= 0;
        done <= 1'b1;
        // read
        read_AXI4 <= 0;
        count <= 0;
        target_count <= 0;
        // inst
        buffer_start_address <= 0;
        buffer_address_length <= 0;
        dram_start_address <= 0;
        dram_byte_length <= 0;
        // write buffer
        write_valid <= 0;
        write_addr <= 0;
        write_data <= 0;
    end
    else begin
        // reading
        if(processing) begin
            // reset read_AXI4
            if(read_AXI4) read_AXI4<=0;
            // if data valid
            if (data_tvalid) begin
                write_valid <= 1;
                write_addr <= buffer_start_address[9-1:0] + count;
                write_data <= data_tdata;
                count <= count + 1;
                // if read finish
                if (count == target_count-1) begin
                    // reset count
                    count <= 0;
                    // pre_set done
                    pre_done <= 1;
                    // change to idle
                    processing <= 0;
                end
            end
            else begin
                write_valid <= 0;
            end
        end
        // idle
        else begin
            // reset write
            if(write_valid) begin
                write_valid <= 0;
                write_addr <= 0;
                write_data <= 0;
            end
            // set done
            if(pre_done) begin
                done <= 1;
                pre_done <= 0;
            end
            // reset done
            if(done) done <= 0;
            // start reading
            if(hold) begin
                // set up for reading
                target_count <= buffer_address_length[9-1:0];
                read_AXI4 <= 1;
                // change state
                hold <= 0;
                processing <= 1;
            end
            else if(ap_start) begin
                // decode inst
                dram_offset <= ctrl_addr_offset;
                buffer_start_address <= ctrl_instruction[47:32];
                buffer_address_length <= ctrl_instruction[63:48];
                dram_start_address <= ctrl_instruction[79:64];
                dram_byte_length <= ctrl_instruction[95:80];
                // hold for next cycle
                hold <= 1;
            end
        end
    end
end

endmodule : gnn_0_example_bias
`default_nettype wire