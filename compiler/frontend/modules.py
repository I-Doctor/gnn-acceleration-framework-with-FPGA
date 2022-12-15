import torch.nn as nn
import torch.nn.functional as F
import dgl.nn as dglnn

# Model definination is the same as https://github.com/dmlc/dgl/blob/0.9.1/examples/pytorch/gcn/train.py
class GCN(nn.Module):
    def __init__(self, in_size, hid_size, out_size):
        super().__init__()
        self.layers = nn.ModuleList()
        # two-layer GCN
        self.layers.append(dglnn.GraphConv(in_size, hid_size, activation=F.relu))
        self.layers.append(dglnn.GraphConv(hid_size, out_size))
        self.dropout = nn.Dropout(0.5)

    def forward(self, g, features):
        h = features
        for i, layer in enumerate(self.layers):
            if i != 0:
                h = self.dropout(h)
            h = layer(g, h)
        return h

# Model defination is the same as https://github.com/dmlc/dgl/blob/0.9.1/examples/pytorch/graphsage/train_full.py
class SAGE(nn.Module):
    def __init__(self, in_size, hid_size, out_size, aggregation_type='mean'):
        super().__init__()
        self.layers = nn.ModuleList()
        # two-layer GraphSAGE-mean
        self.layers.append(dglnn.SAGEConv(in_size, hid_size, aggregator_type=aggregation_type, activation=F.relu))
        self.layers.append(dglnn.SAGEConv(hid_size, out_size, aggregator_type=aggregation_type))
        self.dropout = nn.Dropout(0.5)

    def forward(self, g, features):
        h = features
        for i, layer in enumerate(self.layers):
            if i != 0:
                h = self.dropout(h)
            h = layer(g, h)
        return h