`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/14 01:50:12
// Design Name: 
// Module Name: matrix
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


module matrix
#(parameter M = 16,
            N = 16,
            DW = 32
)
(
    input wire [(DW*N*M)-1:0] matrix_input,
    input wire [(DW*N)-1:0] vector_input,
    input wire input_valid,
    
    input wire clk,
    
    output wire [(DW*N)-1:0] vector_output,
    output wire add_valid
    );
   
    genvar i;
    
    //16 columns i.e. (16x16 matrix) multiply 1x16 vector
    generate
        // fix N = 16
        for(i=0;i<16;i=i+1)
        begin
            vector u_vector(
                .matrix_vector_input(matrix_input[(i+1)*(DW*N)-1:i*(DW*N)]),
                .vector_input(vector_input),
                .input_valid(input_valid),
    
                .clk(clk),
    
                .matrix_vector_output(vector_output[((i+1)*DW)-1:i*DW]),
                .add_valid(add_valid)            
            );
        end
    endgenerate
endmodule
