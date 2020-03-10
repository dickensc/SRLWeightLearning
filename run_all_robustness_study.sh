#!/bin/bash

./download_data_and_jar.sh
echo "Running Robustness study on all methods. This might take a few days to finish...."

n=100
fold=0
weightlearning_randomweights="true"
datasets='Citeseer Cora Epinions Jester LastFM'
metrics='Categorical Discrete Continuous Ranking'

for method in $methods; do
    for j in Categorical Discrete; do
        # Citeseer 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm Citeseer/Citeseer/robustness_weights_${method}_${j}.csv
        touch Citeseer/Citeseer/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm Citeseer/Citeseer/robustness_evaluations_${method}_${j}.csv
        touch Citeseer/Citeseer/robustness_evaluations_${method}_${j}.csv
    done

    for j in Categorical Discrete; do
        # Cora 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm Cora/Cora/robustness_weights_${method}_${j}.csv
        touch Cora/Cora/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm Cora/Cora/robustness_evaluations_${method}_${j}.csv
        touch Cora/Cora/robustness_evaluations_${method}_${j}.csv
    done

    for j in Ranking Discrete; do
        # Epinions 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm Epinions/Epinions/robustness_weights_${method}_${j}.csv
        touch Epinions/Epinions/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm Epinions/Epinions/robustness_evaluations_${method}_${j}.csv
        touch Epinions/Epinions/robustness_evaluations_${method}_${j}.csv
    done

    for j in Continuous Ranking; do
        # LastFM 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm LastFM/LastFM/robustness_weights_${method}_${j}.csv
        touch LastFM/LastFM/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm LastFM/LastFM/robustness_evaluations_${method}_${j}.csv
        touch LastFM/LastFM/robustness_evaluations_${method}_${j}.csv
    done

    for j in Continuous Ranking; do
        # Jester 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm Jester/Jester/robustness_weights_${method}_${j}.csv
        touch Jester/Jester/robustness_weights_${method}_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm Jester/Jester/robustness_evaluations_${method}_${j}.csv
        touch Jester/Jester/robustness_evaluations_${method}_${j}.csv
    done
done

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