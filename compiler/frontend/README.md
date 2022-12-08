compiler

```
python train.py --dataset pubmed --epochs 20 --train --model sage      # Train.
python trace.py --root ../IR_and_data/gcn-2-16-pubmed --dataset pubmed # Generate IR and intermediate results.
python train.py --dataset pubmed --model sage                                       # Generate DGL inference feature output.
python check.py --root ../IR_and_data/gcn-2-16-pubmed/                 # Check.
```
