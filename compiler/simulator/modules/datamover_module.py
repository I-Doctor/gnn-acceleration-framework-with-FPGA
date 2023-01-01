# -*-coding:utf-8-*-
import logging

import numpy as np

from compiler.simulator.utils import tools
from compiler.simulator.utils import hardware_config


class DatamoverModule:
    def __init__(self):
        self.buffer_address_length = 0 # for weight, bias, load, save
        self.buffer_start_address = 0 # for weight, bias, load, save
        self.dram_byte_length = 0 # for weight, bias, load, save
        self.dram_start_address = 0 # for weight, bias, load, save
        self.group = 0 # for load, save
        self.last_save_addr = None # defualt dump ddr_addr: last save dram_start_address

    def run_weight(self, inst_param, DDR, Mempool):
        self.buffer_address_length = inst_param['buffer_address_length']
        self.buffer_start_address = inst_param['buffer_start_address']
        self.dram_byte_length = inst_param['dram_byte_length']
        self.dram_start_address = inst_param['dram_start_address']
        assert self.buffer_address_length * hardware_config.hw_define['BANK_WIDTH_WEIGHT'] * 4 == self.dram_byte_length
        # read data from DDR and write to mempool
        data_lines = DDR.read_ddr("weight", self.dram_start_address, self.dram_byte_length)
        Mempool.write_mempool(data_lines, "weight", 0, self.buffer_start_address, self.buffer_address_length)

    def run_bias(self, inst_param, DDR, Mempool):
        self.buffer_address_length = inst_param['buffer_address_length']
        self.buffer_start_address = inst_param['buffer_start_address']
        self.dram_byte_length = inst_param['dram_byte_length']
        self.dram_start_address = inst_param['dram_start_address']
        assert self.buffer_address_length * hardware_config.hw_define['BANK_WIDTH_BIAS'] * 4 == self.dram_byte_length
        # read data from DDR and write to mempool
        data_lines = DDR.read_ddr("bias", self.dram_start_address, self.dram_byte_length)
        Mempool.write_mempool(data_lines, "bias", 0, self.buffer_start_address, self.buffer_address_length)

    def run_load(self, inst_param, DDR, Mempool):
        self.buffer_address_length = inst_param['buffer_address_length']
        self.buffer_start_address = inst_param['buffer_start_address']
        self.dram_byte_length = inst_param['dram_byte_length']
        self.dram_start_address = inst_param['dram_start_address']
        self.group = inst_param['group']
        assert self.buffer_address_length * hardware_config.hw_define['BANK_WIDTH_FMP'] * 4 == self.dram_byte_length
        # read data from DDR and write to mempool
        bank_id = tools.decode_bank_id(self.group)
        data_lines = DDR.read_ddr("fmp", self.dram_start_address, self.dram_byte_length)
        Mempool.write_mempool(data_lines, "fmp", bank_id, self.buffer_start_address, self.buffer_address_length)

    def run_save(self, inst_param, DDR, Mempool):
        self.buffer_address_length = inst_param['buffer_address_length']
        self.buffer_start_address = inst_param['buffer_start_address']
        self.dram_byte_length = inst_param['dram_byte_length']
        self.dram_start_address = inst_param['dram_start_address']
        self.group = inst_param['group']
        assert self.buffer_address_length * hardware_config.hw_define['BANK_WIDTH_FMP'] * 4 == self.dram_byte_length
        self.last_save_addr = self.dram_start_address # update dump address
        # read data from mempool and write to DDR
        bank_id = tools.decode_bank_id(self.group)
        data_lines = Mempool.read_mempool("fmp", bank_id, self.buffer_start_address, self.buffer_address_length)
        DDR.write_ddr(data_lines, "fmp", self.dram_start_address, self.dram_byte_length)
