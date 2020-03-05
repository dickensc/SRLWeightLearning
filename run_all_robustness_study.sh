#!/bin/bash

./download_data_and_jar.sh
echo "Running Robustness study on all methods. This might take a few days to finish...."

n=100
fold=1

for (( i=1; i<=n; i++ )) do
  ./run_i_BOWLSS.sh $fold
  ./run_i_BOWLOS.sh $fold
  ./run_i_LME.sh $fold
  ./run_i_MLE.sh $fold
  ./run_i_MPLE.sh $fold
  ./run_i_RGS.sh $fold
  ./run_i_CRGS.sh $fold
  ./run_i_HB.sh $fold
done