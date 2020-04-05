"""
Helper functions not specific to any experiment
"""

import csv
import os
import pandas as pd

# evaluator methods
from evaluators import evaluate_accuracy
from evaluators import evaluate_f1
from evaluators import evaluate_roc_auc_score
from evaluators import evaluate_mse

# dict to access the specific evaluator representative needed for weight learning
EVALUATE_METHOD = {'Categorical': evaluate_accuracy,
                   'Discrete': evaluate_f1,
                   'Ranking': evaluate_roc_auc_score,
                   'Continuous': evaluate_mse}

# dict to map the examples to their evaluation predicate
EVAL_PREDICATE = {'citeseer': 'hasCat',
                  'cora': 'hasCat',
                  'epinions': 'trusts',
                  'lastfm': 'rating',
                  'jester': 'rating'}


def load_file(filename):
    output = []

    with open(filename, 'r') as tsvfile:
        reader = csv.reader(tsvfile, delimiter='\t')
        for line in reader:
            output.append(line)

    return output


def load_observed_frame(dataset, fold, predicate, phase='eval'):
    # path to this file relative to caller
    dirname = os.path.dirname(__file__)

    observed_path = "{}/../psl-examples/{}/data/{}/{}/{}/{}_obs.txt".format(dirname, dataset, dataset, fold, phase, predicate)
    observed_df = pd.read_csv(observed_path, sep='\t', header=None)

    # clean up column names and set multi-index for predicate
    arg_columns = ['arg_' + str(col) for col in observed_df.columns[:-1]]
    value_column = ['val']
    observed_df.columns = arg_columns + value_column
    observed_df = observed_df.astype({col: int for col in arg_columns})
    observed_df = observed_df.set_index(arg_columns)

    return observed_df


def load_truth_frame(dataset, fold, predicate, phase='eval'):
    # path to this file relative to caller
    dirname = os.path.dirname(__file__)

    truth_path = "{}/../psl-examples/{}/data/{}/{}/{}/{}_truth.txt".format(dirname, dataset, dataset, fold, phase, predicate)
    truth_df = pd.read_csv(truth_path, sep='\t', header=None)

    # clean up column names and set multi-index for predicate
    arg_columns = ['arg_' + str(col) for col in truth_df.columns[:-1]]
    value_column = ['val']
    truth_df.columns = arg_columns + value_column
    truth_df = truth_df.astype({col: int for col in arg_columns})
    truth_df = truth_df.set_index(arg_columns)

    return truth_df