`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/5 11:26:36
// Design Name: 
// Module Name: buffer_w
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
//  
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module buffer_w#(
    parameter BUFFER_ADDR_WIDTH   = 13,
    parameter BUFFER_DATA_WIDTH   = 8192,
    parameter MEM_POOL_PRIMITIVE= "ultra" //"ultra","b","d","auto"
)(
    input clk,
    input rst_n,

    // write ports: load
    input  load_write_addr_valid,
    input  [BUFFER_ADDR_WIDTH-1:0] load_write_addr,
    input  [BUFFER_DATA_WIDTH-1:0] load_write_data,

    // read ports: mm
    input  mm_read_addr_valid,
    input  [BUFFER_ADDR_WIDTH-1:0] mm_read_addr,
    output reg mm_read_data_valid,
    output reg [BUFFER_DATA_WIDTH-1:0] mm_read_data
);
    //*******************************************************************
    // localparam,regs and wires
    //*******************************************************************
    localparam BUFFER_SIZE = (2 ** BUFFER_ADDR_WIDTH) * BUFFER_DATA_WIDTH;

    // write
    reg write_enable;
    reg [BUFFER_ADDR_WIDTH-1:0] write_addr;
    reg [BUFFER_DATA_WIDTH-1:0] write_data;
    // read
    reg dst_0, dst_1, dst_2; // read destination
    // reg read_enable;
    reg [BUFFER_ADDR_WIDTH-1:0] read_addr;
    wire [BUFFER_DATA_WIDTH-1:0] read_data; // output data

    //*******************************************************************
    // generate and connect RAM
    //*******************************************************************
    xpm_memory_sdpram # (
    // Common module parameters
    .MEMORY_SIZE        (BUFFER_SIZE), //size of bank
    .MEMORY_PRIMITIVE   (MEM_POOL_PRIMITIVE), //choose "d" "b" "u"
    .CLOCKING_MODE      ("common_clock"), //a,b use one clock 
    .MEMORY_INIT_FILE   ("none"), //no init
    .MEMORY_INIT_PARAM  (""    ), //no init
    .USE_MEM_INIT       (1),
    .WAKEUP_TIME        ("disable_sleep"), //no sleep
    .MESSAGE_CONTROL    (0),
    .ECC_MODE           ("no_ecc"), //no ecc
    .AUTO_SLEEP_TIME    (0), //Do not Change
    // Port A module parameters
    .WRITE_DATA_WIDTH_A (BUFFER_DATA_WIDTH), //bank data width
    .BYTE_WRITE_WIDTH_A (BUFFER_DATA_WIDTH), //not byte write 
    .ADDR_WIDTH_A       (BUFFER_ADDR_WIDTH), //addr width
    // Port B module parameters
    .READ_DATA_WIDTH_B  (BUFFER_DATA_WIDTH), //bank data width
    .ADDR_WIDTH_B       (BUFFER_ADDR_WIDTH), //addr width
    .READ_RESET_VALUE_B ("0"),
    .READ_LATENCY_B     (2), //latency cycles
    .WRITE_MODE_B       ("read_first") //no change order
    ) INST_sdpram_bank (
        // Common module ports
        .sleep          (1'b0),
        // Port A module ports
        .clka           (clk),
        .ena            (1'b1),
        .wea            (write_enable),
        .addra          (write_addr),
        .dina           (write_data),
        .injectsbiterra (1'b0),
        .injectdbiterra (1'b0),
        // Port B module ports
        .clkb           (clk),
        .rstb           (~rst_n),
        .enb            (dst_0),
        .regceb         (1'b1),
        .addrb          (read_addr),
        .doutb          (read_data),
        .sbiterrb       (),
        .dbiterrb       ()
    );

    //*******************************************************************
    // read latency: 4 cycle
    //*******************************************************************
    // input: 1 cycle
    always @(negedge rst_n or posedge clk)
    begin
        if (~rst_n) begin
            dst_0 <= 0;
            read_addr <= 0;
        end
        else begin
            if (mm_read_addr_valid) begin
                dst_0 <= 1'b1;
                read_addr <= mm_read_addr;
            end
            else begin
                dst_0 <= 0;
                read_addr <= 0; // no latch
            end
        end
    end

    // read delay: 2 cycle
    always @(negedge rst_n or posedge clk)
    begin
        if (~rst_n) dst_1 <= 0;
        else dst_1 <= dst_0;
    end
    always @(negedge rst_n or posedge clk)
    begin
        if (~rst_n) dst_2 <= 0;
        else dst_2 <= dst_1;
    end

    // output: 1 cycle
    always @(negedge rst_n or posedge clk)
    begin
        if (~rst_n) begin
            mm_read_data_valid <= 0;
            mm_read_data <= 0;
        end
        else begin
            if (dst_2) begin
                mm_read_data_valid <= 1'b1;
                mm_read_data <= read_data;
            end
            else begin
                mm_read_data_valid <= 0;
                mm_read_data <= 0;
            end
        end
    end

    //*******************************************************************
    // write latency: 2 cycle
    //*******************************************************************
    // input: 1 cycle
    always @(negedge rst_n or posedge clk)
    begin
        if (~rst_n) begin
            write_enable <= 0;
            write_addr <= 0;
            write_data <= 0;
        end
        else begin
            if (load_write_addr_valid) begin
                write_enable <= 1'b1;
                write_addr <= load_write_addr;
                write_data <= load_write_data;
            end
            else begin
                write_enable <= 0;
                write_addr <= 0;
                write_data <= 0;
            end
        end
    end

endmodule
