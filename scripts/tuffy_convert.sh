#!/bin/bash

readonly THIS_DIR=$(realpath "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )")
readonly BASE_DIR="${THIS_DIR}/.."

readonly TUFFY_EXAMPLES_PATH="${BASE_DIR}/tuffy-examples"
readonly PSL_EXAMPLES_PATH="${BASE_DIR}/psl-examples"

function main() {
   trap exit SIGINT

   for dataset_path in "$@"; do
      experiment=$(basename "${dataset_path}")
      echo "INFO: Converting data for ${experiment}"
      convert_data_tuffy ${TUFFY_EXAMPLES_PATH} ${PSL_EXAMPLES_PATH} ${experiment}
   done
}

function convert_data_tuffy() {
   local tuffypath=$1
   local pslpath=$2
   local experiment=$3

   pushd . > /dev/null

     cd ${BASE_DIR}/scripts || exit 1
     python3 prepare-tuffy.py "${tuffypath}" "${pslpath}" "${experiment}"

   popd > /dev/null
}

main "$@"
