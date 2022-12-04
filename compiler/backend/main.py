from typing import Dict, Tuple, List
from fusion_recognition import fusion_detector
from operators_loading import operator_loader
from utils.coding import *
from utils.reorder import *

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


def agg_distribute(agg_op: Dict, fbuffer_size: List, 
    input_address: List[int], output_address: List[int]):

    instructions = list()

    N = agg_op['op_input_data']['data_shape'][0]
    C = agg_op['op_input_data']['data_shape'][1]

    assert N == agg_op['op_adj']['data_shape'][0]
    assert N == agg_op['op_adj']['data_shape'][1]

    bool_a = agg_op['apply'] == "true"
    bool_r = agg_op['relu'] == "true"
    bool_t = agg_op['reduce_type'] == "max"

    # corresponding to columns
    block_in_N = ((fbuffer_size[0] // 4) * fbuffer_size[1] // 2) // C  
    # corrsponding to rows
    block_out_N = ((fbuffer_size[0] // 4) * fbuffer_size[1]) // C

    # reorder the adjacent matrix
    nnz_list, adj_dram_address_list = adj_reorder(
        agg_op['op_adj']['read_data_path'], agg_op['op_adj']['read_index_path'], 
        N, agg_op['op_adj']['non_zero'], agg_op['op_name'] + '_adj.bin', block_out_N, block_in_N)
    
    block_in_num = (N + block_in_N - 1) // block_in_N
    block_out_num = (N + block_out_N - 1) // block_out_N

    count = 0
    out_feature_dram_start_address = input_address[-1] + N * C * 4
    output_address.append(out_feature_dram_start_address)
    for i in range(block_out_num):

        in_feature_dram_start_address = input_address[-1]
        for j in range(block_in_num):
            in_buffer_depth_offset = (count % 2) * fbuffer_size[1] // 2

            # the (i, j)-th block in adjacent matrix
            nnzs = nnz_list[i * block_in_num + j]
            adj_dram_address = adj_dram_address_list[i * block_in_num + j]

            in_dram_byte = min(block_in_N * C * 4, N * C * 4 - in_feature_dram_start_address)
            
            # loadf, W: agg; R: agg
            instructions.append(loadf([4], [4], 0, in_dram_byte // fbuffer_size[0], \
                in_buffer_depth_offset, in_dram_byte, in_feature_dram_start_address))
            in_feature_dram_start_address += in_dram_byte

            # agg, W: loadf, savef; R: loadf, savef
            instructions.append(agg([2, 3], [2, 3], bool_a, bool_r, 1, 0, C // (fbuffer_size[0] // 4), \
                in_buffer_depth_offset, bool_t, 0, nnzs, adj_dram_address))

            count += 1
        
        # savef
        # handle the residue
        out_dram_byte = min(block_out_N * C * 4, N * C * 2 * 4 - out_feature_dram_start_address)
        # savef, W: agg; R: agg
        instructions.append(savef([4], [4], 1, out_dram_byte // fbuffer_size[0], \
            0, out_dram_byte, out_feature_dram_start_address))
        out_feature_dram_start_address += out_dram_byte

    return instructions, input_address, output_address


def mm_distribute(mm_op: Dict, fbuffer_size: List, wbuffer_size: List, bbuffer_szie: List, 
    weight_address: int, bias_address: int, weight_bias_dram_byte_address: int, 
    input_address: List[int], output_address: List[int]):

    instructions = list()

    bool_a = mm_op['accumulation'] == "true"
    bool_b = mm_op['bias'] == "true"
    bool_r = mm_op['relu'] == "true"

    N = mm_op['op_input_data']['data_shape'][0]
    C_in = mm_op['op_input_data']['data_shape'][1]
    C_out = mm_op['op_weight']['data_shape'][1]

    assert C_in == mm_op['op_weight']['data_shape'][0]

    # load w
    this_weight_address = weight_address
    weight_offset = weight_reorder(wbuffer_size, mm_op['op_weight']['read_data_path'], C_in, C_out, 
        'weight_bias_combined.bin', weight_bias_dram_byte_address)
    instructions.append(loadw([100], [5], weight_offset, weight_address, \
        weight_offset * wbuffer_size[0], weight_bias_dram_byte_address))
    weight_address += weight_offset
    weight_bias_dram_byte_address += weight_offset * wbuffer_size[0]

    # load b
    if mm_op['bias'] == "true":
        this_bias_address = bias_address
        bias_offset = bias_combination(bbuffer_szie, mm_op['op_bias']['read_data_path'], C_out, 
            'weight_bias_combined.bin', weight_bias_dram_byte_address)
        instructions.append(loadb([100], [5], bias_offset, bias_address, \
            bias_offset * bbuffer_szie[0], weight_bias_dram_byte_address))
        bias_address += bias_offset
        weight_bias_dram_byte_address += bias_offset * bbuffer_szie[0]

    # load - mm - save
    block_N = ((fbuffer_size[0] // 4) * fbuffer_size[1]) // max(C_in, C_out)
    block_num = (N + block_N - 1) // block_N
    # decide the dram address of input and output features
    in_feature_dram_start_address = input_address[-1]
    out_feature_dram_start_address = in_feature_dram_start_address + N * C_in * 4
    if bool_a:
        out_feature_dram_start_address = output_address[-1]
    else: 
        output_address.append(out_feature_dram_start_address)
    
    for i in range(block_num):
        # buffer order
        in_group_id = i % 2 + 1
        out_group_id = i % 2 + 3
        # handle the residue
        in_dram_byte = min(block_N * C_in * 4, N * C_in * 4 - in_feature_dram_start_address)
        out_dram_byte = min(block_N * C_out * 4, N * (C_in + C_out) * 4 - out_feature_dram_start_address)

        loadz_W = [3]
        loadz_R = [5]
        loadf_W = [5]
        loadf_R = [5]
        mm_W = [0, 1, 2, 3]
        mm_R = [2, 3]
        savef_W = [5]
        savef_R = [5]
        if i < 3:
            loadz_W = [100]
            loadf_W = [100]
            mm_W = [0, 1, 2]
            mm_R = [3]
            if i < 2:
                savef_R = [100]

        if bool_a:
            # load the output first if accumulate
            instructions.append(loadf(loadz_W, loadz_R, out_group_id, out_dram_byte // fbuffer_size[0], \
                0, out_dram_byte, out_feature_dram_start_address))
        
        # does the first load wait for any instruction ? 
        # loadf, W: mm; R: mm
        # from the 3rd,...
        
        instructions.append(loadf(loadf_W, loadf_R, in_group_id, in_dram_byte // fbuffer_size[0], \
                0, in_dram_byte, in_feature_dram_start_address))
        in_feature_dram_start_address += in_dram_byte

        # mm, W: loadw, loadb, loadf, savef; R: loadf, savef
        instructions.append(mm(mm_W, mm_R, bool_b, bool_a, bool_r, out_group_id, in_group_id, \
            this_bias_address, this_weight_address, C_in // (fbuffer_size[0] // 4), 0, \
                C_out // (fbuffer_size[0] // 4), 0))
    
        # savef, W: mm; R: mm
        instructions.append(savef(savef_W, savef_R, out_group_id, out_dram_byte // fbuffer_size[0], \
            0, out_dram_byte, out_feature_dram_start_address))
        out_feature_dram_start_address += out_dram_byte
    
    return instructions, weight_address, bias_address, weight_bias_dram_byte_address, input_address, output_address
        

def fusion_distribute(agg_mm_op: Tuple[Dict], fbuffer_size: List, wbuffer_size: List, bbuffer_szie: List, 
    weight_address: int, bias_address: int, weight_bias_dram_byte_address: int, 
    input_address: List[int], output_address: List[int]):

    instructions = list()

    agg_op = agg_mm_op[0]
    mm_op = agg_mm_op[1]

    bool_agg_a = agg_op['apply'] == "true"
    bool_agg_r = agg_op['relu'] == "true"
    bool_agg_t = agg_op['reduce_type'] == "max"

    bool_mm_a = mm_op['accumulation'] == "true"
    bool_mm_b = mm_op['bias'] == "true"
    bool_mm_r = mm_op['relu'] == "true"

    # load weight
    this_weight_address = weight_address
    weight_offset = weight_reorder(wbuffer_size, mm_op['op_weight']['read_data_path'], C_in, C_out, 
        'weight_bias_combined.bin', weight_bias_dram_byte_address)

    instructions.append(loadw([0], [5], weight_offset, weight_address, \
        weight_offset * wbuffer_size[0], weight_bias_dram_byte_address))
    weight_address += weight_offset
    weight_bias_dram_byte_address += weight_offset * wbuffer_size[0]

    # load bias
    if mm_op['bias'] == "true":
        this_bias_address = bias_address
        bias_offset = bias_combination(bbuffer_szie, mm_op['op_bias']['read_data_path'], C_out, 
            'weight_bias_combined.bin', weight_bias_dram_byte_address)
        instructions.append(loadb([1], [5], bias_offset, bias_address, \
            bias_offset * bbuffer_szie[0], weight_bias_dram_byte_address))
        bias_address += bias_offset
        weight_bias_dram_byte_address += bias_offset * bbuffer_szie[0]


    N = agg_op['op_input_data']['data_shape'][0]
    C_in = agg_op['op_input_data']['data_shape'][1]
    C_out = mm_op['op_weight']['data_shape'][1]

    assert N == mm_op['op_input_data']['data_shape'][0]
    assert C_in == mm_op['op_input_data']['data_shape'][1]
    assert N == agg_op['op_adj']['data_shape'][0]
    assert N == agg_op['op_adj']['data_shape'][1]

    # corresponding to columns
    block_in_N = ((fbuffer_size[0] // 4) * fbuffer_size[1] // 2) // C_in  
    # corrsponding to rows
    # consider if the output of mm excceds the buffer size
    block_out_N = ((fbuffer_size[0] // 4) * fbuffer_size[1]) // max(C_in, C_out)

    # reorder the adjacent matrix
    nnz_list, adj_dram_address_list = adj_reorder(
        agg_op['op_adj']['read_data_path'], agg_op['op_adj']['read_index_path'], 
        N, agg_op['op_adj']['non_zero'], agg_op['op_name'] + '_adj.bin', block_out_N, block_in_N)

    block_in_num = (N + block_in_N - 1) // block_in_N
    block_out_num = (N + block_out_N - 1) // block_out_N

    # parallel computation
    count = 0
    out_feature_dram_start_address = input_address[-1] + N * C_in * 4
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
            
            # loadf, W: agg; R: agg
            instructions.append(loadf([4], [4], 0, in_dram_byte // fbuffer_size[0], \
                in_buffer_depth_offset, in_dram_byte, in_feature_dram_start_address))
            in_feature_dram_start_address += in_dram_byte

            # agg, W: loadf, mm; R: loadf, mm
            instructions.append(agg([2, 5], [2, 5], bool_agg_a, bool_agg_r, in_group_id, 0, C_in // (fbuffer_size[0] // 4), \
                in_buffer_depth_offset, bool_agg_t, 0, nnzs, adj_dram_address))

            count += 1
        
        # 1 load w load b
        # mm, W: load w, load b, savef, agg; R: savef
        instructions.append(mm([0, 1, 3, 4], [3], bool_mm_b, bool_mm_a, bool_mm_r, out_group_id, in_group_id, \
            this_bias_address, this_weight_address, C_in // (fbuffer_size[0] // 4), 0, \
                C_out // (fbuffer_size[0] // 4), 0))

        # savef
        # handle the residue
        out_dram_byte = min(block_out_N * C_out * 4, N * (C_in + C_out) * 4 - out_feature_dram_start_address)
        # savef, W: mm; R: loadf, agg, mm
        instructions.append(savef([5], [2, 4, 5], 1, out_dram_byte // fbuffer_size[0], \
            0, out_dram_byte, out_feature_dram_start_address))
        out_feature_dram_start_address += out_dram_byte

    return instructions, weight_address, bias_address, weight_bias_dram_byte_address, input_address, output_address


def partition(operators: List, fbuffer: List, wbuffer: List, bbuffer: List):
    
    instruction = list()

    # weight and bias
    w_add = 0
    b_add = 0
    w_b_dram_byte_add = 0

    # input and output features
    input_address = [0]
    output_address = []

    # start partition
    for i, operator in enumerate(operators):
        # find the input feature address
        if i > 0: 
            input_name = operator['op_input_data']['data_name']      
            for j in range(i):
                if operators[j]['op_output_data']['data_name'] == input_name:
                    assert operator['op_input_data']['data_shape'] == operators[j]['op_output_data']['data_shape']
                    input_address.append(output_address[j])

        if isinstance(operator, Dict):
            if operator['op_type'] == 'agg':
                partition_agg, input_address, output_address = agg_distribute(operator, fbuffer, input_address, output_address)
                instruction = instruction + partition_agg
            elif operator['op_type'] == 'mm':
                # if accumulate, the connected operator should be found
                if operator['accumulation'] == True:
                    output_name = operator['op_output_data']['data_name']
                    # find the connected operator from before ?
                    for j in range(i):
                        if operators[j]['op_output_data']['data_name'] == output_name:
                            assert operator['op_output_data']['data_shape'] == operators[j]['op_output_data']['data_shape']
                            output_address.append(output_address[j])
                partition_mm, w_add, b_add, w_b_dram_byte_add, input_address, output_address = mm_distribute(operator, 
                    fbuffer, wbuffer, bbuffer, w_add, b_add, w_b_dram_byte_add, input_address, output_address)
                instruction = instruction + partition_mm
            else:
                raise NotImplementedError
        
        elif isinstance(operator, Tuple):
            partition_fusion, w_add, b_add, w_b_dram_byte_add, input_address, output_address = fusion_distribute(operator, 
                    fbuffer, wbuffer, bbuffer, w_add, b_add, w_b_dram_byte_add, input_address, output_address)
            instruction = instruction + partition_fusion
        
        else:
            raise NotImplementedError


if __name__ == '__main__': 
    operators = operator_loader('ir_example_pubmed_gcn_2_128.yaml')
    fusion_operators = fusion_detector(operators)
    # feature buffer size: 64 bytes width and 2048 depth
    # weight buffer size: 1024 bytes width and 4096 depth
    # bias buffer size: 64 bytes width and 1024 depth
    # separate_instructions = partition(fusion_operators, [64, 2048], [1024, 4096], [64, 1024])

    

    