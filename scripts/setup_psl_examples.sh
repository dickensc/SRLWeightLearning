#!/usr/bin/env bash

# Fetch the PSL examples and modify the CLI configuration for these experiments.
# Note that you can change the version of PSL used with the PSL_VERSION option here.

readonly BASE_DIR=$(realpath "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/..)

readonly PSL_EXAMPLES_DIR="${BASE_DIR}/psl-examples"
readonly PSL_EXAMPLES_REPO='https://github.com/linqs/psl-examples.git'
readonly PSL_EXAMPLES_BRANCH='develop'

readonly PSL_VERSION='2.2.1'

readonly ER_DATA_SIZE='large'

#readonly AVAILABLE_MEM_KB=$(cat /proc/meminfo | grep 'MemTotal' | sed 's/^[^0-9]\+\([0-9]\+\)[^0-9]\+$/\1/')
## Floor by multiples of 5 and then reserve an additional 5 GB.
#readonly JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))

readonly JAVA_MEM_GB=8

function fetch_psl_examples() {
   if [ -e ${PSL_EXAMPLES_DIR} ]; then
      return
   fi

   git clone ${PSL_EXAMPLES_REPO} ${PSL_EXAMPLES_DIR}

   pushd . > /dev/null
      cd "${PSL_EXAMPLES_DIR}"
      git checkout ${PSL_EXAMPLES_BRANCH}
   popd > /dev/null
}

# Special fixes for select examples.
function special_fixes() {
   # Change the size of the ER example to the max size.
   sed -i "s/^readonly SIZE='.*'$/readonly SIZE='${ER_DATA_SIZE}'/" "${PSL_EXAMPLES_DIR}/entity-resolution/data/fetchData.sh"
}

# Common to all examples.
function standard_fixes() {
    for exampleDir in `find ${PSL_EXAMPLES_DIR} -maxdepth 1 -mindepth 1 -type d -not -name '.*'`; do
        local baseName=`basename ${exampleDir}`

        pushd . > /dev/null
            cd "${exampleDir}/cli"

            # Increase memory allocation.
            sed -i "s/java -jar/java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar/" run.sh

            # Set the PSL version.
            sed -i "s/^readonly PSL_VERSION='.*'$/readonly PSL_VERSION='${PSL_VERSION}'/" run.sh

        popd > /dev/null

    done
}

function main() {
   trap exit SIGINT

   fetch_psl_examples
   special_fixes
   standard_fixes

   exit 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"