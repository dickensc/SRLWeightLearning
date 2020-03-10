methods='RGS MPLE MLE LME HB CRGS BOWLSS BOWLOS'

for method in $methods; do
    for j in Categorical Discrete; do
        # Citeseer 
        # add weights to weight files for each dataset and weightlearning method and metric
        awk '/:/ {print $0}' Citeseer/Citeseer-learned-${method}-0-${j}.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> Citeseer/robustness_weights_${method}_${j}.csv

        # add evaluations to evaluation files for each dataset and weightlearning method and metric
        grep -o "Accuracy: ......." Citeseer/run_eval_${method}_Citeseer-eval-0.data_${j}.out | sed "s/Accuracy: //g" >> Citeseer/robustness_evaluations_${method}_${j}.csv
    done

    for j in Categorical Discrete; do
        # Cora
        # add weights to weight files for each dataset and weightlearning method and metric
        awk '/:/ {print $0}' Cora/Cora-learned-${method}-0-${j}.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> Cora/robustness_weights_${method}_${j}.csv
        
        # add evaluations to evaluation files for each dataset and weightlearning method and metric
        grep -o "Accuracy: ......." Cora/run_eval_${method}_Cora-eval-0.data_${j}.out | sed "s/Accuracy: //g" >> Cora/robustness_evaluations_${method}_${j}.csv
    done

    for j in Ranking Discrete; do
        # Epinions 
        # add weights to weight files for each dataset and weightlearning method and metric
        awk '/:/ {print $0}' Epinions/Epinions-learned-${method}-0-${j}.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> Epinions/robustness_weights_${method}_${j}.csv

        # add evaluations to evaluation files for each dataset and weightlearning method and metric
        grep -o "Accuracy: ......." Epinions/run_eval_${method}_Epinions-eval-0.data_${j}.out | sed "s/Accuracy: //g" >> Epinions/robustness_evaluations_${method}_${j}.csv
    done

    for j in Continuous Ranking; do
        # LastFM 
        # add weights to weight files for each dataset and weightlearning method and metric
        awk '/:/ {print $0}' LastFM/LastFM-learned-${method}-0-${j}.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> LastFM/robustness_weights_${method}_${j}.csv
        
        # add evaluations to evaluation files for each dataset and weightlearning method and metric
        grep -o "Accuracy: ......." LastFM/run_eval_${method}_LastFM-eval-0.data_${j}.out | sed "s/Accuracy: //g" >> LastFM/robustness_evaluations_${method}_${j}.csv
    done

    for j in Continuous Ranking; do
        # Jester 
        # Jester 
        # add weights to weight files for each dataset and weightlearning method and metric
        awk '/:/ {print $0}' Jester/Jester-learned-${method}-0-${j}.psl | awk -F ':' '{ print $1 }' | tr '\n' ',' | sed 's/,$/\n/' >> Jester/robustness_weights_${method}_${j}.csv
        
        # add evaluations to evaluation files for each dataset and weightlearning method and metric
        grep -o "Accuracy: ......." Jester/run_eval_${method}_Jester-eval-0.data_${j}.out | sed "s/Accuracy: //g" >> Jester/robustness_evaluations_${method}_${j}.csv
    done
done