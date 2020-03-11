#!/bin/bash

./download_data_and_jar.sh
echo "Running Robustness study on all methods. This might take a few days to finish...."

n=1
fold=0
weightlearning_randomweights="true"
# methods='RGS MPLE MLE LME HB CRGS BOWLSS BOWLOS'
methods='RGS HB CRGS'

for method in $methods; do
    for j in Categorical; do
        # Citeseer
        # clear and make new weight files for each dataset and weightlearning method and metric
        true > Citeseer/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        true > Citeseer/robustness_evaluations_${method}_${j}.csv
    done

    for j in Categorical; do
        # Cora
        # clear and make new weight files for each dataset and weightlearning method and metric
        true > Cora/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        true > Cora/robustness_evaluations_${method}_${j}.csv
    done

    for j in Discrete; do
        # Epinions
        # clear and make new weight files for each dataset and weightlearning method and metric
        true > Epinions/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        true > Epinions/robustness_evaluations_${method}_${j}.csv
    done

    for j in Continuous; do
        # LastFM
        # clear and make new weight files for each dataset and weightlearning method and metric
        true > LastFM/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        true > LastFM/robustness_evaluations_${method}_${j}.csv
    done

    for j in Continuous; do
        # Jester
        # clear and make new weight files for each dataset and weightlearning method and metric
        true > Jester/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        true > Jester/robustness_evaluations_${method}_${j}.csv
    done
done

# iterate will seed the random initial weights or search or both, depending on the method
for (( seed=1; seed<=n; seed++ )) do
#   ./run_i_LME.sh $fold $weightlearning_randomweights $seed
#   ./run_i_MLE.sh $fold $weightlearning_randomweights $seed
#   ./run_i_MPLE.sh $fold $weightlearning_randomweights $seed
  ./run_i_RGS.sh $fold $seed
  ./run_i_CRGS.sh $fold $seed
  ./run_i_HB.sh $fold $seed
# add weights and evalulations for each dataset, wl_method, and metric
  ./append_learned_weights_and_evaluations.sh $fold "$methods"
done
