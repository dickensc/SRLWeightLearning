#!/usr/bin/python
"""
This file contains the driver and methods for running a random grid search for an SRL model
"""
import logging
import sys
import os
import numpy as np


# Adds higher directory to python modules path.
sys.path.append("..")

# logger helper method
from log import initLogging

# representative evaluators
from helpers import EVALUATE_METHOD

# eval predicates
from helpers import EVAL_PREDICATE

# non SRL method specific helpers
from helpers import load_truth_frame
from helpers import load_observed_frame
from helpers import load_target_frame

# SRL method specific helper methods
from psl_scripts.helpers import write_learned_weights as write_learned_psl_weights
from tuffy_scripts.helpers import write_learned_weights as write_learned_tuffy_weights

from psl_scripts.helpers import get_num_weights as get_num_psl_weights
from tuffy_scripts.helpers import get_num_weights as get_num_tuffy_weights

from psl_scripts.helpers import load_prediction_frame as load_psl_prediction_frame
from tuffy_scripts.helpers import load_prediction_frame as load_tuffy_prediction_frame

# dict to access the specific srl method needed for RGS
HELPER_METHODS = {'tuffy': {'get_num_weights': get_num_tuffy_weights,
                            'write_learned_weights': write_learned_tuffy_weights,
                            'load_prediction_frame': load_tuffy_prediction_frame
                            },
                  'psl': {'get_num_weights': get_num_psl_weights,
                          'write_learned_weights': write_learned_psl_weights,
                          'load_prediction_frame': load_psl_prediction_frame,
                          }
                  }


def main(srl_method_name, evaluator_name, example_name, fold, out_directory):
    """
    Driver for RGS weight learning
    :param srl_method_name:
    :param evaluator_name:
    :param example_name:
    :param fold:
    :param out_directory:
    :return:
    """
    # path to this file relative to caller
    dirname = os.path.dirname(__file__)

    # Initialize logging level, switch to DEBUG for more info.
    initLogging(logging_level=logging.INFO)

    logging.info("Performing RGS on {}:{}:{}".format(srl_method_name, evaluator_name, example_name))

    # the same grid as the default psl core implementation of RGS
    # TODO: (Charles D.) Verify
    grid = [1, 10, 100]

    # the same number of iterations as the default psl core implementation of RGS
    # TODO: (Charles D.) Verify
    n = 2

    # model specific parameters
    num_weights = HELPER_METHODS[srl_method_name]['get_num_weights'](example_name)
    predicate = EVAL_PREDICATE[example_name]

    # the dataframe we will be using as ground truth for this process
    truth_df = load_truth_frame(example_name, fold, predicate, 'learn')
    observed_df = load_observed_frame(example_name, fold, predicate, 'learn')
    target_df = load_target_frame(example_name, fold, predicate, 'learn')

    # initial state
    # TODO: (Charles.) Check if is less or more is better for this evaluator
    best_performance = -np.inf
    best_weights = np.zeros(num_weights)

    for i in range(n):
        logging.info("Iteration {}".format(i))

        # obtain a random weight configuration for the model
        weights = np.random.choice(grid, num_weights)
        logging.info("Trying Configuration: {}".format(weights))

        # assign weight configuration to the model file
        HELPER_METHODS[srl_method_name]['write_learned_weights'](weights, example_name)

        # perform inference
        # TODO: psl file structure needs to fit this pattern: wrapper_learn
        os.system('cd {}/../{}_scripts; ./run_inference.sh {} {} {} {} {}'.format(
            dirname, srl_method_name, example_name, 'wrapper_learn', fold, evaluator_name, out_directory))

        # fetch results
        predicted_df = HELPER_METHODS[srl_method_name]['load_prediction_frame'](example_name, 'RGS', evaluator_name,
                                                                                fold, predicate)
        performance = EVALUATE_METHOD[evaluator_name](predicted_df, truth_df, observed_df, target_df)

        logging.info("Configuration Performance: {}: {}".format(evaluator_name, performance))

        # update best weight configuration if improved
        # TODO: (Charles.) Check if is less or more is better for this evaluator
        if performance > best_performance:
            best_performance = performance
            best_weights = weights

    # assign best weight configuration to the model file
    HELPER_METHODS[srl_method_name]['write_learned_weights'](best_weights, example_name)


def _load_args(args):
    executable = args.pop(0)
    if len(args) < 5 or ({'h', 'help'} & {arg.lower().strip().replace('-', '') for arg in args}):
        print("USAGE: python3 {} <srl method name> <evaluator name> <example_name> <fold> <out_directory>... <additional inference script args>".format(
            executable), file=sys.stderr)
        sys.exit(1)

    srl_method_name = args.pop(0)
    evaluator_name = args.pop(0)
    example_name = args.pop(0)
    fold = args.pop(0)
    out_directory = args.pop(0)

    return srl_method_name, evaluator_name, example_name, fold, out_directory


if __name__ == '__main__':
    srl_method, evaluator, example, fold, out_directory = _load_args(sys.argv)
    main(srl_method, evaluator, example, fold, out_directory)