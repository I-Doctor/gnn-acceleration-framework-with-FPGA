from modules import GCN, SAGE
import torch
import torch.nn as nn
import numpy as np
import argparse
import os
from utils import read_dgl_graph, create_dgl_graph

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
            acc = evaluate(g, features, labels, val_mask, model) # Only report the final evaluation accuracy to save training time
            print("Epoch {:05d} | Loss {:.4f} | Accuracy {:.4f} ".format(epoch, loss.item(), acc))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, default="gcn", help="gcn: GCN and sage: GraphSAGE")
    parser.add_argument("--dataset", type=str, default="pubmed",
                        help="Dataset name ('cora', 'citeseer', 'pubmed', 'reddit', 'enzymes').")
    parser.add_argument("--epochs", type=int, default=20, help="Training epochs")
    parser.add_argument("--train", action="store_true", help="Do training")
    parser.add_argument("--agg", type=str, default="mean", help="Aggregation type of SAGEConv")

    args = parser.parse_args()
    print(f'Training with DGL built-in GraphConv module.')

    root = os.path.join(os.path.dirname(os.path.realpath(__file__)),"..","IR_and_data")
    raw_dir = os.path.join(root,"dgl")
    
    if args.dataset == "enzymes":
        create_dgl_graph(raw_dir, args.dataset)
        
    (g, features, num_classes, labels, masks) = read_dgl_graph(raw_dir, args.dataset)
    in_size = features.shape[1]
    out_size = num_classes
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
            model = GCN(in_size, hidden_size, out_size)
        elif args.model == 'sage':
            model = SAGE(in_size, hidden_size, out_size, args.agg)
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
    