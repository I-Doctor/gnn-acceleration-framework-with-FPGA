from typing import Dict, List, Tuple
from operators_loading import operator_loader

def fusion_detector(operators: List[Dict]):
    fusion_list = operators.copy()
    for i, operator in enumerate(operators):
        fusion_flag = False
        if operator['op_type'] == 'agg':
            tmp_output_name = operator['op_output_data']['data_name']
            # find if its next operator is mm
            # in case that the operators are residual
            for j, next_operator in enumerate(operators):
                if next_operator['op_input_data']['data_name'] == tmp_output_name and \
                    next_operator['op_type'] == 'mm':
                    # fusion_list = fusion_list + [(i, j)]
                    fusion_flag = True
                    break
        if fusion_flag:
            del fusion_list[i]
            # as i-th operator is deleted
            del fusion_list[j - 1]
            fusion_list.insert(i, (operator, next_operator))

    return fusion_list


if __name__ == '__main__': 
    operators = operator_loader('ir_example_pubmed_gcn_2_128.yaml')
    fusion_operators = fusion_detector(operators)

    print(fusion_operators)