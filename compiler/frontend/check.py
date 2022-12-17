import yaml
import os
import os.path as path
import numpy as np
import scipy.sparse as sp
import torch
import argparse
from utils import enlarge_and_save, read_dgl_graph

def check_accuracy(ir, dgl, labels, mask):
    ir_logits = torch.from_numpy(ir[mask])
    dgl_logits = torch.from_numpy(dgl[mask])
    labels = labels[mask]
    _, ir_indices = torch.max(ir_logits, dim=1)
    _, dgl_indices = torch.max(dgl_logits, dim=1)
    ir_acc = torch.sum(ir_indices == labels).item() * 1.0 / len(labels)
    dgl_acc = torch.sum(dgl_indices == labels).item() * 1.0 / len(labels)
    assert abs(ir_acc - dgl_acc) < 1e-6, f"Wrong accuracy {round(ir_acc,4)}. Real accuracy {round(dgl_acc,4)}"
    print("Accuracy: {:.4f}, {:.4f}".format(ir_acc, dgl_acc))


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
    print(f"Output Feature: {np.all(np.isclose(ir_feat, true_output, rtol=1e-2, atol=0), axis=0)}")
    np.savetxt(path.join(root,"dgl_output.out"), true_output)
    np.savetxt(path.join(root,"ir_output.out"), ir_feat)
    return (ir_feat, true_output)
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=str, default="../IR_and_data/gcn-2-16-pubmed", 
                        help="Path to the pre-trained model")
    parser.add_argument("--dataset", type=str, default="pubmed",
                    help="Dataset name ('cora', 'citeseer', 'pubmed').")
    args = parser.parse_args()

    root = "../IR_and_data/"
    raw_dir = os.path.join(root,"dgl")
    # load and preprocess dataset
    data = read_dgl_graph(raw_dir, args.dataset)
    g = data[0].int()
    test_masks = g.ndata['test_mask']
    labels = g.ndata['label']

    (ir_feat, true_output) = check(args.root)
    check_accuracy(ir_feat, true_output, labels, test_masks)
