#!/bin/bash

readonly THIS_DIR=$(realpath "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )")
readonly BASE_DIR="${THIS_DIR}/../.."

readonly PSL_TO_MLN_HELPER_PATH="${BASE_DIR}/psl_to_mln_examples"
readonly ALCHEMY_EXAMPLES_PATH="${BASE_DIR}/alchemy-examples"
readonly PSL_EXAMPLES_PATH="${BASE_DIR}/psl-examples"

function main() {
   trap exit SIGINT

   if [[ $# -eq 0 ]]; then
      echo "USAGE: $0 <example dir> ..."
      echo "USAGE: Example Directories can be among: ${SUPPORTED_EXAMPLES}"
      exit 1
   fi

   echo "$@"

   for dataset in "$@"; do
      dataset_path="${BASE_DIR}/${dataset}"
      experiment=$(basename "${dataset_path}")

      if [ ! -d "${ALCHEMY_EXAMPLES_PATH}/${experiment}" ]; then
        echo "INFO: Converting data for ${experiment}"
        # make the example directory
        mkdir -p "${dataset_path}"
        mkdir -p "${dataset_path}/data"
        copy_alchemy_model "${ALCHEMY_EXAMPLES_PATH}/${experiment}" "${PSL_TO_MLN_HELPER_PATH}/${experiment}"
        convert_data_alchemy "$PSL_TO_MLN_HELPER_PATH" "$ALCHEMY_EXAMPLES_PATH" "$PSL_EXAMPLES_PATH" "$experiment"
      else
        echo "INFO: Data for ${experiment} has already been converted from PSL to Alchemy. Skipping"
      fi
   done
}

function copy_alchemy_model() {
   local example_path=$1
   local model_path=$2
   local experiment
   experiment=$(basename "${example_path}")

   # copy the mln model to the example directory
   # We should have verified this exists in the init script
   cp -r "${model_path}/alchemy" "${example_path}/"
   mv "${example_path}/alchemy" "${example_path}/cli"
}

function convert_data_alchemy() {
   local psl_to_mln_helper_path=$1
   local alchemy_experiment_path=$2
   local psl_experiment_path=$3
   local experiment=$4

   pushd . > /dev/null

     cd ${BASE_DIR}/scripts || exit 1
     python3 "${THIS_DIR}"/prepare_alchemy.py "${psl_to_mln_helper_path}" "${alchemy_experiment_path}" "${psl_experiment_path}" "${experiment}" || exit 1

   popd > /dev/null
}

main "$@"
