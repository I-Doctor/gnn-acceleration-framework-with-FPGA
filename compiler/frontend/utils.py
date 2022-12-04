import torch
import torch.nn.functional as F
import numpy as np
import os

def get_upper_multiples_16(x: int):
    if x % 16 == 0:
        return x
    else:
        return int((x // 16 + 1) * 16) 

def enlarge_and_save(root, t: torch.Tensor, dims ,name: str):
    print(f"{name}: {t.shape}")
    if len(t.shape) == 1:
        old_col = t.shape[0]
        f = open(os.path.join(root, f"{name}.npy"), "wb")
        new_col = get_upper_multiples_16(old_col)
        t = F.pad(t, (0, int(new_col - old_col)), "constant", 0)
        np.save(f, t.cpu().numpy())
        f.close()
        print(f"{name}: {t.shape}")
        return torch.Size([new_col])
    if len(t.shape) == 2:
        (old_row, old_col) = t.shape
        f = open(os.path.join(root, f"{name}.npy"), "wb")
        if dims == (0,1):
            new_row = get_upper_multiples_16(old_row)
            new_col = get_upper_multiples_16(old_col)
            t = F.pad(t, (0, int(new_col - old_col), 0, int(new_row - old_row)), "constant", 0)
        elif dims == 0:
            new_row = get_upper_multiples_16(old_row)
            new_col = old_col
            t = F.pad(t, (0, 0, 0, int(new_row - old_row)), "constant", 0)
        elif dims == 1:
            new_col = get_upper_multiples_16(old_col)
            new_row = old_row
            t = F.pad(t, (0, int(new_col - old_col)), "constant", 0)
        else:
            raise NotImplementedError
        np.save(f, t.cpu().numpy())
        f.close()
        print(f"{name}: {t.shape}")
        return torch.Size((new_row, new_col))
    raise NotImplementedError