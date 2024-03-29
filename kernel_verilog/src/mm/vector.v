`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/13 21:45:14
// Design Name: 
// Module Name: vector
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


module vector
#(parameter num = 16,
            DW = 32
)
(
    input wire [(DW*num)-1:0] matrix_vector_input,
    input wire [(DW*num)-1:0] vector_input,
    input wire input_valid,
    
    input wire clk,
    
    output wire [DW-1:0] matrix_vector_output,
    output wire add_valid
    
 );
 
    wire [DW-1:0] res_multi[num-1:0];
    wire [DW-1:0] res_add_0[7:0];
    wire [DW-1:0] res_add_1[3:0];
    wire [DW-1:0] res_add_2[1:0];
    wire [num-1:0] multiply_valid;
    wire [7:0] add_valid_0;
    wire [3:0] add_valid_1;
    wire [1:0] add_valid_2;
 
 
    genvar i;
    
    //16x1 vector multipy 1x16 vector
    generate 
        // fix num=16
        for(i=0;i<16;i=i+1)
        begin
            floating_point_multiply u_floating_point_multiply(
              .aclk(clk),
              .s_axis_a_tvalid(input_valid),
              .s_axis_a_tdata(matrix_vector_input[((i+1)*DW)-1:i*DW]),
              .s_axis_b_tvalid(input_valid),
              .s_axis_b_tdata(vector_input[((i+1)*DW)-1:i*DW]),
              .m_axis_result_tvalid(multiply_valid[i]),
              .m_axis_result_tdata(res_multi[i]) 
            );
        end
    endgenerate
 
    //level 1 8 times add
    generate 
        // fix num=16
        for(i=0;i<16;i=i+2)
        begin
            floating_point_add u_floating_point_add_0(
              .aclk(clk),
              .s_axis_a_tvalid(multiply_valid[i]),
              .s_axis_a_tdata(res_multi[i]),
              .s_axis_b_tvalid(multiply_valid[i+1]),
              .s_axis_b_tdata(res_multi[i+1]),
              .m_axis_result_tvalid(add_valid_0[i/2]),
              .m_axis_result_tdata(res_add_0[i/2]) 
            );
        end
    endgenerate
    
    //level 2 4 times add
    generate 
        // num/2=8
        for(i=0;i<8;i=i+2)
        begin
            floating_point_add u_floating_point_add_1(
              .aclk(clk),
              .s_axis_a_tvalid(add_valid_0[i]),
              .s_axis_a_tdata(res_add_0[i]),
              .s_axis_b_tvalid(add_valid_0[i+1]),
              .s_axis_b_tdata(res_add_0[i+1]),
              .m_axis_result_tvalid(add_valid_1[i/2]),
              .m_axis_result_tdata(res_add_1[i/2]) 
            );
        end
    endgenerate

    //level 3 2 times add
    generate 
        // num/4=4
        for(i=0;i<4;i=i+2)
        begin
            floating_point_add u_floating_point_add_2(
              .aclk(clk),
              .s_axis_a_tvalid(add_valid_1[i]),
              .s_axis_a_tdata(res_add_1[i]),
              .s_axis_b_tvalid(add_valid_1[i+1]),
              .s_axis_b_tdata(res_add_1[i+1]),
              .m_axis_result_tvalid(add_valid_2[i/2]),
              .m_axis_result_tdata(res_add_2[i/2]) 
            );
        end
    endgenerate
    
 
    //level 4 final add
    floating_point_add u_floating_point_add_final(
              .aclk(clk),
              .s_axis_a_tvalid(add_valid_2[0]),
              .s_axis_a_tdata(res_add_2[0]),
              .s_axis_b_tvalid(add_valid_2[1]),
              .s_axis_b_tdata(res_add_2[1]),
              .m_axis_result_tvalid(add_valid),
              .m_axis_result_tdata(matrix_vector_output) 
            );
 
 
endmodule
