for method in $2; do

    # Citeseer 
    # add weights to weight files for each dataset and weightlearning method and metric
    awk '/:/ {print $0}' Citeseer/Citeseer-learned-${method}-${1}-Categorical.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> Citeseer/robustness_weights_${method}_Categorical.csv

    # add evaluations to evaluation files for each dataset and weightlearning method and metric
    grep -o "Accuracy: ......." Citeseer/run_eval_${method}_Citeseer-eval-${1}.data_Categorical.out | sed "s/Accuracy: //g" >> Citeseer/robustness_evaluations_${method}_${j}.csv

    # Cora
    # add weights to weight files for each dataset and weightlearning method and metric
    awk '/:/ {print $0}' Cora/Cora-learned-${method}-${1}-Categorical.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> Cora/robustness_weights_${method}_Categorical.csv

    # add evaluations to evaluation files for each dataset and weightlearning method and metric
    grep -o "Accuracy: ......." Cora/run_eval_${method}_Cora-eval-${1}.data_Categorical.out | sed "s/Accuracy: //g" >> Cora/robustness_evaluations_${method}_Categorical.csv

    # Epinions 
    # add weights to weight files for each dataset and weightlearning method and metric
    awk '/:/ {print $0}' Epinions/Epinions-learned-${method}-${1}-Discrete.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> Epinions/robustness_weights_${method}_Discrete.csv

    # add evaluations to evaluation files for each dataset and weightlearning method and metric
    grep -o "F1: ......." Epinions/run_eval_${method}_Epinions-eval-${1}.data_Discrete.out | sed "s/F1: //g" >> Epinions/robustness_evaluations_${method}_Discrete.csv

    # LastFM 
    # add weights to weight files for each dataset and weightlearning method and metric
    awk '/:/ {print $0}' LastFM/LastFM-learned-${method}-${1}-Continuous.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> LastFM/robustness_weights_${method}_Continuous.csv

    # add evaluations to evaluation files for each dataset and weightlearning method and metric
    grep -o "MSE: ......." LastFM/run_eval_${method}_LastFM-eval-${1}.data_Continuous.out | sed "s/MSE: //g" >> LastFM/robustness_evaluations_${method}_Continuous.csv

    # Jester 
    # add weights to weight files for each dataset and weightlearning method and metric
    awk '/:/ {print $0}' Jester/Jester-learned-${method}-${1}-Continuous.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> Jester/robustness_weights_${method}_Continuous.csv

    # add evaluations to evaluation files for each dataset and weightlearning method and metric
    grep -o "MSE: ......." Jester/run_eval_${method}_Jester-eval-${1}.data_Continuous.out | sed "s/MSE: //g" >> Jester/robustness_evaluations_${method}_Continuous.csv
done