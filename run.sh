#!/bin/bash

# Run all the experiments.

WEIGHT_LEARNING_DATASETS='citeseer cora epinions lastfm jester'

function main() {
    trap exit SIGINT

    # Fetch the data/models if they are not already present.
    if [ ! -e psl-examples ]; then
        echo "Models and data not found, fetching them."
        ./scripts/setup_psl_examples.sh
    fi

    local datasetPaths=''
    for dataset in $INFERENCE_DATASETS; do
        datasetPaths="${datasetPaths} psl-examples/${dataset}"
    done

    echo "Running inference experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
    ./scripts/run_weight_learning_performance_experiments.sh $datasetPaths

    echo "Running robustness experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
    ./scripts/run_weight_learning_robustness_experiments.sh $datasetPaths
}

main "$@"