`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/1/11
// Design Name: testbench_agg
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench generation for agg module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench_agg(

    );
    parameter TEST_NUM = 1;
    reg clk,rst;

    reg ap_start;
    wire ap_done;

    wire [31:0] dram_xfer_size_in_bytes;
    wire [63:0] dram_xfer_start_addr;

//  ���1����

    reg [511:0] adj_data_buffer[511:0];   
    reg [511:0] feature_data_buffer[511:0];   
    reg [511:0] result_buffer[511:0];    
    reg [511:0] result_validation_buffer[511:0];     
    reg [511:0] output_flag;            //flag
    reg[7:0] next_test;

    reg [128-1:0] inst_reg[1:0];
    wire [128-1:0]instructions;
    assign instructions=inst_reg[0];

    initial begin           //读取数据+初始化信�??
        $readmemb("C:/Users/10126/Desktop/agg_sims/test2/instructions.txt",inst_reg,0,1);
        $readmemb("C:/Users/10126/Desktop/agg_sims/test2/adj.txt",adj_data_buffer,0,26);
        $readmemb("C:/Users/10126/Desktop/agg_sims/test2/feature.txt",feature_data_buffer,0,37);
        $readmemb("C:/Users/10126/Desktop/agg_sims/test2/initial_result.txt",result_buffer,0,37);    //ȫ0
        $readmemb("C:/Users/10126/Desktop/agg_sims/test2/simulator_result.txt",result_validation_buffer,0,37);
//        $readmemb("C:/Users/10126/Desktop/agg_sims/case37-agg1/instructions.txt",inst_reg,0,1);
//        $readmemb("C:/Users/10126/Desktop/agg_sims/case37-agg1/adj.txt",adj_data_buffer,0,26);
//        $readmemb("C:/Users/10126/Desktop/agg_sims/case37-agg1/feature.txt",feature_data_buffer,0,37);
//        $readmemb("C:/Users/10126/Desktop/agg_sims/case37-agg1/initial_result.txt",result_buffer,0,37);    //ȫ0
//        $readmemb("C:/Users/10126/Desktop/agg_sims/case37-agg1/simulator_result.txt",result_validation_buffer,0,37);
        output_flag<=512'b0;
        clk<=1;
        rst<=1;
        ap_start<=0;
  
        #20 rst<=0;
        ap_start<=1;
        next_test<=1;

        #10 ap_start<=0;
    end
    
    always #5 clk<=!clk;


//      data   ģ��ʱΪ����û???�Ƿô�Ĺ̶���??
    wire read_start,data_tready;
    reg read_done,data_tvalid,data_tlast;
    reg [511:0]data_tdata;

    reg read_enable;
    reg [31:0]transfer_num;      //�������??
    reg [31:0]transfer_counter;  //����??
    reg [63:0]transfer_start_addr;

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            read_done<=0;
            read_enable<=0;
            transfer_num<=0;
            transfer_start_addr<=0;
        end
        else if (read_start) begin
            read_done<=0;
            read_enable<=1;
            transfer_num<=dram_xfer_size_in_bytes/64;       //������λ���
            transfer_start_addr<=dram_xfer_start_addr;
        end
        else if(read_enable)    begin
            if (data_tready&&data_tvalid&&transfer_counter==transfer_num-1) begin
                read_done<=1;
                read_enable<=0;
                transfer_num<=0;
                transfer_start_addr<=0;
            end
        end
    end

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            transfer_counter<=0;
            data_tdata<=0;
        end
        else if (read_start) begin
            transfer_counter<=0;
            data_tlast<=0;
        end
        else if (read_enable)begin
            if(data_tready&&data_tvalid) begin
                if(transfer_counter==transfer_num-1) begin
                    transfer_counter<=0;
                    data_tlast<=1;
                end
                else begin
                    transfer_counter<=transfer_counter+1;
                    data_tlast <=0;
                end
            end
        end
    end
    
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            data_tvalid<=0;
            data_tdata<=0;
        end
        else if (read_enable) begin
            data_tvalid<=1;
            data_tdata<=adj_data_buffer[transfer_start_addr+transfer_counter];
        end
        else begin
            data_tvalid<=0;
            data_tdata<=0;
        end
    end

//data
    wire feature_data_valid;
    wire [511:0]feature_data;

    wire input_result_data_valid;
    wire [511:0]input_result_data;

    wire output_result_valid;
    wire [511:0]output_result_data;
    

//addr
    wire [10:0]output_result_addr;  //output address
    
    wire [10:0]input_result_addr;   //input address
    wire input_result_addr_valid;          //input valid
    
    wire feature_addr_valid;   //weight valid
    wire [10:0]feature_addr;    //weight address


//  weight�Ķ�����4��ʱ
    reg [4-1:0]feature_data_valid_reg;
    reg [512*4-1:0]feature_data_reg;

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            feature_data_valid_reg<=4'b0;
            feature_data_reg<=0;
        end
        else if (feature_addr_valid) begin
            feature_data_valid_reg[0]<=1;
            feature_data_reg[512-1:0]<=feature_data_buffer[feature_addr];
            feature_data_valid_reg[3:1]<=feature_data_valid_reg[2:0];
            feature_data_reg[512*4-1:512]<=feature_data_reg[512*3-1:0];
        end
        else begin
            feature_data_valid_reg[0]<=0;
            feature_data_reg[512-1:0]<=0;
            feature_data_valid_reg[3:1]<=feature_data_valid_reg[2:0];
            feature_data_reg[512*4-1:512]<=feature_data_reg[512*3-1:0];
        end
    end

    assign feature_data=feature_data_reg[512*4-1:512*3];
    assign feature_data_valid=feature_data_valid_reg[3];

//  result�Ķ�����4��ʱ
    reg [4-1:0]input_result_data_valid_reg;
    reg [512*4-1:0]input_result_reg;

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            input_result_data_valid_reg<=4'b0;
            input_result_reg<=0;
        end
        else if (input_result_addr_valid) begin
            input_result_data_valid_reg[0]<=1;
            input_result_reg[512-1:0]<=result_buffer[input_result_addr];
            input_result_data_valid_reg[3:1]<=input_result_data_valid_reg[2:0];
            input_result_reg[512*4-1:512]<=input_result_reg[512*3-1:0];
        end
        else begin
            input_result_data_valid_reg[0]<=0;
            input_result_reg[512-1:0]<=0;
            input_result_data_valid_reg[3:1]<=input_result_data_valid_reg[2:0];
            input_result_reg[512*4-1:512]<=input_result_reg[512*3-1:0];
        end
    end

    assign input_result_data=input_result_reg[512*4-1:512*3];
    assign input_result_data_valid=input_result_data_valid_reg[3];


//  ��������д����??
    always@(posedge clk or posedge rst) begin
        if (output_result_valid) begin
            result_buffer[output_result_addr]<=output_result_data;
        end
    end
    
    always@(posedge clk or posedge rst) begin
        if (output_result_valid) begin
            if (result_validation_buffer[output_result_addr]==output_result_data) begin
                output_flag[output_result_addr]<=1;
            end
            else begin
                output_flag[output_result_addr]<=0;
            end
        end
    end

   gnn_0_example_agg G(.aclk(clk),
   .areset(rst),
   .kernel_clk(clk),
   .kernel_rst(rst),
   .agg_read_buffer_0_avalid(feature_addr_valid),
   .agg_read_buffer_0_addr(feature_addr),
   .agg_read_buffer_0_valid(feature_data_valid),
   .agg_read_buffer_0_data(feature_data),
   .agg_read_buffer_1_A_avalid(input_result_addr_valid),
   .agg_read_buffer_1_A_addr(input_result_addr),
   .agg_read_buffer_1_A_valid(input_result_data_valid),
   .agg_read_buffer_1_A_data(input_result_data),
   .agg_write_buffer_1_A_valid(output_result_valid),
   .agg_write_buffer_1_A_addr(output_result_addr),
   .agg_write_buffer_1_A_data(output_result_data),
   .ap_start(ap_start),
   .ap_done(ap_done),
   .ctrl_addr_offset(64'b0),
   .ctrl_instruction(instructions),
   .dram_xfer_start_addr(dram_xfer_start_addr),
   .dram_xfer_size_in_bytes(dram_xfer_size_in_bytes),
   .read_start(read_start),
   .read_done(read_done),
   .data_tvalid(data_tvalid),
   .data_tready(data_tready),
   .data_tlast(data_tlast),
   .data_tdata(data_tdata)
   );
endmodule