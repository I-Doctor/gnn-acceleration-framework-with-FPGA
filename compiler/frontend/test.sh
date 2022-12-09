epoch=20
layer=2
hidden=16
model=sage
for dataset in pubmed; do
  for agg in mean gcn; do
    root1="../IR_and_data/$model-$agg-$layer-$hidden-$dataset"
    python train.py --dataset $dataset --epoch $epoch --train --model $model --agg $agg
    python trace.py --root $root1 --dataset $dataset --model $model
    python train.py --dataset $dataset --model $model --agg $agg
    python check.py --root $root1
  done
done

model=gcn
for dataset in pubmed; do
  root1="../IR_and_data/$model-$layer-$hidden-$dataset"
  python train.py --dataset $dataset --epoch $epoch --train --model $model
  python trace.py --root $root1 --dataset $dataset --model $model
  python train.py --dataset $dataset --model $model
  python check.py --root $root1
done