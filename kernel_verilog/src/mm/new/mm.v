`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/26 23:52:02
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


module mm(
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
    input done,

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
    
    parameter   INIT = 3'b000;          //Initial state
    parameter   Ci_mult_1 = 3'b001;     //The innermost layer
    parameter   Ci_mult_2 = 3'b010;     //The innermost layer
    parameter   Co_mult = 3'b011;       //The middle layer
    parameter   N_mult = 3'b100;        //The outermost layer
    
    reg [2:0]   st_cur;
    reg [2:0]   st_next;
    
    reg [10:0]feature_addr;
    reg [12:0]weight_addr;
    reg [10:0]output_addr;
    reg output_valid;
    reg input_valid;
    reg weight_valid;
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn)begin
            st_cur <= INIT;
        end
        else begin
            st_cur <= st_next;
        end
    end
    
    integer i;  //ci
    integer o;  //co
    integer n;  //n
    reg [7:0]check_i;
    reg [7:0]check_o;
    reg [15:0]check_n;
    
    always @(*)begin
        case(st_cur)
            INIT:begin
                    output_valid = 1'b0;
                    input_valid = 1'b1;
                    weight_valid = 1'b1;
                    //start address
                    weight_addr = weight_start_addr;
                    feature_addr = input_start_addr;
                    output_addr = output_start_addr;
                    st_next = Ci_mult_1;
                    i=0;
                    o=0;
                    n=0;
                    check_i = 8'b0;
                    check_o = 8'b0;
                    check_n = 16'b0;
            end
            
            Ci_mult_1:begin
                //feature move, weight move
                feature_addr = feature_addr + 11'b1;
                weight_addr = weight_addr + 13'b1;
                //Count + 1
                i = i + 1;
                check_i = check_i + 8'b1;
                st_next = Ci_mult_2;
                //Whether it can jump to next leavel
                if(check_i==input_addr_per_feature-8'b1)begin
                    st_next = Co_mult;
                    //High value for output
                    output_valid = 1'b1;
                    if(check_o==output_addr_per_feature-8'b1)begin
                        st_next = N_mult;      
                    end
                end
                //High value for Buffer
                weight_valid = 1'b1;
                input_valid = 1'b1;
            end
            
           Ci_mult_2:begin
                //feature move, weight move
                feature_addr = feature_addr + 11'b1;
                weight_addr = weight_addr + 13'b1;
                //Count + 1
                i = i + 1;
                check_i = check_i + 8'b1;
                st_next = Ci_mult_1;
                //Whether it can jump to next leavel
                if(check_i==input_addr_per_feature-8'b1)begin
                    st_next = Co_mult;
                    //High value for output
                    output_valid = 1'b1;
                    if(check_o==output_addr_per_feature-8'b1)begin
                        st_next = N_mult;            
                    end
                end
                //High value for Buffer
                weight_valid = 1'b1;
                input_valid = 1'b1;
            end
            
            Co_mult:begin
                output_valid = 1'b0;
                //Move back to the start addr
                feature_addr = feature_addr - i*(11'b1);
                //Count clear
                i = 0;
                check_i = 8'b0;
                //Output and weight move
                output_addr = output_addr + 11'b1;
                weight_addr = weight_addr + 13'b1;
                //Back to the innermost layer
                st_next = Ci_mult_1;
                o = o + 1;
                check_o = check_o + 8'b1;
              end    
              
            N_mult:begin
                output_valid = 1'b0;
                n = n+1;
                check_n = check_n+16'b1;
                //Clear input and weight valid
                if(check_n==number_of_node)begin
                    input_valid = 1'b0;
                    weight_valid = 1'b0;
                end
                //Not the end of calculation
                if(check_n!=number_of_node)begin
                    //weight back to the start addr
                    weight_addr = weight_start_addr;
                    //counter clear
                    o = 0;
                    check_o = 8'b0;
                    i=0;
                    check_i = 8'b0;
                    //Move forward
                    output_addr = output_addr + 11'b1;
                    feature_addr = feature_addr +11'b1;
                    st_next = Ci_mult_1;
                end
            end

            default: st_next = INIT;
            endcase
    end

    assign addr = output_addr;
    assign addr_valid = output_valid;
    assign addr_weight = weight_addr;
    assign addr_input_valid = input_valid;
    assign addr_input = feature_addr;
    assign addr_weight_valid = weight_valid;
    
endmodule
