`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/27 21:24:49
// Design Name: 
// Module Name: mm_top
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


module mm_top(
    input ap_clk,
    input areset,
    input [127:0]instruction_to_mm,
    input valid_to_mm,
    output done_from_mm,
    
    //read buffer 1A
    output mm_read_buffer_1_A_avalid,
    output [10:0]mm_read_buffer_1_A_addr,
    input mm_read_buffer_1_A_valid,
    input [511:0]mm_read_buffer_1_A_data,
    
    //read buffer 1B
    output mm_read_buffer_1_B_avalid,
    output [10:0]mm_read_buffer_1_B_addr,
    input mm_read_buffer_1_B_valid,
    input [511:0]mm_read_buffer_1_B_data,
    
    //read buffer 2A
    output mm_read_buffer_2_A_avalid,
    output [10:0]mm_read_buffer_2_A_addr,
    input mm_read_buffer_2_A_valid,
    input [511:0]mm_read_buffer_2_A_data,
    
    //read buffer 2B
    output mm_read_buffer_2_B_avalid,
    output [10:0]mm_read_buffer_2_B_addr,
    input mm_read_buffer_2_B_valid,
    input [511:0]mm_read_buffer_2_B_data,
    
    //write buffer 2A
    output mm_write_buffer_2_A_valid,
    output [10:0]mm_write_buffer_2_A_addr,
    output [511:0]mm_write_buffer_2_A_data,
    
    //write buffer 2B
    output mm_write_buffer_2_B_valid,
    output [10:0]mm_write_buffer_2_B_addr,
    output [511:0]mm_write_buffer_2_B_data,
    
    //read buffer b
    output mm_read_buffer_b_avalid,
    output [8:0]mm_read_buffer_b_addr,
    input mm_read_buffer_b_valid,
    input [511:0]mm_read_buffer_b_data,
    
    //read buffer w
    output mm_read_buffer_w_avalid,
    output [15:0]mm_read_buffer_w_addr,
    input mm_read_buffer_w_valid,
    input [8191:0]mm_read_buffer_w_data
    
    );
    
    
    reg input_data_valid;
    reg [511:0]input_data;

    reg output_data_valid_reg;
    reg [511:0]output_data_reg;
    
    wire output_data_valid;
    wire [511:0]output_data;

    assign output_data_valid = output_data_valid_reg;
    assign output_data = output_data_reg;

    reg [10:0]output_addr_reg;  //output address

    wire [10:0]output_addr;  //output address
    
    assign output_addr = output_addr_reg;
    
    reg input_addr_valid_reg;    //input valid
    reg [10:0]input_addr_reg;   //input address
    
    wire input_addr_valid;    //input valid
    wire [10:0]input_addr;   //input address
    
    assign input_addr_valid = input_addr_valid_reg;
    assign input_addr = input_addr_reg;
    
    reg [511:0]output_read_data;
    reg output_read_data_valid;
    wire [10:0]output_read_addr;
    wire output_read_addr_valid;
    
    reg [10:0]output_read_addr_reg;
    reg output_read_addr_valid_reg;
    
    assign output_read_addr = output_read_addr_reg;
    assign output_read_addr_valid = output_read_addr_valid_reg;
    
    always @(instruction_to_mm[4:1]) begin
        case(instruction_to_mm[4:1])
            4'b0001: begin
                input_data_valid <= mm_read_buffer_1_A_valid;
                input_data <= mm_read_buffer_1_A_data;
                input_addr_valid_reg <= mm_read_buffer_1_A_avalid;
                input_addr_reg <= mm_read_buffer_1_A_addr;
            end
            4'b0010: begin
                input_data_valid <= mm_read_buffer_1_B_valid;
                input_data <= mm_read_buffer_1_B_data;
                input_addr_valid_reg <= mm_read_buffer_1_B_avalid;
                input_addr_reg <= mm_read_buffer_1_B_addr;
            end
            4'b0100: begin
                input_data_valid <= mm_read_buffer_2_A_valid;
                input_data <= mm_read_buffer_2_A_data;
                input_addr_valid_reg <= mm_read_buffer_2_A_avalid;
                input_addr_reg <= mm_read_buffer_2_A_addr;
            end
            4'b1000: begin
                input_data_valid <= mm_read_buffer_2_B_valid;
                input_data <= mm_read_buffer_2_B_data;
                input_addr_valid_reg <= mm_read_buffer_2_B_avalid;
                input_addr_reg <= mm_read_buffer_2_B_addr;
            end
       endcase
   end
       
    always @(instruction_to_mm[10:7]) begin
       case(instruction_to_mm[10:7])
//            6'b000010: begin
//                output_data_valid <= mm_read_buffer_1_A_valid;
//                output_data <= mm_read_buffer_1_A_data;
//                output_addr_valid <= mm_read_buffer_1_A_avalid;
//                output_addr <= mm_read_buffer_1_A_addr;
//                output_read_data_valid <= mm_read_buffer_1_A_valid;
//                output_read_data <= mm_read_buffer_1_A_data;
//                output_read_addr_valid <= mm_read_buffer_1_A_avalid;
//                output_read_addr <= mm_read_buffer_1_A_addr;
//            end
//            6'b000100: begin
//                output_data_valid <= mm_read_buffer_1_B_valid;
//                output_data <= mm_read_buffer_1_B_data;
//                output_addr_valid <= mm_read_buffer_1_B_avalid;
//                output_addr <= mm_read_buffer_1_B_addr;
//                output_read_data_valid <= mm_read_buffer_1_B_valid;
//                output_read_data <= mm_read_buffer_1_B_data;
//                output_read_addr_valid <= mm_read_buffer_1_B_avalid;
//                output_read_addr <= mm_read_buffer_1_B_addr;
//            end
            4'b0100: begin
                output_data_valid_reg <= mm_write_buffer_2_A_valid;
                output_data_reg <= mm_write_buffer_2_A_data;
                output_addr_reg <= mm_write_buffer_2_A_addr;
                //acc
                output_read_data_valid <= mm_read_buffer_2_A_valid;
                output_read_data <= mm_read_buffer_2_A_data;
                output_read_addr_valid_reg <= mm_read_buffer_2_A_avalid;
                output_read_addr_reg <= mm_read_buffer_2_A_addr;
            end
            4'b1000: begin
                output_data_valid_reg <= mm_write_buffer_2_B_valid;
                output_data_reg <= mm_write_buffer_2_B_data;
                output_addr_reg <= mm_write_buffer_2_B_addr;
                //acc
                output_read_data_valid <= mm_read_buffer_2_B_valid;
                output_read_data <= mm_read_buffer_2_B_data;
                output_read_addr_valid_reg <= mm_read_buffer_2_B_avalid;
                output_read_addr_reg <= mm_read_buffer_2_B_addr;
            end
       endcase
    end
    
    mm mm_main(
        .clk(ap_clk),
        .rstn(areset),
    
        // buffer start address
        .weight_start_addr(instruction_to_mm[44:32]),
        .input_start_addr(instruction_to_mm[74:64]),
        .output_start_addr(instruction_to_mm[106:96]),
        
        .input_addr_per_feature(instruction_to_mm[95:88]),  //Ci
        .output_addr_per_feature(instruction_to_mm[87:80]), //Co
        .number_of_node(instruction_to_mm[127:110]),          //N
    
        .start_valid(valid_to_mm),
        .done(done_from_mm),
        //relu
        .r(instruction_to_mm[12:12]),
        
        //acc
        .a(instruction_to_mm[13:13]),
        .output_read_data(output_read_data),
        .output_read_data_valid(output_read_data_valid),
        .output_read_addr(output_read_addr),
        .output_read_addr_valid(output_read_addr_valid),
        
        //bias
        .b(instruction_to_mm[14:14]),
        .bias_start_addr(instruction_to_mm[24:16]),
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
