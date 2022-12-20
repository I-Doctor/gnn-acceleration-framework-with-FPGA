epochs=$1
hidden=$2
layer=2

model=sage
dataset=enzymes
agg=mean
root1="$model-$agg-$layer-$hidden-$dataset"
python ../train.py --dataset $dataset --epochs $epochs --train --model $model --agg $agg
python ../trace.py --root $root1 --dataset $dataset --model $model
python ../train.py --dataset $dataset --model $model --agg $agg
python ../check.py --root $root1 --dataset $dataset


model=sage
for dataset in pubmed cora citeseer; do
  for agg in mean gcn pool; do
    root1="$model-$agg-$layer-$hidden-$dataset"
    python ../train.py --dataset $dataset --epochs $epochs --train --model $model --agg $agg
    python ../trace.py --root $root1 --dataset $dataset --model $model
    python ../train.py --dataset $dataset --model $model --agg $agg
    python ../check.py --root $root1 --dataset $dataset
  done
done

model=gcn
for dataset in pubmed cora citeseer; do
  root1="$model-$layer-$hidden-$dataset"
  python ../train.py --dataset $dataset --epochs $epochs --train --model $model
  python ../trace.py --root $root1 --dataset $dataset --model $model
  python ../train.py --dataset $dataset --model $model
  python ../check.py --root $root1 --dataset $dataset
done
