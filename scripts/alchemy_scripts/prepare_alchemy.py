#!/usr/bin/python

"""
This file contains methods for converting psl formatted data into psl_to_mln_examples formatted data.
"""

import csv
import logging
import os
import sys

# Adds higher directory to python modules path.
sys.path.append(".")

from log import initLogging

DATA = 'data'
# file name for the predicate information needed to translate from PSL to psl_to_mln_examples
# format: Name	Size	Open/Closed	Filename	Prior	Truth	Force  Target
PREDICATES_FILE = 'predicates.txt'
EVIDENCE_FILE = 'evidence.db'
QUERY_FILE = 'query.db'

EVAL = 'eval'
LEARN = 'learn'
BUILT_IN_LEARN = 'built_in_learn'
WRAPPER_LEARN = 'wrapper_learn'


FALSE = 'false'
TRUE = 'true'

# format for predicate information file
# Name	Size	Open/Closed	Filename	Prior	Truth	Force  Target
H_PRED = 0
H_SIZE = 1
H_OPEN = 2
H_FILE = 3
H_PRIOR = 4
H_TRUTH = 5
H_FORCE = 6
H_TARGET = 7


def write_data(data, path, out_file_name):
    os.makedirs(path, exist_ok=True)
    with open(os.path.join(path, out_file_name), 'w') as out_file:
        out_file.write('\n'.join(data))


def load_split(predicate, split):
    # dereference predicate information
    size = int(predicate[H_SIZE])
    pred = predicate[H_PRED]
    filename = predicate[H_FILE]
    prior = predicate[H_PRIOR]
    force = predicate[H_FORCE]

    if not os.path.isfile(os.path.join(split, filename)):
        logging.error("No file named %s in %s" % (filename, split))
        return

    # mln_data is an array of psl_to_mln_examples formatted evidence
    # predicate_data is an array of psl_to_mln_examples formatted queries
    mln_data = []
    predicate_data = []
    with open(os.path.join(split, filename), 'r') as tsvfile:
        reader = csv.reader(tsvfile, delimiter='\t')

        for line in reader:
            value = 1.0

            if force == TRUE:
                value = 1.0
            elif prior != FALSE:
                value = float(prior)
            elif len(line) > size:
                value = float(line[-1])

            predicate_data.append(pred + '(' + ', '.join(line[0:size]) + ')')
            if value == 1.0 or value == 1:
                mln_data.append(pred + '(' + ', '.join(line[0:size]) + ')')
            elif value == 0.0 or value == 0:
                mln_data.append('!' + pred + '(' + ', '.join(line[0:size]) + ')')
            else:
                # TODO(Charles): Continuous evidence is not supported in PSL to Alchemy translation.
                #  In cases where this is necessary, the evidence is incorporated as a prior in the model.
                continue

    return mln_data, predicate_data


def load_predicate_properties(helper_file):
    predicate_properties = []

    with open(helper_file, 'r') as tsvfile:
        reader = csv.reader(tsvfile, delimiter='\t')
        for line in reader:
            predicate_properties.append(line)

    return predicate_properties


def main(psl_to_alchemy_helper_dir, alchemy_experiment_dir, psl_experiment_dir, experiment):
    """
    Drive procedure for translating data in psl format to Alchemy format
    :param psl_to_alchemy_helper_dir:
    :param alchemy_experiment_dir:
    :param psl_experiment_dir:
    :param experiment:
    :return:
    """
    # Initialize logging level, switch to DEBUG for more info.
    initLogging(logging_level=logging.INFO)

    logging.info("Working on experiment %s" % experiment)

    # save experiment paths for psl_to_alchemy_examples and psl
    psl_to_alchemy_helper_experiment_path = os.path.join(psl_to_alchemy_helper_dir, experiment)
    alchemy_experiment_path = os.path.join(alchemy_experiment_dir, experiment)
    psl_experiment_path = os.path.join(psl_experiment_dir, experiment)

    predicate_properties = load_predicate_properties(os.path.join(psl_to_alchemy_helper_experiment_path, PREDICATES_FILE))

    # ensure that data set exists in the psl_experiment_path
    if experiment not in os.listdir(os.path.join(psl_experiment_path, DATA)):
        # data has not been fetched yet
        logging.info("%s data has not been fetched yet. Fetching ..." % experiment)

        # go to psl experiment directory and run fetch data script
        cwd = os.getcwd()
        os.chdir(os.path.join(psl_experiment_path, DATA))
        os.system(os.path.join(psl_experiment_path, DATA) + '/fetchData.sh')
        os.chdir(cwd)

    for split_dir in os.listdir(os.path.join(psl_experiment_path, DATA, experiment)):
        if (split_dir == EVAL) or (split_dir == LEARN):
            # data is not split into folds
            # i.e. the path looks like .../data/eval/ rather than .../data/0/eval/
            # TODO: Charles, handle this case
            continue

        for phase in [EVAL, BUILT_IN_LEARN, WRAPPER_LEARN]:
            logging.info("Translating %s PSL to Alchemy ..." % (experiment + ':' + split_dir + ':' + phase))

            if phase == EVAL:
                psl_phase = EVAL
            else:
                psl_phase = LEARN

            psl_split_path = os.path.join(psl_experiment_path, DATA, experiment, split_dir, psl_phase)
            alchemy_split_path = os.path.join(alchemy_experiment_path, DATA, experiment, split_dir, phase)
            evidence_data = []
            query_data = []

            if not os.path.isdir(psl_split_path):
                logging.error("No eval/learn in %s" % (os.path.join(psl_experiment_path, DATA, experiment, psl_phase)))
                continue

            for predicate in predicate_properties:
                split_data, predicate_data = load_split(predicate, psl_split_path)

                if predicate[H_TARGET] == TRUE:
                    # if the predicate is a target, then it should be in the Alchemy query file
                    query_data = query_data + predicate_data
                elif predicate[H_TRUTH] == TRUE:
                    if phase == BUILT_IN_LEARN:
                        # if the predicate is a truth, and its a built in learn trial,
                        # then it should be in the Alchemy evidence
                        evidence_data = evidence_data + split_data
                else: 
                    # if the predicate is neither truth or target, then its evidence and should be
                    # in the Alchemy evidence file
                    evidence_data = evidence_data + split_data

            write_data(query_data, alchemy_split_path, QUERY_FILE)
            write_data(evidence_data, alchemy_split_path, EVIDENCE_FILE)


def _load_args(args):
    """
    Load command line arguments
    :param args:
    :return: alchemy_dir, psl_dir, experiment
    """
    executable = args.pop(0)
    if (len(args) != 4) or ({'h', 'help'} & {arg.lower().strip().replace('-', '') for arg in args}):
        print("USAGE: python3 %s <psl_to_mln_helper_dir> <alchemy_dir> <psl_dir> <experiment>"
              % executable, file=sys.stderr)
        sys.exit(1)

    psl_to_mln_dir = args.pop(0)
    alchemy_exp_dir = args.pop(0)
    psl_exp_dir = args.pop(0)
    experiment = args.pop(0)

    return psl_to_mln_dir, alchemy_exp_dir, psl_exp_dir, experiment


if __name__ == '__main__':
    psl_to_mln_helper_dir, alchemy_experiment_dir, psl_experiment_dir, experiment_name = _load_args(sys.argv)
    main(psl_to_mln_helper_dir, alchemy_experiment_dir, psl_experiment_dir, experiment_name)
