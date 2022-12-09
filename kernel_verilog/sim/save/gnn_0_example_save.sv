// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module gnn_0_example_save #(
  parameter integer SAVE_INST_LENGTH         = 96,
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
  output wire                                   m_axi_awvalid      ,
  input wire                                    m_axi_awready      ,
  output wire [C_M_AXI_ADDR_WIDTH  -1:0]        m_axi_awaddr       ,
  output wire [8-1:0]                           m_axi_awlen        ,
  output wire                                   m_axi_wvalid       ,
  input wire                                    m_axi_wready       ,
  output wire [C_M_AXI_DATA_WIDTH  -1:0]        m_axi_wdata        ,
  output wire [C_M_AXI_DATA_WIDTH/8-1:0]        m_axi_wstrb        ,
  output wire                                   m_axi_wlast        ,
  input wire                                    m_axi_bvalid       ,
  output wire                                   m_axi_bready       ,
  // read from buffer port commected with buffer, use it
  output logic                                  save_read_buffer_addr_valid,
  output logic [11-1:0]                         save_read_buffer_addr      ,
  input wire                                    save_read_buffer_data_valid,
  input wire  [C_M_AXI_DATA_WIDTH-1:0]          save_read_buffer_data      ,
  // ctrl signals connected with ctrl module, use it
  input wire                                    ap_start           ,
  output wire                                   ap_done            ,
  input wire  [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_addr_offset   ,
  input wire  [SAVE_INST_LENGTH  -1:0]          ctrl_instruction   ,
  input wire                                   data_tready        ,
  output logic                                  data_tvalid        ,
  output logic [C_M_AXI_DATA_WIDTH-1:0]         data_tdata         
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

// Control logic
logic                          done = 1'b0;
// writting ctrl port, use it
logic [C_M_AXI_ADDR_WIDTH-1:0] dram_xfer_start_addr;
logic [C_XFER_SIZE_WIDTH-1:0] dram_xfer_size_in_bytes;
// writting data port stage, use it
// AXI write master stage, use it 
logic                          write_done;
logic                          write_start;


logic [C_M_AXI_DATA_WIDTH-1:0] FIFO [0:4-1];
logic [1:0] FIFO_head;
logic [1:0] FIFO_tail;
logic [2:0] FIFO_count;
logic [11-1:0] buffer_cur_addr;
logic [11-1:0] buffer_end_addr;
logic [7:0] clk_cnt;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////




always @(posedge aclk or posedge areset) begin
  if (areset) begin
    write_start <= 1'b0;
    dram_xfer_start_addr <= 0;
    dram_xfer_size_in_bytes <= 0;
    buffer_cur_addr <= 0;
    buffer_end_addr <= 0;
    FIFO_head <= 0;
    FIFO_tail <= 0;
    FIFO_count <= 0;
    FIFO[0] <= 0;
    FIFO[1] <= 0;
    FIFO[2] <= 0;
    FIFO[3] <= 0;
    save_read_buffer_addr_valid <= 0;
    data_tvalid <= 0;
    clk_cnt <= 0;
  end else begin
    if (ap_start) begin
      write_start <= 1'b1;
      write_done <= 1'b0;
      dram_xfer_start_addr <= ctrl_instruction[SAVE_INST_LENGTH-17:SAVE_INST_LENGTH-32];  
      dram_xfer_size_in_bytes <= ctrl_instruction[SAVE_INST_LENGTH-1:SAVE_INST_LENGTH-16]; 
      buffer_cur_addr <= ctrl_instruction[SAVE_INST_LENGTH-49:SAVE_INST_LENGTH-64]; 
      buffer_end_addr <= ctrl_instruction[SAVE_INST_LENGTH-49:SAVE_INST_LENGTH-64] + ctrl_instruction[SAVE_INST_LENGTH-33:SAVE_INST_LENGTH-48];
      save_read_buffer_addr_valid <= 0;
      data_tvalid <= 0;
    end else if (ap_done) begin
      write_start <= 1'b0;
      dram_xfer_start_addr <= 0;
      dram_xfer_size_in_bytes <= 0;
      buffer_cur_addr <= 0;
      buffer_end_addr <= 0;
      save_read_buffer_addr_valid <= 0;
      data_tvalid <= 0;
    end



    if (write_start) begin
        if (data_tvalid && data_tready) begin
          if (save_read_buffer_data_valid) begin
            if (FIFO_count == 0) begin
              data_tvalid <= 1'b1;
              data_tdata <= save_read_buffer_data;
            end
            else begin
              data_tvalid <= 1'b1;
              data_tdata <= FIFO[FIFO_head];
              FIFO[FIFO_tail] <= save_read_buffer_data;
              FIFO_head <= FIFO_head + 1;
              FIFO_tail <= FIFO_tail + 1;
            end
          end else
            if (FIFO_count == 0) begin
              data_tvalid <= 1'b0;
            end
            else begin
              data_tvalid <= 1'b1;
              data_tdata <= FIFO[FIFO_head];
              FIFO_head <= FIFO_head + 1;
              FIFO_count <= FIFO_count - 1;
            end
        end else if (data_tvalid && !data_tready) begin
          data_tvalid <= 1'b1;
          data_tdata <= data_tdata;
          if (save_read_buffer_data_valid) begin
            FIFO[FIFO_tail] <= save_read_buffer_data;
            FIFO_tail <= FIFO_tail + 1;
            FIFO_count <= FIFO_count + 1;
          end
        end else if (!data_tvalid) begin
          if (save_read_buffer_data_valid) begin
            if (FIFO_count == 0) begin
              data_tvalid <= 1'b1;
              data_tdata <= save_read_buffer_data;
            end else begin
              data_tvalid <= 1'b1;
              data_tdata <= FIFO[FIFO_head];
              FIFO[FIFO_tail] <= save_read_buffer_data;
              FIFO_head <= FIFO_head + 1;
              FIFO_tail <= FIFO_tail + 1;
            end
          end else begin
            if (FIFO_count == 0) begin
              data_tvalid <= 1'b0;
            end else begin
              data_tvalid <= 1'b1;
              data_tdata <= FIFO[FIFO_head];
              FIFO_head <= FIFO_head + 1;
              FIFO_count <= FIFO_count - 1;
            end
          end
        end else begin
          data_tvalid <= 1'b0;
        end

      if (FIFO_count == 0 && !save_read_buffer_data_valid && buffer_cur_addr < buffer_end_addr) begin
        save_read_buffer_addr_valid <= 1'b1;
        save_read_buffer_addr <= buffer_cur_addr;
        buffer_cur_addr <= buffer_cur_addr + 1;
      end else
        save_read_buffer_addr_valid <= 1'b0;

      if (buffer_cur_addr == buffer_end_addr && !write_done)
        clk_cnt <= clk_cnt + 1;
      if (clk_cnt >= 4 && FIFO_count == 0 && {data_tvalid,data_tready} == 2'b11) begin
        write_done <= 1'b1;
        clk_cnt <= 0;
      end

    end
  end
end




assign ap_done = write_done;

endmodule : gnn_0_example_save
`default_nettype wire

