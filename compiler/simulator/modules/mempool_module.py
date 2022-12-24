# -*-coding:utf-8-*-
import logging

import numpy as np

from compiler.simulator.utils import tools
from compiler.simulator.utils import hardware_config


class MempoolModule:
    def __init__(self):
        self.fmp_bank = [
            np.zeros((hardware_config.hw_define['BANK_DEPTH_FMP'], hardware_config.hw_define['BANK_WIDTH_FMP']), dtype=np.float32)
            for i in range(hardware_config.hw_define['BANK_NUM_FMP'])
        ]
        self.weight_bank = np.zeros((hardware_config.hw_define['BANK_DEPTH_WEIGHT'], hardware_config.hw_define['BANK_WIDTH_WEIGHT']), dtype=np.float32)
        self.bias_bank = np.zeros((hardware_config.hw_define['BANK_DEPTH_BIAS'], hardware_config.hw_define['BANK_WIDTH_BIAS']), dtype=np.float32)

    def _get_target_bank(self, bank_type, bank_id):
        if bank_type == "weight":
            assert bank_id == 0
            return self.weight_bank
        elif bank_type == "bias":
            assert bank_id == 0
            return self.bias_bank
        elif bank_type == "fmp":
            assert bank_id in [0, 1, 2, 3, 4]
            return self.fmp_bank[bank_id]
        else:
            raise Exception

    def read_mempool(self, bank_type, bank_id, bank_addr, addr_length):  # 返回np.float32的datalines
        target_bank = self._get_target_bank(bank_type, bank_id)
        bank_depth = target_bank.shape[0]
        bank_width = target_bank.shape[1]
        assert bank_addr + addr_length <= bank_depth
        data_lines = target_bank[bank_addr: bank_addr + addr_length, :]
        assert data_lines.dtype == np.float32
        return data_lines

    def write_mempool(self, data_lines, bank_type, bank_id, bank_addr, addr_length):
        target_bank = self._get_target_bank(bank_type, bank_id)
        bank_depth = target_bank.shape[0]
        bank_width = target_bank.shape[1]
        assert data_lines.dtype == np.float32
        assert bank_addr + addr_length <= bank_depth
        assert np.prod(list(data_lines.shape)) == addr_length * bank_width
        data_lines = data_lines.reshape((addr_length, bank_width))
        target_bank[bank_addr: bank_addr + addr_length, :] = data_lines
    