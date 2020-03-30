#!/usr/bin/env bash

# run weight learning performance experiments,
#i.e. collects runtime and evaluation statistics of various weight learning methods

readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BASE_OUT_DIR="${THIS_DIR}/../results/weightlearning/psl"

# readonly WL_METHODS='UNIFORM BOWLOS BOWLSS CRGS HB RGS LME MLE MPLE'
readonly WL_METHODS='UNIFORM BOWLOS BOWLSS CRGS HB RGS'
readonly SUPPORTED_EXAMPLES='citeseer cora epinions jester lastfm'

# Examples that cannot use int ids.
readonly STRING_IDS='entity-resolution simple-acquaintances user-modeling'

# Standard options for all examples and models
# note that this is assuming that we are only using datasets that have int-ids
readonly POSTGRES_DB='psl'
readonly STANDARD_PSL_OPTIONS="--postgres ${POSTGRES_DB} -D admmreasoner.initialconsensusvalue=ZERO -D log4j.threshold=TRACE"
# Random Seed is constant for performance experiments
readonly STANDARD_WEIGHT_LEARNING_OPTIONS='-D random.seed=4'

# The weight learning classes for each method
declare -A WEIGHT_LEARNING_METHODS
WEIGHT_LEARNING_METHODS[BOWLOS]='--learn org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior'
WEIGHT_LEARNING_METHODS[BOWLSS]='--learn org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior'
WEIGHT_LEARNING_METHODS[CRGS]='--learn org.linqs.psl.application.learning.weight.search.grid.ContinuousRandomGridSearch'
WEIGHT_LEARNING_METHODS[HB]='--learn org.linqs.psl.application.learning.weight.search.Hyperband'
WEIGHT_LEARNING_METHODS[RGS]='--learn org.linqs.psl.application.learning.weight.search.grid.RandomGridSearch'
WEIGHT_LEARNING_METHODS[LME]='--learn org.linqs.psl.application.learning.weight.search.grid.RandomGridSearch'
WEIGHT_LEARNING_METHODS[MLE]='--learn'
WEIGHT_LEARNING_METHODS[MPLE]='--learn org.linqs.psl.application.learning.weight.maxlikelihood.MaxPseudoLikelihood'
WEIGHT_LEARNING_METHODS[UNIFORM]='--learn'

# Options specific to each method (missing keys yield empty strings).
declare -A WEIGHT_LEARNING_METHOD_OPTIONS
WEIGHT_LEARNING_METHOD_OPTIONS[BOWLOS]='-D gpp.kernel=WEIGHTED_SQUARED_EXP -D gpp.earlyStopping=false -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D gppker.space=OS'
WEIGHT_LEARNING_METHOD_OPTIONS[BOWLSS]='-D gpp.kernel=WEIGHTED_SQUARED_EXP -D gpp.earlyStopping=false -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D gppker.space=SS'
WEIGHT_LEARNING_METHOD_OPTIONS[CRGS]='-D continuousrandomgridsearch.maxlocations=50'
WEIGHT_LEARNING_METHOD_OPTIONS[HB]=''
WEIGHT_LEARNING_METHOD_OPTIONS[RGS]='-D randomgridsearch.maxlocations=50'
WEIGHT_LEARNING_METHOD_OPTIONS[LME]='-D frankwolfe.maxiter=100 -D weightlearning.randomweights=true'
WEIGHT_LEARNING_METHOD_OPTIONS[MLE]='-D votedperceptron.numsteps=200 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=false -D votedperceptron.inertia=0.5 -D admmreasoner.initiallocalvalue=ATOM  votedperceptron.stepsize=1'
WEIGHT_LEARNING_METHOD_OPTIONS[MPLE]='-D votedperceptron.numsteps=100 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=true'
WEIGHT_LEARNING_METHOD_OPTIONS[UNIFORM]=''

# Weight learning methods that can optimize an arbitrary objective
readonly OBJECTIVE_LEARNERS='BOWLOS BOWLSS CRGS HB RGS'

# Options specific to each example (missing keys yield empty strings).
declare -A EXAMPLE_OPTIONS
EXAMPLE_OPTIONS[citeseer]='-D categoricalevaluator.defaultpredicate=hasCat'
EXAMPLE_OPTIONS[cora]='-D categoricalevaluator.defaultpredicate=hasCat'
EXAMPLE_OPTIONS[epinions]=''
EXAMPLE_OPTIONS[jester]=''
EXAMPLE_OPTIONS[lastfm]=''

# Evaluators to be use for each example
declare -A EXAMPLE_EVALUATORS
EXAMPLE_EVALUATORS[citeseer]='Categorical Discrete'
EXAMPLE_EVALUATORS[cora]='Categorical Discrete'
EXAMPLE_EVALUATORS[epinions]='Discrete Ranking'
EXAMPLE_EVALUATORS[jester]='Continuous Ranking'
EXAMPLE_EVALUATORS[lastfm]='Continuous Ranking'

# Evaluators to be use for each example
declare -A EXAMPLE_FOLDS
EXAMPLE_FOLDS[citeseer]=7
EXAMPLE_FOLDS[cora]=7
EXAMPLE_FOLDS[epinions]=7
EXAMPLE_FOLDS[jester]=7
EXAMPLE_FOLDS[lastfm]=4


function run() {
    local cliDir=$1
    local outDir=$2

    mkdir -p "${outDir}"

    local outPath="${outDir}/out.txt"
    local errPath="${outDir}/out.err"
    local timePath="${outDir}/time.txt"

    if [[ -e "${outPath}" ]]; then
        echo "Output file already exists, skipping: ${outPath}"
        return 0
    fi

    # note that this timing information includes both inference and weightlearning
    pushd . > /dev/null
        cd "${cliDir}" || exit
        /usr/bin/time -v --output="${timePath}" ./run.sh > "${outPath}" 2> "${errPath}"
    popd > /dev/null
    # note that this timing information includes both inference and weightlearning
#     pushd . > /dev/null
#         cd "${cliDir}" || exit
#         ./run.sh > "${outPath}" 2> "${errPath}"
#     popd > /dev/null
}

function run_example() {
    local example_directory=$1
    local wl_method=$2

    local exampleName
    exampleName=$(basename "${example_directory}")
    local cliDir="$example_directory/cli"

    # Check if uniform weight run
    if [[ "${wl_method}" == "UNIFORM" ]]; then
        # if so skip learning step
        deactivate_weight_learning $example_directory
    fi

    for evaluator in ${EXAMPLE_EVALUATORS[${exampleName}]}; do
        # modify runscript to run with the options for this study
        modify_run_script $example_directory $wl_method $evaluator

        for ((fold=0; fold<${EXAMPLE_FOLDS[${exampleName}]}; fold++)) do

            # Check if uniform weight run
            if [[ "${wl_method}" == "UNIFORM" ]]; then
                # if so, write uniform weights to -learned.psl file for evaluation
                write_uniform_learned_psl_file $example_directory
            fi

            echo "Running ${exampleName} ${evaluator} (#${fold}) -- ${wl_method}."
            outDir="${BASE_OUT_DIR}/performance_study/${exampleName}/${wl_method}/${evaluator}/${fold}"
            # modify data files to point to the fold
            modify_data_files $example_directory 0 $fold
            run  "${cliDir}" "${outDir}" "${fold}" "${wl_method}"
            # modify data files to point back to the 0'th fold
            modify_data_files $example_directory $fold 0
            # save inferred predicates
            mv "${cliDir}/inferred-predicates" "${outDir}/inferred-predicates"
            # save learned model
            mv "${cliDir}/${exampleName}-learned.psl" "${outDir}/${exampleName}-learned.psl"
        done
    done

    # Check if uniform weight run
    if [[ "${wl_method}" == "UNIFORM" ]]; then
        reactivate_weight_learning $example_directory
    fi
}

function deactivate_weight_learning() {
    local example_directory=$1
    local exampleName
    exampleName=$(basename "${example_directory}")

    # deactivate weight learning step in run script
    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # deactivate weight learning.
        sed -i 's/^\(\s\+\)runWeightLearning/\1# runWeightLearning/' run.sh

    popd > /dev/null
}

function reactivate_weight_learning() {
    local example_directory=$1
    local exampleName
    exampleName=$(basename "${example_directory}")

    # reactivate weight learning step in run script
    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # reactivate weight learning.
        sed -i 's/^\(\s\+\)# runWeightLearning/\1runWeightLearning/' run.sh

    popd > /dev/null
}

function write_uniform_learned_psl_file() {
    local example_directory=$1
    local exampleName
    exampleName=$(basename "${example_directory}")

    # write uniform weights as learned psl file
    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # set the weights in the learned file to 1 and write to learned.psl file
        sed -r "s/^[0-9]+.[0-9]+:|^[0-9]+:/1.0:/g"  "${exampleName}.psl" > "${exampleName}-learned.psl"

    popd > /dev/null
}

function modify_run_script() {
    local example_directory=$1
    local wl_method=$2
    local objective=$3

    local exampleName
    exampleName=$(basename "${example_directory}")
    local evaluator_options=''
    local int_ids_options=''

    # Check for objective learner.
    if [[ "${OBJECTIVE_LEARNERS}" == *"${wl_method}"* ]]; then
        evaluator_options="-D weightlearning.evaluator=org.linqs.psl.evaluation.statistics.${objective}Evaluator"
    fi

    # Check for int ids.
    if [[ "${STRING_IDS}" != *"${exampleName}"* ]]; then
        int_ids_options="--int-ids ${int_ids_options}"
    fi

    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # set the ADDITIONAL_LEARN_OPTIONS
        sed -i "s/^readonly ADDITIONAL_LEARN_OPTIONS='.*'$/readonly ADDITIONAL_LEARN_OPTIONS='${WEIGHT_LEARNING_METHODS[${wl_method}]} ${STANDARD_WEIGHT_LEARNING_OPTIONS} ${WEIGHT_LEARNING_METHOD_OPTIONS[${wl_method}]} ${EXAMPLE_OPTIONS[${exampleName}]} ${evaluator_options}'/" run.sh

        # set the ADDITIONAL_PSL_OPTIONS
        sed -i "s/^readonly ADDITIONAL_PSL_OPTIONS='.*'$/readonly ADDITIONAL_PSL_OPTIONS='${int_ids_options} ${STANDARD_PSL_OPTIONS}'/" run.sh

        # set the ADDITIONAL_EVAL_OPTIONS
        sed -i "s/^readonly ADDITIONAL_EVAL_OPTIONS='.*'$/readonly ADDITIONAL_EVAL_OPTIONS='--infer --eval org.linqs.psl.evaluation.statistics.${objective}Evaluator ${EXAMPLE_OPTIONS[${exampleName}]}'/" run.sh

    popd > /dev/null

}

function modify_data_files() {
    local example_directory=$1
    local old_fold=$2
    local new_fold=$3

    local exampleName=`basename ${example_directory}`

    pushd . > /dev/null
        cd "${example_directory}/cli" || exit

        # update the fold in the .data file
        sed -i "s/\/${old_fold}\//\/${new_fold}\//g" ${exampleName}-learn.data
        sed -i "s/\/${old_fold}\//\/${new_fold}\//g" ${exampleName}-eval.data
    popd > /dev/null
}

function main() {
    if [[ $# -eq 0 ]]; then
        echo "USAGE: $0 <example dir> ..."
        echo "USAGE: Example Directories can be among: ${SUPPORTED_EXAMPLES}"
        exit 1
    fi

    trap exit SIGINT

    for example_directory in "$@"; do
        for wl_method in ${WL_METHODS}; do
            run_example "${example_directory}" "${wl_method}"
        done
    done
}

main "$@"