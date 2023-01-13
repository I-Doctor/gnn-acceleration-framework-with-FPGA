#-*-coding:utf-8-*-
import collections
import struct
import copy

# 本文件实现了将所有的指令按照需要的格式进行转存，反转也是在本文件中实现的
# 相当与将指令集包装了一层接口

# 定义指令集中每条指令的配置
# 默认搜索的指令第一行前四个字节均为opcode
# 默认每行字符数永远为32
# 每条指令都是128bit
# opcode, length分别代表opcode的值以及指令集的总长度
# structure存储的是每个字段对应的位置，是一个列表，列表中每个元素是个四元组，分别代表行号，起始位置，结束位置（均包含），可选列表
# 可选列表为None代表是默认位置，默认大端模式

## Img Group
## load: first 3 groups (1, 2-A, 2-B)
## save: last 4 groups
## conv: input the first group, output the second group
## misc: input the second group, output the third group

inst_set_configuration = collections.OrderedDict()

## weight
inst_set_configuration['weight'] = collections.OrderedDict()
inst_set_configuration['weight']['opcode'] = 0b1000
inst_set_configuration['weight']['length'] = 4
inst_set_configuration['weight']['structure'] = collections.OrderedDict()
inst_set_configuration['weight']['structure']['wait'] = [(0, 27, 22, None)]
inst_set_configuration['weight']['structure']['release'] = [(0, 21, 16, None)]
inst_set_configuration['weight']['structure']['buffer_address_length'] = [(1, 31, 16, None)]
inst_set_configuration['weight']['structure']['buffer_start_address'] = [(1, 15, 0, None)]
inst_set_configuration['weight']['structure']['dram_byte_length'] = [(2, 31, 16, None)]
inst_set_configuration['weight']['structure']['dram_start_address'] = [(3, 31, 0, None)]
inst_set_configuration['weight']['structure']['reserved'] = [(0, 15, 0, None), (2, 15, 0, None)]

## bias
inst_set_configuration['bias'] = collections.OrderedDict()
inst_set_configuration['bias']['opcode'] = 0b1001
inst_set_configuration['bias']['length'] = 4
inst_set_configuration['bias']['structure'] = collections.OrderedDict()
inst_set_configuration['bias']['structure']['wait'] = [(0, 27, 22, None)]
inst_set_configuration['bias']['structure']['release'] = [(0, 21, 16, None)]
inst_set_configuration['bias']['structure']['buffer_address_length'] = [(1, 31, 16, None)]
inst_set_configuration['bias']['structure']['buffer_start_address'] = [(1, 15, 0, None)]
inst_set_configuration['bias']['structure']['dram_byte_length'] = [(2, 31, 16, None)]
inst_set_configuration['bias']['structure']['dram_start_address'] = [(3, 31, 0, None)]
inst_set_configuration['bias']['structure']['reserved'] = [(0, 15, 0, None), (2, 15, 0, None)]

## load
inst_set_configuration['load'] = collections.OrderedDict()
inst_set_configuration['load']['opcode'] = 0b1010
inst_set_configuration['load']['length'] = 4
inst_set_configuration['load']['structure'] = collections.OrderedDict()
inst_set_configuration['load']['structure']['wait'] = [(0, 27, 22, None)]
inst_set_configuration['load']['structure']['release'] = [(0, 21, 16, None)]
inst_set_configuration['load']['structure']['group'] = [(0, 5, 0, [0b000001, 0b000010, 0b000100, 0b001000, 0b010000])]
inst_set_configuration['load']['structure']['buffer_address_length'] = [(1, 31, 16, None)]
inst_set_configuration['load']['structure']['buffer_start_address'] = [(1, 15, 0, None)]
inst_set_configuration['load']['structure']['dram_byte_length'] = [(2, 31, 16, None)]
inst_set_configuration['load']['structure']['dram_start_address'] = [(3, 31, 0, None)]
inst_set_configuration['load']['structure']['reserved'] = [(0, 15, 6, None), (2, 15, 0, None)]

## save
inst_set_configuration['save'] = collections.OrderedDict()
inst_set_configuration['save']['opcode'] = 0b1011
inst_set_configuration['save']['length'] = 4
inst_set_configuration['save']['structure'] = collections.OrderedDict()
inst_set_configuration['save']['structure']['wait'] = [(0, 27, 22, None)]
inst_set_configuration['save']['structure']['release'] = [(0, 21, 16, None)]
inst_set_configuration['save']['structure']['group'] = [(0, 5, 0, [0b000010, 0b000100, 0b001000, 0b010000])]
inst_set_configuration['save']['structure']['buffer_address_length'] = [(1, 31, 16, None)]
inst_set_configuration['save']['structure']['buffer_start_address'] = [(1, 15, 0, None)]
inst_set_configuration['save']['structure']['dram_byte_length'] = [(2, 31, 16, None)]
inst_set_configuration['save']['structure']['dram_start_address'] = [(3, 31, 0, None)]
inst_set_configuration['save']['structure']['reserved'] = [(0, 15, 6, None), (2, 15, 0, None)]

## agg
inst_set_configuration['agg'] = collections.OrderedDict()
inst_set_configuration['agg']['opcode'] = 0b1100
inst_set_configuration['agg']['length'] = 4
inst_set_configuration['agg']['structure'] = collections.OrderedDict()
inst_set_configuration['agg']['structure']['wait'] = [(0, 27, 22, None)]
inst_set_configuration['agg']['structure']['release'] = [(0, 21, 16, None)]
inst_set_configuration['agg']['structure']['t'] = [(0, 15, 15, [0b0, 0b1])]
inst_set_configuration['agg']['structure']['b'] = [(0, 14, 14, [0b0, 0b1])]
inst_set_configuration['agg']['structure']['e'] = [(0, 13, 13, [0b0, 0b1])]
inst_set_configuration['agg']['structure']['r'] = [(0, 12, 12, [0b0, 0b1])]
inst_set_configuration['agg']['structure']['out_group'] = [(0, 11, 6, [0b000010, 0b000100])]
inst_set_configuration['agg']['structure']['in_group'] = [(0, 5, 0, [0b000001, 0b000010, 0b000100])]
inst_set_configuration['agg']['structure']['address_per_feature'] = [(1, 31, 24, None)]
inst_set_configuration['agg']['structure']['bias_start_address'] = [(1, 23, 16, None)]
inst_set_configuration['agg']['structure']['input_buffer_start_address'] = [(1, 15, 0, None)]
inst_set_configuration['agg']['structure']['edge_number'] = [(2, 31, 16, None)]
inst_set_configuration['agg']['structure']['output_buffer_start_address'] = [(2, 15, 0, None)]
inst_set_configuration['agg']['structure']['adj_dram_start_address'] = [(3, 31, 0, None)]
# inst_set_configuration['agg']['structure']['reserved'] = []

## mm
inst_set_configuration['mm'] = collections.OrderedDict()
inst_set_configuration['mm']['opcode'] = 0b1101
inst_set_configuration['mm']['length'] = 4
inst_set_configuration['mm']['structure'] = collections.OrderedDict()
inst_set_configuration['mm']['structure']['wait'] = [(0, 27, 22, None)]
inst_set_configuration['mm']['structure']['release'] = [(0, 21, 16, None)]
inst_set_configuration['mm']['structure']['b'] = [(0, 14, 14, [0b0, 0b1])]
inst_set_configuration['mm']['structure']['a'] = [(0, 13, 13, [0b0, 0b1])]
inst_set_configuration['mm']['structure']['r'] = [(0, 12, 12, [0b0, 0b1])]
inst_set_configuration['mm']['structure']['out_group'] = [(0, 11, 6, [0b001000, 0b010000])]
inst_set_configuration['mm']['structure']['in_group'] = [(0, 5, 0, [0b000010, 0b000100, 0b001000, 0b010000])]
inst_set_configuration['mm']['structure']['bias_start_address'] = [(1, 31, 16, None)]
inst_set_configuration['mm']['structure']['weight_start_address'] = [(1, 15, 0, None)]
inst_set_configuration['mm']['structure']['input_address_per_feature'] = [(2, 31, 24, None)]
inst_set_configuration['mm']['structure']['output_address_per_feature'] = [(2, 23, 16, None)]
inst_set_configuration['mm']['structure']['input_start_address'] = [(2, 15, 0, None)]
inst_set_configuration['mm']['structure']['node_number'] = [(3, 31, 16, None)]
inst_set_configuration['mm']['structure']['output_start_address'] = [(3, 15, 0, None)]
inst_set_configuration['mm']['structure']['reserved'] = [(0, 15, 15, None)]

## 所有指令都为128bit
for key in inst_set_configuration.keys():
    assert inst_set_configuration[key]['length'] == 4

## 将opcode也加入到structure中
for key in inst_set_configuration.keys():
    inst_set_configuration[key]['structure']['opcode'] = [(0, 31, 28, None)]

## 检查所有字段，确保默认值只可能出现在第一个part
for key in inst_set_configuration.keys():
    for field_name, field_param in inst_set_configuration[key]['structure'].items():
        if not all(map(lambda x: x[3] is None, field_param[1:])):
            raise Exception(f'field_param {field_param} is not in correct format')

## 遍历检查所有的字段（包括reserved）不重不漏地覆盖了所有的位置
for key in inst_set_configuration.keys():
    inst_configuration = inst_set_configuration[key]
    ### 检查所有的可能位置
    for i in range(inst_configuration['length']):
        for j in range(32):
            j = 31 - j # 反向
            appear_count = 0
            for field_parameter in inst_configuration['structure'].values():
                for cover_range in field_parameter:
                    #### cover_range是覆盖范围的四元组，测试是否出现
                    if i == cover_range[0] and j <= cover_range[1] and j >= cover_range[2]:
                        appear_count = appear_count + 1
            # appear_count应该永远为1
            if not appear_count == 1:
                raise Exception(f'{key}, {inst_configuration} appear_count is {appear_count}')
            assert appear_count == 1
    ### 在不重不漏的前提下，还应保证数量的一致性
    total_count = 0
    for field_parameter in inst_configuration['structure'].values():
        for cover_range in field_parameter:
            total_count = total_count + cover_range[1] - cover_range[2] + 1
    assert total_count == inst_configuration['length'] * 32

## 建立opcode到inst_type和length的字典
opcode_inst_dict = collections.OrderedDict()
for key, value in inst_set_configuration.items():
    opcode_inst_dict[str(value['opcode'])] = {'inst_type': key, 'length': value['length']}

## 建立指令名到占据长度的字典
inst_info_dict = collections.OrderedDict()
for key, value in inst_set_configuration.items():
    assert 'structure' in value.keys()
    inst_info_dict[key] = collections.OrderedDict()
    for field_name, field_value in value['structure'].items():
        total_length = 0
        for parts in field_value:
            total_length += (parts[1] - parts[2] + 1)
        inst_info_dict[key][field_name] = total_length

# 定义transfer函数
def transfer(value, start, end):
    return (value >> end) % (1 << (start - end + 1))

## 编码指令到一个带有TYPE的字典上
def inst_add_type(inst_type, inst_dict):
    '''
    input a inst, add type, return inst
    '''
    out_inst_dict = collections.OrderedDict()
    out_inst_dict['TYPE'] = inst_type
    # 改变为对输入的指令集进行筛选，检查，补充，只保留在inst_set_configuration中出现的键值，且校验是否满足要求
    out_inst_dict['HEX'] = ''
    out_inst_dict['PARAM'] = collections.OrderedDict()
    inst_configuration = inst_set_configuration[inst_type]
    for key, field_parameter in inst_configuration['structure'].items():
        if key in ['opcode', 'reserved']:
            continue
        # 如果键在输入内，检查是否满足范围要求，如果不在输入内，那么取一个默认值，默认范围是第一部分的第四块
        default_values = field_parameter[0][3]
        if key in inst_dict:
            # None是没有要求，否则是个列表
            if default_values is not None and inst_dict[key] not in default_values:
                print(inst_type)
                print(inst_dict)
                print(key)
                raise Exception(f'{inst_dict[key]} not in {default_values}')
            value = inst_dict[key]
        else:
            value = 0 if default_values is None else default_values[0]
        # 接着就可以赋值了
        out_inst_dict['PARAM'][key] = value
    # 对于在inst_dict中，但是不在inst_configuration中的，必须满足为0，否则视为错误
    for key, value in inst_dict.items():
        if key not in inst_configuration['structure'] and value != 0:
            raise Exception(f'value out of inst_configuration must be 0')
    bin_inst = encode_inst(inst_type, inst_dict)
    hex_inst = ''
    for i in range(inst_set_configuration[inst_type]['length']):
        hex_inst = hex_inst + ("%08x" % bin_inst[i]) + " "
    out_inst_dict['HEX'] = hex_inst.strip()
    return out_inst_dict

## 利用上述configuration生成所需的encode和decode文件，此时，需要额外的一个参数作为输入配置
## 编码的时候，输入是inst_type 字符串，inst_dict需要的字典，输出是指令列表
def encode_inst(inst_type, inst_dict):
    ### 先选出对应的配置文件
    inst_configuration = inst_set_configuration[inst_type]
    ### 根据配置文件的信息确定相关的操作
    inst_list = [0] * inst_configuration['length']
    for key, field_parameter in inst_configuration['structure'].items():
        if key in ['reserved']:
            continue
        if key in ['opcode']:
            inst_list[0] = inst_list[0] + ((inst_configuration['opcode']) << 28)
            continue
        field_length = 0
        for cover_range in field_parameter:
            field_length = field_length + cover_range[1] - cover_range[2] + 1
        #### 取值，判定，赋值，先出现的是低位
        if key not in inst_dict.keys():
            tmp = 0
        else:
            tmp = inst_dict[key]
        if not(tmp >= 0 and tmp < 2**field_length):
            print(inst_dict)
            print(key)
            assert 0
        for cover_range in field_parameter:
            field_length = cover_range[1] - cover_range[2] + 1
            inst_list[cover_range[0]] = inst_list[cover_range[0]] + ((tmp % (2 ** field_length)) << cover_range[2])
            tmp = tmp // (2 ** field_length)
    return inst_list

## 解码的时候，输入是inst_type 字符串，inst_list需要的指令列表，输出是字典
## 在之后的使用中基本是无效的，因为被更高效的字典代替
def decode_inst(inst_type, inst_list):
    ### 先选出对应的配置文件
    inst_configuration = inst_set_configuration[inst_type]
    assert len(inst_list) == inst_configuration['length']
    assert transfer(inst_list[0], 31, 28) == inst_configuration['opcode']
    inst_dict = collections.OrderedDict()
    for key, field_parameter in inst_configuration['structure'].items():
        if key in ['opcode', 'reserved']:
            continue
        inst_dict[key] = 0
        field_length = 0
        for cover_range in field_parameter:
            inst_dict[key] = inst_dict[key] + transfer(inst_list[cover_range[0]], cover_range[1], cover_range[2]) * (2 ** field_length)
            field_length = field_length + cover_range[1] - cover_range[2] + 1
    return inst_dict

# 定义将inst生成后保存为文件的操作
def write_inst_file(f_name_0, f_name_1, inst_list):
    # 默认输入的长度必然为4Byte，根据NG的取值来确定如何分布
    # num of group
    NG = 4
    assert NG == 4
    assert 4 % NG == 0
    if f_name_0 != None:
        with open(f_name_0, 'a') as f0:
            # inst_list每一行均为一个单独的指令模块，需要按照NG的数量进行拆分
            for inst in inst_list:
                # inst实际上就是个数值
                tmp = inst
                for _ in range(4 // NG):
                    f0.write(('0x%%0%dx\n' % (NG * 2)) % (tmp % (1 << (NG * 8))))
                    tmp = tmp // (1 << (NG * 8))
    if f_name_1 != None:
        with open(f_name_1, 'ab') as f1:
            for inst in inst_list:
                tmp = inst
                for _ in range(4 // NG):
                    f1.write(struct.pack('I', (tmp % (1 << (NG * 8)))))
                    tmp = tmp // (1 << (NG * 8))

