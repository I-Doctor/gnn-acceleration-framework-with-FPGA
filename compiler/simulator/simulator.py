# -*-coding:utf-8-*-
import argparse
import filecmp
import logging
import os
import sys
import time

import numpy as np

sys.path.append(os.getcwd())

from configparser import ConfigParser
from compiler.simulator.modules.agg_module import AggModule
from compiler.simulator.modules.datamover_module import DatamoverModule
from compiler.simulator.modules.ddr_module import DDRModule
from compiler.simulator.modules.inst_module import InstModule
from compiler.simulator.modules.mempool_module import MempoolModule
from compiler.simulator.modules.mm_module import MmModule
from compiler.simulator.utils import hardware_config
logging.basicConfig(format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt='%d %b %H:%M:%S', level=logging.INFO, stream=sys.stdout)

class Simulator:
    def __init__(self, input_dir, ddr_channel_size_KB):
        self.Inst = InstModule()
        self.Mempool = MempoolModule()
        self.DDR = DDRModule(channel_size_KB=ddr_channel_size_KB)
        self.Datamover = DatamoverModule()
        self.Agg = AggModule()
        self.Mm = MmModule()

        adj_dir = os.path.join(input_dir, 'adj.bin')
        weight_dir = os.path.join(input_dir, 'weight.bin')
        bias_dir = os.path.join(input_dir, 'bias.bin')
        inst_dir = os.path.join(input_dir, 'instructions.bin')
        fmp_dir = os.path.join(input_dir, 'feature.bin')
        # result_ref_dir = os.path.join(input_dir, 'xxx.bin')
        output_inst_read_dir = os.path.join(input_dir, 'inst_read.yaml')

        assert os.path.isfile(adj_dir)
        assert os.path.isfile(weight_dir)
        assert os.path.isfile(bias_dir)
        assert os.path.isfile(inst_dir)
        assert os.path.isfile(fmp_dir)
        # assert os.path.isfile(result_ref_dir)
        assert hardware_config.hw_define['DDR_CHANNEL_SIZE_KB'] > 0

        self.DDR.load_bin_file_to_ddr(adj_dir, "adj", 0)
        self.DDR.load_bin_file_to_ddr(weight_dir, "weight", 0)
        self.DDR.load_bin_file_to_ddr(bias_dir, "bias", 0)
        self.DDR.load_bin_file_to_ddr(inst_dir, "inst", 0)
        self.DDR.load_bin_file_to_ddr(fmp_dir, "fmp", 0)
        # read inst directly from the file! and decode the insts to the FIFO
        self.Inst.read_inst_and_decode(inst_dir, output_inst_read_dir)
        logging.info("GNN Accelerator Simulator is Instantiated!")

    def _exec_inst(self, inst_type, inst_param):
        if inst_type == "weight":
            self.Datamover.run_weight(inst_param, self.DDR, self.Mempool)
        elif inst_type == "bias":
            self.Datamover.run_bias(inst_param, self.DDR, self.Mempool)
        elif inst_type == "load":
            self.Datamover.run_load(inst_param, self.DDR, self.Mempool)
        elif inst_type == "save":
            self.Datamover.run_save(inst_param, self.DDR, self.Mempool)
        elif inst_type == "agg":
            self.Agg.run_agg(inst_param, self.DDR, self.Mempool)
        elif inst_type == "mm":
            self.Mm.run_mm(inst_param, self.Mempool)
        else:
            raise Exception

    def run(self):
        start_time = time.time()
        total_inst_cnt = self.Inst.total_inst_num
        # start run
        module_inst_cnt = [0 for i in range(self.Inst.module_num)]
        exec_inst_cnt = 0
        while exec_inst_cnt < total_inst_cnt:
            module_inst = [self.Inst.send_module_inst(i) for i in range(self.Inst.module_num)]
            execute_inst_flag = False # 这轮有没有执行指令
            for module_id in range(self.Inst.module_num):
                this_inst = module_inst[module_id]
                if this_inst != None:
                    execute_inst_flag = True
                    module_inst_cnt[module_id] += 1
                    exec_inst_cnt += 1
                    wait = this_inst['PARAM']['wait']
                    release = this_inst['PARAM']['release']
                    self.Inst.write_depend_reg(module_id, wait, release)
                    logging.info("run %6s inst %5d, %6.2f%%" % (this_inst['TYPE'], module_inst_cnt[module_id], 100 * exec_inst_cnt / total_inst_cnt))
                    self._exec_inst(this_inst['TYPE'], this_inst['PARAM'])
                    # self.Inst.print_depend_reg()
            if not execute_inst_flag: # 该轮没有执行任何指令，说明依赖出现了bug
                self.Inst.print_depend_reg()
                for i in range(self.Inst.module_num):
                    print("======= " + self.Inst.module_id_to_inst_type[i] + " next inst =======")
                    if len(self.Inst.module_inst_dict_list[i]) > 0:
                        print(self.Inst.module_inst_dict_list[i][0])
                    else:
                        print("None")
                logging.error("Dependency wrong!")
                raise Exception
        self.Inst.print_depend_reg()
        finish_time = time.time()
        logging.info("Simulator finish running in %.2f s" % (finish_time - start_time))
        return 0

    def dump_and_check_result(self, ddr_dump_dir, result_ref_dir):
        result_size = np.fromfile(result_ref_dir, dtype=np.int8).shape[0]
        self.DDR.dump_ddr_channel("fmp", 0, result_size, ddr_dump_dir)
        cmp_ans = filecmp.cmp(ddr_dump_dir, result_ref_dir)
        logging.info("Compare reference result %s with simulation result %s" % (result_ref_dir, ddr_dump_dir))
        logging.info("Compare ans: %s", cmp_ans)


def run_simulator(test_dir):
    if not os.path.exists(test_dir):
        logging.error("Cannot find input folder %s" % test_dir)
        exit(0)
    hardware_config.generate_hardware_define('./compiler/simulator/hardware_config.ini')
    simulator = Simulator(test_dir, hardware_config.hw_define['DDR_CHANNEL_SIZE_KB'])
    simulator.run()
    # simulator.dump_and_check_result(os.path.join(test_dir, './simulator_result.bin'), result_ref_dir)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # 输入的output文件夹路径
    parser.add_argument('--input', required=True, help='input data folder, including adj, bias, weight, inst, feature .bin file')
    args = parser.parse_args()
    run_simulator(args.input)
