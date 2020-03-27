#!/usr/bin/env bash

# run weight learning performance experiments,
#i.e. collects runtime and evaluation statistics of various weight learning methods

readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BASE_OUT_DIR="${THIS_DIR}/../results/weightlearning/tuffy"

# path to the PSL to tuffy helper files
readonly PSL_TO_TUFFY_HELPER_PATH="${BASE_DIR}/psl_to_tuffy_examples"

# readonly WL_METHODS='UNIFORM CRGS HB RGS'
readonly WL_METHODS='UNIFORM'
readonly SUPPORTED_EXAMPLES='citeseer cora epinions jester lastfm'

# Examples that cannot use int ids.
readonly STRING_IDS='entity-resolution simple-acquaintances user-modeling'

# Standard options for all examples and models
# note that this is assuming that we are only using datasets that have int-ids
readonly POSTGRES_DB='psl_to_tuffy_examples'
readonly STANDARD_TUFFY_OPTIONS="--postgres ${POSTGRES_DB}"

# Weight learning methods that can optimize an arbitrary objective
readonly OBJECTIVE_LEARNERS='CRGS HB RGS'

# Options specific to each example (missing keys yield empty strings).
declare -A EXAMPLE_OPTIONS
EXAMPLE_OPTIONS[citeseer]=''
EXAMPLE_OPTIONS[cora]=''
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

#     # note that this timing information includes both inference and weightlearning
#     pushd . > /dev/null
#         cd "${cliDir}" || exit
#         /usr/bin/time -v --output="${timePath}" ./run.sh > "${outPath}" 2> "${errPath}"
#     popd > /dev/null
    # note that this timing information includes both inference and weightlearning
    pushd . > /dev/null
        cd "${cliDir}" || exit
        ./run.sh > "${outPath}" 2> "${errPath}"
    popd > /dev/null
}

function run_example() {
    local exampleDir=$1
    local wl_method=$2

    local exampleName
    exampleName=$(basename "${exampleDir}")

    for evaluator in ${EXAMPLE_EVALUATORS[${exampleName}]}; do
        for ((fold=0; fold<${EXAMPLE_FOLDS[${exampleName}]}; fold++)) do

            outDir="${BASE_OUT_DIR}/performance_study/${exampleName}/${wl_method}/${evaluator}/${fold}"

            echo "Running ${exampleName} ${evaluator} (#${fold}) -- ${wl_method}."
            # Check if uniform weight run
            if [[ "${wl_method}" == "UNIFORM" ]]; then
                # if so, write uniform weights to -learned.psl file for evaluation
                write_uniform_learned_tuffy_file "${exampleDir}"
            else
                run_tuffy_wl "${exampleDir}" "${outDir}" "${fold}" "${wl_method}"
            fi

            run_tuffy_inference "${exampleDir}" "${outDir}" "${fold}" "${wl_method}"
        done
    done

}

function run_tuffy_inference() {
    local exampleDir=$1
    local outDir=$2

    mkdir -p "$outDir"

    local outPath="${outDir}/out.txt"
    local errPath="${outDir}/out.err"
    local timePath="${outDir}/time.txt"

    if [[ -e "$outPath" ]]; then
        echo "Output file already exists, skipping: ${outPath}"
        return 0
    fi



    # save inferred predicates
    mv "${cliDir}/inferred-predicates" "${outDir}/inferred-predicates"
    # save learned model
    mv "${cliDir}/${exampleName}-learned.psl" "${outDir}/${exampleName}-learned.psl"
}

function run_tuffy_wl() {
    #TODO, right now it merely does uniform weight learning
    write_uniform_learned_tuffy_file "$@"
}

function write_uniform_learned_tuffy_file() {
    local example_directory=$1
    local exampleName
    exampleName=$(basename "${example_directory}")

    # write uniform weights as learned psl file
    pushd . > /dev/null
        cd "${example_directory}" || exit

        # set the weights in the learned file to 1 and write to learned.psl file
        sed -r "s/^[0-9]+.[0-9]+:|^[0-9]+:/1.0:/g"  "prog.mln" > "prog-learned.mln"

    popd > /dev/null
}

function main() {
    if [[ $# -eq 0 ]]; then
        echo "USAGE: $0 <example dir> ..."
        echo "USAGE: Example Directories can be among: ${SUPPORTED_EXAMPLES}"
        exit 1
    fi

    trap exit SIGINT

    for exampleDir in "$@"; do
        for wl_method in ${WL_METHODS}; do
            run_example "${exampleDir}" "${wl_method}"
        done
    done
}

main "$@"