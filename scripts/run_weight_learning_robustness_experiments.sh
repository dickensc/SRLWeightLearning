#!/usr/bin/env bash

# run weight learning performance experiments,
#i.e. collects runtime and evaluation statistics of various weight learning methods

readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BASE_OUT_DIR="${THIS_DIR}/../results/weightlearning"

readonly WL_METHODS='BOWLOS BOWLSS CRGS HB RGS LME MLE MPLE'
readonly EXAMPLES='citeseer cora epinions jester lastfm'

readonly NUM_RUNS=100
readonly FOLD=0

# Examples that cannot use int ids.
readonly STRING_IDS='entity-resolution simple-acquaintances user-modeling'

# Standard options for all examples and models
# note that this is assuming that we are only using datasets that have int-ids
readonly POSTGRES_DB='psl'
readonly STANDARD_PSL_OPTIONS="--postgres ${POSTGRES_DB} -D admmreasoner.initialconsensusvalue=ZERO -D log4j.threshold=TRACE"
# Random Seed is constant for performance experiments
readonly STANDARD_WEIGHT_LEARNING_OPTIONS=''

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

# Options specific to each method (missing keys yield empty strings).
declare -A WEIGHT_LEARNING_METHOD_OPTIONS
WEIGHT_LEARNING_METHOD_OPTIONS[BOWLOS]='-D gpp.kernel=weightedSquaredExp -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D gppker.space=OS'
WEIGHT_LEARNING_METHOD_OPTIONS[BOWLSS]='-D gpp.kernel=weightedSquaredExp -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D gppker.space=SS'
WEIGHT_LEARNING_METHOD_OPTIONS[CRGS]='-D continuousrandomgridsearch.maxlocations=50'
WEIGHT_LEARNING_METHOD_OPTIONS[HB]=''
WEIGHT_LEARNING_METHOD_OPTIONS[RGS]='-D randomgridsearch.maxlocations=50'
WEIGHT_LEARNING_METHOD_OPTIONS[LME]='-D frankwolfe.maxiter=100 -D weightlearning.randomweights=true'
WEIGHT_LEARNING_METHOD_OPTIONS[MLE]='-D votedperceptron.numsteps=100 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=true'
WEIGHT_LEARNING_METHOD_OPTIONS[MPLE]='-D votedperceptron.numsteps=100 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=true'

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
EXAMPLE_EVALUATORS[citeseer]='Categorical'
EXAMPLE_EVALUATORS[cora]='Categorical'
EXAMPLE_EVALUATORS[epinions]='Discrete'
EXAMPLE_EVALUATORS[jester]='Continuous'
EXAMPLE_EVALUATORS[lastfm]='Continuous'

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
        cd "${cliDir}"
        /usr/bin/time -v --output="${timePath}" ./run.sh > "${outPath}" 2> "${errPath}"
    popd > /dev/null
}

function run_example() {
    local exampleDir=$1
    local wl_method=$2
    local iteration=$3

    local exampleName=`basename "${exampleDir}"`
    local cliDir="$exampleDir/cli"

    for evaluator in ${EXAMPLE_EVALUATORS[${exampleName}]}; do
        # modify runscript to run with the options for this study. iteration number will be used as random seed
        modify_run_script $exampleDir $wl_method $evaluator $iteration
        echo "Running Robustness Study On ${exampleName} ${evaluator} Iteration #${iteration} Fold #${FOLD} -- ${wl_method}."
        outDir="${BASE_OUT_DIR}/robustness_study/${exampleName}/${wl_method}/${evaluator}/${FOLD}"
        # modify data files to point to the fold
        modify_data_files $exampleDir 0 $FOLD
        run  "${cliDir}" "${outDir}" "${FOLD}" "${wl_method}"
        # modify data files to point back to the 0'th fold
        modify_data_files $exampleDir $FOLD 0
        # save inferred predicates
        mv "${cliDir}/inferred-predicates" "${outDir}/inferred-predicates"
        # save learned model
        mv "${cliDir}/${exampleName}-learned.psl" "${outDir}/${exampleName}-learned.psl"
    done
}

function modify_run_script() {
    local exampleDir=$1
    local wl_method=$2
    local objective=$3
    local seed=$4

    local exampleName=`basename ${exampleDir}`
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

        cd "${exampleDir}/cli"

        # set the ADDITIONAL_LEARN_OPTIONS
        sed "s/^readonly ADDITIONAL_LEARN_OPTIONS='.*'$/readonly ADDITIONAL_LEARN_OPTIONS='${WEIGHT_LEARNING_METHODS[${exampleName}]} ${STANDARD_WEIGHT_LEARNING_OPTIONS} ${WEIGHT_LEARNING_METHOD_OPTIONS[${exampleName}]} ${EXAMPLE_OPTIONS[${exampleName}]} ${evaluator_options} -D random.seed=${seed}'/" run.sh > run.sh

        # set the ADDITIONAL_PSL_OPTIONS
        sed "s/^readonly ADDITIONAL_PSL_OPTIONS='.*'$/readonly ADDITIONAL_PSL_OPTIONS='${int_ids_options} ${STANDARD_PSL_OPTIONS}'/" run.sh > run.sh

        # set the ADDITIONAL_EVAL_OPTIONS
        sed "s/^readonly ADDITIONAL_EVAL_OPTIONS='.*'$/readonly ADDITIONAL_EVAL_OPTIONS='--infer --eval org.linqs.psl.evaluation.statistics.${objective}Evaluator ${EXAMPLE_OPTIONS[${exampleName}]}'/" run.sh > run.sh

    popd > /dev/null

}

function modify_data_files() {
    local exampleDir=$1
    local old_fold=$2
    local new_fold=$3

    local exampleName=`basename ${exampleDir}`

    pushd . > /dev/null
        cd "${exampleDir}/cli"

        # update the fold in the .data file
        sed -i "" "s/\/${old_fold}\//\/${new_fold}\//g" ${exampleName}-learn.data
        sed -i "" "s/\/${old_fold}\//\/${new_fold}\//g" ${exampleName}-eval.data
    popd > /dev/null
}

function main() {
    if [[ $# -eq 0 ]]; then
        echo "USAGE: $0 <example dir> ..."
        echo "USAGE: Example Directories can be among: ${EXAMPLES}"
        exit 1
    fi

    trap exit SIGINT

    echo `seq -w 1 ${NUM_RUNS}`

    for i in `seq -w 1 ${NUM_RUNS}`; do
      echo "$i"
      for exampleDir in "$@"; do
          for wl_method in ${WL_METHODS}; do
              run_example "${exampleDir}" "${wl_method}"
          done
      done
    done
}

main "$@"