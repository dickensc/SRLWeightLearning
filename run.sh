#!/usr/bin/env bash

# Run all the experiments.

#WEIGHT_LEARNING_DATASETS='citeseer cora epinions lastfm jester'
WEIGHT_LEARNING_DATASETS='epinions'

function main() {
    trap exit SIGINT

    # dataset paths to pass to scripts
    psl_dataset_paths=''
    tuffy_dataset_paths=''
    for dataset in $WEIGHT_LEARNING_DATASETS; do
        psl_dataset_paths="${psl_dataset_paths}psl-examples/${dataset} "
        tuffy_dataset_paths="${tuffy_dataset_paths}tuffy-examples/${dataset} "
    done

    # PSL Experiments
    # Fetch the data and models if they are not already present and make some
    # modifactions to the run scripts and models.
    # required for both Tuffy and PSL experiments
    ./scripts/setup_psl_examples.sh

    echo "Running psl performance experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
    # shellcheck disable=SC2086
    ./scripts/run_psl_weight_learning_performance_experiments.sh ${psl_dataset_paths}

#    echo "Running psl robustness experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
#    # shellcheck disable=SC2086
#    ./scripts/run_psl_weight_learning_robustness_experiments.sh ${psl_dataset_paths}


#    # Tuffy Experiments
#    # Initialize Tuffy environment
#    # shellcheck disable=SC2086
#    ./scripts/tuffy_init.sh ${tuffy_dataset_paths}
#
#    # Convert psl formatted data into psl_to_tuffy_examples formatted data
#    # shellcheck disable=SC2086
#    ./scripts/tuffy_convert.sh ${tuffy_dataset_paths}
#
#    # run psl_to_tuffy_examples performance experiments
#    echo "Running tuffy performance experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
#    # shellcheck disable=SC2086
#    ./scripts/run_tuffy_weight_learning_performance_experiments.sh ${tuffy_dataset_paths}

#    echo "Running psl_to_tuffy_examples robustness experiments on datasets: [${WEIGHT_LEARNING_DATASETS}]."
#    # shellcheck disable=SC2086
#    ./scripts/run_tuffy_weight_learning_robustness_experiments.sh ${tuffy_dataset_paths}
}

main "$@"