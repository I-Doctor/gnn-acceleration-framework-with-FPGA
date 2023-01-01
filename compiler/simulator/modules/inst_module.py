# -*-coding:utf-8-*-
import logging

import collections
import numpy as np

from compiler.simulator.utils import inst_set, tools, yamlparser
from compiler.simulator.utils import hardware_config


class InstModule:
    def __init__(self):
        self.module_num = 6
        self.module_id_to_inst_type = [ # 各module的顺序代表了wait和realse中各模块的bit位
            "weight", # 0
            "bias",   # 1
            "load",   # 2
            "save",   # 3
            "agg",    # 4
            "mm",     # 5
        ]
        self.inst_type_to_module_id = dict()
        for module_id in range(self.module_num):
            self.inst_type_to_module_id[self.module_id_to_inst_type[module_id]] = module_id
        self.inst_dict_list = list() # 存储每条指令的dict
        self.module_inst_dict_list = [list() for i in range(self.module_num)] # 各个模块的指令
        self.depend_reg = [[0, 0, 0, 0, 0, 0] for i in range(self.module_num)]
        self.total_inst_num = -1

    def print_depend_reg(self):
        for module_id in range(self.module_num):
            logging.info("%6s depend_reg: %s" % (self.module_id_to_inst_type[module_id], str(self.depend_reg[module_id])))

    def write_inst_dict_list_to_file(self, output_inst_read_dir):
        for inst_define in self.inst_dict_list:
            inst_define['PARAM']['wait_module'] = "["
            inst_define['PARAM']['release_module'] = "["
            for module_id in range(self.module_num):
                if (inst_define['PARAM']['wait'] & (0b1 << module_id)) > 0: # wait module_id
                    inst_define['PARAM']['wait_module'] += self.module_id_to_inst_type[module_id] + ", "
                if (inst_define['PARAM']['release'] & (0b1 << module_id)) > 0: # release module_id
                    inst_define['PARAM']['release_module'] += (self.module_id_to_inst_type[module_id]) + ", "
            inst_define['PARAM']['wait_module'] = inst_define['PARAM']['wait_module'].rstrip(", ") + "]"
            inst_define['PARAM']['release_module'] = inst_define['PARAM']['release_module'].rstrip(", ") + "]"
        yamlparser.ordered_yaml_dump(self.inst_dict_list, output_inst_read_dir, default_flow_style=False)
        logging.info("Write readable inst to %s" % output_inst_read_dir)
        # encode_list = []
        # for inst_define in self.inst_dict_list:
        #     encode_list.extend(inst_set.encode_inst(inst_define['TYPE'], inst_define['PARAM']))
        # inst_set.write_inst_file(txt_file_dir, bin_file_dir, encode_list)

    def read_inst_and_decode(self, inst_file_dir, output_inst_read_dir):
        logging.info("Read Inst from %s", inst_file_dir)
        with open(inst_file_dir, encoding = "utf-8") as f:
            inst_bit_data = f.readline()
            assert len(inst_bit_data) % 128 == 0 # 所有指令均为128bit
            self.total_inst_num = len(inst_bit_data) // 128
            for inst_num in range(self.total_inst_num):
                bit_line = inst_bit_data[inst_num * 128: (inst_num + 1) * 128]
                this_inst_info = inst_set.opcode_inst_dict[str(int(bit_line[3 * 32: 3 * 32 + 4], base=2))]  # 低32bit的高4位是opcode，即96:100位
                inst_value_list = [
                    int(bit_line[3 * 32: 4 * 32], base=2), 
                    int(bit_line[2 * 32: 3 * 32], base=2), 
                    int(bit_line[1 * 32: 2 * 32], base=2), 
                    int(bit_line[0 * 32: 1 * 32], base=2),
                ] # 从低到高排列
                this_inst_type = this_inst_info['inst_type']
                this_inst_len = this_inst_info['length']
                assert this_inst_len == 4
                self.inst_dict_list.append(inst_set.inst_add_type(this_inst_type, inst_set.decode_inst(this_inst_type, inst_value_list)))
        
        if False: # set it True if debug inst from yaml file rather than .bin
            self.inst_dict_list = yamlparser.ordered_yaml_load(output_inst_read_dir)
        else:
            self.write_inst_dict_list_to_file(output_inst_read_dir)
        logging.info("Total inst num = %d", len(self.inst_dict_list))
        assert len(self.inst_dict_list) > 0
        for inst_define in self.inst_dict_list:
            self.module_inst_dict_list[self.inst_type_to_module_id[inst_define['TYPE']]].append(inst_define)
        assert self.total_inst_num == len(self.inst_dict_list)
        logging.info("Finished decode the inst FIFO")
        return self.total_inst_num

    def check_depend_reg(self, module_id, wait):
        flag = True
        for i, depend_r in enumerate(self.depend_reg[module_id]):
            if tools.value_at_bit(wait, i) == 1 and depend_r == 0:
                flag = False
                break
        return flag

    def write_depend_reg(self, module_id, wait, release):
        for i in range(self.module_num):
            if tools.value_at_bit(wait, i) == 1:
                self.depend_reg[module_id][i] -= 1
            if tools.value_at_bit(release, i) == 1:
                self.depend_reg[i][module_id] += 1

    def send_module_inst(self, module_id):
        if len(self.module_inst_dict_list[module_id]) != 0:
            wait = self.module_inst_dict_list[module_id][0]['PARAM']['wait']
            if self.check_depend_reg(module_id, wait) == True:
                return self.module_inst_dict_list[module_id].pop(0)
            else:
                return None
        else:
            return None
