`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/09 18:38:39
// Design Name: 
// Module Name: vector_add
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


module vector_add(
    input wire          clk,
    input wire [511:0]  vector_1,
    input wire [511:0]  vector_2,
    input wire          vector_input_valid,
    
    output wire         vector_output_valid,
    output wier [511:0] vector
    );
    
    genvar i;
    
    generate 
        for(i=0;i<16;i=i+1)
        begin
            floating_point_add u_floating_point_add(
              .aclk(clk),
              .s_axis_a_tvalid(vector_input_valid),
              .s_axis_a_tdata(vector_1[((i+1)*32)-1:i*32]),
              .s_axis_b_tvalid(vector_input_valid),
              .s_axis_b_tdata(vector_2[((i+1)*32)-1:i*32]),
              .m_axis_result_tvalid(vector_output_valid),
              .m_axis_result_tdata(vector[((i+1)*32)-1:i*32]) 
            );
        end
    endgenerate
    
endmodule
