`timescale 1ns / 1ps
`define PERIOD 10

module load_tb();
// parameters
parameter integer LOAD_INST_LENGTH         = 96;
parameter integer C_M_AXI_ADDR_WIDTH       = 64;
parameter integer C_M_AXI_DATA_WIDTH       = 512;
parameter integer C_XFER_SIZE_WIDTH        = 32;
parameter integer C_ADDER_BIT_WIDTH        = 32;

///////////////////////////////////////////////////////////////////////////////
// mem signals
///////////////////////////////////////////////////////////////////////////////
// AXI4 Ports for simulation
// reading ctrl port, use it
wire [C_M_AXI_ADDR_WIDTH-1:0] dram_xfer_start_addr   ;
wire [C_XFER_SIZE_WIDTH -1:0] dram_xfer_size_in_bytes;
// AXI read master stage, use it
wire                    read_start;
wire                     read_done;
// receiving data port stage, use it
reg                          data_tvalid;
wire                         data_tready;
reg                          data_tlast;
reg [C_M_AXI_DATA_WIDTH-1:0] data_tdata;

///////////////////////////////////////////////////////////////////////////////
// control signals
///////////////////////////////////////////////////////////////////////////////
// ctrl signals connected with ctrl module, use it
reg                                    ap_start           ;
wire                                    ap_done            ;
reg [C_M_AXI_ADDR_WIDTH-1:0]           ctrl_addr_offset   ;
reg [LOAD_INST_LENGTH  -1:0]           ctrl_instruction   ;
// Extra clocks (don't change)
reg                                    kernel_clk         ;
reg                                    kernel_rst         ;

///////////////////////////////////////////////////////////////////////////////
// buffer signals
///////////////////////////////////////////////////////////////////////////////
// write to buffer port commected with buffer, use it
wire                                   load_write_buffer_valid;
wire [9-1:0]                           load_write_buffer_addr      ;
wire [C_M_AXI_DATA_WIDTH-1:0]          load_write_buffer_data      ;

///////////////////////////////////////////////////////////////////////////////
// unrelated signals
///////////////////////////////////////////////////////////////////////////////
// System Signals (don't change)
wire                                    aclk               ;
wire                                    areset             ;
// AXI4 master interface (don't change)
wire                                   m_axi_arvalid      ;
wire                                    m_axi_arready      ;
wire [C_M_AXI_ADDR_WIDTH-1:0]          m_axi_araddr       ;
wire [8-1:0]                           m_axi_arlen        ;
wire                                    m_axi_rvalid       ;
wire                                   m_axi_rready       ;
wire [C_M_AXI_DATA_WIDTH-1:0]           m_axi_rdata        ;
wire                                    m_axi_rlast        ;

///////////////////////////////////////////////////////////////////////////////
// load module
///////////////////////////////////////////////////////////////////////////////
gnn_0_example_load load (
    .aclk(aclk),
    .areset(areset),
    .kernel_clk(kernel_clk),
    .kernel_rst(kernel_rst),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rlast(m_axi_rlast),
    .load_write_buffer_valid(load_write_buffer_valid),
    .load_write_buffer_addr(load_write_buffer_addr),
    .load_write_buffer_data(load_write_buffer_data),
    // ctrl signals connected with ctrl module, use it
    .ap_start(ap_start),
    .ap_done(ap_done),
    .ctrl_addr_offset(ctrl_addr_offset),
    .ctrl_instruction(ctrl_instruction),
    // AXI4 Ports for simulation
    // reading ctrl port, use it
    .dram_xfer_start_addr(dram_xfer_start_addr),
    .dram_xfer_size_in_bytes(dram_xfer_size_in_bytes),
    // AXI read master stage, use it
    .read_start(read_start),
    .read_done(read_done),
    // receiving data port stage, use it
    .data_tvalid(data_tvalid),
    .data_tready(data_tready),
    .data_tlast(data_tlast),
    .data_tdata(data_tdata)
);

///////////////////////////////////////////////////////////////////////////////
// simulation setup
///////////////////////////////////////////////////////////////////////////////
// Generate the clock
initial begin
    forever
        #(`PERIOD/2) kernel_clk = ~kernel_clk;
end
// simulation setup
initial begin
    // Initialization
    kernel_rst = 0;
    kernel_clk = 0;
    // mem
    data_tvalid = 0;
    data_tdata = 0;
    data_tlast = 0;
    // ctrl
    ap_start = 0;
    ctrl_addr_offset = 0;
    ctrl_instruction = 0;
    // Reset
    #(`PERIOD*5)
    kernel_rst = 1'b1;
    #(`PERIOD)
    kernel_rst = 1'b0;
    // send instructions
    #(`PERIOD)
    ap_start = 1; 
    ctrl_addr_offset = 0;
    ctrl_instruction = {16'd128,16'd0,16'd2,16'd0,16'd0,10'd0,6'd1};
    #(`PERIOD)
    ap_start = 0;
    ctrl_addr_offset = 0;
    ctrl_instruction = 0;
    #(`PERIOD*10)
    ap_start = 1; 
    ctrl_addr_offset = 0;
    ctrl_instruction = {16'd1024,16'd0,16'd16,16'd12,16'd0,10'd0,6'd2};
    #(`PERIOD)
    ap_start = 0;
    ctrl_addr_offset = 0;
    ctrl_instruction = 0;
end

///////////////////////////////////////////////////////////////////////////////
// mem simulation
///////////////////////////////////////////////////////////////////////////////
reg [1:0] mem_state;
reg [1:0] delay_count;
reg [8:0] write_count;
reg [C_XFER_SIZE_WIDTH -1:0] dram_size_in_bytes;
// mem simulation
always@(posedge kernel_rst or posedge read_start or posedge kernel_clk) begin
    if(kernel_rst) begin
        data_tvalid <= 0;
        data_tdata <= 0;
        data_tlast <= 0;
        mem_state <= 0;
        delay_count <= 0;
        write_count <= 0;
        dram_size_in_bytes <= 0;
    end
    else begin
        if(read_start) begin
            mem_state <= 2'b01;
            delay_count <= 2'b11;
            dram_size_in_bytes <= dram_xfer_size_in_bytes;
        end
        else begin
            case(mem_state)
                // preparing
                2'b01:begin
                    if(delay_count==0) begin
                        mem_state <= 2'b10;
                        write_count <= dram_size_in_bytes>>6;
                    end else delay_count<= delay_count-1;
                end
                // outputing
                2'b10:begin
                    if(write_count==0) begin
                        data_tvalid <= 0;
                        mem_state <= 2'b00;
                    end
                    else begin
                        write_count <= write_count -1;
                        data_tvalid <= 1;
                        data_tdata <= write_count;
                    end
                end
            endcase
        end
    end
end
///////////////////////////////////////////////////////////////////////////////
// ctrl simulation
///////////////////////////////////////////////////////////////////////////////


endmodule
