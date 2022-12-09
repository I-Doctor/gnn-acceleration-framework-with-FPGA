import yaml
from os import path
import numpy as np
import scipy.sparse as sp
import torch
import argparse
from utils import enlarge_and_save

def check(root):
    f = open(path.join(root,"ir_generated.yaml"), "r")
    totinfo = yaml.safe_load(f)
    bias = None
    feat = 0
    store_paths = []
    for info in totinfo:
        if info['op_type'] == 'mm':
            input_feat = np.load(path.join(root,info['op_input_data']['read_data_path']))
            weight = np.load(path.join(root,info['op_weight']['read_data_path']))

            feat = input_feat.dot(weight)
            if info['accumulation'] == True:
                acc_data = np.load(path.join(root,info['op_acc_data']['read_data_path']))
                feat += acc_data      
            
        elif info['op_type'] == 'agg':
            if info['reduce_type'] == 'sum':
                index = np.load(path.join(root,info['op_adj']['read_index_path']))
                adj = np.load(path.join(root,info['op_adj']['read_data_path']))
                num_nodes = info['op_adj']['data_shape'][0]
                agg_coo = sp.coo_matrix((adj, (index[0], index[1])), shape=(num_nodes, num_nodes))
                input_feat = np.load(path.join(root,info['op_input_data']['read_data_path']))
                feat = agg_coo.dot(input_feat)
            elif info['reduce_type'] == 'max':
                index = np.load(path.join(root,info['op_adj']['read_index_path']))
                num_nodes = info['op_adj']['data_shape'][0]
                input_feat = np.load(path.join(root,info['op_input_data']['read_data_path']))
                feat = np.zeros(input_feat.shape)
                agg_csr = sp.csr_matrix((np.ones(index[0].shape), (index[0], index[1])), shape=(num_nodes, num_nodes)).sorted_indices()
                indices = agg_csr.indices
                indptr = agg_csr.indptr
                for row in range(num_nodes):
                    pos_start = indptr[row]
                    pos_end = indptr[row + 1]
                    assert pos_start != pos_end, "In-degree is at least 1"
                    feat[row] = input_feat[indices[pos_start]]
                    for pos in range(pos_start + 1, pos_end):
                        feat[row] = np.maximum(feat[row], input_feat[indices[pos]])



        if info['bias'] == True:
            bias = np.load(path.join(root,info['op_bias']['read_data_path']))
            feat = feat + bias
        if info['relu'] == True:
            feat = feat * (feat > 0)
        store_path = path.join(root,info['op_output_data']['write_data_path'])
        np.save(store_path, feat)
        store_paths.append(store_path)

    ir_feat = np.load(store_paths[-1])
    enlarge_and_save(root, torch.from_numpy(np.load(path.join(root,"true_output.npy"))), 1, "enlarge_true_output")
    true_output = np.load(path.join(root,"enlarge_true_output.npy"))
    print(f"DGL vs. IR: {np.all(np.isclose(ir_feat, true_output, rtol=1e-2, atol=0), axis=0)}")
    np.savetxt(path.join(root,"dgl_output.out"), true_output)
    np.savetxt(path.join(root,"ir_output.out"), ir_feat)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=str, default="../IR_and_data/gcn-2-16-pubmed", 
                        help="Path to the pre-trained model")
    args = parser.parse_args()

    check(args.root)
