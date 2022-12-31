import numpy as np
from typing import List
from collections import defaultdict

# TODO: @fty - 4 data processing functions

def weight_reorder(wbuffer: List[int], file: str, C_in: int, C_out: int, dst_file: str, dram_address: int):
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

    # add the weight to the end of the dst_file
    with open(dst_file, "ab") as f:
        reshaped_weights.astype(np.float32).tofile(f)
    
    return depth

def bias_combination(bbuffer: List[int], file: str, C_out: int, dst_file: str, dram_address: int):
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
    # TODO: C_out channel and dram_address not used for now

    bias: np.ndarray = np.load(file)

    # bias size / buffer size
    depth = bias.reshape(-1).shape[0] // (bbuffer[0]//4)

    # partition bias into 16*16 blocks
    bias = bias.reshape(-1)

    # add the bias to the end of the dst_file
    with open(dst_file, "ab") as f:
        bias.astype(np.float32).tofile(f)
    
    return depth

def adj_reorder(data_file: str, index_file: str, 
    nodes: int, edges: int, dst_file: str, row_N: int, col_N: int):
    '''input:
        data_file: adjacent matrix data (value) read path
        index_file: adjacent matrix index (row + column) read path
        nodes: the number of nodes
        edges: the number of edges
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
    minimun_col_interval = 4
    
    # read value array and index array
    value_array: np.ndarray = np.load(data_file).reshape(1,-1)
    index_array: np.ndarray = np.load(index_file).reshape(2,-1)
    coo_array = np.concatenate((index_array, value_array), axis=0)

    # convert coo format to 2D numpy array
    adj_matrix = COO2Matrix(coo_array, nodes)

    # partition the matrix into blocks
    block_size = (row_N, col_N)
    blocks = reshaped_2d_matrix(adj_matrix, block_size[0], block_size[1])

    # reorder the blocks
    nnzs = list()
    coo_blocks = list()
    for block_rows in blocks:
        for block in block_rows:
            # reorder the block
            coo_block = Matrix2COO(block)
            coo_block = COOInterleave(coo_block, block_size[0], minimun_col_interval)
            coo_blocks.append(coo_block)
            # count nnzs
            nnz = coo_block.shape[1]
            nnzs.append(nnz)
            assert nnz < 2**16

    coo_custom_blocks = list()
    for coo_block in coo_blocks:
        order = np.lexsort((coo_block[1],coo_block[0]))
        coo_standard = coo_block[:,order]
        coo_custom = [CustomCOOElement(coo_element) for coo_element in coo_standard.T]
        # set first_in_row and last_in_row
        last_r = -1
        for i in range(len(coo_custom)):
            this_r = coo_custom[i].row
            if this_r != last_r:
                coo_custom[i].first_in_row = True
                if i > 0:
                    coo_custom[i-1].last_in_row = True
            last_r = this_r
        coo_custom[-1].last_in_row = True
        coo_custom = [coo_custom[i] for i in np.argsort(order)]
        coo_custom_blocks.append(coo_custom)

    adj_dram_address = list()
    current_dram_address = 0
    for coo_block in coo_custom_blocks:
        adj_dram_address.append(current_dram_address)
        current_dram_address += len(coo_block) * 8

    # save the reordered blocks into dst_file
    for coo_block in coo_custom_blocks:
        for coo_element in coo_block:
            coo_element.tofile(dst_file)

    return nnzs, adj_dram_address

class CustomCOOElement:
    # 8 bytes per element
    def __init__(self, row, col, data):
        self.row = row
        self.col = col
        self.data = data
        self.first_in_row: bool = False
        self.last_in_row: bool = False
    
    def __init__(self, coo_element):
        self.row: int = int(coo_element[0])
        self.col: int = int(coo_element[1])
        self.data: float = float(coo_element[2])
        self.first_in_row: bool = False
        self.last_in_row: bool = False

    def tofile(self, file: str):
        with open(file, "ab") as f:
            row = np.uint16(self.row)
            if self.first_in_row:
                # set the highest bit to 1
                row = row | 0x8000
            col = np.uint16(self.col)
            if self.last_in_row:
                # set the highest bit to 1
                col = col | 0x8000
            np.array([row, col], dtype=np.uint16).tofile(f)
            np.array([self.data], dtype=np.float32).tofile(f)

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

def COO2Matrix(coo: np.ndarray, nodes: int):
    '''input:
        coo: a coo format adjacent matrix
        nodes: the number of nodes
    output:
        adj_matrix: a 2D numpy array
    '''
    adj_matrix = np.zeros((nodes, nodes))
    for i in range(coo.shape[1]):
        adj_matrix[int(coo[0][i])][int(coo[1][i])] = coo[2][i]
    return adj_matrix

def Matrix2COO(adj_matrix: np.ndarray):
    '''input:
        adj_matrix: a 2D numpy array
    output:
        coo: a coo format adjacent matrix
    '''
    coo = np.zeros((0,3))
    for r in range(adj_matrix.shape[0]):
        for c in range(adj_matrix.shape[1]):
            if adj_matrix[r][c] != 0:
                coo = np.append(coo, np.array([[r, c, adj_matrix[r][c]]]), axis=0)
    return coo.T
    
def COOInterleave(coo: np.ndarray, nodes, minimun_col_interval: int):
    '''input:
        coo: a coo format adjacent matrix
        minimun_col_interval: the minimun number of colums between two nnzs in one row
    output:
        interleave_coo: a COO format adjacent matrix
    '''
    # sort the coo array by row index, column index
    coo = coo[:,np.lexsort((coo[1],coo[0]))]


    # find the col and row with zero value    
    zero_index = np.zeros((0,2))
    this_r, this_c = coo[0,0], coo[1,0]
    this = 0
    for this_r in range(nodes):
        for c in range(nodes):
            if this_r == this_r and c == this_c:
                this += 1
                try:
                    this_r, this_c = coo[0,this], coo[1,this]
                except:
                    this_r, this_c = nodes, nodes
                continue
            else:
                zero_index = np.append(zero_index, np.array([[this_r,c]]), axis=0)

    # make each row a queue
    row_queue = {r:[] for r in np.unique(coo[0])}
    # iterate through each column in coo
    for i in range(coo.shape[1]):
        row_queue[coo[0][i]].append((coo[1,i], coo[2,i])) # (col, value)

    interleave_coo = np.zeros((0,3))
    # add the first element of each row queue and calculate the interval requirement
    row_interval_requirement = dict()
    for this_r in row_queue.keys():
        # update the requirements of all rows by minus 1
        for r in row_interval_requirement.keys():
            row_interval_requirement[r] -= 1
        # update the requirement of this row
        if len(row_queue[this_r]) > 1:
            row_interval_requirement[this_r] = minimun_col_interval
        else:
            # row_interval_requirement[this_r] = 0
            pass

        interleave_coo = np.append(interleave_coo, np.array([[this_r, row_queue[this_r][0][0], row_queue[this_r][0][1]]]), axis=0)
        row_queue[this_r].pop(0)
    
    # if the row queue is empty, remove it
    rows = list(row_queue.keys())
    for this_r in rows:
        if len(row_queue[this_r]) == 0:
            row_queue.pop(this_r)
            continue

    # loop until all the queues are empty
    add_zero_num = 0
    while len(row_queue) > 0:
        # choose the most acceptable row with the smallest requirement
        this_r = min(row_interval_requirement, key=row_interval_requirement.get)
        if row_interval_requirement[this_r] <= 0:
            # acceptable interval
            # update the requirements of all rows by minus 1
            for r in row_interval_requirement.keys():
                row_interval_requirement[r] -= 1
            # update the requirement of this row
            if len(row_queue[this_r]) > 1:
                row_interval_requirement[this_r] = minimun_col_interval
            else:
                row_interval_requirement[this_r] = 0
            # add to coo
            interleave_coo = np.append(interleave_coo, np.array([[this_r, row_queue[this_r][0][0], row_queue[this_r][0][1]]]), axis=0)
            row_queue[this_r].pop(0)
            # if the row queue is empty, remove it
            if len(row_queue[this_r]) == 0:
                row_queue.pop(this_r)
                row_interval_requirement.pop(this_r)
        else:
            # not acceptable interval, add dummy indecies with zero index
            for i in range(row_interval_requirement[this_r]):
                row, col = zero_index[add_zero_num]
                interleave_coo = np.append(interleave_coo, np.array([[row, col, 0.0]]), axis=0)
                add_zero_num += 1
            # update the requirements of all rows by minus dummy indecies
            for this_r in row_interval_requirement.keys():
                row_interval_requirement[this_r] -= row_interval_requirement[this_r]
    
    return interleave_coo.T

def MatrixInterleave(matrix: np.ndarray, minimun_col_interval: int):
    '''input:
        matrix: a 2D numpy array
        minimun_col_interval: the minimun number of colums between two nnzs in one row
    output:
        interleave_matrix: a COO format adjacent matrix
    '''
    interleave_matrix = np.zeros((0,3))
    for c in range(matrix.shape[1]):
        for r in range(matrix.shape[0]):
            last_col = -minimun_col_interval
            if matrix[r][c] != 0:
                if c - last_col > minimun_col_interval:
                    interleave_matrix = np.append(interleave_matrix, np.array([[r, c, matrix[r][c]]]), axis=0)
                    last_col = c
                else:
                    # add zero to fillin coo
                    for i in range(minimun_col_interval-(c-last_col)):
                        interleave_matrix = np.append(interleave_matrix, np.array([[r, last_col, 0]]), axis=0)
                interleave_matrix = np.append(interleave_matrix, np.array([[r, c, matrix[r][c]]]), axis=0)
    raise NotImplementedError
