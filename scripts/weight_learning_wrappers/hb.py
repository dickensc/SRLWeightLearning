#!/usr/bin/python
"""
This file contains the driver and methods for running a continous random grid search for an SRL model
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

# dict to access the specific srl method needed for hb
HELPER_METHODS = {'tuffy': {'get_num_weights': get_num_tuffy_weights,
                            'write_learned_weights': write_learned_tuffy_weights,
                            'load_prediction_frame': load_tuffy_prediction_frame
                            },
                  'psl': {'get_num_weights': get_num_psl_weights,
                          'write_learned_weights': write_learned_psl_weights,
                          'load_prediction_frame': load_psl_prediction_frame,
                          }
                  }

# method specific option to pass to inference method to set the maximum number of iterations
MAX_ITER_OPTION = {'tuffy': "-maxFlips ",
                  'psl': "-D admmreasoner.maxiterations="
                  }

SURVIVAL_DEFAULT = 4
BASE_BRACKET_SIZE_DEFAULT = 10
NUM_BRACKETS_DEFAULT = 4
MIN_BRACKET_SIZE = 1
MIN_BUDGET_PROPORTION = 0.001
MAX_ITER_DEFAULT = {'tuffy': 25,
                    'psl': 25000}
MEAN = 0.50
VARIANCE = 0.10


def main(srl_method_name, evaluator_name, example_name, fold, out_directory):
    """
    Driver for CRGS weight learning
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

    logging.info("Performing Hyperband on {}:{}:{}".format(srl_method_name, evaluator_name, example_name))

    # model specific parameters
    num_weights = HELPER_METHODS[srl_method_name]['get_num_weights'](example_name)
    predicate = EVAL_PREDICATE[example_name]

    # parameters for sampling distribution
    mean_vector = np.array([MEAN]*num_weights)
    variance_matrix = np.eye(num_weights)*VARIANCE

    logging.info("Optimizing over {} weights".format(num_weights))

    # the dataframes we will be using for evaluation
    truth_df = load_truth_frame(example_name, fold, predicate, 'learn')
    observed_df = load_observed_frame(example_name, fold, predicate, 'learn')
    target_df = load_target_frame(example_name, fold, predicate, 'learn')

    def get_random_configuration():
        weights = np.random.multivariate_normal(mean_vector, variance_matrix)
        return weights

    def run_then_return_val_loss(num_iters, weights):
        # assign weight configuration to the model file
        HELPER_METHODS[srl_method_name]['write_learned_weights'](weights, example_name)

        # extra options to set max number of iterations
        extra_options = MAX_ITER_OPTION[srl_method_name] + str(int(np.ceil(num_iters)))

        # perform inference
        # TODO: (Charles.)  psl file structure needs to fit this pattern: wrapper_learn
        os.system('cd {}/../{}_scripts; ./run_inference.sh {} {} {} {} {} {}'.format(
            dirname, srl_method_name, example_name, 'wrapper_learn', fold,
            evaluator_name, out_directory, extra_options))

        # fetch results
        predicted_df = HELPER_METHODS[srl_method_name]['load_prediction_frame'](example_name, 'HB', evaluator_name,
                                                                                fold, predicate)

        # return negative since we are maximizing performance
        # TODO: (Charles.) Check if is less or more is better for this evaluator
        return -EVALUATE_METHOD[evaluator_name](predicted_df, truth_df, observed_df, target_df)

    max_iter = MAX_ITER_DEFAULT[srl_method_name]  # maximum iterations/epochs per configuration
    eta = SURVIVAL_DEFAULT  # defines downsampling rate (default=4)
    logeta = lambda x: np.log(x) / np.log(eta)
    s_max = int(logeta(max_iter))  # number of unique executions of Successive Halving (minus one)
    B = (s_max + 1) * max_iter  # total number of iterations (without reuse) per execution of Succesive Halving (n,r)

    # initialize
    best_val = np.inf
    best_weights = np.zeros(num_weights)

    # Begin Finite Horizon Hyperband outerloop.
    for s in reversed(range(s_max + 1)):
        n = int(np.ceil(int(B / max_iter / (s + 1)) * eta ** s))  # initial number of configurations
        r = max_iter * eta ** (-s)  # initial number of iterations to run configurations for

        # Begin Finite Horizon Successive Halving with (n,r)
        T = [get_random_configuration() for _ in range(n)]
        val_losses = []
        for i in range(s + 1):
            # Run each of the n_i configs for r_i iterations and keep best n_i/eta
            n_i = n * eta ** (-i)
            r_i = r * eta ** (i)
            val_losses = [run_then_return_val_loss(num_iters=r_i, weights=t) for t in T]
            T = [T[i] for i in np.argsort(val_losses)[0:int(np.ceil(n_i / eta))]]
            logging.info("Successive halving: (n,r) = ({}, {}) Bracket winners: Configs: {} Vals: {}".format(
                n_i, r_i, T, np.sort(val_losses)[0:int(np.ceil(n_i / eta))]))

        tournament_winning_val = min(val_losses)
        logging.info("Hyperband outerloop: (s) = ({}) Tournament winner: Config: {} Val:".format(
            s, T, tournament_winning_val))
        if tournament_winning_val < best_val:
            best_weights = T[0]

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