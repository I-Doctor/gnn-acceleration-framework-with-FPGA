from modules import GCN, SAGE
import torch
import torch.nn as nn
from dgl.data import CoraGraphDataset, CiteseerGraphDataset, PubmedGraphDataset
from dgl import AddSelfLoop
import numpy as np
import argparse
import os

def evaluate(g, features, labels, mask, model):
    model.eval()
    with torch.no_grad():
        logits = model(g, features)
        logits = logits[mask]
        labels = labels[mask]
        _, indices = torch.max(logits, dim=1)
        correct = torch.sum(indices == labels)
        return correct.item() * 1.0 / len(labels)

def inference(g, features, model, path):
    model.eval()
    with torch.no_grad():
        logits = model(g, features)
        f = open(path, "wb")
        print(logits.shape)
        np.save(f, logits.cpu().numpy())
        f.close()

def train(g, features, labels, masks, model, epochs):
    # define train/val samples, loss function and optimizer
    train_mask = masks[0]
    val_mask = masks[1]
    loss_fcn = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-2, weight_decay=5e-4)

    # training loop
    for epoch in range(epochs):
        model.train()
        logits = model(g, features)
        loss = loss_fcn(logits[train_mask], labels[train_mask])
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        if epoch == epochs - 1:
            acc = evaluate(g, features, labels, val_mask, model)
            print("Epoch {:05d} | Loss {:.4f} | Accuracy {:.4f} ".format(epoch, loss.item(), acc))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, default="gcn", help="gcn: GCN and sage: GraphSAGE")
    parser.add_argument("--dataset", type=str, default="pubmed",
                        help="Dataset name ('cora', 'citeseer', 'pubmed').")
    parser.add_argument("--epochs", type=int, default=20, help="Training epochs")
    parser.add_argument("--train", action="store_true", help="Do training")
    parser.add_argument("--agg", type=str, default="mean", help="Aggregation type of SAGEConv")

    args = parser.parse_args()
    print(f'Training with DGL built-in GraphConv module.')

    root = "../IR_and_data/"
    raw_dir = os.path.join(root,"dgl")
    # load and preprocess dataset
    transform = AddSelfLoop()  # by default, it will first remove self-loops to prevent duplication
    if args.dataset == 'cora':
        data = CoraGraphDataset(raw_dir=raw_dir, transform=transform)
    elif args.dataset == 'citeseer':
        data = CiteseerGraphDataset(raw_dir=raw_dir, transform=transform)
    elif args.dataset == 'pubmed':
        data = PubmedGraphDataset(raw_dir=raw_dir, transform=transform)
    else:
        raise ValueError('Unknown dataset: {}'.format(args.dataset))
    g = data[0]
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    g = g.int().to(device)
    features = g.ndata['feat']
    labels = g.ndata['label']
    masks = g.ndata['train_mask'], g.ndata['val_mask'], g.ndata['test_mask']

    in_size = features.shape[1]
    out_size = data.num_classes
    num_layers = 2
    hidden_size = 16
    params = [args.model +'-'+ args.agg if args.model=='sage' else args.model, str(num_layers), str(hidden_size), args.dataset]
    folder_name = '-'.join(params)
    folder_path = os.path.join(root,folder_name)
    if not os.path.exists(folder_path):
        print(f"Create folder {folder_path}")
        os.mkdir(folder_path)
    print(f"Store to {folder_path}")
    model_path = os.path.join(folder_path, "model.pt")

    
    # model training
    if args.train == True:
        print('Training...')
        if args.model == 'gcn':
            model = GCN(in_size, hidden_size, out_size).to(device)
        elif args.model == 'sage':
            model = SAGE(in_size, hidden_size, out_size, args.agg).to(device)
        else:
            raise ValueError('Unknown Model: {}'.format(args.model))
        train(g, features, labels, masks, model, args.epochs)
        print(f"Save model to {model_path}")
        torch.save(model, model_path)
    else:
        print("Inference...")
        model = torch.load(model_path)
        output_path = os.path.join(folder_path, "true_output.npy")
        inference(g, features, model, output_path)
    