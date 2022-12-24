# -*-coding:utf-8-*-
import numpy as np

def value_at_bit(value, bit):
    return (value >> bit) & 1

def decode_bank_id(bank_group): # one hot to int
    if   bank_group == 0b000001:
        return 0
    elif bank_group == 0b000010:
        return 1
    elif bank_group == 0b000100:
        return 2
    elif bank_group == 0b001000:
        return 3
    elif bank_group == 0b010000:
        return 4
    else:
        raise Exception

def relu(value):
    return np.maximum(value, 0)
