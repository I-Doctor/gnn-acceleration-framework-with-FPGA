import numpy as np
from typing import List
from collections import deque
from tqdm import tqdm
import io

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
    coo_array = np.concatenate((index_array, value_array), axis=0) # shape: (3, edges)

    # convert coo format to 2D numpy array
    # calculate the number of rows and columns so that the matrix can be divided by row_N and col_N
    size_x = int((np.ceil((1.0*nodes)/row_N)*row_N))
    size_y = int((np.ceil((1.0*nodes)/col_N)*col_N))
    size_xy = max(size_x, size_y)
    adj_matrix = COO2Matrix(coo_array, size_xy, size_xy)

    # partition the matrix into blocks
    block_size = (row_N, col_N)
    blocks = reshaped_2d_matrix(adj_matrix, block_size[0], block_size[1]) # shape: (block_row, block_col, row_in_block, col_in_block)

    # reorder each block
    nnzs = list()
    coo_blocks = list()
    block_row_offset = []
    block_col_offset = []
    for row_block, block_rows in enumerate(tqdm(blocks)):
        for col_block, block in enumerate(block_rows):
            # reorder the block
            coo_block = Matrix2COO(block)
            coo_block = COOInterleave(coo_block, block_size[0], minimun_col_interval)
            coo_blocks.append(coo_block)
            # record offset of the block
            row_offset = row_block * block_size[0]
            col_offset = col_block * block_size[1]
            block_row_offset.append(row_offset)
            block_col_offset.append(col_offset)
            # count nnzs
            length = coo_block.shape[1]
            nnzs.append(length)
            assert length < 2**16

    # set first_in_row and last_in_row for the whole adjacent matrix
    coo_custom_all = list()
    for coo_block, row_offset, col_offset in zip(coo_blocks, block_row_offset, block_col_offset):
        coo_custom = [CustomCOOElement(coo_element) for coo_element in coo_block.T] # shape: (nnz, ), each element is a CustomCOOElement with row, col, value, and first_in_row and last_in_row flags
        for coo_element in coo_custom:
            coo_element.row_with_offset = row_offset + coo_element.row
            coo_element.col_with_offset = col_offset + coo_element.col
        coo_custom_all.extend(coo_custom)
    
    # sort the whole adjacent matrix by row and column
    order = np.lexsort((np.array([coo_element.col_with_offset for coo_element in coo_custom_all]), np.array([coo_element.row_with_offset for coo_element in coo_custom_all])))
    coo_custom_sorted = [coo_custom_all[i] for i in order]

    # if the number of edges in coo_custom_all is not a multiple of 8, pad zeros-value edges
    pad_zero = (8 - len(coo_custom_sorted)%8)%8
    for i in range(len(coo_custom_sorted)-nnzs[-1],len(coo_custom_sorted)): # iterate in the last block
        if pad_zero == 0:
            break
        this_r = coo_custom_sorted[i].row_with_offset
        this_c = coo_custom_sorted[i].col_with_offset
        col_offset = coo_custom_sorted[i].col_with_offset - coo_custom_sorted[i].col
        if i >= len(coo_custom_sorted)-1:
            raise ValueError("The number of edges in coo_custom_all is not a multiple of 8, and there is no next element to pad zeros-value edges.")
        next_r = coo_custom_sorted[i+1].row_with_offset
        next_c = coo_custom_sorted[i+1].col_with_offset
        if this_r == next_r and next_c != this_c+1:
            for c in range(this_c+1, next_c):
                coo_custom_all.append(CustomCOOElement((coo_custom_sorted[i].row, c-col_offset, 0.0)))
                pad_zero -= 1
                if pad_zero == 0:
                    break

    # set first_in_row and last_in_row based on weather it is the first or last element of the row for the whole adjacent matrix
    first_element_in_row = {i:None for i in range(nodes)}
    last_element_in_row = {i:None for i in range(nodes)}
    for coo_element in coo_custom_all:
        if first_element_in_row[coo_element.row_with_offset] is None:
            first_element_in_row[coo_element.row_with_offset] = coo_element
        last_element_in_row[coo_element.row_with_offset] = coo_element
    for coo_element in first_element_in_row.values():
        if coo_element is not None:
            coo_element.first_in_row = True
    for coo_element in last_element_in_row.values():
        if coo_element is not None:
            coo_element.last_in_row = True

    # debug purpose, can be deleted, noqa
    index_array = np.array([[e.row_with_offset for e in coo_custom_all],[e.col_with_offset for e in coo_custom_all]], dtype=int)
    value_array = np.array([e.data for e in coo_custom_all], dtype=np.float32)
    flag_array = np.array([[e.first_in_row for e in coo_custom_all], [e.last_in_row for e in coo_custom_all]], dtype=int)

    # save the reordered blocks into dst_file
    for coo_element in tqdm(coo_custom_all):
        with open(dst_file, 'ab') as file:
            coo_element.tofile(file)

    # devide the coo_custom_all into coo_blocks
    coo_blocks = list()
    start = 0
    for length in nnzs:
        coo_blocks.append(coo_custom_all[start:start+length])
        start += length

    # calculate the start address of each block
    adj_dram_address = list()
    current_dram_address = 0
    for coo_block in coo_blocks:
        adj_dram_address.append(current_dram_address)
        current_dram_address += len(coo_block) * 8

    return nnzs, adj_dram_address, current_dram_address


def feature2bin(data_file: str, bin_file: str):
    feature: np.ndarray = np.load(data_file)
    # convert feature array to one dimension fp32 binary file
    feature.reshape(-1).astype(np.float32).tofile(bin_file)
    # np.from_file(bin_file, dtype=np.float32).reshape(feature.shape)

    return None


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

    def tofile(self, file: io.BufferedWriter):
        '''
        need to pass a file object
        '''
        assert(file.mode == 'ab')
        row = np.uint16(self.row)
        if self.first_in_row:
            # set the highest bit to 1
            row = row | 0x8000
        col = np.uint16(self.col)
        if self.last_in_row:
            # set the highest bit to 1
            col = col | 0x8000
        np.array([row, col], dtype=np.uint16).tofile(file)
        np.array([self.data], dtype=np.float32).tofile(file)


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

def COO2Matrix(coo: np.ndarray, size_x: int, size_y: int = -1):
    '''input:
        coo: a coo format adjacent matrix
        size_x: the number of rows
        size_y: the number of columns, if -1, then size_y = size_x
    output:
        adj_matrix: a 2D numpy array
    '''
    if size_y == -1:
        size_y = size_x
    adj_matrix = np.zeros((size_x, size_y))
    for i in range(coo.shape[1]):
        adj_matrix[int(coo[0][i])][int(coo[1][i])] = coo[2][i]
    return adj_matrix


def Matrix2COO(adj_matrix: np.ndarray, row_offset: int = 0, col_offset: int = 0):
    '''input:
        adj_matrix: a 2D numpy array
        row_offset: the offset of row index
        col_offset: the offset of column index
    output:
        coo: a coo format adjacent matrix
    '''
    coo = np.zeros((0,3))
    for r in range(adj_matrix.shape[0]):
        for c in range(adj_matrix.shape[1]):
            if adj_matrix[r][c] != 0:
                coo = np.append(coo, np.array([[r+row_offset, c+col_offset, adj_matrix[r][c]]]), axis=0)
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


    # find a col and row pair with zero value that are not in coo
    def find_zero_pos(coo, last_r: int, last_c: int, coo_pos: int, nodes: int):
        '''
        input: 
            coo: a coo format adjacent matrix
            last_r: the last row index of a zero value
            last_c: the last column index of a zero value
            coo_pos: the next non-zero-element position in coo
            nodes: the number of nodes
        output:
            zero_index: a tuple of (row, column) index of the zero value
            coo_pos: the next non-zero-element position in coo
        '''
        next_r, next_c = coo[0,coo_pos], coo[1,coo_pos]
        for r in range(last_r, nodes):
            for c in range(last_c+1, nodes):
                if r == next_r and c == next_c:
                    # this is a nnz, continue
                    coo_pos += 1
                    next_r, next_c = coo[0,coo_pos], coo[1,coo_pos]
                    continue
                else:
                    zero_index = (r,c)
                    return zero_index, coo_pos
        raise Exception("No zero value found")

    # find the col and row pair with zero value that are not in coo in this row
    def find_zero_pos_in_row(coo_this_row, last_c: int, coo_pos: int, nodes: int):
        next_c = coo_this_row[1,coo_pos]
        for c in range(last_c+1, nodes):
            if c == next_c:
                # this is a nnz, continue
                coo_pos += 1
                if coo_pos >= coo_this_row.shape[1]:
                    return None, None
                next_c = coo_this_row[1,coo_pos]
                continue
            else:
                zero_col_index = c
                return zero_col_index, coo_pos
        return None, None # no more zero value found in this row


    # make each row a queue
    row_queue = {r:[] for r in np.unique(coo[0])}
    # iterate through each column in coo
    for i in range(coo.shape[1]):
        row_queue[coo[0][i]].append((coo[1,i], coo[2,i])) # (col, value)

    # last added rows
    last_add_rows = deque(maxlen=minimun_col_interval)

    interleave_coo = np.zeros((0,3))
    # add the first element of each row queue and calculate the interval requirement
    row_interval_requirement = dict()
    for this_r in row_queue.keys():
        # update the requirements of all rows by minus 1
        for row in row_interval_requirement.keys():
            row_interval_requirement[row] -= 1
        # update the requirement of this row
        if len(row_queue[this_r]) > 1:
            row_interval_requirement[this_r] = minimun_col_interval
        else:
            # row_interval_requirement[this_r] = 0
            pass
        interleave_coo = np.append(interleave_coo, np.array([[this_r, row_queue[this_r][0][0], row_queue[this_r][0][1]]]), axis=0)
        row_queue[this_r].pop(0)
        last_add_rows.appendleft(this_r)
    
    # if the row queue is empty, remove it
    rows = list(row_queue.keys())
    for this_r in rows:
        if len(row_queue[this_r]) == 0:
            row_queue.pop(this_r)
            continue

    # seperate the coo into multiple parts, each part has the same number of rows
    coo_for_different_row = dict()
    for row in range(nodes):
        coo_for_different_row[row] = np.append(coo[:,coo[0]==row], np.array([row, nodes, 0]).reshape(3,1), axis=1) #ALERT: add none-existing zero value to the end of each row
    

    # zero pad info
    zero_pad_info_for_different_row = {r:{'col':0, 'pos':0} for r in range(nodes)}

    # loop until all the queues are empty
    add_zero_num = 0
    while len(row_queue) > 0:
        # choose the most acceptable row with the smallest requirement
        this_r = min(row_interval_requirement, key=row_interval_requirement.get)
        if row_interval_requirement[this_r] <= 0:
            # acceptable interval
            # update the requirements of all rows by minus 1
            for row in row_interval_requirement.keys():
                row_interval_requirement[row] -= 1
            # update the requirement of this row
            if len(row_queue[this_r]) > 1:
                row_interval_requirement[this_r] = minimun_col_interval
            else:
                row_interval_requirement[this_r] = 0
            # add to coo
            interleave_coo = np.append(interleave_coo, np.array([[this_r, row_queue[this_r][0][0], row_queue[this_r][0][1]]]), axis=0)
            last_add_rows.appendleft(this_r)
            row_queue[this_r].pop(0)
            # if the row queue is empty, remove it
            if len(row_queue[this_r]) == 0:
                row_queue.pop(this_r)
                row_interval_requirement.pop(this_r)
        else:
            # not acceptable interval, add dummy indecies with zero index
            for i in range(row_interval_requirement[this_r]):
                # find one zero index
                found = False
                for row in coo_for_different_row.keys():
                    if row in last_add_rows:
                        continue # skip the last added row, zero value can not be in it
                    else:
                        col, pos = find_zero_pos_in_row(coo_for_different_row[row], zero_pad_info_for_different_row[row]['col'], zero_pad_info_for_different_row[row]['pos'], nodes)
                        if col is not None: # find a zero value
                            zero_pad_info_for_different_row[row]['col'] = col
                            zero_pad_info_for_different_row[row]['pos'] = pos
                            interleave_coo = np.append(interleave_coo, np.array([[row, col, 0.0]]), axis=0)
                            last_add_rows.appendleft(row)
                            add_zero_num += 1
                            found = True
                            break
                        else:
                            continue
                if not found:
                    raise Exception('No zero value found in any row')
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
