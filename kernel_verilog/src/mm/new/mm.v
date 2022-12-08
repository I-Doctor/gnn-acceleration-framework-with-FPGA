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
    output done,

    input weight_data_valid,
    input [8191:0]weight_data,

    input input_data_valid,
    input [511:0]input_data,

    output output_data_valid,
    output [511:0]output_data,

    output output_addr_valid,  //output valid
    output [10:0]output_addr,  //output address
    
    output input_addr_valid,    //input valid
    output [10:0]input_addr,    //input address
    
    output weight_addr_valid,   //weight valid
    output [12:0]weight_addr    //weight address
    
    //output [511:0]matrix_out

    );
    
    parameter   INIT = 2'b00;
    parameter   Ci_mult = 2'b01;     //The innermost layer
    parameter   Co_mult = 2'b10;       //The middle layer
    parameter   N_mult = 2'b11;        //The outermost layer
    
    reg [1:0]   state;
    
    reg [10:0]feature_addr;
    reg [12:0]weight_address;
    reg [10:0]output_address;
    reg output_valid;
    reg input_valid;
    reg weight_valid;
    
    reg done_valid;
    
    reg [7:0]check_i;
    reg [7:0]check_o;
    reg [15:0]check_n;
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn)begin
            state = INIT;
        end
        else begin
            case(state)
                INIT:begin
                    //done_valid = 1'b0;
                    if(start_valid==1'b1)begin
                        //output_valid = 1'b0;
                        input_valid = 1'b1;
                        weight_valid = 1'b1;
                        //start address
                        weight_address = weight_start_addr;
                        feature_addr = input_start_addr;
                        //output_addr = output_start_addr;
                        state = Ci_mult;
                        check_i = 8'b0;
                        check_o = 8'b0;
                        check_n = 16'b0;
                    end
               end
               
               Ci_mult:begin
                    //feature move, weight move
                    feature_addr = feature_addr + 11'b1;
                    weight_address = weight_addr + 13'b1;
                    //Count + 1
                    check_i = check_i + 8'b1;
                    state = Ci_mult;
                    //Whether it can jump to next leavel
                    if(check_i==input_addr_per_feature-8'b1)begin
                        state = Co_mult;
                        //High value for output
                        //output_valid = 1'b1;
                        if(check_o==output_addr_per_feature-8'b1)begin
                            state = N_mult;      
                        end
                    end
                    //High value for Buffer
                    weight_valid = 1'b1;
                    input_valid = 1'b1;
                end
                
                Co_mult:begin
                    //output_valid = 1'b0;
                    //Move back to the start addr
                    feature_addr = feature_addr  - input_addr_per_feature + 8'b1;
                    //Count clear
                    check_i = 8'b0;
                    //Output and weight move
                    //output_addr = output_addr + 11'b1;
                    weight_address = weight_addr + 13'b1;
                    //Back to the innermost layer
                    state = Ci_mult;
                    check_o = check_o + 8'b1;
                end    
                  
                N_mult:begin
                    //output_valid = 1'b0;
                    check_n = check_n+16'b1;
                    //Clear input and weight valid
                    if(check_n==number_of_node)begin
                        input_valid = 1'b0;
                        weight_valid = 1'b0;
                        state = INIT;
                    end
                    //Not the end of calculation
                    if(check_n!=number_of_node)begin
                        //weight back to the start addr
                        weight_address = weight_start_addr;
                        //counter clear
                        check_o = 8'b0;
                        check_i = 8'b0;
                        //Move forward
                        //output_addr = output_addr + 11'b1;
                        feature_addr = feature_addr +11'b1;
                        state = Ci_mult;
                    end
                end            
                default:  begin
                    state = INIT;
                end
          endcase
       end
    end
    
    reg [1:0]state_data;
    parameter   INIT_data = 2'b00;
    parameter   Ci_mult_data = 2'b01;     //The innermost layer
    parameter   Co_mult_data = 2'b10;       //The middle layer
    parameter   N_mult_data = 2'b11;        //The outermost layer

    reg [511:0]data_input;
    reg [8191:0]data_weight;
    wire [15:0]multiply_valid;
    wire [511:0]res_multi;
    reg [511:0]data_output;
    reg [7:0]co;
    reg [7:0]ci;
    reg [15:0]node;
    reg outputdata_valid;
    
//    reg [511:0]res;
//    always@(res_multi)begin
//        res = res_multi;
//    end
    
    reg matrix_multi_valid;
    
    matrix u_matrix(
        .matrix_input(data_weight),
        .vector_input(data_input),
        .input_valid(matrix_multi_valid),
    
        .clk(clk),
    
        .vector_output(res_multi),
        .add_valid(multiply_valid)
    );
    

    always @(posedge clk) begin
        if(!rstn)begin
            state_data = INIT;
        end
        else begin
            case(state_data)
                INIT_data:begin
                    done_valid=1'b0;
                    if(start_valid==1'b1)begin
                        co = 8'b0;
                        ci = 8'b0;
                        node = 16'b0;
                        output_valid=1'b0;
                        outputdata_valid=1'b0;
                        output_address = output_start_addr;
                        data_output=512'b0;
                        state_data = Ci_mult_data;
                    end
               end
               
               Ci_mult_data:begin
                    if(weight_data_valid==1'b1)begin
                        data_weight = weight_data;
                    end
                    if(input_data_valid==1'b1)begin
                        data_input = input_data;
                    end
                    if(weight_data_valid==1'b1&&input_data_valid==1'b1)begin
                        matrix_multi_valid = 1'b1;
                    end
                    // matrix multiple
                    if(multiply_valid==16'hffff)begin
                        data_output = data_output + res_multi;
                        ci = ci + 8'b1;
                    end
                    if(ci==input_addr_per_feature-8'b1)begin
                        //High value for output
                        output_valid = 1'b1;
                        //High value for output
                        outputdata_valid = 1'b1;
                        state_data = Co_mult_data;
                        if(co==output_addr_per_feature-8'b1)begin
                            state_data = N_mult_data;
                        end
                    end
                end
                
                Co_mult_data:begin
                    output_valid = 1'b0;
                    outputdata_valid=1'b0;
                    data_output = 512'b0;
                    ci=8'b0;
                    output_address = output_addr + 11'b1;
                    state_data = Ci_mult_data;
                    co = co+8'b1;
                end    
                  
                N_mult_data:begin
                    output_valid = 1'b0;
                    outputdata_valid=1'b0;
                    data_output = 512'b0;
                    node = node + 16'b1;
                    //Clear input and weight valid
                    if(node==number_of_node)begin
                        done_valid = 1'b1;
                        state_data = INIT_data;
                        matrix_multi_valid=1'b0;
                    end
                    //Not the end of calculation
                    if(node!=number_of_node)begin
                        //counter clear
                        co = 8'b0;
                        ci = 8'b0;
                        //Move forward
                        output_address = output_addr + 11'b1;
                        state_data = Ci_mult_data;
                    end
                end            
                default:  begin
                    state_data = INIT_data;
                end
          endcase
       end        
    end

    assign output_addr = output_address;
    assign output_addr_valid = output_valid;
    
    assign weight_addr = weight_address;
    assign weight_addr_valid = weight_valid;
    
    assign input_addr_valid = input_valid;
    assign input_addr = feature_addr;
    
    assign output_data = data_output;
    
    assign done = done_valid;
    assign output_data_valid = outputdata_valid;
    
    //assign matrix_out = res_multi;
    
endmodule
