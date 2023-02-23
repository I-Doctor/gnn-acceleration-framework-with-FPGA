// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module load #(
  parameter integer LOAD_INST_BIT_WIDTH      = 128,
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
  output reg                                    load_write_buffer_0_valid,
  output reg [11-1:0]                           load_write_buffer_0_addr,
  output reg [C_M_AXI_DATA_WIDTH-1:0]           load_write_buffer_0_data,
  output reg                                    load_write_buffer_1_A_valid,
  output reg [11-1:0]                           load_write_buffer_1_A_addr,
  output reg [C_M_AXI_DATA_WIDTH-1:0]           load_write_buffer_1_A_data,
  output reg                                    load_write_buffer_1_B_valid,
  output reg [11-1:0]                           load_write_buffer_1_B_addr,
  output reg [C_M_AXI_DATA_WIDTH-1:0]           load_write_buffer_1_B_data,
  output reg                                    load_write_buffer_2_A_valid,
  output reg [11-1:0]                           load_write_buffer_2_A_addr,
  output reg [C_M_AXI_DATA_WIDTH-1:0]           load_write_buffer_2_A_data,
  output reg                                    load_write_buffer_2_B_valid,
  output reg [11-1:0]                           load_write_buffer_2_B_addr,
  output reg [C_M_AXI_DATA_WIDTH-1:0]           load_write_buffer_2_B_data,
  // ctrl signals connected with ctrl module, use it
  input wire                                    ap_start           ,
  output wire                                   ap_done            ,
  input wire [C_M_AXI_ADDR_WIDTH-1:0]           ctrl_addr_offset   ,
  input wire [LOAD_INST_LENGTH  -1:0]           ctrl_instruction   
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
  .m_axis_tready           ( 1'b1                    ) ,
  .m_axis_tlast            ( data_tlast              ) ,
  .m_axis_tdata            ( data_tdata              ) 
);

// dram read addr
assign dram_xfer_start_addr = dram_offset + dram_start_address;
assign dram_xfer_size_in_bytes = dram_byte_length;
// wire connection
assign read_start = read_AXI4;
assign ap_done = done;

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
        load_write_buffer_0_valid <= 0;
        load_write_buffer_0_addr <= 0;
        load_write_buffer_0_data <= 0;
        load_write_buffer_1_A_valid <= 0;
        load_write_buffer_1_A_addr <= 0;
        load_write_buffer_1_A_data <= 0;
        load_write_buffer_1_B_valid <= 0;
        load_write_buffer_1_B_addr <= 0;
        load_write_buffer_1_B_data <= 0;
        load_write_buffer_2_A_valid <= 0;
        load_write_buffer_2_A_addr <= 0;
        load_write_buffer_2_A_data <= 0;
        load_write_buffer_2_B_valid <= 0;
        load_write_buffer_2_B_addr <= 0;
        load_write_buffer_2_B_data <= 0;
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
                        load_write_buffer_0_valid <= 1;
                        load_write_buffer_0_addr <= buffer_start_address[11-1:0] + count;
                        load_write_buffer_0_data <= data_tdata;
                    end
                    6'b000010: begin
                        load_write_buffer_1_A_valid <= 1;
                        load_write_buffer_1_A_addr <= buffer_start_address[11-1:0] + count;
                        load_write_buffer_1_A_data <= data_tdata;
                    end
                    6'b000100: begin
                        load_write_buffer_1_B_valid <= 1;
                        load_write_buffer_1_B_addr <= buffer_start_address[11-1:0] + count;
                        load_write_buffer_1_B_data <= data_tdata;
                    end
                    6'b001000: begin
                        load_write_buffer_2_A_valid <= 1;
                        load_write_buffer_2_A_addr <= buffer_start_address[11-1:0] + count;
                        load_write_buffer_2_A_data <= data_tdata;
                    end
                    6'b010000: begin
                        load_write_buffer_2_B_valid <= 1;
                        load_write_buffer_2_B_addr <= buffer_start_address[11-1:0] + count;
                        load_write_buffer_2_B_data <= data_tdata;
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
                load_write_buffer_0_valid <= 0;
                load_write_buffer_1_A_valid <= 0;
                load_write_buffer_1_B_valid <= 0;
                load_write_buffer_2_A_valid <= 0;
                load_write_buffer_2_B_valid <= 0;
            end
        end
        // idle
        else begin
            // reset write to buffer 0
            if(load_write_buffer_0_valid) begin
                load_write_buffer_0_valid <= 0;
                load_write_buffer_0_addr <= 0;
                load_write_buffer_0_data <= 0;
            end
            // reset write to buffer 1_A
            if(load_write_buffer_1_A_valid) begin
                load_write_buffer_1_A_valid <= 0;
                load_write_buffer_1_A_addr <= 0;
                load_write_buffer_1_A_data <= 0;
            end
            // reset write to buffer 1_B
            if(load_write_buffer_1_B_valid) begin
                load_write_buffer_1_B_valid <= 0;
                load_write_buffer_1_B_addr <= 0;
                load_write_buffer_1_B_data <= 0;
            end
            // reset write to buffer 2_A
            if(load_write_buffer_2_A_valid) begin
                load_write_buffer_2_A_valid <= 0;
                load_write_buffer_2_A_addr <= 0;
                load_write_buffer_2_A_data <= 0;
            end
            // reset write to buffer 2_B
            if(load_write_buffer_2_B_valid) begin
                load_write_buffer_2_B_valid <= 0;
                load_write_buffer_2_B_addr <= 0;
                load_write_buffer_2_B_data <= 0;
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