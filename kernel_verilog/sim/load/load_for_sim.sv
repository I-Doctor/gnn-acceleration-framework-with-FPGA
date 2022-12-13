// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module gnn_0_example_load #(
  parameter integer LOAD_INST_LENGTH         = 96,
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
  output wire                                   load_write_buffer_valid_0,
  output wire [11-1:0]                           load_write_buffer_addr_0,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          load_write_buffer_data_0,
  output wire                                   load_write_buffer_valid_1,
  output wire [11-1:0]                           load_write_buffer_addr_1,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          load_write_buffer_data_1,
  output wire                                   load_write_buffer_valid_2,
  output wire [11-1:0]                           load_write_buffer_addr_2,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          load_write_buffer_data_2,
  // ctrl signals connected with ctrl module, use it
  input wire                                    ap_start           ,
  output wire                                   ap_done            ,
  input wire [C_M_AXI_ADDR_WIDTH-1:0]           ctrl_addr_offset   ,
  input wire [LOAD_INST_LENGTH  -1:0]           ctrl_instruction   ,
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
reg [5:0] group; // inst[5:0]
reg [C_M_AXI_ADDR_WIDTH-1:0] dram_offset;
// states
reg processing; // working state
reg hold; // hold for 1 cycle
reg done;
reg pre_done;
reg read_AXI4;
// counts
reg [11-1:0] count; // read times
reg [11-1:0] target_count; // target read times
// buffer write
reg write_valid_0;
reg [11-1:0] write_addr_0;
reg [C_M_AXI_DATA_WIDTH-1:0] write_data_0;
reg write_valid_1;
reg [11-1:0] write_addr_1;
reg [C_M_AXI_DATA_WIDTH-1:0] write_data_1;
reg write_valid_2;
reg [11-1:0] write_addr_2;
reg [C_M_AXI_DATA_WIDTH-1:0] write_data_2;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// dram read addr
assign dram_xfer_start_addr = dram_offset + dram_start_address;
assign dram_xfer_size_in_bytes = dram_byte_length;
// wire connection
assign read_start = read_AXI4;
assign ap_done = done;
assign load_write_buffer_valid_0 = write_valid_0;
assign load_write_buffer_addr_0 = write_addr_0;
assign load_write_buffer_data_0 = write_data_0;
assign load_write_buffer_valid_1 = write_valid_1;
assign load_write_buffer_addr_1 = write_addr_1;
assign load_write_buffer_data_1 = write_data_1;
assign load_write_buffer_valid_2 = write_valid_2;
assign load_write_buffer_addr_2 = write_addr_2;
assign load_write_buffer_data_2 = write_data_2;

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
        group <= 0;
        // write buffer
        write_valid_0 <= 0;
        write_addr_0 <= 0;
        write_data_0 <= 0;
        write_valid_1 <= 0;
        write_addr_1 <= 0;
        write_data_1 <= 0;
        write_valid_2 <= 0;
        write_addr_2 <= 0;
        write_data_2 <= 0;
    end
    else begin
        // reading
        if(processing) begin
            // reset read_AXI4
            if(read_AXI4) read_AXI4<=0;
            // if data valid
            if (data_tvalid) begin
                case(group)
                    6'b000001: begin
                        write_valid_0 <= 1;
                        write_addr_0 <= buffer_start_address[11-1:0] + count;
                        write_data_0 <= data_tdata;
                    end
                    6'b000010: begin
                        write_valid_1 <= 1;
                        write_addr_1 <= buffer_start_address[11-1:0] + count;
                        write_data_1 <= data_tdata;
                    end
                    6'b000100: begin
                        write_valid_2 <= 1;
                        write_addr_2 <= buffer_start_address[11-1:0] + count;
                        write_data_2 <= data_tdata;
                    end
                endcase
                count <= count + 1;
                // if read finish
                if (count == target_count-1) begin
                    // reset count
                    count <= 0;
                    // reset group
                    group <= 0;
                    // pre_set done
                    pre_done <= 1;
                    // change to idle
                    processing <= 0;
                end
            end
            else begin
                case(group)
                    6'b000001: write_valid_0 <= 0;
                    6'b000010: write_valid_1 <= 0;
                    6'b000100: write_valid_2 <= 0;
                endcase
            end
        end
        // idle
        else begin
            // reset write to buffer 0
            if(write_valid_0) begin
                write_valid_0 <= 0;
                write_addr_0 <= 0;
                write_data_0 <= 0;
            end
            // reset write to buffer 1
            if(write_valid_1) begin
                write_valid_1 <= 0;
                write_addr_1 <= 0;
                write_data_1 <= 0;
            end
            // reset write to buffer 2
            if(write_valid_2) begin
                write_valid_2 <= 0;
                write_addr_2 <= 0;
                write_data_2 <= 0;
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
                target_count <= buffer_address_length[11-1:0];
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
                group <= ctrl_instruction[5:0];
                // hold for next cycle
                hold <= 1;
            end
        end
    end
end

endmodule : gnn_0_example_load
`default_nettype wire