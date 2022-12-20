epochs=$1
hidden=$2
layer=2
model=sage
agg=pool
dataset=reddit
root1="$model-$agg-$layer-$hidden-$dataset"
python ../train.py --dataset $dataset --epochs $epochs --train --model $model --agg $agg
python ../trace.py --root $root1 --dataset $dataset --model $model
python ../train.py --dataset $dataset --model $model --agg $agg
python ../check.py --root $root1 --dataset $dataset