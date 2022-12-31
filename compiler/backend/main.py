from typing import Dict, Tuple, List
from fusion import fusion_detector
from loading import operator_loader
from utils.coding import *
from utils.reorder import *
import os
import argparse

# global weight_address
# global bias_address
# global weight_bias_dram_byte_address

### one hot note ###
## wait / release:
# 0: loadw
# 1: loadb
# 2: loadf
# 3: savef
# 4: agg
# 5: mm
# 100: none
## group:
# 0: buffer0
# 1: buffer1-A
# 2: buffer1-B
# 3: buffer2-A
# 4: buffer2-B

TYPE_FIRST = 0
TYPE_AGG_BEFORE = 1
TYPE_MM_BEFORE = 2
TYPE_BOTH_BEFORE = 3

TYPE_END = 4
TYPE_AGG_AFTER = 5
TYPE_MM_AFTER = 6
TYPE_BOTH_AFTER = 7

TYPE_ACC = 8
TYPE_NORMAL = 9

TYPE_DRAM_BEFORE = 10
TYPE_DRAM_NON_BEFORE = 11

TYPE_DRAM_AFTER = 12
TYPE_DRAM_NON_AFTER = 13

def check_after_type(ops: List, idx: int):
    if idx == len(ops) - 1:
        return TYPE_END
    else:
        if isinstance(ops[idx + 1], Tuple):
            return TYPE_BOTH_AFTER
        else:
            if ops[idx + 1]['op_type'] == 'agg':
                return TYPE_AGG_AFTER
            elif ops[idx + 1]['op_type'] == 'mm':     
                return TYPE_MM_AFTER
            else:
                raise NotImplementedError


def check_save_type(ops: List, idx: int):
    if idx == len(ops) - 1:
        return TYPE_NORMAL
    else:
        j = idx + 1
        cand_op = dict()
        cand_op['accumulation'] = False
        while (j < len(ops)):
            cand_op = ops[j]
            if isinstance(cand_op, Dict) and cand_op['op_type'] == 'mm':    
                break 
            if isinstance(cand_op, Tuple):
                cand_op = cand_op[1]
                break
            j += 1
        if cand_op['accumulation']:   
            return TYPE_ACC
        else:
            return TYPE_NORMAL


def check_dram_type(ops: List, idx: int):
    dram_before = TYPE_DRAM_NON_BEFORE
    dram_after = TYPE_DRAM_NON_AFTER

    if isinstance(ops[0], Dict):
        input_name = ops[0]['op_input_data']['data_name']
    elif isinstance(ops[0], Tuple):
        input_name = ops[0][0]['op_input_data']['data_name']
    else:
        raise NotImplementedError
    
    if isinstance(ops[idx], Dict):
        output_name = ops[idx]['op_output_data']['data_name']
    elif isinstance(ops[idx], Tuple):
        output_name = ops[idx][1]['op_output_data']['data_name']
    else:
        raise NotImplementedError
    
    if isinstance(ops[idx], Dict):
        input_op = ops[idx]
    elif isinstance(ops[idx], Tuple):
        input_op = ops[idx][0]
    else:
        raise NotImplementedError
    # check if the load should wait a save in dram
    if input_op['op_input_data']['data_name'] == input_name:
        dram_before = TYPE_DRAM_NON_BEFORE
    else:
        dram_before = TYPE_DRAM_BEFORE
    
    # check if the save should release a load in dram
    if idx == len(ops) - 1:
        dram_after = TYPE_DRAM_NON_AFTER
    else:
        dram_after = TYPE_DRAM_NON_AFTER
        j = idx + 1
        while(j < len(ops)):
            cand_op = ops[j]
            if isinstance(cand_op, Tuple):
                cand_op = cand_op[0]
            if cand_op['op_input_data']['data_name'] == output_name:
                dram_after = TYPE_DRAM_AFTER
            j += 1
    
    return (dram_before, dram_after)


def agg_distribute(agg_op: Dict, fbuffer_size: List, input_address: List[int], 
    output_address: List[int], bias_dram_byte_address: int, adj_dram_byte_address: int, before_type: int, after_type: int, dram_type: Tuple[int, int]):

    instructions = list()

    N = agg_op['op_input_data']['data_shape'][0]
    C = agg_op['op_input_data']['data_shape'][1]

    assert N == agg_op['op_adj']['data_shape'][0]
    assert N == agg_op['op_adj']['data_shape'][1]

    bool_b = agg_op['bias']
    bool_e = agg_op['apply']
    bool_r = agg_op['relu']
    bool_t = agg_op['reduce_type'] == "sum"

    bias_start_address = 0
    # load b
    if bool_b:
        bias_start_address = bias_dram_byte_address
        _ = bias_combination([-1, -1], os.path.join('../IR_and_data', agg_op['op_bias']['read_data_path']), C, 
            '../result/bias.bin', bias_dram_byte_address)
        bias_dram_byte_address += C * 4

    # corresponding to columns
    block_in_N = min(((fbuffer_size[0] // 4) * fbuffer_size[1]) // C, N)
    # corrsponding to rows
    block_out_N = min(((fbuffer_size[0] // 4) * fbuffer_size[1]) // C, N)

    # reorder the adjacent matrix
    nnz_list, adj_dram_address_list, dram_offset = adj_reorder(
        os.path.join('input', agg_op['op_adj']['read_data_path']), 
        os.path.join('input', agg_op['op_adj']['read_index_path']), 
        N, agg_op['op_adj']['non_zeros'], os.path.join('../result', 'adj.bin'), 
        block_out_N, block_in_N)
    for ad in adj_dram_address_list:
        ad += adj_dram_byte_address
    adj_dram_byte_address += dram_offset
    
    block_in_num = (N + block_in_N - 1) // block_in_N
    block_out_num = (N + block_out_N - 1) // block_out_N

    loadf_w = []
    loadf_r = []
    agg_w = []
    agg_r = []
    savef_w = []
    savef_r = []

    count = 0
    out_feature_dram_start_address = np.max(input_address) + N * C * 4
    output_address.append(out_feature_dram_start_address)
    for i in range(block_out_num):

        in_feature_dram_start_address = input_address[-1]
        for j in range(block_in_num):
            in_buffer_depth_offset = (count % 2) * fbuffer_size[1] // 2

            # the (i, j)-th block in adjacent matrix
            nnzs = nnz_list[i * block_in_num + j]
            adj_dram_address = adj_dram_address_list[i * block_in_num + j]

            in_dram_byte = min(block_in_N * C * 4, input_address[-1] + N * C * 4 - in_feature_dram_start_address)
            
            if (count < 2 and before_type in [TYPE_FIRST, TYPE_MM_BEFORE]):
                loadf_w = [100]
                loadf_r = [4]
            else:
                loadf_w = [4]
                loadf_r = [4]
            if (count == 0 and dram_type[0] == TYPE_DRAM_BEFORE):
                loadf_w.append(3)
            
            instructions.append(loadf(loadf_w, loadf_r, 0, in_dram_byte // fbuffer_size[0], \
                in_buffer_depth_offset, in_dram_byte, in_feature_dram_start_address))
            in_feature_dram_start_address += in_dram_byte

            if (count < 2 and before_type in [TYPE_FIRST]):
                agg_w = [2]
            elif (count < 2 and before_type in [TYPE_MM_BEFORE, TYPE_BOTH_BEFORE]):
                agg_w = [2, 5]
            else:
                agg_w = [2, 3]
            if (i == block_out_num - 1 and j > block_in_num - 3 and after_type in [TYPE_MM_AFTER, TYPE_END]):
                agg_r = [3]
            else:
                agg_r = [2, 3]
                
            if (count == 0 and bool_b):
                agg_w.append(1)
            
            instructions.append(agg(agg_w, agg_r, bool_t, bool_b, bool_e, bool_r, 1, 0, C // (fbuffer_size[0] // 4), \
                in_buffer_depth_offset, bias_start_address, 0, nnzs, adj_dram_address))

            count += 1
        
        # savef
        # handle the residue
        out_dram_byte = min(block_out_N * C * 4, input_address[-1] + N * C * 2 * 4 - out_feature_dram_start_address)
        savef_w = [4]
        if (i > block_out_num - 3 and after_type in [TYPE_MM_AFTER]):
            savef_r = [2]
        elif (i > block_out_num - 3 and after_type in [TYPE_END]):
            savef_r = [100]
        else:
            savef_r = [4]
        if (i == block_out_num - 1 and dram_type[1] == TYPE_DRAM_AFTER):
            savef_r.append(2)
        instructions.append(savef(savef_w, savef_r, 1, out_dram_byte // fbuffer_size[0], \
            0, out_dram_byte, out_feature_dram_start_address))
        out_feature_dram_start_address += out_dram_byte

    return instructions, input_address, output_address, bias_dram_byte_address, adj_dram_byte_address


def mm_distribute(mm_op: Dict, fbuffer_size: List, wbuffer_size: List, bbuffer_szie: List, 
    weight_buffer_address: int, bias_buffer_address: int, 
    weight_dram_byte_address: int, bias_dram_byte_address: int, 
    input_address: List[int], output_address: List[int], before_type: int, after_type: int, save_type: int, dram_type: Tuple[int, int]):

    instructions = list()

    bool_a = mm_op['accumulation']
    bool_b = mm_op['bias']
    bool_r = mm_op['relu']

    N = mm_op['op_input_data']['data_shape'][0]
    C_in = mm_op['op_input_data']['data_shape'][1]
    C_out = mm_op['op_weight']['data_shape'][1]

    assert C_in == mm_op['op_weight']['data_shape'][0]

    # load w
    this_weight_address = weight_buffer_address
    weight_offset = weight_reorder(wbuffer_size, os.path.join('../IR_and_data', mm_op['op_weight']['read_data_path']), 
        C_in, C_out, '../result/weight.bin', weight_dram_byte_address)
    instructions.append(loadw([100], [5], weight_offset, this_weight_address, \
        weight_offset * wbuffer_size[0], weight_dram_byte_address))
    weight_buffer_address += weight_offset
    weight_dram_byte_address += weight_offset * wbuffer_size[0]

    this_bias_address = 0
    # load b
    if bool_b:
        this_bias_address = bias_buffer_address
        bias_offset = bias_combination(bbuffer_szie, os.path.join('../IR_and_data', mm_op['op_bias']['read_data_path']), 
            C_out, '../result/bias.bin', bias_dram_byte_address)
        instructions.append(loadb([100], [5], bias_offset, this_bias_address, \
            bias_offset * bbuffer_szie[0], bias_dram_byte_address))
        bias_buffer_address += bias_offset
        bias_dram_byte_address += bias_offset * bbuffer_szie[0]

    # load - mm - save
    block_N = min(((fbuffer_size[0] // 4) * fbuffer_size[1]) // max(C_in, C_out), N)
    block_num = (N + block_N - 1) // block_N
    # decide the dram address of input and output features
    in_feature_dram_start_address = input_address[-1]
    out_feature_dram_start_address = np.max(input_address) + N * C_in * 4
    if bool_a:
        out_feature_dram_start_address = output_address[-1]
    else: 
        output_address.append(out_feature_dram_start_address)

    loado_w = []
    loado_r = []
    loadf_w = []
    loadf_r = []
    mm_w = []
    mm_r = []
    savef_w = []
    savef_r = []

    
    for i in range(block_num):
        # buffer order
        in_group_id = i % 2 + 1
        out_group_id = i % 2 + 3
        # handle the residue
        in_dram_byte = min(block_N * C_in * 4, input_address[-1] + N * C_in * 4 - in_feature_dram_start_address)
        out_dram_byte = min(block_N * C_out * 4, input_address[-1] + N * (C_in + C_out) * 4 - out_feature_dram_start_address)
        if bool_a:
            out_dram_byte = min(block_N * C_out * 4, output_address[-1] + N * C_out * 4 - out_feature_dram_start_address)

        # if the operator is connected, then it's not the first two
        if bool_a:
            # if (i < 2 and before_type in [TYPE_FIRST, TYPE_AGG_BEFORE]):
            #     loado_w = [100]
            #     loado_r = [100]
            # else:
            loado_w = [3]
            loado_r = [100]
            # load the output first if accumulate
            instructions.append(loadf(loado_w, loado_r, out_group_id, out_dram_byte // fbuffer_size[0], \
                0, out_dram_byte, out_feature_dram_start_address))
        
        
        if (i < 2 and before_type == TYPE_FIRST):
            loadf_w = [100]
            loadf_r = [5]
        elif (i < 2 and before_type == TYPE_AGG_BEFORE):
            if bool_a:
                loadf_w = [100]
            else: 
                loadf_w = [3]
            loadf_r = [5]
        else:
            loadf_w = [5]
            loadf_r = [5]
        if (i == 0 and dram_type[0] == TYPE_DRAM_BEFORE and not bool_a):
            loadf_w.append(3)
        instructions.append(loadf(loadf_w, loadf_r, in_group_id, in_dram_byte // fbuffer_size[0], \
            0, in_dram_byte, in_feature_dram_start_address))
        in_feature_dram_start_address += in_dram_byte

        if (i > block_num - 3 and after_type in [TYPE_AGG_AFTER, TYPE_BOTH_AFTER]):
            mm_r = [3, 4]
        elif (i > block_num - 3 and after_type in [TYPE_END]):
            mm_r = [3]
        else:
            mm_r = [2, 3]
        if (i < 2 and before_type in [TYPE_FIRST, TYPE_AGG_BEFORE]):
            mm_w = [2]
        else:
            mm_w = [2, 3]
        if (i == 0):
            mm_w.append(0)
            if bool_b:
                mm_w.append(1)
            
        instructions.append(mm(mm_w, mm_r, bool_b, bool_a, bool_r, out_group_id, in_group_id, \
            this_bias_address, this_weight_address, C_in // (fbuffer_size[0] // 4), 0, \
            C_out // (fbuffer_size[0] // 4), 0, in_dram_byte // 4 // C_in))
    
        savef_w = [5]
        if (i > block_num - 3 and save_type == TYPE_ACC):    
            savef_r = [2]
            if after_type == TYPE_MM_AFTER:
                savef_r.append(5)
        elif (i > block_num - 3 and after_type in [TYPE_END, TYPE_AGG_AFTER]):
            savef_r = [100]
        else:
            savef_r = [5]
        if (i == block_num - 1 and dram_type[1] == TYPE_DRAM_AFTER):
            savef_r.append(2)
        instructions.append(savef(savef_w, savef_r, out_group_id, out_dram_byte // fbuffer_size[0], \
            0, out_dram_byte, out_feature_dram_start_address))
        out_feature_dram_start_address += out_dram_byte
    
    return instructions, weight_buffer_address, bias_buffer_address, \
        weight_dram_byte_address, bias_dram_byte_address, input_address, output_address
        

def fusion_distribute(agg_mm_op: Tuple, fbuffer_size: List, wbuffer_size: List, bbuffer_szie: List, 
    weight_buffer_address: int, bias_buffer_address: int, 
    weight_dram_byte_address: int, bias_dram_byte_address: int, adj_dram_byte_address: int, 
    input_address: List[int], output_address: List[int], before_type: int, after_type: int, save_type: int, dram_type: Tuple[int, int]):

    instructions = list()

    agg_op = agg_mm_op[0]
    mm_op = agg_mm_op[1]

    bool_agg_b = agg_op['bias']
    bool_agg_e = agg_op['apply'] 
    bool_agg_r = agg_op['relu'] 
    bool_agg_t = agg_op['reduce_type'] == "sum"

    bool_mm_a = mm_op['accumulation'] 
    bool_mm_b = mm_op['bias']
    bool_mm_r = mm_op['relu']

    N = agg_op['op_input_data']['data_shape'][0]
    C_in = agg_op['op_input_data']['data_shape'][1]
    C_out = mm_op['op_weight']['data_shape'][1]

    assert N == mm_op['op_input_data']['data_shape'][0]
    assert C_in == mm_op['op_input_data']['data_shape'][1]
    assert N == agg_op['op_adj']['data_shape'][0]
    assert N == agg_op['op_adj']['data_shape'][1]

    agg_bias_start_address = 0
    # load agg bias
    if bool_agg_b:
        agg_bias_start_address = bias_dram_byte_address
        _ = bias_combination([-1, -1], os.path.join('../IR_and_data', agg_op['op_bias']['read_data_path']), 
            C_in, '../result/bias.bin', bias_dram_byte_address)
        bias_dram_byte_address += C_in * 4

    # load weight
    this_weight_address = weight_buffer_address
    weight_offset = weight_reorder(wbuffer_size, os.path.join('../IR_and_data', mm_op['op_weight']['read_data_path']), 
        C_in, C_out, '../result/weight.bin', weight_dram_byte_address)
    instructions.append(loadw([100], [5], weight_offset, this_weight_address, \
        weight_offset * wbuffer_size[0], weight_dram_byte_address))
    weight_buffer_address += weight_offset
    weight_dram_byte_address += weight_offset * wbuffer_size[0]

    this_bias_address = 0
    # load bias
    if bool_mm_b:
        this_bias_address = bias_buffer_address
        bias_offset = bias_combination(bbuffer_szie, os.path.join('../IR_and_data', mm_op['op_bias']['read_data_path']), 
            C_out, '../result/bias.bin', bias_dram_byte_address)
        instructions.append(loadb([100], [5], bias_offset, this_bias_address, \
            bias_offset * bbuffer_szie[0], bias_dram_byte_address))
        bias_buffer_address += bias_offset
        bias_dram_byte_address += bias_offset * bbuffer_szie[0]

    # corresponding to columns
    block_in_N = min(((fbuffer_size[0] // 4) * fbuffer_size[1]) // C_in, N) 
    # corrsponding to rows
    # consider if the output of mm excceds the buffer size
    block_out_N = min(((fbuffer_size[0] // 4) * fbuffer_size[1]) // max(C_in, C_out), N)

    # reorder the adjacent matrix
    nnz_list, adj_dram_address_list, dram_offset = adj_reorder(
        os.path.join('input', agg_op['op_adj']['read_data_path']), 
        os.path.join('input', agg_op['op_adj']['read_index_path']), 
        N, agg_op['op_adj']['non_zeros'], os.path.join('../result', 'adj.bin'), 
        block_out_N, block_in_N)
    for ad in adj_dram_address_list:
        ad += adj_dram_byte_address
    adj_dram_byte_address += dram_offset
    
    block_in_num = (N + block_in_N - 1) // block_in_N
    block_out_num = (N + block_out_N - 1) // block_out_N

    loadf_w = []
    loadf_r = []
    agg_w = []
    agg_r = []
    mm_w = []
    mm_r = []
    savef_w = []
    savef_r = []

    # parallel computation
    count = 0
    out_feature_dram_start_address = np.max(input_address) + N * C_in * 4
    output_address.append(out_feature_dram_start_address)
    for i in range(block_out_num):

        in_group_id = i % 2 + 1
        out_group_id = i % 2 + 3

        in_feature_dram_start_address = input_address[-1]
        for j in range(block_in_num):
            in_buffer_depth_offset = (count % 2) * fbuffer_size[1] // 2

            # the (i, j)-th block in adjacent matrix
            nnzs = nnz_list[i * block_in_num + j]
            adj_dram_address = adj_dram_address_list[i * block_in_num + j]

            in_dram_byte = min(block_in_N * C_in * 4, N * C_in * 4 - in_feature_dram_start_address)
            
            if (count < 2 and before_type in [TYPE_FIRST, TYPE_MM_BEFORE]):
                loadf_w = [100]
                loadf_r = [4]
            else:
                loadf_w = [4]
                loadf_r = [4]
            if (count == 0 and dram_type[0] == TYPE_DRAM_BEFORE):
                loadf_w.append(3)
            instructions.append(loadf(loadf_w, loadf_r, 0, in_dram_byte // fbuffer_size[0], \
                in_buffer_depth_offset, in_dram_byte, in_feature_dram_start_address))
            in_feature_dram_start_address += in_dram_byte

            if (i == block_out_num - 1 and j > block_in_num - 3  and after_type in [TYPE_MM_AFTER, TYPE_END]):
                agg_r = [5]
            else:
                agg_r = [2, 5]
            if (count < 2 and before_type in [TYPE_FIRST, TYPE_MM_BEFORE]):
                agg_w = [2]
            else:
                agg_w = [2, 5]
            if (count == 0 and bool_agg_b):
                agg_w.append(1)
            
            instructions.append(agg(agg_w, agg_r, bool_agg_t, bool_agg_b, bool_agg_e, bool_agg_r, in_group_id, 0, C_in // (fbuffer_size[0] // 4), \
                in_buffer_depth_offset, agg_bias_start_address, 0, nnzs, adj_dram_address))

            count += 1
        
        # handle the residue
        out_dram_byte = min(block_out_N * C_out * 4, input_address[-1] + N * (C_in + C_out) * 4 - out_feature_dram_start_address)

        if (i > block_out_num - 3 and after_type in [TYPE_MM_AFTER]):
            mm_r = [2, 3]
        elif (i > block_out_num - 3 and after_type in [TYPE_END]):
            mm_r = [3]
        else:
            mm_r = [3, 4]
        if (i < 2 and before_type in [TYPE_FIRST, TYPE_AGG_BEFORE]):
            mm_w = [4]
        else:
            mm_w = [3, 4]
        if (i == 0):
            mm_w.append(0)
            if bool_mm_b:
                mm_w.append(1)

        instructions.append(mm(mm_w, mm_r, bool_mm_b, bool_mm_a, bool_mm_r, out_group_id, in_group_id, \
            this_bias_address, this_weight_address, C_in // (fbuffer_size[0] // 4), 0, \
            C_out // (fbuffer_size[0] // 4), 0, out_dram_byte // 4 // C_out))

        savef_w = [5]
        if (i > block_out_num - 3 and save_type == TYPE_ACC):
            savef_r = [2, 5]
        elif (i > block_out_num - 3 and after_type in [TYPE_AGG_AFTER, TYPE_END]):
            savef_r = [100]
        else:
            savef_r = [5]
        if (i == block_out_num - 1 and dram_type[1] == TYPE_DRAM_AFTER):
            savef_r.append(2)
        instructions.append(savef(savef_w, savef_r, out_group_id, out_dram_byte // fbuffer_size[0], \
            0, out_dram_byte, out_feature_dram_start_address))
        out_feature_dram_start_address += out_dram_byte

    return instructions, weight_buffer_address, bias_buffer_address, \
        weight_dram_byte_address, bias_dram_byte_address, adj_dram_byte_address, input_address, output_address


def partition(operators: List, fbuffer: List, wbuffer: List, bbuffer: List):
    
    instruction = list()

    # weight and bias
    w_buf_add = 0
    b_buf_add = 0
    w_dram_byte_add = 0
    b_dram_byte_add = 0
    adj_dram_byte_add = 0

    # input and output features
    input_address = [0]
    output_address = []

    # tag the operator type
    before_type = TYPE_FIRST

    # start partition
    for i, operator in enumerate(operators):

        # display
        print("------ operator %d ------" % i)
        if isinstance(operator, Dict):
            print("operator name:", operator['op_name'])
        else:
            print("operator agg name:", operator[0]['op_name'])
            print("operator mm name:", operator[1]['op_name'])

        # find the input feature address
        if i > 0: 
            if isinstance(operator, Dict):
                input_name = operator['op_input_data']['data_name']  
            elif isinstance(operator, Tuple):
                input_name = operator[0]['op_input_data']['data_name']
            else:
                raise NotImplementedError  
            for j in range(i):
                candidate_op = operators[j]
                # either from other operator's input or output
                # it's ok to do either because the dram address is the same
                if isinstance(candidate_op, Tuple):  
                    # for fused operators, only the input of agg and the output of mm are considered
                    if candidate_op[1]['op_output_data']['data_name'] == input_name:
                        input_address.append(output_address[j])
                        # add once
                        break
                    if candidate_op[0]['op_input_data']['data_name'] == input_name:
                        input_address.append(input_address[j])
                        # add once
                        break
                else:
                    if candidate_op['op_output_data']['data_name'] == input_name:
                        input_address.append(output_address[j])
                        # add once
                        break
                    if candidate_op['op_input_data']['data_name'] == input_name:
                        input_address.append(input_address[j])
                        # add once
                        break
        
        print("weight starting address:", w_dram_byte_add)
        print("bias starting address:", b_dram_byte_add)
        print("adj starting address:", adj_dram_byte_add)

        after_type = check_after_type(operators, i)
        save_type = check_save_type(operators, i)
        dram_type = check_dram_type(operators, i)

        if isinstance(operator, Dict):
            if operator['op_type'] == 'agg':

                results = agg_distribute(
                    operator, fbuffer, input_address, output_address, b_dram_byte_add, adj_dram_byte_add, before_type, after_type, dram_type)
                partition_agg = results[0]
                input_address = results[1]
                output_address = results[2] 
                b_dram_byte_add = results[3]
                adj_dram_byte_add = results[4]
                instruction = instruction + partition_agg

                before_type = TYPE_AGG_BEFORE

                print("%d instructions added." % len(partition_agg))

            elif operator['op_type'] == 'mm':

                # if accumulate, the connected operator should be found
                if operator['accumulation'] == True:
                    output_name = operator['op_acc_data']['data_name']
                    # only find the connected operator from before
                    for j in range(i):
                        candidate_op = operators[j]
                        if isinstance(candidate_op, Tuple):
                            if candidate_op[1]['op_output_data']['data_name'] == output_name:
                                assert operator['op_output_data']['data_shape'] == candidate_op[1]['op_output_data']['data_shape']
                                output_address.append(output_address[j])
                                break
                            if candidate_op[0]['op_input_data']['data_name'] == output_name:
                                assert operator['op_output_data']['data_shape'] == candidate_op[0]['op_input_data']['data_shape']
                                output_address.append(input_address[j])
                                break
                        else:
                            if candidate_op['op_output_data']['data_name'] == output_name:
                                assert operator['op_output_data']['data_shape'] == candidate_op['op_output_data']['data_shape']
                                output_address.append(output_address[j])
                                break
                            if candidate_op['op_input_data']['data_name'] == output_name:
                                assert operator['op_output_data']['data_shape'] == candidate_op['op_input_data']['data_shape']
                                output_address.append(input_address[j])
                                break


                results =  mm_distribute(operator, fbuffer, wbuffer, bbuffer, w_buf_add, b_buf_add, \
                    w_dram_byte_add, b_dram_byte_add, input_address, output_address, before_type, after_type, save_type, dram_type)
                partition_mm = results[0]
                w_buf_add = results[1]
                b_buf_add = results[2]
                w_dram_byte_add = results[3]
                b_dram_byte_add = results[4]
                input_address = results[5]
                output_address = results[6]
                instruction = instruction + partition_mm

                before_type = TYPE_MM_BEFORE

                print("%d instructions added." % len(partition_mm))
            else:
                raise NotImplementedError
        
        elif isinstance(operator, Tuple):

            results = fusion_distribute(operator, fbuffer, wbuffer, bbuffer, w_buf_add, b_buf_add, \
                w_dram_byte_add, b_dram_byte_add, adj_dram_byte_add, input_address, output_address, before_type, after_type, save_type, dram_type)
            partition_fusion = results[0] 
            w_buf_add = results[1]
            b_buf_add = results[2]
            w_dram_byte_add = results[3]
            b_dram_byte_add = results[4]
            adj_dram_byte_add = results[5]
            input_address = results[6]
            output_address = results[7]
            instruction = instruction + partition_fusion

            before_type = TYPE_BOTH_BEFORE

            print("%d instructions added." % len(partition_fusion))
        
        else:
            raise NotImplementedError

        print("input feature starting address:", input_address)
        print("output feature starting address:", output_address)
    
    return instruction


if __name__ == '__main__': 

    parser = argparse.ArgumentParser()
    parser.add_argument('--ir-name', type=str, default=None)
    args = parser.parse_args()

    operators = operator_loader('../IR_and_data/' + args.ir_name + '.yaml')
    fusion_operators = fusion_detector(operators)
    # feature buffer size: 64 bytes width and 2048 depth, but only 1024 depth can be expressed as 16bits
    # weight buffer size: 1024 bytes width and 4096 depth
    # bias buffer size: 64 bytes width and 1024 depth
    # fusion_operators = [operators[1]]
    # fusion_operators = [operators[3]]
    # usion_operators = operators
    separate_instructions = partition(fusion_operators, [64, 1024], [1024, 4096], [64, 1024])
    first_op = fusion_operators[0]
    if isinstance(first_op, Tuple):
        first_op = first_op[0]
    input_feature_file = os.path.join('input', first_op['op_input_data']['read_data_path'])
    feature2bin(input_feature_file, '../result/feature.bin')
    
    with open('../result/instructions.bin', "a") as f:
        for ins in separate_instructions:
            for stream in ins:
                f.write(stream)

    print("-----------------")
    
    for ins in separate_instructions:
        print(ins)