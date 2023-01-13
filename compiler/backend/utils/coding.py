import numpy as np
from typing import List

def int2bin(number: int, width: int):
    # code should be width bits binary str
    # TODO: convert integer to binary code
    for i in range(width):
        if number % 2 == 1:
            if i == 0:
                code = '1'
            else:
                code = '1' + code
        else:
            if i == 0:
                code = '0'
            else:
                code = '0' + code
        number = number // 2
    return code


def hotcode(number: List[int], width: int):
    code = ''
    for i in range(width):
        if i in number:
            code = '1' + code
        else:
            code = '0' + code
    return code


def loadw(wait: List[int], release: List[int], 
    buffer_address_length: int, buffer_start_address: int, 
    dram_byte_length: int, dram_start_address: int):

    code1 = '0' * 32
    code2 = '0' * 32
    code3 = '0' * 32
    code4 = '0' * 32

    # OpCode
    code_opcode = '1000'
    # wait
    code_wait = hotcode(wait, 6)
    # release 
    code_release = hotcode(release, 6)
    code1 = code_opcode + code_wait + code_release + '0' * 16

    # buffer_address_length
    code_buf_len = int2bin(buffer_address_length, 16)
    # buffer_start_address
    code_buf_add = int2bin(buffer_start_address, 16)
    code2 = code_buf_len + code_buf_add

    # dram_byte_length
    code_dram_len = int2bin(dram_byte_length, 16)
    code3 = code_dram_len + '0' * 16

    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 32)
    code4 = code_dram_add

    return (code4, code3, code2, code1)
    

def loadb(wait: List[int], release: List[int], 
    buffer_address_length: int, buffer_start_address: int, 
    dram_byte_length: int, dram_start_address: int):

    code1 = '0' * 32
    code2 = '0' * 32
    code3 = '0' * 32
    code4 = '0' * 32

    # OpCode
    code_opcode = '1001'
    # wait
    code_wait = hotcode(wait, 6)
    # release 
    code_release = hotcode(release, 6)
    code1 = code_opcode + code_wait + code_release + '0' * 16

    # buffer_address_length
    code_buf_len = int2bin(buffer_address_length, 16)
    # buffer_start_address
    code_buf_add = int2bin(buffer_start_address, 16)
    code2 = code_buf_len + code_buf_add

    # dram_byte_length
    code_dram_len = int2bin(dram_byte_length, 16)
    code3 = code_dram_len + '0' * 16

    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 32)
    code4 = code_dram_add

    return (code4, code3, code2, code1)


def loadf(wait: List[int], release: List[int], group: int,
    buffer_address_length: int, buffer_start_address: int, 
    dram_byte_length: int, dram_start_address: int):
    
    code1 = '0' * 32
    code2 = '0' * 32
    code3 = '0' * 32
    code4 = '0' * 32

    # OpCode
    code_opcode = '1010'
    # wait
    code_wait = hotcode(wait, 6)
    # release 
    code_release = hotcode(release, 6)
    # group
    code_group = hotcode([group], 6)
    code1 = code_opcode + code_wait + code_release + '0' * 10 + code_group

   # buffer_address_length
    code_buf_len = int2bin(buffer_address_length, 16)
    # buffer_start_address
    code_buf_add = int2bin(buffer_start_address, 16)
    code2 = code_buf_len + code_buf_add

    # dram_byte_length
    code_dram_len = int2bin(dram_byte_length, 16)
    code3 = code_dram_len + '0' * 16

    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 32)
    code4 = code_dram_add

    return (code4, code3, code2, code1)


def savef(wait: List[int], release: List[int], group: int,
    buffer_address_length: int, buffer_start_address: int, 
    dram_byte_length: int, dram_start_address: int):

    code1 = '0' * 32
    code2 = '0' * 32
    code3 = '0' * 32
    code4 = '0' * 32

    # OpCode
    code_opcode = '1011'
    # wait
    code_wait = hotcode(wait, 6)
    # release 
    code_release = hotcode(release, 6)
    # group
    code_group = hotcode([group], 6)
    code1 = code_opcode + code_wait + code_release + '0' * 10 + code_group

   # buffer_address_length
    code_buf_len = int2bin(buffer_address_length, 16)
    # buffer_start_address
    code_buf_add = int2bin(buffer_start_address, 16)
    code2 = code_buf_len + code_buf_add

    # dram_byte_length
    code_dram_len = int2bin(dram_byte_length, 16)
    code3 = code_dram_len + '0' * 16

    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 32)
    code4 = code_dram_add

    return (code4, code3, code2, code1)


def agg(wait: List[int], release: List[int], t: bool, b: bool, e: bool, r: bool, out_group: int, in_group: int, 
    address_per_feature: int, input_start_address: int, 
    bias_start_address: int, output_start_address: int, 
    edge_number: int, dram_start_address: int):

    code1 = '0' * 32
    code2 = '0' * 32
    code3 = '0' * 32
    code4 = '0' * 32

    # OpCode
    code_opcode = '1100'
    # wait
    code_wait = hotcode(wait, 6)
    # release 
    code_release = hotcode(release, 6)
    # t
    code_t = '0'
    if t:
        code_t = '1'
    # b
    code_b = '0'
    if b:
        code_b = '1'
    # a
    code_e = '0'
    if e:
        code_e = '1'
    # r:
    code_r = '0'
    if r:
        code_r = '1'
    # output group
    code_out_group = hotcode([out_group], 6)
    # input group
    code_in_group = hotcode([in_group], 6) 
    code1 = code_opcode + code_wait + code_release + code_t + \
        code_b + code_e + code_r + code_out_group + code_in_group

    # buffer_per_feature
    code_add_per_feats = int2bin(address_per_feature, 8)
    # bias_start_address
    bias_add_code = int2bin(bias_start_address, 8)
    # input_start_address
    code_in_add = int2bin(input_start_address, 16)
    code2 = code_add_per_feats + bias_add_code + code_in_add

    # edge number
    code_edge_num = int2bin(edge_number, 16)
    # output_start_address
    code_out_add = int2bin(output_start_address, 16)
    code3 = code_edge_num  + code_out_add

    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 32)
    code4 = code_dram_add

    return (code4, code3, code2, code1)


def mm(wait: List[int], release: List[int], b: bool, a: bool, r: bool, out_group: int, in_group: int, 
    bias_start_address: int, weight_start_address: int, 
    input_address_per_feature: int, input_start_address: int, 
    output_address_per_feature: int, output_start_address: int, node_number: int):
    
    code1 = '0' * 32
    code2 = '0' * 32
    code3 = '0' * 32
    code4 = '0' * 32

   # OpCode
    code_opcode = '1101'
    # wait
    code_wait = hotcode(wait, 6)
    # release 
    code_release = hotcode(release, 6)
    # b
    code_b = '0'
    if b:
        code_b = '1'
    # a
    code_a = '0'
    if a:
        code_a = '1'
    # r:
    code_r = '0'
    if r:
        code_r = '1'
    # output group
    code_out_group = hotcode([out_group], 6)
    # input group
    code_in_group = hotcode([in_group], 6) 
    code1 = code_opcode + code_wait + code_release + '0' + code_b + \
        code_a + code_r + code_out_group + code_in_group
    
    # bias_start_address
    code_bias_add = int2bin(bias_start_address, 16)
    # weight_start_address
    code_weight_add = int2bin(weight_start_address, 16)
    code2 = code_bias_add + code_weight_add

    # input_address_per_feature
    code_in_add_per_feats = int2bin(input_address_per_feature, 8)
    # output_address_per_featurer
    code_out_add_per_feats = int2bin(output_address_per_feature, 8)
    # input_start_address
    code_in_add = int2bin(input_start_address, 16)
    code3 = code_in_add_per_feats + code_out_add_per_feats + code_in_add

    # node number
    code_node_number = int2bin(node_number, 16)
    # output_start_address
    code_out_add = int2bin(output_start_address, 16)
    code4 = code_node_number + code_out_add

    return (code4, code3, code2, code1)


if __name__ == '__main__': 
    
    # code = int2bin(100, 8)
    # print(code)

    # code = hotcode([2,3,5], 6)
    # print(code)

    # code = loadw([100], [5], 256, 0, 256 * 1024, 0)
    # print(code)

    # code = loadb([100], [5], 8, 0, 8 * 64, 0)
    # print(code)

    # code = loadf([3], [5], 3, 512 * 4, 0, 64 * 512 * 4, 0)
    # print(code)

    # code = savef([5], [5], 3, 512 * 4, 0, 64 * 512 * 4, 0)
    # print(code)

    # code = agg([2, 3], [2, 3], False, True, True, 1, 0, 1, 0, 0, 1237, 0)
    # print(code)

    code = mm([0, 1, 2, 3], [3], True, False, False, 3, 1, 0, 0, 32, 0, 8, 0, 64)
    print(code)
