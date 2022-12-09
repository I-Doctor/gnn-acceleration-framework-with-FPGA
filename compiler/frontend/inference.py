import dgl.function as fn
from dgl.utils import expand_as_pair
from dgl.data import PubmedGraphDataset
from dgl import AddSelfLoop
import torch.nn.functional as F
import torch
import numpy as np
import os.path as pt

def dgl_SAGEConv(graph, feat_src, fc_pool, fc_neigh, fc_self, feat_base, root, relu):
    h_self = feat_src
    msg_fn = fn.copy_src('h', 'm')
    graph.srcdata['h'] = F.relu(torch.matmul(feat_src, fc_pool))
    np.savetxt(pt.join(root, f"dgl_feat{feat_base}.out"), feat_src.numpy())
    np.savetxt(pt.join(root, f"ir_feat{feat_base}.out"), np.load(pt.join(root, f"feat{feat_base}.npy")))
    feat_base += 1
    np.savetxt(pt.join(root, f"dgl_feat{feat_base}.out"), graph.ndata['h'].numpy())
    np.savetxt(pt.join(root, f"ir_feat{feat_base}.out"), np.load(pt.join(root, f"feat{feat_base}.npy")))

    graph.update_all(msg_fn, fn.max('m', 'neigh'))
    feat_base += 1
    np.savetxt(pt.join(root, f"dgl_feat{feat_base}.out"), graph.ndata['neigh'].numpy())
    np.savetxt(pt.join(root, f"ir_feat{feat_base}.out"), np.load(pt.join(root, f"feat{feat_base}.npy")))

    h_neigh = torch.matmul(graph.dstdata['neigh'], fc_neigh)
    feat_base += 1
    np.savetxt(pt.join(root, f"dgl_feat{feat_base}.out"), h_neigh.numpy())
    np.savetxt(pt.join(root, f"ir_feat{feat_base}.out"), np.load(pt.join(root, f"feat{feat_base}.npy")))

    rst = torch.matmul(h_self, fc_self) + h_neigh
    if relu:
        rst = F.relu(rst)
    feat_base += 1
    np.savetxt(pt.join(root, f"dgl_feat{feat_base}.out"), rst.numpy())
    np.savetxt(pt.join(root, f"ir_feat{feat_base}.out"), np.load(pt.join(root, f"feat{feat_base}.npy")))

    return rst


raw_dir = "../IR_and_data/dgl"
transform = AddSelfLoop() 
data = PubmedGraphDataset(raw_dir=raw_dir, transform=transform)
g = data[0].int()

raw_dir = "../IR_and_data/sage-pool-2-16-pubmed"

num_base = 1
input_feature = np.load(pt.join(raw_dir, f"feat{num_base}.npy"))
input_feature_t = torch.from_numpy(input_feature)

fc_weights = []
for i in range(1,4):
    fc_weights.append(torch.from_numpy(np.load(pt.join(raw_dir, f"fc{i}_weight.npy"))))

dgl_SAGEConv(g, input_feature_t, fc_weights[0], fc_weights[1], fc_weights[2], feat_base=num_base, root=raw_dir, relu=True)


num_base = 5
input_feature = np.load(pt.join(raw_dir, f"feat{num_base}.npy"))
input_feature_t = torch.from_numpy(input_feature)

fc_weights = []
for i in range(4,7):
    fc_weights.append(torch.from_numpy(np.load(pt.join(raw_dir, f"fc{i}_weight.npy"))))

dgl_SAGEConv(g, input_feature_t, fc_weights[0], fc_weights[1], fc_weights[2], feat_base=num_base, root=raw_dir, relu=False)
