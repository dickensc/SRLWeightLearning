#!/usr/bin/env bash

# Run all the experiments.

#WEIGHT_LEARNING_DATASETS='citeseer cora epinions lastfm jester'
WEIGHT_LEARNING_DATASETS='jester'

function main() {
    trap exit SIGINT

    # Fetch the data and models if they are not already present.
    if [ ! -e psl-examples ]; then
        echo "Models and data not found, fetching them."
        ./scripts/setup_psl_examples.sh
    fi

    # write dataset paths to pass to scripts
    dataset_paths=''
    for dataset in $WEIGHT_LEARNING_DATASETS; do
        dataset_paths="${dataset_paths}psl-examples/${dataset} "
    done

    # PSL Experiments
    echo "Running psl performance experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
    ./scripts/run_psl_weight_learning_performance_experiments.sh $dataset_paths

#    echo "Running psl robustness experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
#    ./scripts/run_psl_weight_learning_robustness_experiments.sh $dataset_paths


    # Tuffy Experiments

    # Initialize Tuffy environment
    tuffy_init.sh $dataset_paths

    # Convert psl formatted data into tuffy formatted data
    tuffy_convert.sh $dataset_paths

    # run tuffy performance experiments
    echo "Running tuffy performance experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
    ./scripts/run_tuffy_weight_learning_performance_experiments.sh $dataset_paths

#    echo "Running tuffy robustness experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
#    ./scripts/run_tuffy_weight_learning_robustness_experiments.sh $dataset_paths
}

main "$@"