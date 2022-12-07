`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/06 16:57:54
// Design Name: 
// Module Name: mm_main
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


module mm_main(
    input clk,
    input rstn,

    // buffer start address
    input [12:0]weight_start_addr,
    input [10:0]input_start_addr,
    input [10:0]output_start_addr,
    
    input [7:0]input_addr_per_feature,  //Ci
    input [7:0]output_addr_per_feature, //Co
    input [15:0]number_of_node,          //N

    input start_valid,
    output done,

    input weight_data_valid,
    input [8191:0]weight_data,

    input input_data_valid,
    input [511:0]input_data,

    output output_data_valid,
    output [511:0]output_data,

    output addr_valid,  //output valid
    output [10:0]addr,  //output address
    
    output addr_input_valid,    //input valid
    output [10:0]addr_input,    //input address
    
    output addr_weight_valid,   //weight valid
    output [12:0]addr_weight    //weight address

    );
    
    parameter   Ci_mult = 2'b00;     //The innermost layer
    parameter   Co_mult = 2'b01;       //The middle layer
    parameter   N_mult = 2'b10;        //The outermost layer
    
    reg [1:0]   state;
    
    reg [10:0]feature_addr;
    reg [12:0]weight_addr;
    reg [10:0]output_addr;
    reg output_valid;
    reg input_valid;
    reg weight_valid;
    reg done_valid;
 
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn)begin
            st_cur <= Ci_mult;
        end
        else begin
            st_cur <= st_next;
        end
    end
    
    reg [7:0]check_i;
    reg [7:0]check_o;
    reg [15:0]check_n;

    
    always @(posedge clk)begin
            if(start_valid)begin
                    output_valid <= 1'b0;
                    input_valid <= 1'b1;
                    weight_valid <= 1'b1;
                    //start address
                    weight_addr <= weight_start_addr;
                    feature_addr <= input_start_addr;
                    output_addr <= output_start_addr;
                    check_i <= 8'b0;
                    check_o <= 8'b0;
                    check_n <= 16'b0;
                    done_valid<=1'b0;
            end
            else begin
                if(st_cur==Ci_mult)begin
                    check_i = check_i + 8'b1;
                    feature_addr = feature_addr + 11'b1;
                    weight_addr = weight_addr + 13'b1;
                end
                else if(st_cur==N_mult)begin
                    //weight back to the start addr
                     weight_addr = weight_start_addr;
                     output_addr = output_addr + 11'b1;
                end
                else if(st_cur==Co_mult )begin
                    //Move back to the start addr
                    feature_addr = feature_addr - input_addr_per_feature+8'b1;
                    weight_addr = weight_addr + 13'b1;
                    output_addr = output_addr + 11'b1;
               end
           end
    end
    
    assign addr = output_addr;
    assign addr_valid = output_valid;
    assign addr_weight = weight_addr;
    assign addr_input_valid = input_valid;
    assign addr_input = feature_addr;
    assign addr_weight_valid = weight_valid;
    assign done = done_valid;
    
endmodule