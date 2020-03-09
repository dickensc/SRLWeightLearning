#!/bin/bash

./download_data_and_jar.sh
echo "Running Robustness study on all methods. This might take a few days to finish...."

n=100
fold=1
weightlearning_randomweights="true"

# open and clear weight files for each dataset and weightlearning method and metric

# open and clear evaluation files for each dataset and weightlearning method and metric

# iterate will seed the random initial weights or search or both, depending on the method
for (( seed=1; seed<=n; seed++ )) do
#   ./run_i_LME.sh $fold $weightlearning_randomweights $seed
#   ./run_i_MLE.sh $fold $weightlearning_randomweights $seed
#   ./run_i_MPLE.sh $fold $weightlearning_randomweights $seed
  ./run_i_RGS.sh $fold $seed
#   ./run_i_CRGS.sh $fold $seed
#   ./run_i_HB.sh $fold $seed
# add weights and evalulations for each dataset, wl_method, and metric
    ./append_learned_weights.sh $fold
    ./append_learned_evaluations.sh $fold
done