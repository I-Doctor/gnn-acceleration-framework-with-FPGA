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
    weight: np.ndarray = np.load(file)

    # bias size / buffer size
    depth = weight.reshape(-1).shape[0] // (wbuffer[0]//4)

    # split bias into blocks
    block_size = (16,16)
    weights = reshaped_2d_matrix(weight, block_size[0], block_size[1])

    # reshape the blocks into 1D array
    reshaped_weights = np.array([])
    weights = weights.swapaxes(0,1)
    weights = weights.swapaxes(2,3)
    for col_block in weights:
        for row_block in col_block:
            row_block.reshape(-1)
            reshaped_weights = np.append(reshaped_weights, row_block)
    
    return depth


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
    # TODO: C_out channel and dram_address not used for now

    bias: np.ndarray = np.load(file)

    # bias size / buffer size
    depth = bias.reshape(-1).shape[0] // (bbuffer[0]//4)

    # partition bias into 16*16 blocks
    bias = bias.reshape(-1)

    # add the bias to the end of the dst_file
    with open(dst_file, "ab") as f:
        bias.tofile(f)
    
    return depth


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
    feature: np.ndarray = np.load(data_file)
    # convert feature array to one dimension fp32 binary file
    feature.reshape(-1).astype(np.float32).tofile(bin_file)
    # np.from_file(bin_file, dtype=np.float32).reshape(feature.shape)

    return None

def reshaped_2d_matrix(arr, nrows, ncols):
    """
    Return an array of shape (n, nrows, ncols) where
    n * nrows * ncols = arr.size

    If arr is a 2D array, the returned array should look like n subblocks with
    each subblock preserving the "physical" layout of arr.
    """
    h, w = arr.shape
    assert h % nrows == 0, f"{h} rows is not evenly divisible by {nrows}"
    assert w % ncols == 0, f"{w} cols is not evenly divisible by {ncols}"
    return (arr.reshape(h//nrows, nrows, -1, ncols)
               .swapaxes(1,2)
               .reshape(h//nrows, w//ncols, nrows, ncols))