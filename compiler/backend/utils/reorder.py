import numpy as np
from typing import List

# TODO: @fty - 4 data processing functions

'''input:
        wbuffer: the weight buffer size [width(bytes), depth]
        file: a single weight data path
        C_in: input channel
        C_out: output channel
        dst_file: a combined saving path for all weights and bias
        dram_address: the starting address of the weight after reordering, in bytes
    TODO:
        1. offset = the depth that the weight occupies in buffer, in depth
        2. save the weight into dst_file (.bin) in the unit of 16x16 blocks (input-channel-first)
    output:
        offset: int
'''
def weight_reorder(wbuffer: List[int], file: str, C_in: int, C_out: int, dst_file: str, dram_address: int):
    
    offset = 0
    
    return offset


'''input:
        bbuffer: the bias buffer size [width(bytes), depth]
        file: a single bias data path
        C_out: output channel
        dst_file: a combined saving path for all weights and bias
        dram_address: the starting address of the bias after reordering, in bytes
    TODO:
        1. offset = the depth that the bias occupies in buffer, in depth
        2. save the bias into dst_file (.bin)
    output:
        offset: int
'''
def bias_combination(bbuffer: List[int], file: str, C_out: int, dst_file: str, dram_address: int):
    
    offset = 0
    
    return offset


'''input:
        data_file: adjacent matrix data (value) read path
        index_file: adjacent matrix index (row + column) read path
        nodes: the amount of nodes
        edges: the amount of edges
        dst_file: destination adjacent matrix saving path 
        row_N: the number of rows in one block
        col_N: the number of columns in one block
    TODO:
        1. read the COO format adjacent matrix from data_file and index_file
        2. separate the adjacent matrix into dense blocks of shape (row_N, col_N)
        3. check if the nnzs in one row are at least 4 columns away from each other, 
           and pad zeros to satisfy the condition
        4. save the blocks in order into dst_file in COO format, fp32 for values, 
           16 bits for rows and 16 bits for columns (the row msb indicates if the nnz
           is the first in the row and the column msb indicates if the nnz is the last
           in the matrix, and the other 15 bits indicate the row/column index in the block)
    output: 
        nnzs: List, how many nnzs in each block 
        adj_dram_address: List, the start address of each block after reordering, in bytes
'''
def adj_reorder(data_file: str, index_file: str, 
    nodes: int, edges: int, dst_file: str, row_N: int, col_N: int):
    
    nnzs = list()
    adj_dram_address = list()

    return nnzs, adj_dram_address


def feature2bin(data_file: str, bin_file: str):

    # TODO: save .npy(FP32) to .bin
    
    return None