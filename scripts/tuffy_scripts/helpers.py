"""
File containing helper functions specific for tuffy experiments that can be used by various scripts
"""

import sys
import os
import pandas as pd
import re

# Adds higher directory to python modules path.
sys.path.append("..")

from helpers import load_file

TUFFY_EXAMPLES_PATH = '../../tuffy-examples'


def get_num_weights(example_name):
    """
    :param example_name:
    :return:
    """
    count = 0
    with open(os.path.join(TUFFY_EXAMPLES_PATH, example_name, 'prog.mln'), 'r') as prog_file:
        for line in prog_file:
            pattern = re.compile("^-?[0-9]+")
            if pattern.match(line):
                count = count + 1

    return count


def write_learned_weights(weights, example_name):
    """
    :param weights:
    :param example_name:
    :return:
    """
    # path to this file relative to caller
    dirname = os.path.dirname(__file__)

    # tuffy example directory relative to this directory
    example_directory = os.path.join(dirname, TUFFY_EXAMPLES_PATH, example_name)

    # first copy over original prog.mln
    os.system('cd {};cp prog.mln {}-learned.mln'.format(example_directory, example_name))

    i = 1
    for weight in weights:
        # incrementally set the weights in the learned file to the learned weight and write to prog-learned.mln file
        os.system('cd ' + example_directory + ';awk -v inc=' + str(i) + ' -v new_weight="' + str(weight) +
                  ' " \'/^-?[0-9]+.[0-9]+ |^-?[0-9]+ /{c+=1}{if(c==inc){sub(/^-?[0-9]+.[0-9]+ |^-?[0-9]+ /, new_weight, $0)};print}\' "' +
                  example_name + '-learned.mln" > "tmp" && mv "tmp" "' + example_name + '-learned.mln"')
        i = i + 1


def load_results(tuffy_dir):
    results_path = os.path.join(tuffy_dir, 'inferred-predicates.txt')
    results_tmp = load_file(results_path)
    results = []

    for result in results_tmp:
        if len(result) == 1:
            # then we did not run in marginal mode, i.e. outputs in this file are all "true" or 1
            predicate = result[0][result[0].find("(") + 1:result[0].find(")")].replace(' ', '').split(',')
            predicate.append(1.0)
            results.append(predicate)
        else:
            # we ran this experiment in marginal mode, i.e., the marginal probability precedes the ground atom
            predicate = result[1][result[1].find("(") + 1:result[1].find(")")].replace(' ', '').split(',')
            predicate.append(result[0])
            results.append(predicate)

    return results


def load_prediction_frame(dataset, wl_method, evaluation_metric, fold, predicate):
    # path to this file relative to caller
    dirname = os.path.dirname(__file__)

    # read inferred and truth data
    tuffy_experiment_directory = "{}/../../results/weightlearning/tuffy/performance_study/{}/{}/{}/{}".format(
        dirname, dataset, wl_method, evaluation_metric, fold)

    results = load_results(tuffy_experiment_directory)
    predicted_df = pd.DataFrame(results)

    # clean up column names and set multi-index for predicate
    arg_columns = ['arg_' + str(col) for col in predicted_df.columns[:-1]]
    value_column = ['val']
    predicted_df.columns = arg_columns + value_column
    predicted_df = predicted_df.astype({col: int for col in arg_columns})
    predicted_df = predicted_df.set_index(arg_columns)

    return predicted_df