# -*-coding:utf-8-*-
import argparse
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
from compiler.simulator.utils import hardware_config, yamlparser

logging.basicConfig(format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt='%d %b %H:%M:%S', level=logging.INFO, stream=sys.stdout)

class Simulator:
    def __init__(self, input_dir, ddr_channel_size_KB):
        self.Inst = InstModule()
        self.Mempool = MempoolModule()
        self.DDR = DDRModule(channel_size_KB=ddr_channel_size_KB)
        self.Datamover = DatamoverModule()
        self.Agg = AggModule()
        self.Mm = MmModule()

        self.input_dir = input_dir
        adj_dir = os.path.join(input_dir, 'adj.bin')
        weight_dir = os.path.join(input_dir, 'weight.bin')
        bias_dir = os.path.join(input_dir, 'bias.bin')
        inst_dir = os.path.join(input_dir, 'instructions.bin')
        fmp_dir = os.path.join(input_dir, 'feature.bin')
        output_inst_read_dir = os.path.join(input_dir, 'inst_read.yaml')
        output_inst_rtl_dir = os.path.join(input_dir, 'inst.rtl.bin')

        assert os.path.exists(input_dir), ("Cannot find input folder " + input_dir)
        assert os.path.isfile(inst_dir)
        assert os.path.isfile(fmp_dir)
        assert hardware_config.hw_define['DDR_CHANNEL_SIZE_KB'] > 0

        self.DDR.load_bin_file_to_ddr(inst_dir, "inst", 0)
        self.DDR.load_bin_file_to_ddr(fmp_dir, "fmp", 0)
        if os.path.isfile(adj_dir):
            self.DDR.load_bin_file_to_ddr(adj_dir, "adj", 0)
        if os.path.isfile(weight_dir):
            self.DDR.load_bin_file_to_ddr(weight_dir, "weight", 0)
        if os.path.isfile(bias_dir):
            self.DDR.load_bin_file_to_ddr(bias_dir, "bias", 0)
        # read inst directly from the file! and decode the insts to the FIFO
        self.Inst.read_inst_and_decode(inst_dir, output_inst_read_dir, output_inst_rtl_dir)
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
        # for this_inst in self.Inst.inst_dict_list:
        #     self._exec_inst(this_inst['TYPE'], this_inst['PARAM'])
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
                    logging.info("run inst %3d: %6s %3d, %6.1f%%" % (exec_inst_cnt, this_inst['TYPE'], module_inst_cnt[module_id], 100 * exec_inst_cnt / total_inst_cnt))
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
        assert self.Agg.first_edge_cnt == self.Agg.last_edge_cnt, "Agg module: first edge: %d, last edge: %d" % (self.Agg.first_edge_cnt, self.Agg.last_edge_cnt)
        finish_time = time.time()
        logging.info("Simulator finish running in %.2f s" % (finish_time - start_time))
        return 0

    def dump_and_check_result(self, ref_result_dir):
        ERROR_THRESHOLD = 1e-6
        assert ref_result_dir.endswith(".npy")
        output_info_dir = os.path.join(self.input_dir, 'output.yaml')
        ddr_dump_dir = os.path.join(self.input_dir, 'simulator_result.bin')
        assert os.path.isfile(ref_result_dir)
        assert os.path.isfile(output_info_dir)
        output_info = yamlparser.ordered_yaml_load(output_info_dir)
        start_ddr_addr = output_info["output_info"]["output_addr"]
        dump_size = output_info["output_info"]["output_size"]
        ref_result = np.load(ref_result_dir)
        assert dump_size == np.prod(ref_result.shape) * 4
        sim_result = self.DDR.dump_ddr_channel("fmp", start_ddr_addr, ref_result.shape, ddr_dump_dir)
        assert ref_result.dtype == np.float32
        assert sim_result.dtype == np.float32

        delta_result = ref_result - sim_result
        total_error = np.sum(abs(delta_result))
        max_error = np.max(abs(delta_result))
        avg_error = np.mean(abs(delta_result))
        cmp_result = max_error < ERROR_THRESHOLD
        logging.info("Compare reference result %s with simulation result %s" % (ref_result_dir, ddr_dump_dir))
        logging.info("Max error: {:.2e}; Avg error: {:.2e}; Total error: {:.2e}".format(max_error, avg_error, total_error))
        logging.info("Compare result: " + str(cmp_result))
        return cmp_result


def run_simulator(test_dir, ref_result_dir):
    hardware_config.generate_hardware_define('./compiler/simulator/hardware_config.ini')
    simulator = Simulator(test_dir, hardware_config.hw_define['DDR_CHANNEL_SIZE_KB'])
    simulator.run()
    cmp_result = simulator.dump_and_check_result(ref_result_dir)
    return cmp_result


if __name__ == '__main__':
    ## single agg layer passed case
    # run_simulator("./compiler/result/agg1-case37-0207", "./compiler/IR_and_data/sage-mean-2-16-enzymes/feat2.npy")
    # run_simulator("./compiler/result/agg1-cora-0207", "./compiler/IR_and_data/sage-mean-2-16-cora/feat3.npy")
    # run_simulator("./compiler/result/agg1-pubmed-0207", "./compiler/IR_and_data/sage-mean-2-16-pubmed/feat3.npy")
    ## single mm layer passed case
    # run_simulator("./compiler/result/mm1-cora-0207", "./compiler/IR_and_data/sage-mean-2-16-cora/feat2.npy")
    ## network passed case
    # run_simulator("./compiler/result/case37-0207", "./compiler/IR_and_data/sage-mean-2-16-enzymes/feat7.npy")
    # run_simulator("./compiler/result/pubmed-0207", "./compiler/IR_and_data/sage-mean-2-16-pubmed/feat7.npy")
    pass
