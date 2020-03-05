#!/bin/bash

./download_data_and_jar.sh
echo "Running Robustness study on all methods. This might take a few days to finish...."

n=100
fold=1
weightlearning_randomweights="true"

# iterate will seed the random initial weights or search or both, depending on the method
for (( seed=1; seed<=n; seed++ )) do
  ./run_i_LME.sh $fold $weightlearning_randomweights $seed
  ./run_i_MLE.sh $fold $weightlearning_randomweights $seed
  ./run_i_MPLE.sh $fold $weightlearning_randomweights $seed
  ./run_i_RGS.sh $fold $seed
  ./run_i_CRGS.sh $fold $seed
  ./run_i_HB.sh $fold $seed
done