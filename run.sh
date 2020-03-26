#!/usr/bin/env bash

# Run all the experiments.

#WEIGHT_LEARNING_DATASETS='citeseer cora epinions lastfm jester'
WEIGHT_LEARNING_DATASETS='jester'

function main() {
    trap exit SIGINT

    # dataset paths to pass to scripts
    psl_dataset_paths=''
    tuffy_dataset_paths=''
    for dataset in $WEIGHT_LEARNING_DATASETS; do
        psl_dataset_paths="${dataset_paths}psl-examples/${dataset} "
        tuffy_dataset_paths="${dataset_paths}tuffy-examples/${dataset} "
    done

    # PSL Experiments
    # Fetch the data and models if they are not already present and make some
    # modifactions to the run scripts and models.
    # required for both Tuffy and PSL experiments
    ./scripts/setup_psl_examples.sh

#    echo "Running psl performance experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
#    ./scripts/run_psl_weight_learning_performance_experiments.sh $psl_dataset_paths

#    echo "Running psl robustness experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
#    ./scripts/run_psl_weight_learning_robustness_experiments.sh $psl_dataset_paths


    # Tuffy Experiments
    # Initialize Tuffy environment
    ./scripts/tuffy_init.sh $dataset_paths

    # Convert psl formatted data into tuffy formatted data
    ./scripts/tuffy_convert.sh $dataset_paths

    # run tuffy performance experiments
    echo "Running tuffy performance experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
    ./scripts/run_tuffy_weight_learning_performance_experiments.sh $dataset_paths

#    echo "Running tuffy robustness experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
#    ./scripts/run_tuffy_weight_learning_robustness_experiments.sh $dataset_paths
}

main "$@"