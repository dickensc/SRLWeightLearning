#!/usr/bin/env bash

# runs psl weight learning,

readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BASE_EXAMPLE_DIR="${THIS_DIR}/../../psl-examples"

readonly SUPPORTED_WL_METHODS='UNIFORM BOWLOS BOWLSS CRGS HB RGS LME MLE MPLE'
readonly SUPPORTED_EXAMPLES='citeseer cora epinions jester lastfm'

# Examples that cannot use int ids.
readonly STRING_IDS='entity-resolution simple-acquaintances user-modeling'

# Standard options for all examples and models
# note that this is assuming that we are only using datasets that have int-ids
# todo: (Charles D.) break this assumption
readonly POSTGRES_DB='psl'
readonly STANDARD_PSL_OPTIONS="--postgres ${POSTGRES_DB} -D log4j.threshold=INFO"
# Random Seed is constant for performance experiments
readonly WEIGHT_LEARNING_SEED='-D random.seed='

# The weight learning classes for each method
declare -A WEIGHT_LEARNING_METHODS
WEIGHT_LEARNING_METHODS[BOWLOS]='--learn org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior'
WEIGHT_LEARNING_METHODS[BOWLSS]='--learn org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior'
WEIGHT_LEARNING_METHODS[CRGS]='--learn org.linqs.psl.application.learning.weight.search.grid.ContinuousRandomGridSearch'
WEIGHT_LEARNING_METHODS[HB]='--learn org.linqs.psl.application.learning.weight.search.Hyperband'
WEIGHT_LEARNING_METHODS[RGS]='--learn org.linqs.psl.application.learning.weight.search.grid.RandomGridSearch'
WEIGHT_LEARNING_METHODS[LME]='--learn'
WEIGHT_LEARNING_METHODS[MLE]='--learn'
WEIGHT_LEARNING_METHODS[MPLE]='--learn org.linqs.psl.application.learning.weight.maxlikelihood.MaxPseudoLikelihood'
WEIGHT_LEARNING_METHODS[UNIFORM]=''

# Options specific to each method (missing keys yield empty strings).
declare -A WEIGHT_LEARNING_METHOD_OPTIONS
WEIGHT_LEARNING_METHOD_OPTIONS[BOWLOS]='-D admmreasoner.initialconsensusvalue=ZERO -D gpp.kernel=weightedSquaredExp -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D gppker.space=OS'
WEIGHT_LEARNING_METHOD_OPTIONS[BOWLSS]='-D admmreasoner.initialconsensusvalue=ZERO -D gpp.kernel=weightedSquaredExp -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D gppker.space=SS'
WEIGHT_LEARNING_METHOD_OPTIONS[CRGS]='-D admmreasoner.initialconsensusvalue=ZERO -D continuousrandomgridsearch.maxlocations=50'
WEIGHT_LEARNING_METHOD_OPTIONS[HB]='-D admmreasoner.initialconsensusvalue=ZERO'
WEIGHT_LEARNING_METHOD_OPTIONS[RGS]='-D admmreasoner.initialconsensusvalue=ZERO -D randomgridsearch.maxlocations=50'
WEIGHT_LEARNING_METHOD_OPTIONS[LME]='-D admmreasoner.initialconsensusvalue=ZERO -D frankwolfe.maxiter=100 -D weightlearning.randomweights=true'
WEIGHT_LEARNING_METHOD_OPTIONS[MLE]='-D admmreasoner.initialconsensusvalue=ZERO -D votedperceptron.zeroinitialweights=true -D votedperceptron.numsteps=100 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=true'
WEIGHT_LEARNING_METHOD_OPTIONS[MPLE]='-D votedperceptron.zeroinitialweights=true -D votedperceptron.numsteps=100 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=true'
WEIGHT_LEARNING_METHOD_OPTIONS[UNIFORM]='-D admmreasoner.initialconsensusvalue=ZERO'

# Weight learning methods that can optimize an arbitrary objective
readonly OBJECTIVE_LEARNERS='BOWLOS BOWLSS CRGS HB RGS'

# Options specific to each example (missing keys yield empty strings).
declare -A EXAMPLE_OPTIONS
EXAMPLE_OPTIONS[citeseer]='-D categoricalevaluator.defaultpredicate=hasCat'
EXAMPLE_OPTIONS[cora]='-D categoricalevaluator.defaultpredicate=hasCat'
EXAMPLE_OPTIONS[epinions]=''
EXAMPLE_OPTIONS[jester]=''
EXAMPLE_OPTIONS[lastfm]=''

function run() {
    local cli_directory=$1

    pushd . > /dev/null
        cd "${cli_directory}" || exit
        ./run.sh
    popd > /dev/null
}

function run_weight_learning() {
    local example_name=$1
    local fold=$2
    local seed=$3
    local study=$4
    local wl_method=$5
    local evaluator=$6
    local out_directory=$7

    local example_directory="${BASE_EXAMPLE_DIR}/${example_name}"
    local cli_directory="${example_directory}/cli"

    # Check if uniform weight run
    if [[ "${wl_method}" == "UNIFORM" ]]; then
        # if so, write uniform weights to -learned.psl file for evaluation
        write_uniform_learned_psl_file "$example_directory"

    elif [[ "${SUPPORTED_WL_METHODS}" == *"${wl_method}"* ]]; then
        # deactivate evaluation step in run script
        deactivate_evaluation "$example_directory"

        # modify runscript to run with the options for this study
        modify_run_script_options "$example_directory" "$wl_method" "$evaluator" "$seed"

        # modify data files to point to the fold
        modify_data_files "$example_directory" 0 "$fold"

        # run weight learning
        run  "${cli_directory}"

        # modify data files to point back to the 0'th fold
        modify_data_files "$example_directory" "$fold" 0

        # reactivate evaluation step in run script
        reactivate_evaluation "$example_directory"
    else

        echo "USAGE: Weight learning method: ${wl_method} not supported can be among: ${SUPPORTED_WL_METHODS}"
    fi

    # save learned model
    cp "${cli_directory}/${example_name}-learned.psl" "${out_directory}/${example_name}-learned.psl"

    return 0
}

function deactivate_evaluation() {
    local example_directory=$1
    local example_name
    example_name=$(basename "${example_directory}")

    # deactivate evaluation step in run script
    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # deactivate evaluation.
        sed -i 's/^\(\s\+\)runEvaluation/\1# runEvaluation/' run.sh

    popd > /dev/null
}

function reactivate_evaluation() {
    local example_directory=$1
    local example_name
    example_name=$(basename "${example_directory}")

    # reactivate evaluation step in run script
    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # reactivate evaluation.
        sed -i 's/^\(\s\+\)# runEvaluation/\1runEvaluation/' run.sh

    popd > /dev/null
}

function write_uniform_learned_psl_file() {
    local example_directory=$1
    local example_name
    example_name=$(basename "${example_directory}")

    # write uniform weights as learned psl file
    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # set the weights in the learned file to 1 and write to learned.psl file
        sed -r "s/^[0-9]+.[0-9]+:|^[0-9]+:/1.0:/g"  "${example_name}.psl" > "${example_name}-learned.psl"

    popd > /dev/null
}

function modify_run_script_options() {
    local example_directory=$1
    local wl_method=$2
    local objective=$3
    local seed=$4

    local example_name
    example_name=$(basename "${example_directory}")

    local evaluator_options=''
    local int_ids_options=''

    # Check for objective learner.
    if [[ "${OBJECTIVE_LEARNERS}" == *"${wl_method}"* ]]; then
        evaluator_options="-D weightlearning.evaluator=org.linqs.psl.evaluation.statistics.${objective}Evaluator"
    fi

    # Check for int ids.
    if [[ "${STRING_IDS}" != *"${example_name}"* ]]; then
        int_ids_options="--int-ids ${int_ids_options}"
    fi

    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # set the ADDITIONAL_LEARN_OPTIONS
        sed -i "s/^readonly ADDITIONAL_LEARN_OPTIONS='.*'$/readonly ADDITIONAL_LEARN_OPTIONS='${WEIGHT_LEARNING_METHODS[${wl_method}]} ${WEIGHT_LEARNING_SEED}${seed} ${WEIGHT_LEARNING_METHOD_OPTIONS[${wl_method}]} ${EXAMPLE_OPTIONS[${example_name}]} ${evaluator_options}'/" run.sh

        # set the ADDITIONAL_PSL_OPTIONS
        sed -i "s/^readonly ADDITIONAL_PSL_OPTIONS='.*'$/readonly ADDITIONAL_PSL_OPTIONS='${int_ids_options} ${STANDARD_PSL_OPTIONS}'/" run.sh
    popd > /dev/null
}

function modify_data_files() {
    local example_directory=$1
    local old_fold=$2
    local new_fold=$3

    local example_name
    example_name=$(basename "${example_directory}")

    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # update the fold in the .data file
        sed -i -E "s/${example_name}\/[0-9]+\/learn/${example_name}\/${new_fold}\/learn/g" "${example_name}"-learn.data
    popd > /dev/null
}

function main() {
    if [[ $# -ne 7 ]]; then
        echo "USAGE: $0 <example name> <fold> <seed> <study> <wl_method> <evaluator> <outDir>"
        echo "USAGE: Examples can be among: ${SUPPORTED_EXAMPLES}"
        echo "USAGE: Weight Learning methods can be among: ${SUPPORTED_WL_METHODS}"
        exit 1
    fi

    trap exit SIGINT

    run_weight_learning "$@"
}

main "$@"