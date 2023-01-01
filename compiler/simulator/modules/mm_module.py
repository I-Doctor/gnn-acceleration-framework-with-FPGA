# -*-coding:utf-8-*-
import logging

import numpy as np

from compiler.simulator.utils import tools
from compiler.simulator.utils import hardware_config


class MmModule:
    def __init__(self):
        self.b = 0
        self.a = 0
        self.r = 0
        self.out_group = 0
        self.in_group = 0
        self.bias_start_address = 0
        self.weight_start_address = 0
        self.input_address_per_feature = 0
        self.output_address_per_feature = 0
        self.input_start_address = 0
        self.node_number = 0
        self.output_start_address = 0

    def run_mm(self, inst_param, Mempool):
        self.b = inst_param['b']
        self.a = inst_param['a']
        self.r = inst_param['r']
        self.out_group = inst_param['out_group']
        self.in_group = inst_param['in_group']
        self.bias_start_address = inst_param['bias_start_address']
        self.weight_start_address = inst_param['weight_start_address']
        self.input_address_per_feature = inst_param['input_address_per_feature']
        self.output_address_per_feature = inst_param['output_address_per_feature']
        self.input_start_address = inst_param['input_start_address']
        self.node_number = inst_param['node_number']
        self.output_start_address = inst_param['output_start_address']

        bank_id_in = tools.decode_bank_id(self.in_group)
        bank_id_out = tools.decode_bank_id(self.out_group)
        N = self.node_number
        ICP = hardware_config.hw_define['MM_PARALLEL_IC']
        OCP = hardware_config.hw_define['MM_PARALLEL_OC']
        feature_in = Mempool.read_mempool("fmp", bank_id_in, self.input_start_address, N * self.input_address_per_feature)
        feature_in = feature_in.reshape((N, self.input_address_per_feature, ICP)) # Feature In: N * input_addr_per_feature * ICP
        weight_data = Mempool.read_mempool("weight", 0, self.weight_start_address, self.input_address_per_feature * self.output_address_per_feature)
        weight_data = weight_data.reshape((self.input_address_per_feature * self.output_address_per_feature, ICP, OCP)) # Weight: weight_addr_length * ICP * OCP
        feature_out = np.zeros((N, self.output_address_per_feature, OCP), dtype=np.float32) # Feature Out: N * output_addr_per_feature * OCP
        if self.b: # 加bias
            bias_data = Mempool.read_mempool("bias", 0, self.bias_start_address, self.output_address_per_feature)
            bias_data = bias_data.reshape((self.output_address_per_feature, OCP))
        
        # mm compute
        for n in range(N): # 计算一个node的结果
            for out_addr in range(self.output_address_per_feature): # 计算一个output_bank地址的数据
                this_output_feature = np.zeros((OCP), dtype=np.float32) # OCP
                for in_addr in range(self.input_address_per_feature): # 进行一次ICP*OCP的MM并累加
                    this_mm_feature_in = feature_in[n, in_addr, :] # ICP
                    weight_addr = out_addr * in_addr + in_addr
                    this_mm_weight = weight_data[weight_addr, :, :] # ICP * OCP
                    this_output_feature += np.matmul(this_mm_weight, this_mm_feature_in) # OCP
                feature_out[n, out_addr, :] = this_output_feature
            if self.b:
                feature_out[n, :, :] += bias_data

        if self.a: # 加另一个矩阵
            add_matrix = Mempool.read_mempool("fmp", bank_id_out, self.output_start_address, N * self.output_address_per_feature)
            add_matrix = add_matrix.reshape((N, self.output_address_per_feature, OCP))
            feature_out += add_matrix

        if self.r: # ReLU
            feature_out = tools.relu(feature_out)

        Mempool.write_mempool(feature_out, "fmp", bank_id_out, self.output_start_address, N * self.output_address_per_feature)
