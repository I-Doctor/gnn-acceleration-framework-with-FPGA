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
    //relu
    input r,
    
    //acc
    input a,
    input [511:0]output_read_data,
    input output_read_data_valid,
    output [10:0]output_read_addr,
    output output_read_addr_valid,
    
    //bias
    input b,
    input [8:0]bias_start_addr,
    input [511:0]bias_data,
    input bias_data_valid,
    output [8:0]bias_addr,
    output bias_addr_valid,

    input weight_data_valid,
    input [8191:0]weight_data,

    input input_data_valid,
    input [511:0]input_data,

    output output_data_valid,
    output [511:0]output_data,

    output [10:0]output_addr,  //output address
    
    output input_addr_valid,    //input valid
    output [10:0]input_addr,    //input address
    
    output weight_addr_valid,   //weight valid
    output [12:0]weight_addr    //weight address
    );
    
    reg [7:0]co;
    reg [7:0]ci;
    reg [15:0]n;
    reg [11*8-1:0]ci_reg;
    reg [11*8-1:0]co_reg;
    reg [11*16-1:0]n_reg;
    reg [10:0]out_valid;
    
    reg [10:0]feature_address;
    reg [12:0]weight_address;
    reg [10:0]output_address;
    
    reg input_valid;
    reg weight_valid;
    
    reg outputdata_valid;
    
    reg done_valid;
    reg en;
    
    reg [8:0]bias_address;
    reg bias_valid;
    reg en_bias;
    
    reg en_acc;
    reg [10:0]acc_address;
    reg acc_valid;
    
    reg first_addr;
    
    reg en_relu;
    
    
    //start_valid, read parameter
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            en<=1'b0;
        end
        else begin
            if(start_valid==1'b1)begin
                en <= 1'b1;
                ci<=8'b0;
                co<=8'b0;
                n<=16'b0;
                ci_reg<=88'b0;
                co_reg<=88'b0;
                n_reg<=176'b0;
                out_valid <= 11'd0;
                weight_valid <= 1'b1;
                input_valid <= 1'b1;
                outputdata_valid<=1'b0;
                first_addr<=1'b1;    // test first output address
                weight_address <= weight_start_addr;
                feature_address <= input_start_addr;
                output_address <= output_start_addr;
                if(b==1'b1)begin
                    en_bias <= 1'b1;
                    bias_valid<=1'b1;
                    bias_address <= bias_start_addr;
                end
                else begin
                    en_bias <= 1'b0;
                    bias_valid<=1'b0;
                end
                if(a==1'b1)begin
                    en_acc <= 1'b1;
                    acc_valid <= 1'b1;
                    acc_address <= output_start_addr;
                end
                else begin
                    en_acc <= 1'b0;
                    acc_valid <= 1'b0;
                end
                if(r==1'b1)begin
                    en_relu <= 1'b1;
                end
                else begin
                    en_relu <= 1'b0;
                end
            end
        end
    end
    
    //ci state
    always @(posedge clk or negedge rstn)begin
         if(!rstn) begin
            ci<=8'd0;
        end
        else begin
            if(en==1'b1)begin
                if(ci!=input_addr_per_feature-8'd1)begin
                    ci <= ci + 8'd1;
                end
                else begin
                    ci <= 8'd0;
                end
            end
        end
    end
    
    //co state
   always @(posedge clk or negedge rstn)begin
        if(!rstn) begin
            co<=8'd0;
        end
        else begin
            if(en==1'b1)begin
                if(ci==input_addr_per_feature-8'd1)begin
                    if(co!=output_addr_per_feature-8'd1)begin
                        co <= co + 8'd1;
                    end
                    else begin
                        co <= 8'd0;
                    end
               end
            end
        end
    end
    
    //n state
   always @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            n<=8'd0;
        end
        else begin
            if(en==1'b1)begin
                if(co==output_addr_per_feature-8'd1)begin
                    if(ci==input_addr_per_feature-8'd1)begin
                        if(n!=number_of_node-16'd1)begin
                            n <= n + 16'd1;
                        end
                        else begin
                            n <= 16'd0;
                        end
                   end
               end
            end
        end
    end
     
    // input addr
    always @(posedge clk or negedge rstn)begin
         if(!rstn) begin
            feature_address <= 11'd0;
        end
        else begin
            if(en==1'b1)begin
                if(input_addr_valid==1'b1)begin
                    if(co!=output_addr_per_feature-8'd1&ci==input_addr_per_feature-8'd1)begin
                        feature_address <= feature_address - input_addr_per_feature + 8'b1;
                    end
                    else begin
                        feature_address <= feature_address + 11'd1;
                    end
                end
           end
       end
    end
    
    //weight addr
   always @(posedge clk or negedge rstn)begin
        if(!rstn) begin
            weight_address<=8'd0;
        end
        else begin
            if(en==1'b1)begin
                if(weight_addr_valid==1'b1)begin
                    if(ci==input_addr_per_feature-8'd1&co==output_addr_per_feature-8'd1&n!=number_of_node-16'd1)begin
                       weight_address <= weight_start_addr;
                    end
                    else begin
                        weight_address <= weight_address + 13'd1;
                    end
                end
            end
        end
    end
    
    //input, weight addr valid
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            weight_valid <= 1'b0;
            input_valid <= 1'b0;
        end
        else begin
            if(en==1'b1)begin
                if(co==output_addr_per_feature-8'd1)begin
                    if(ci==input_addr_per_feature-8'd1)begin
                        if(n==number_of_node-16'd1)begin
                            weight_valid <= 1'b0;
                            input_valid <= 1'b0;
                            bias_valid <= 1'b0;
                            acc_valid <= 1'b0;
                            ci<=8'b0;
                            co<=8'b0;
                            n<=16'b0;
                        end
                   end
               end
            end
        end
    end

    wire [511:0]data_input;
    wire [8191:0]data_weight;
    wire [511:0]data_output;
    
    reg matrix_multi_valid;
    wire multiply_valid;
    wire [511:0]res_multi;
    
    assign data_weight = (en==1'b1&weight_data_valid==1'b1)?weight_data:512'b0;
    assign data_input = (en==1'b1&input_data_valid==1'b1)?input_data:512'b0;
    
    //Add delay for output data and address
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            ci_reg <= 88'd0;
            co_reg <= 88'd0;
            n_reg <= 176'd0;
            out_valid <= 9'd0;
        end
        else begin
            if(en==1'b1)begin
                ci_reg <= {ci_reg[10*8-1:0],ci};
                co_reg <= {co_reg[10*8-1:0],co};
                n_reg <= {n_reg[16*10-1:0],n};
                out_valid <= {out_valid[9:0],input_addr_valid};
            end
        end
    end

    // vector x matrix
    matrix u_matrix(
        .matrix_input(data_weight),
        .vector_input(data_input),
        .input_valid(1'b1),
    
        .clk(clk),
    
        .vector_output(res_multi),
        .add_valid(multiply_valid)
    );
    
   wire [511:0]vector_add_output;
   
   // output result + last time result
   vector_add u_vector_add(
        .clk(clk),
        .vector_1(data_output),
        .vector_2(res_multi),
        .vector_input_valid(1'b1),
        
        .vector_output_valid(vector_output_valid),
        .vector(vector_add_output)
    );
    
    wire [511:0]data_bias;
    wire [511:0]vector_bias_output;
   // output res + bais
   vector_add u_vector_add_bias(
        .clk(clk),
        .vector_1(data_bias),
        .vector_2(vector_add_output),
        .vector_input_valid(1'b1),
        
        .vector_output_valid(vector_output_valid),
        .vector(vector_bias_output)
    );
        
    //bias addr
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            bias_address <= 9'b0;
        end
        else begin
            if(en==1'b1&en_bias==1'b1)begin
                if(bias_valid==1'b1)begin
                    if(ci==input_addr_per_feature-8'd1)begin
                        if(co!=output_addr_per_feature-8'd1)begin
                            bias_address <= bias_address + 9'd1;
                        end
                        else begin
                            bias_address <= bias_start_addr;
                        end    
                    end                
                end
            end
        end
    end
    
    //bias data read and shift
    reg [512*6-1:0] bias_data_reg;
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            bias_data_reg <=  3072'b0;
        end
        else begin
            if(en==1'b1&en_bias==1'b1)begin
               bias_data_reg <= {bias_data_reg[5*512-1:0],bias_data};
            end
            else begin
               bias_data_reg <= 3072'd0;
            end
        end
    end
 
   //bias data calculate
   assign data_bias = (en==1'b1&en_acc==1'b1&ci_reg[10*8-1:9*8]==input_addr_per_feature-8'd1)?bias_data_reg[6*512-1:5*512]:512'd0;
    
   wire [511:0]data_acc;
   wire [511:0]vector_acc_output;
   // output res + bais
   vector_add u_vector_add_acc(
        .clk(clk),
        .vector_1(data_acc),
        .vector_2(vector_bias_output),
        .vector_input_valid(1'b1),
        
        .vector_output_valid(vector_output_valid),
        .vector(vector_acc_output)
    );
    
    //acc addr
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            acc_address <= 10'b0;
        end
        else begin
            if(en==1'b1&en_acc==1'b1)begin
                if(acc_valid==1'b1)begin
                    if(ci==input_addr_per_feature-8'd1)begin
                        acc_address <= acc_address + 9'd1;
                    end
                end
            end
        end
    end
    
    //acc data read and shift
    reg [512*7-1:0] acc_data_reg;
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            acc_data_reg <=  3584'b0;
        end
        else begin
            if(en==1'b1&en_acc==1'b1)begin
                acc_data_reg <= {acc_data_reg[6*512-1:0],output_read_data};
            end
            else begin
                 acc_data_reg <= 3584'd0;
            end
        end
    end
    
 
   //acc data calculate
   assign data_acc = (en==1'b1&en_acc==1'b1&ci_reg[11*8-1:10*8]==input_addr_per_feature-8'd1)?acc_data_reg[7*512-1:6*512]:512'd0;

   //Clear the last result
   assign data_output = (en==1'b0||ci_reg[9*8-1:8*8]==8'd0)?512'd0:vector_add_output;
   
   // If it is the First output address 
   //output address and valid
   always @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            output_address<=8'd0;
            first_addr<=1'b1;
        end
        else begin
            if(en==1'b1)begin
               if(ci_reg[11*8-1:10*8]==input_addr_per_feature-8'd1&out_valid[10]==1'b1)begin
                  if(first_addr==1'b1)begin
                      output_address <= output_start_addr;
                      first_addr <= 1'b0;
                  end
                  else begin
                      output_address <= output_address + 11'd1;
                  end
                  outputdata_valid <= 1'b1;
               end
               else begin
                  outputdata_valid <= 1'b0;
               end
            end
       end
    end
 
    // 1 clk delay than done
    reg done_ok;
    always @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            done_ok <= 1'b0;
        end
        else begin
           if(en==1'b1)begin
               if(co_reg[11*8-1:10*8]==output_addr_per_feature-8'd1)begin
                  if(ci_reg[11*8-1:10*8]==input_addr_per_feature-8'd1)begin
                    if(n_reg[11*16-1:10*16]==number_of_node-16'd1)begin
                        if(out_valid[10]==1'b1)begin
                            done_ok <=1'b1;
                        end
                    end
                 end
              end
          end
       end
    end
    
    always@(posedge clk or negedge rstn)begin
        if(!rstn) begin
            done_valid <= 1'b0;
        end
        else begin
            if(done_ok==1'b1)begin
                done_valid <= 1'b1;
                en <= 1'b0;
                en_acc <= 1'b0;
                en_bias <= 1'b0;
                en_relu <= 1'b0;
                ci_reg<=88'b0;
                co_reg<=88'b0;
                n_reg<=176'b0;
                out_valid <= 9'd0;
                outputdata_valid<=1'b0;
                done_ok <=1'b0;
                first_addr<=1'b1;
            end
            else begin
                 done_valid <= 1'b0;
            end
        end
    end
    
    assign output_addr = output_address;
    
    assign weight_addr = weight_address;
    assign weight_addr_valid = weight_valid;
    
    assign input_addr_valid = input_valid;
    assign input_addr = feature_address;
    
    assign output_data_valid = outputdata_valid;
    assign done = done_valid;
    
    //bias
    assign bias_addr = bias_address;
    assign bias_addr_valid = bias_valid;
    
    //acc
    assign output_read_addr = acc_address;
    assign output_read_addr_valid = acc_valid;
    
    //relu
    genvar i;
    for(i=0;i<16;i=i+1)begin
        assign output_data[((i+1)*32)-1:i*32] = (vector_acc_output[((i+1)*32)-1]&en_relu)==1'b1 ?  32'b0 : vector_acc_output[((i+1)*32)-1:i*32];
    end  
    
endmodule