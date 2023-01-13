from typing import Dict
import yaml

def operator_loader(ir_file: str): 
    ir_data = open(ir_file, 'r')
    all_operators = yaml.load(ir_data, Loader=yaml.FullLoader)
    return all_operators

if __name__ == '__main__': 
    operators = operator_loader('input/ir_generated.yaml')
    for operator in operators:
        print(operator['op_type'])