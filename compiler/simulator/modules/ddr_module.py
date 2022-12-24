# -*-coding:utf-8-*-
import logging
import os

import numpy as np

from compiler.simulator.utils import hardware_config


class DDRModule:
    def __init__(self, channel_size_KB):
        self.ddr_name_list = list()
        self.ddr_size_dict = dict()
        self.ddr_dict = dict()
        self.add_ddr_channel("adj", channel_size_KB)
        self.add_ddr_channel("weight", channel_size_KB)
        self.add_ddr_channel("bias", channel_size_KB)
        self.add_ddr_channel("fmp", channel_size_KB)
        self.add_ddr_channel("inst", channel_size_KB)

    def add_ddr_channel(self, ddr_name, total_size_KB):
        assert ddr_name not in self.ddr_name_list
        assert ddr_name not in self.ddr_dict.keys()
        assert ddr_name not in self.ddr_size_dict.keys()
        ddr_size = total_size_KB * 1024 // 4 # float32 = 4Bytes
        # assert ddr_size % 4 == 0
        self.ddr_size_dict[ddr_name] = ddr_size
        self.ddr_dict[ddr_name] = np.zeros(ddr_size, dtype=np.float32)
        self.ddr_name_list.append(ddr_name)

    def dump_ddr_channel(self, ddr_name, dump_start_addr, dump_end_addr, output_file_dir):
        assert ddr_name in self.ddr_name_list
        assert dump_start_addr % 4 == 0
        assert dump_end_addr % 4 == 0
        dump_start_addr = dump_start_addr // 4
        dump_end_addr = dump_end_addr // 4
        assert dump_start_addr < dump_end_addr
        assert dump_end_addr <= self.ddr_size_dict[ddr_name]
        self.ddr_dict[ddr_name][dump_start_addr: dump_end_addr].tofile(output_file_dir)
        logging.info("Dump ddr channel %s addr %d ~ %d to %s" % (ddr_name, dump_start_addr, dump_end_addr, output_file_dir))
    
    def load_bin_file_to_ddr(self, bin_file_dir, ddr_name, addr):
        logging.info("Load %s to ddr channel %s" % (bin_file_dir, ddr_name))
        assert ddr_name in self.ddr_name_list
        assert addr % 4 == 0
        addr = addr // 4
        assert os.path.isfile(bin_file_dir)
        data = np.fromfile(bin_file_dir, dtype=np.float32)
        data_size = data.shape[0]
        assert addr + data_size <= self.ddr_size_dict[ddr_name]
        self.ddr_dict[ddr_name][addr: addr + data_size] = data

    def read_ddr(self, ddr_name, addr, size_B):
        assert ddr_name in self.ddr_name_list
        assert addr % 4 == 0
        addr = addr // 4
        assert size_B % 4 == 0
        size_B = size_B // 4
        assert addr + size_B <= self.ddr_size_dict[ddr_name]
        read_data_lines = self.ddr_dict[ddr_name][addr: addr + size_B]
        return read_data_lines

    def write_ddr(self, data_lines, ddr_name, addr, size_B):
        assert ddr_name in self.ddr_name_list
        assert data_lines.dtype == np.float32
        assert addr % 4 == 0
        addr = addr // 4
        assert size_B % 4 == 0
        size_B = size_B // 4
        assert addr + size_B <= self.ddr_size_dict[ddr_name]
        self.ddr_dict[ddr_name][addr: addr + size_B] = data_lines.reshape(size_B)
