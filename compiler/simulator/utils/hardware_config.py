# -*-coding:utf-8-*-
import os
import collections
from configparser import ConfigParser

# hardware define
hw_define = None


def generate_hardware_define(config_path):
    '''
    load hardware config from config_path
    '''
    assert os.path.exists(config_path)
    cp = ConfigParser()
    cp.read(config_path)

    global hw_define
    hw_define = collections.OrderedDict()

    hw_define['BANK_NUM_FMP'] = 5  # 片上mempool用来存储Feature Map的bank组数

    bank_width_fmp = cp.getint('hardware_config', 'bank_width_fmp')
    bank_width_weight = cp.getint('hardware_config', 'bank_width_weight')
    bank_width_bias = cp.getint('hardware_config', 'bank_width_bias')
    assert bank_width_fmp % 32 == 0 # fp32
    assert bank_width_weight % 32 == 0 # fp32
    assert bank_width_bias % 32 == 0 # fp32

    # bank_width的单位都是数
    hw_define['BANK_WIDTH_FMP'] = bank_width_fmp // 32
    hw_define['BANK_WIDTH_WEIGHT'] = bank_width_weight // 32
    hw_define['BANK_WIDTH_BIAS'] = bank_width_bias // 32

    hw_define['BANK_DEPTH_FMP'] = cp.getint('hardware_config', 'bank_depth_fmp')
    hw_define['BANK_DEPTH_WEIGHT'] = cp.getint('hardware_config', 'bank_depth_weight')
    hw_define['BANK_DEPTH_BIAS'] = cp.getint('hardware_config', 'bank_depth_bias')

    hw_define['AGG_PARALLEL'] = cp.getint('hardware_config', 'agg_parallel')
    hw_define['MM_PARALLEL_IC'] = cp.getint('hardware_config', 'mm_parallel_ic')
    hw_define['MM_PARALLEL_OC'] = cp.getint('hardware_config', 'mm_parallel_oc')
    hw_define['MM_PARALLEL'] = hw_define['MM_PARALLEL_IC'] * hw_define['MM_PARALLEL_OC']

    hw_define['DDR_CHANNEL_SIZE_KB'] = cp.getint('hardware_config', 'ddr_channel_size_KB')

    assert hw_define['MM_PARALLEL'] == hw_define['BANK_WIDTH_WEIGHT']
    assert hw_define['MM_PARALLEL_IC'] == hw_define['BANK_WIDTH_FMP']
    assert hw_define['MM_PARALLEL_OC'] == hw_define['BANK_WIDTH_FMP']
    assert hw_define['BANK_WIDTH_BIAS'] == hw_define['BANK_WIDTH_FMP']

