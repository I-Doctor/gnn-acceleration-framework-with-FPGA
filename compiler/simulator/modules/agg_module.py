import logging

import numpy as np

from compiler.simulator.utils import tools
from compiler.simulator.utils import hardware_config

class AggModule:
    def __init__(self):
        self.t = 0
        self.b = 0
        self.e = 0
        self.r = 0
        self.out_group = 0
        self.in_group = 0
        self.address_per_feature = 0
        self.bias_start_address = 0
        self.input_buffer_start_address = 0
        self.edge_number = 0
        self.output_buffer_start_address = 0
        self.adj_dram_start_address = 0

        self.first_edge_cnt = 0
        self.last_edge_cnt = 0

    def decode_edge_input_offset_output_offset(self, float32_value):
        assert float32_value.dtype == np.float32
        float32_data = np.array([float32_value], dtype=np.float32)
        int16_data = float32_data.view(np.int16)
        assert np.prod(int16_data.shape) == 2
        output_offset = int16_data[1] # rol
        input_offset = int16_data[0] # column
        first_edge_flag = tools.value_at_bit(output_offset, 15)
        last_edge_flag = tools.value_at_bit(input_offset, 15)
        input_offset = input_offset & 0x7FFF # set highest bit 0
        output_offset = output_offset & 0x7FFF # set highest bit 0
        return input_offset, output_offset, first_edge_flag, last_edge_flag

    def run_agg(self, inst_param, DDR, Mempool):
        self.t = inst_param['t']
        self.b = inst_param['b']
        self.e = inst_param['e']
        self.r = inst_param['r']
        self.out_group = inst_param['out_group']
        self.in_group = inst_param['in_group']
        self.address_per_feature = inst_param['address_per_feature']
        self.bias_start_address = inst_param['bias_start_address']
        self.input_buffer_start_address = inst_param['input_buffer_start_address']
        self.edge_number = inst_param['edge_number']
        self.output_buffer_start_address = inst_param['output_buffer_start_address']
        self.adj_dram_start_address = inst_param['adj_dram_start_address']

        bank_id_in = tools.decode_bank_id(self.in_group)
        bank_id_out = tools.decode_bank_id(self.out_group)
        N = self.edge_number
        edge_data = DDR.read_ddr("adj", self.adj_dram_start_address, N * 8) # 每个edge的数据是64bit
        
        assert edge_data.shape[0] == 2 * N # 每条边是两个32bit
        for n in range(N): # 计算每条edge
            edge_value = edge_data[n * 2]
            input_offset, output_offset, first_edge_flag, last_edge_flag = self.decode_edge_input_offset_output_offset(edge_data[n * 2 + 1])
            read_bank_addr = self.input_buffer_start_address + input_offset * self.address_per_feature
            write_bank_addr = self.output_buffer_start_address + output_offset * self.address_per_feature
            in_bank_data = Mempool.read_mempool("fmp", bank_id_in, read_bank_addr, self.address_per_feature)
            out_bank_data = Mempool.read_mempool("fmp", bank_id_out, write_bank_addr, self.address_per_feature)
            tmp_data = in_bank_data

            if self.e: # 是否乘边
                tmp_data = in_bank_data * edge_value

            if not first_edge_flag: # 不是first edge则需要和输出累加
                if self.t: # sum
                    tmp_data = tmp_data + out_bank_data
                else: # max
                    tmp_data = np.maximum(tmp_data, out_bank_data)
            else:
                self.first_edge_cnt += 1
            
            if last_edge_flag: # 是last edge则需要加bias和relu
                self.last_edge_cnt += 1
                if self.b: # 加bias
                    read_bias_bank_addr = self.bias_start_address + output_offset * self.address_per_feature
                    bias_data = Mempool.read_mempool("bias", 0, read_bias_bank_addr, self.address_per_feature)
                    tmp_data = tmp_data + bias_data
                if self.r: # ReLU
                    tmp_data = tools.relu(tmp_data)

            Mempool.write_mempool(tmp_data, "fmp", bank_id_out, write_bank_addr, self.address_per_feature)

