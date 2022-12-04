import numpy as np
from typing import List

def int2bin(number: int, width: int):
    # code should be width bits binary str
    code = '0' * width
    # TODO: convert integer to binary code
    return code


def hotcode(number: List[int], width: int):
    code = ''
    for i in range(width):
        if i in number:
            code = code + '1'
        else:
            code = code + '0'
    return code


def loadw(wait: List[int], release: List[int], 
    buffer_address_length: int, buffer_start_address: int, 
    dram_byte_length: int, dram_start_address: int):

    code1 = ['0' * 32]
    code2 = ['0' * 32]
    code3 = ['0' * 32]
    code4 = ['0' * 32]

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
    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 16)
    code3 = code_dram_len + code_dram_add

    return (code1, code2, code3, code4)
    

def loadb(wait: List[int], release: List[int], 
    buffer_address_length: int, buffer_start_address: int, 
    dram_byte_length: int, dram_start_address: int):

    code1 = ['0' * 32]
    code2 = ['0' * 32]
    code3 = ['0' * 32]
    code4 = ['0' * 32]

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
    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 16)
    code3 = code_dram_len + code_dram_add

    return (code1, code2, code3, code4)


def loadf(wait: List[int], release: List[int], group: int,
    buffer_address_length: int, buffer_start_address: int, 
    dram_byte_length: int, dram_start_address: int):
    
    code1 = ['0' * 32]
    code2 = ['0' * 32]
    code3 = ['0' * 32]
    code4 = ['0' * 32]

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
    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 16)
    code3 = code_dram_len + code_dram_add

    return (code1, code2, code3, code4)


def savef(wait: List[int], release: List[int], group: int,
    buffer_address_length: int, buffer_start_address: int, 
    dram_byte_length: int, dram_start_address: int):

    code1 = ['0' * 32]
    code2 = ['0' * 32]
    code3 = ['0' * 32]
    code4 = ['0' * 32]

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
    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 16)
    code3 = code_dram_len + code_dram_add

    return (code1, code2, code3, code4)


def agg(wait: List[int], release: List[int], a: bool, r: bool, out_group: int, in_group: int, 
    address_per_feature: int, input_start_address: int, 
    reduce_type: bool, output_start_address: int, 
    edge_number: int, dram_start_address: int):

    code1 = ['0' * 32]
    code2 = ['0' * 32]
    code3 = ['0' * 32]
    code4 = ['0' * 32]

    # OpCode
    code_opcode = '1100'
    # wait
    code_wait = hotcode(wait, 6)
    # release 
    code_release = hotcode(release, 6)
    # a
    if a:
        code_a = '1'
    # r:
    if r:
        code_r = '1'
    # output group
    code_out_group = hotcode([out_group], 6)
    # input group
    code_in_group = hotcode([in_group], 6) 
    code1 = code_opcode + code_wait + code_release + '0' * 2 + \
        code_a + code_r + code_out_group + code_in_group

    # buffer_per_feature
    code_add_per_feats = int2bin(address_per_feature, 16)
    # input_start_address
    code_in_add = int2bin(input_start_address, 16)
    code2 = code_add_per_feats + code_in_add

    # reduce type
    code_reduce_type = int2bin(reduce_type, 4)
    # output_start_address
    code_out_add = int2bin(output_start_address, 16)
    code3 = '0' * 12 + code_reduce_type + code_out_group

    # edge number
    code_edge_num = int2bin(edge_number, 16)
    # dram_start_address
    code_dram_add = int2bin(dram_start_address, 16)
    code4 = code_edge_num + code_dram_add

    return (code1, code2, code3, code4)


# TODO: @hk change into the latest version
def mm(wait: List[int], release: List[int], b: bool, a: bool, r: bool, out_group: int, in_group: int, 
    bias_start_address: int, weight_start_address: int, 
    input_address_per_feature: int, input_start_address: int, 
    output_address_per_feature: int, output_start_address: int):
    
    code1 = ['0' * 32]
    code2 = ['0' * 32]
    code3 = ['0' * 32]
    code4 = ['0' * 32]

   # OpCode
    code_opcode = '1101'
    # wait
    code_wait = hotcode(wait, 6)
    # release 
    code_release = hotcode(release, 6)
    # b
    if b:
        code_b = '1'
    # a
    if a:
        code_a = '1'
    # r:
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
    code_in_add_per_feats = int2bin(input_address_per_feature, 16)
    # input_start_address
    code_in_add = int2bin(input_start_address, 16)
    code3 = code_in_add_per_feats + code_in_add

    # output_address_per_featurer
    code_out_add_per_feats = int2bin(output_address_per_feature, 16)
    # output_start_address
    code_out_add = int2bin(output_start_address, 16)
    code4 = code_out_add_per_feats + code_out_add

    return (code1, code2, code3, code4)
