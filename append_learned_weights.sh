methods='RGS MPLE MLE LME HB CRGS BOWLSS BOWLOS'

for method in $methods; do
    for j in Categorical Discrete; do
        # Citeseer 
        # add weights to weight files for each dataset and weightlearning method and metric
        awk -F ':' '{ print $1 }' Citeseer-learned-${method}-0-${j}.psl | tr '\n' ',' | sed 's/,$/\n/' >> Citeseer/Citeseer/robustness_weights_${j}.csv

        # add evaluations to evaluation files for each dataset and weightlearning method and metric

        rm Citeseer/Citeseer/robustness_weights_${j}.csv
        touch Citeseer/Citeseer/robustness_weights_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm Citeseer/Citeseer/robustness_evaluations_${j}.csv
        touch Citeseer/Citeseer/robustness_evaluations_${j}.csv
    done

    for j in Categorical Discrete; do
        # Cora 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm Cora/Cora/robustness_weights_${j}.csv
        touch Cora/Cora/robustness_weights_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm Cora/Cora/robustness_evaluations_${j}.csv
        touch Cora/Cora/robustness_evaluations_${j}.csv
    done

    for j in Ranking Discrete; do
        # Epinions 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm Epinions/Epinions/robustness_weights_${j}.csv
        touch Epinions/Epinions/robustness_weights_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm Epinions/Epinions/robustness_evaluations_${j}.csv
        touch Epinions/Epinions/robustness_evaluations_${j}.csv
    done

    for j in Continuous Ranking; do
        # LastFM 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm LastFM/LastFM/robustness_weights_${j}.csv
        touch LastFM/LastFM/robustness_weights_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm LastFM/LastFM/robustness_evaluations_${j}.csv
        touch LastFM/LastFM/robustness_evaluations_${j}.csv
    done

    for j in Continuous Ranking; do
        # Jester 
        # clear and make new weight files for each dataset and weightlearning method and metric
        rm Jester/Jester/robustness_weights_${j}.csv
        touch Jester/Jester/robustness_weights_${j}.csv

        # clear and make new evaluation files for each dataset and weightlearning method and metric
        rm Jester/Jester/robustness_evaluations_${j}.csv
        touch Jester/Jester/robustness_evaluations_${j}.csv
    done
done