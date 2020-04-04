#!/usr/bin/env bash

# run weight learning performance experiments,
#i.e. collects runtime and evaluation statistics of various weight learning methods

readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BASE_EXAMPLE_DIR="${THIS_DIR}/../../tuffy-examples"

# the misc tuffy folder
readonly TUFFY_RESOURCES_DIR="${THIS_DIR}/../../tuffy_resources"
readonly TUFFY_CONFIG="${TUFFY_RESOURCES_DIR}/tuffy.conf"
readonly TUFFY_JAR="${TUFFY_RESOURCES_DIR}/tuffy.jar"

# readonly WL_METHODS='UNIFORM DiagonalNewton CRGS HB RGS'
readonly WL_METHODS='UNIFORM'

# set of currently supported PSL examples
readonly SUPPORTED_EXAMPLES='citeseer cora epinions jester lastfm'
#readonly SUPPORTED_WL_METHODS='UNIFORM DiagonalNewton CRGS HB RGS'
readonly SUPPORTED_WL_METHODS='UNIFORM'

# Weight learning methods that are built in to Tuffy
readonly BUILT_IN_LEARNERS='DiagonalNewton'

# Options specific to each example (missing keys yield empty strings).
declare -A EXAMPLE_OPTIONS
EXAMPLE_OPTIONS[citeseer]=''
EXAMPLE_OPTIONS[cora]=''
EXAMPLE_OPTIONS[epinions]=''
EXAMPLE_OPTIONS[jester]='-marginal'
EXAMPLE_OPTIONS[lastfm]='-marginal'

#readonly AVAILABLE_MEM_KB=$(cat /proc/meminfo | grep 'MemTotal' | sed 's/^[^0-9]\+\([0-9]\+\)[^0-9]\+$/\1/')
## Floor by multiples of 5 and then reserve an additional 5 GB.
#readonly JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))
readonly JAVA_MEM_GB=8


function run_inference() {
    local example_name=$1
    local fold=$2
    local evaluator=$3
    local out_directory=$4

    local example_directory="${BASE_EXAMPLE_DIR}/${example_name}"

    # run tuffy inference
    local prog_file="${example_directory}/${example_name}-learned.mln"
    local evidence_file="${example_directory}/data/${example_name}/${fold}/eval/evidence.db"
    local query_file="${example_directory}/data/${example_name}/${fold}/eval/query.db"
    local results_file="${out_directory}/inferred-predicates.txt"

    java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar "$TUFFY_JAR" -mln "$prog_file" -evidence "$evidence_file" -queryFile "$query_file" -r "$results_file" -conf "$TUFFY_CONFIG" ${EXAMPLE_OPTIONS[${example_name}]} -verbose 3
}

function main() {
    if [[ $# -ne 4 ]]; then
        echo "USAGE: $0 <example name> <fold> <evaluator> <out directory>"
        echo "USAGE: Examples can be among: ${SUPPORTED_EXAMPLES}"
        exit 1
    fi

    trap exit SIGINT

    run_inference "$@"
}

main "$@"