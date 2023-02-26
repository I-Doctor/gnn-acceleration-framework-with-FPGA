`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/27 21:24:49
// Design Name: 
// Module Name: mm
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


module mm #(
    parameter integer MM_INST_BIT_WIDTH   = 128
)
(
    input  wire                                aclk,
    input  wire                                areset,
    input  wire                                kernel_clk,
    input  wire                                kernel_rst,
    //control signal
    input  wire[MM_INST_BIT_WIDTH       -1:0]  ctrl_instruction,
    input  wire                                ap_start,
    output wire                                ap_done,
    //mm buffer ports:
    //read buffer 1A
    output wire                                mm_read_buffer_1_A_avalid,
    output wire[11                      -1:0]  mm_read_buffer_1_A_addr,
    input  wire                                mm_read_buffer_1_A_valid,
    input  wire[512                     -1:0]  mm_read_buffer_1_A_data,
    //read buffer 1B
    output wire                                mm_read_buffer_1_B_avalid,
    output wire[11                      -1:0]  mm_read_buffer_1_B_addr,
    input  wire                                mm_read_buffer_1_B_valid,
    input  wire[512                     -1:0]  mm_read_buffer_1_B_data,
    //read buffer 2A
    output wire                                mm_read_buffer_2_A_avalid,
    output wire[11                      -1:0]  mm_read_buffer_2_A_addr,
    input  wire                                mm_read_buffer_2_A_valid,
    input  wire[512                     -1:0]  mm_read_buffer_2_A_data,
    //read buffer 2B
    output wire                                mm_read_buffer_2_B_avalid,
    output wire[11                      -1:0]  mm_read_buffer_2_B_addr,
    input  wire                                mm_read_buffer_2_B_valid,
    input  wire[512                     -1:0]  mm_read_buffer_2_B_data,
    //write buffer 2A
    output wire                                mm_write_buffer_2_A_valid,
    output wire[11                      -1:0]  mm_write_buffer_2_A_addr,
    output wire[512                     -1:0]  mm_write_buffer_2_A_data,
    //write buffer 2B
    output wire                                mm_write_buffer_2_B_valid,
    output wire[11                      -1:0]  mm_write_buffer_2_B_addr,
    output wire[512                     -1:0]  mm_write_buffer_2_B_data,
    //read buffer b
    output  wire                               mm_read_buffer_b_avalid,
    output  wire[9                      -1:0]  mm_read_buffer_b_addr,
    input   wire                               mm_read_buffer_b_valid,
    input   wire[512                    -1:0]  mm_read_buffer_b_data,
    //read buffer w
    output  wire                               mm_read_buffer_w_avalid,
    output  wire[13                     -1:0]  mm_read_buffer_w_addr,
    input   wire                               mm_read_buffer_w_valid,
    input   wire[8192                   -1:0]  mm_read_buffer_w_data
    );
    
    wire input_data_valid;
    wire [511:0]input_data;
    
    wire output_data_valid;
    wire [511:0]output_data;

    wire [10:0]output_addr;  //output address
    
    wire input_addr_valid;    //input valid
    wire [10:0]input_addr;   //input address
    
    wire [511:0]output_read_data;
    wire output_read_data_valid;
    wire [10:0]output_read_addr;
    wire output_read_addr_valid;

    wire weight_data_valid;
    wire [8191:0]weight_data;
    wire weight_addr_valid;   //weight valid
    wire [12:0]weight_addr;    //weight address
   
    wire [511:0]bias_data;
    wire bias_data_valid;
    wire [8:0]bias_addr;
    wire bias_addr_valid;
    
    assign input_data_valid =
        (ctrl_instruction[1] & mm_read_buffer_1_A_valid)
      | (ctrl_instruction[2] & mm_read_buffer_1_B_valid)
      | (ctrl_instruction[3] & mm_read_buffer_2_A_valid)
      | (ctrl_instruction[4] & mm_read_buffer_2_B_valid);
      
    assign input_data =
        ({512{ctrl_instruction[1]}} & mm_read_buffer_1_A_data)
      | ({512{ctrl_instruction[2]}} & mm_read_buffer_1_B_data)
      | ({512{ctrl_instruction[3]}} & mm_read_buffer_2_A_data)
      | ({512{ctrl_instruction[4]}} & mm_read_buffer_2_B_data);
      
    assign mm_read_buffer_1_A_avalid = (ctrl_instruction[1] & input_addr_valid);
    assign mm_read_buffer_1_B_avalid = (ctrl_instruction[2] & input_addr_valid);
    assign mm_read_buffer_2_A_avalid = (ctrl_instruction[3] & input_addr_valid)|(ctrl_instruction[9] & output_read_addr_valid);
    assign mm_read_buffer_2_B_avalid = (ctrl_instruction[4] & input_addr_valid)|(ctrl_instruction[10] & output_read_addr_valid);
     
    assign mm_read_buffer_1_A_addr = ({11{ctrl_instruction[1]}} & input_addr);
    assign mm_read_buffer_1_B_addr = ({11{ctrl_instruction[2]}} & input_addr);
    assign mm_read_buffer_2_A_addr = ({11{ctrl_instruction[3]}} & input_addr)|({11{ctrl_instruction[9]}} & output_read_addr);
    assign mm_read_buffer_2_B_addr = ({11{ctrl_instruction[4]}} & input_addr)|({11{ctrl_instruction[10]}} & output_read_addr);
    

    assign mm_write_buffer_2_A_valid = (ctrl_instruction[9] & output_data_valid);
    assign mm_write_buffer_2_B_valid = (ctrl_instruction[10] & output_data_valid);
      
    assign mm_write_buffer_2_A_data = ({512{ctrl_instruction[9]}} & output_data);
    assign mm_write_buffer_2_B_data = ({512{ctrl_instruction[10]}} & output_data);
    
    assign mm_write_buffer_2_A_addr = ({11{ctrl_instruction[9]}} & output_addr);
    assign mm_write_buffer_2_B_addr = ({11{ctrl_instruction[10]}} & output_addr);
      
    assign output_read_data= 
        ({512{ctrl_instruction[9]}} & mm_read_buffer_2_A_valid)
      | ({512{ctrl_instruction[10]}} & mm_read_buffer_2_B_valid);
     
    assign output_read_data_valid=
        (ctrl_instruction[9] & mm_read_buffer_2_A_valid)
      | (ctrl_instruction[10] & mm_read_buffer_2_B_valid);
     
   
    mm_main u_mm_main(
        .clk(kernel_clk),
        .rstn(~kernel_rst),
    
        // buffer start address
        .weight_start_addr(ctrl_instruction[44:32]),
        .input_start_addr(ctrl_instruction[74:64]),
        .output_start_addr(ctrl_instruction[106:96]),
        
        .input_addr_per_feature(ctrl_instruction[95:88]),  //Ci
        .output_addr_per_feature(ctrl_instruction[87:80]), //Co
        .number_of_node(ctrl_instruction[127:112]),          //N
    
        .start_valid(ap_start),
        .done(ap_done),
        //relu
        .r(ctrl_instruction[12:12]),
        
        //acc
        .a(ctrl_instruction[13:13]),
        .output_read_data(output_read_data),
        .output_read_data_valid(output_read_data_valid),
        .output_read_addr(output_read_addr),
        .output_read_addr_valid(output_read_addr_valid),
        
        //bias
        .b(ctrl_instruction[14:14]),
        .bias_start_addr(ctrl_instruction[56:48]),
        .bias_data(mm_read_buffer_b_data),
        .bias_data_valid(mm_read_buffer_b_valid),
        .bias_addr(mm_read_buffer_b_addr),
        .bias_addr_valid(mm_read_buffer_b_avalid),
    
        .weight_data_valid(mm_read_buffer_w_valid),
        .weight_data(mm_read_buffer_w_data),
    
        .input_data_valid(input_data_valid),
        .input_data(input_data),
    
        .output_data_valid(output_data_valid),
        .output_data(output_data),
    
        .output_addr(output_addr),  //output address
        
        .input_addr_valid(input_addr_valid),    //input valid
        .input_addr(input_addr),    //input address
        
        .weight_addr_valid(mm_read_buffer_w_avalid),   //weight valid
        .weight_addr(mm_read_buffer_w_addr)    //weight address
    );
    
endmodule
