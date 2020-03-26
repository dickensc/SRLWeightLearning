#!/bin/bash

readonly THIS_DIR=$(realpath "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )")
readonly BASE_DIR="${THIS_DIR}/.."

# Tuffy path variables
readonly TUFFY_EXAMPLES="${BASE_DIR}/tuffy-examples"
readonly TUFFY_URL="http://i.stanford.edu/hazy/tuffy/download/tuffy-0.4-july2014.zip"
readonly TUFFY_BIN="${BASE_DIR}/tuffy-0.3-jun2014"
readonly TUFFY_ZIP="${BASE_DIR}/tuffy-0.4-july2014.zip"

function main() {
  trap exit SIGINT

  echo "INFO: Working on setting up tuffy ${experiment}"

  # Make sure we can run tuffy.
  check_requirements

  # fetch tuffy
  tuffy_load

  # First begin by creating a postgreSQL database and user for tuffy
  tuffy_create_postgres_db

  # Create Tuffy Experiment Directory
  mkdir -p "${TUFFY_EXAMPLES}"

  # Fill tuffy experiment directory and fetch data required for tuffy
  for dataset_path in "$@"; do
    experiment=$(basename "${dataset_path}")
    get_data_tuffy "${TUFFY_EXAMPLES}/${experiment}"
  done
}

function tuffy_create_postgres_db() {
  echo "INFO: Creating tuffy postgres user and db..."
  psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='tuffy'" | grep -q 1 || createuser -s tuffy
  psql postgres -lqt | cut -d \| -f 1 | grep -qw tuffy || createdb tuffy
}

function tuffy_load() {
   echo "INFO: Fetching Tuffy..."
   if [ -f "${BASE_DIR}/tuffy.jar" ] ; then
      echo "Jar exists, skipping request"
      return
   fi

   curl -O ${TUFFY_URL}
   unzip ${TUFFY_ZIP}
   mv ${TUFFY_BIN}/tuffy.jar ${BASE_DIR}/tuffy.jar
   rm -r ${TUFFY_BIN}
   rm ${TUFFY_ZIP}
}

function get_data_tuffy() {
   local path=$1
   local experiment
   experiment=$(basename "${path}")

   mkdir -p "${path}"
   mkdir -p "${path}/data"

   if [ -d "${BASE_DIR}/scripts/tuffy/${experiment}" ] ; then
      cp -a "${BASE_DIR}/scripts/tuffy/${experiment}/." "${path}"
   else
      echo "ERROR: missing ${BASE_DIR}/scripts/tuffy/${experiment}"
      exit 1
   fi
}

function check_requirements() {
   local hasWget
   local hasCurl

   type wget > /dev/null 2> /dev/null
   hasWget=$?

   type curl > /dev/null 2> /dev/null
   hasCurl=$?

   if [[ "${hasWget}" -ne 0 ]] && [[ "${hasCurl}" -ne 0 ]]; then
      echo 'ERROR: wget or curl required to download dataset'
      exit 10
   fi

   type java > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      echo 'ERROR: java required to run project'
      exit 13
   fi

   type postgres > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      echo 'ERROR: postgres required to run project'
      exit 13
   fi
}

function get_fetch_command() {
   type curl > /dev/null 2> /dev/null
   if [[ "$?" -eq 0 ]]; then
      echo "curl -o"
      return
   fi

   type wget > /dev/null 2> /dev/null
   if [[ "$?" -eq 0 ]]; then
      echo "wget -O"
      return
   fi

   echo 'ERROR: wget or curl not found'
   exit 20
}


main "$@"
