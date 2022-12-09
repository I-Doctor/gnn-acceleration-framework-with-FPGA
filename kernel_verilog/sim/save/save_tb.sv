`default_nettype none

parameter integer SAVE_INST_LENGTH         = 96;
parameter integer C_M_AXI_ADDR_WIDTH       = 64;
parameter integer C_M_AXI_DATA_WIDTH       = 512;
parameter integer C_XFER_SIZE_WIDTH        = 32;
parameter integer C_ADDER_BIT_WIDTH        = 32;

module tb_gnn_0_example_save;
reg                                      aclk               ;
reg                                      arst_n             ; 
logic                                    kernel_clk         ;
logic                                    kernel_rst         ;
logic                                    m_axi_awvalid      ;
logic                                    m_axi_awready      ;
logic [C_M_AXI_ADDR_WIDTH  -1:0]         m_axi_awaddr       ;
logic [8-1:0]                            m_axi_awlen        ;
logic                                    m_axi_wvalid       ;
logic                                    m_axi_wready       ;
logic [C_M_AXI_DATA_WIDTH  -1:0]         m_axi_wdata        ;
logic [C_M_AXI_DATA_WIDTH/8-1:0]         m_axi_wstrb        ;
logic                                    m_axi_wlast        ;
logic                                    m_axi_bvalid       ;
logic                                    m_axi_bready       ;
logic                                    save_read_buffer_addr_valid;
logic [11-1:0]                           save_read_buffer_addr      ;
logic                                    save_read_buffer_data_valid;
logic  [C_M_AXI_DATA_WIDTH-1:0]          save_read_buffer_data      ;
logic                                    ap_start           ;
logic                                    ap_done            ;
logic  [C_M_AXI_ADDR_WIDTH-1:0]          ctrl_addr_offset   ;
logic  [SAVE_INST_LENGTH  -1:0]          ctrl_instruction   ;
logic                                    data_tready         ;
logic                                    data_tvalid          ;
logic [C_M_AXI_DATA_WIDTH-1:0]           data_tdata           ;

gnn_0_example_save i_save
(
    .aclk                       (aclk              ),
    .areset                     (arst_n            ),
    .kernel_clk                 (kernel_clk        ),
    .kernel_rst                 (kernel_rst        ),
    .m_axi_awvalid              (m_axi_awvalid     ),
    .m_axi_awready              (m_axi_awready     ),
    .m_axi_awaddr               (m_axi_awaddr      ),
    .m_axi_awlen                (m_axi_awlen       ),
    .m_axi_wvalid               (m_axi_wvalid      ),
    .m_axi_wready               (m_axi_wready      ),
    .m_axi_wdata                (m_axi_wdata       ),
    .m_axi_wstrb                (m_axi_wstrb       ),
    .m_axi_wlast                (m_axi_wlast       ),
    .m_axi_bvalid               (m_axi_bvalid      ),
    .m_axi_bready               (m_axi_bready      ),
    .save_read_buffer_addr_valid(save_read_buffer_addr_valid),
    .save_read_buffer_addr      (save_read_buffer_addr      ),
    .save_read_buffer_data_valid(save_read_buffer_data_valid),
    .save_read_buffer_data      (save_read_buffer_data      ),
    .ap_start                   (ap_start          ),
    .ap_done                    (ap_done           ),
    .ctrl_addr_offset           (ctrl_addr_offset  ),
    .ctrl_instruction           (ctrl_instruction  ),
    .data_tready                (data_tready       ),
    .data_tvalid                (data_tvalid       ),
    .data_tdata                 (data_tdata        )
);

localparam CLK_PERIOD = 10;
localparam DRAM_START = 16'b1100110000110011;
localparam DRAM_SIZE  = 16'b000001000000000;
localparam BUFFER_START = 16'b1100110000110011;
localparam BUFFER_SIZE = 16'b0000000000010000;
localparam BUFFER_SIZE2 = 16'b000000000000100;
localparam BLANK = 32'b0;
localparam INST1 = {DRAM_SIZE, DRAM_START, BUFFER_SIZE, BUFFER_START, BLANK};
localparam INST2 = {DRAM_SIZE, DRAM_START, BUFFER_SIZE2, BUFFER_START, BLANK};
integer i;
always #(CLK_PERIOD/2) aclk=~aclk;

logic [C_M_AXI_ADDR_WIDTH-1:0] addr_buffer[0:4-1];

task accept_return_data();
    begin
        if (addr_buffer[3-1] != 0)
        begin
            save_read_buffer_data_valid <= 1'b1;
            save_read_buffer_data <= addr_buffer[3-1];
        end
        else
            save_read_buffer_data_valid <= 1'b0;
        addr_buffer[3-1] <= addr_buffer[2-1];
        addr_buffer[2-1] <= addr_buffer[1-1];
        if (save_read_buffer_addr_valid)
            addr_buffer[0] <= save_read_buffer_addr;
        else
            addr_buffer[0] <= 0;
        
    end
endtask

initial begin
    #1 arst_n<=1'bx;aclk<=1'b1;
    #(CLK_PERIOD*3) arst_n<=1;
    #(CLK_PERIOD*3) arst_n<=0;ctrl_instruction<=INST1;ap_start<=1;data_tready<=0;
    for (i = 0; i < 100; i = i + 1) begin
        #CLK_PERIOD;
        if (i == 1)
            ap_start <= 0;
        if (ap_done) begin
            ctrl_instruction <= INST2;
            ap_start <= 1;
            #CLK_PERIOD;
            ap_start <= 0;
        end
        if (i == 20)
            data_tready <= 1;
        accept_return_data();
    end
    $finish(2);
end

endmodule
`default_nettype wire