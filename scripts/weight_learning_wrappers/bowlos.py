#!/usr/bin/python
"""
This file contains the driver and methods for running a BOWLOS search for an SRL model
Kernel is squared exp kernel
"""
import logging
import sys
import os
import numpy as np
import subprocess


# Adds higher directory to python modules path.
sys.path.append("..")

# logger helper method
from log import initLogging

# representative evaluators
from helpers import EVALUATE_METHOD

# eval predicates
from helpers import EVAL_PREDICATE

# is we want to minimize or maximize the metric
from helpers import IS_HIGHER_REP_BETTER

# non SRL method specific helpers
from helpers import load_truth_frame
from helpers import load_observed_frame
from helpers import load_target_frame
from helpers import load_wrapper_args

# SRL method specific helper methods
from psl_scripts.helpers import write_learned_weights as write_learned_psl_weights
from tuffy_scripts.helpers import write_learned_weights as write_learned_tuffy_weights

from psl_scripts.helpers import get_num_weights as get_num_psl_weights
from tuffy_scripts.helpers import get_num_weights as get_num_tuffy_weights

from psl_scripts.helpers import load_prediction_frame as load_psl_prediction_frame
from tuffy_scripts.helpers import load_prediction_frame as load_tuffy_prediction_frame

# dict to access the specific srl method needed for bowlos
HELPER_METHODS = {'tuffy': {'get_num_weights': get_num_tuffy_weights,
                            'write_learned_weights': write_learned_tuffy_weights,
                            'load_prediction_frame': load_tuffy_prediction_frame
                            },
                  'psl': {'get_num_weights': get_num_psl_weights,
                          'write_learned_weights': write_learned_psl_weights,
                          'load_prediction_frame': load_psl_prediction_frame,
                          }
                  }

# Bowlos configurations
MAX_ITERATIONS = 50
EARLY_STOPPING = True
MAX = 1.0
MIN = 0.0
MAX_CONFIGS = 1000000
MAX_RAND_INT_VAL = 100000000
EXPLORATION = 10
RELDEP = 1


def exponential_cov(x, y, params):
    return params[0] * np.exp(-0.5 * params[1] * np.subtract.outer(x, y)**2)


def predict(x, data, kernel, params, sigma, t):
    k = [kernel(x, y, params) for y in data]
    Sinv = np.linalg.inv(sigma)
    y_pred = np.dot(k, Sinv).dot(t)
    sigma_new = kernel(x, x, params) - np.dot(k, Sinv).dot(k)
    return y_pred, sigma_new


def main(srl_method_name, evaluator_name, example_name, fold, seed, study, out_directory):
    """
    Driver for BOWLOS weight learning
    :param srl_method_name:
    :param evaluator_name:
    :param example_name:
    :param fold:
    :param seed:
    :param study:
    :param out_directory:
    :return:
    """
    # path to this file relative to caller
    dirname = os.path.dirname(__file__)

    # Initialize logging level, switch to DEBUG for more info.
    initLogging(logging_level=logging.INFO)

    logging.info("Performing BowlOS on {}:{}:{}".format(srl_method_name, evaluator_name, example_name))

    # model specific parameters
    num_weights = HELPER_METHODS[srl_method_name]['get_num_weights'](example_name)
    predicate = EVAL_PREDICATE[example_name]

    logging.info("Optimizing over {} weights".format(num_weights))

    # the dataframes we will be using for evaluation
    truth_df = load_truth_frame(example_name, fold, predicate, 'learn')
    observed_df = load_observed_frame(example_name, fold, predicate, 'learn')
    target_df = load_target_frame(example_name, fold, predicate, 'learn')

    get_function_value = write_get_function_value_fun(srl_method_name, example_name, fold, seed, evaluator_name,
                                                      out_directory, study, truth_df, observed_df, target_df)


def get_random_configs(num_weights):
    configs = []
    for i in np.arange(MAX_CONFIGS) :
        cur_config = np.zeros(num_weights)
        cur_config[i] = {"val": 0,
                         "std": 1,
                         "config": []}
        for j in np.arange(num_weights) :
            cur_config[i]["config"].append((np.random.randint(MAX_RAND_INT_VAL) + 1) / (MAX_RAND_INT_VAL + 1))
        configs.append(cur_config)

    return configs


def get_next_point(configs) :
    best_config = -1
    cur_best_val = -np.inf

    for i in np.arange(len(configs)):
        cur_val = (configs[i]["val"] / EXPLORATION) + configs[i]["std"]
        if (best_config == -1) or (cur_val > cur_best_val):
            cur_best_val = cur_val
            best_config = i

    return best_config


def write_get_function_value_fun(srl_method_name, example_name, fold, seed, evaluator_name,
                       out_directory, study, truth_df, observed_df, target_df):

    def get_function_value (config):
        # path to this file relative to caller
        dirname = os.path.dirname(__file__)

        weights = config["config"]

        predicate = EVAL_PREDICATE[example_name]

        logging.info("Trying Configuration: {}".format(weights))

        # assign weight configuration to the model file
        HELPER_METHODS[srl_method_name]['write_learned_weights'](weights, example_name)

        # perform inference
        # TODO: (Charles.) psl file structure needs to fit this pattern: wrapper_learn
        logging.info("writing to {}".format(out_directory))
        process = subprocess.Popen('cd {}/../{}_scripts; ./run_inference.sh {} {} {} {} {}'.format(
            dirname, srl_method_name, example_name, 'wrapper_learn', fold, evaluator_name, out_directory),
            shell=True)
        logging.info("Waiting for inference")
        process.wait()

        # fetch results
        if study == "robustness_study":
            predicted_df = HELPER_METHODS[srl_method_name]['load_prediction_frame'](example_name, 'BOWLOS', evaluator_name,
                                                                                    seed, predicate, study)
        else:
            predicted_df = HELPER_METHODS[srl_method_name]['load_prediction_frame'](example_name, 'BOWLOS', evaluator_name,
                                                                                    fold, predicate, study)

        performance = EVALUATE_METHOD[evaluator_name](predicted_df, truth_df, observed_df, target_df)

        logging.info("Configuration Performance: {}: {}".format(evaluator_name, performance))

        # update best weight configuration if improved
        if IS_HIGHER_REP_BETTER[evaluator_name]:
            return performance
        else:
            return - 1.0 * performance

    return get_function_value


def kernel(pt1, pt2):
    pt1 = np.array(pt1) - np.array(pt2)
    diff = pt1

    return np.exp(-0.5 * RELDEP * np.linalg.norm(diff))

def predictFnValAndStd(x, xKnown, xyStdData, kernelBuffer1, kernelBuffer2, kernelMatrixShell1,
                       kernelMatrixShell2, xyStdMatrixShell, mulBuffer):

    ValueAndStd fnAndStd = new ValueAndStd();

    for (int i = 0; i < xyStdData.length; i++) {
        xyStdData[i] = kernel.kernel(x, xKnown.get(i).config, kernelBuffer1, kernelBuffer2, kernelMatrixShell1, kernelMatrixShell2);
    }
    xyStdMatrixShell.assume(xyStdData, 1, xyStdData.length);

    FloatMatrix xyStd = xyStdMatrixShell;

    FloatMatrix product = xyStd.mul(knownDataStdInv, mulBuffer, false, false, 1.0f, 0.0f);

    fnAndStd.value = product.dot(blasYKnown);
    fnAndStd.std = kernel.kernel(x, x, kernelBuffer1, kernelBuffer2, kernelMatrixShell1, kernelMatrixShell2) - product.dot(xyStd);

    return fnAndStd;


def doLearn(evaluator_name, num_weights, seed, get_function_value):
    explored_configs = []
    explored_fn_val = []

    # initial state
    np.random.seed(int(seed))
    best_config = None
    best_val = 0.0
    all_std_small = False

    configs = get_random_configs(num_weights)

    iteration = 0
    while (iteration < MAX_ITERATIONS) and not (EARLY_STOPPING and all_std_small) :
        next_point = get_next_point(configs)
        config = configs.pop(next_point)

        fn_val = get_function_value(config)
        explored_fn_val.append(fn_val)
        config["value"] = fn_val
        config["std"] = 0.0
        explored_configs.append(config)

        if (best_config is None) or (fn_val > best_val):
            best_val = fn_val
            best_config = config

        log.info("Iteration {} -- Config Picked: {}, Current Best Config: {}.".format(
            (iteration + 1), exploredConfigs.get(iteration), best_config))

        num_known = len(explored_fn_val)
        known_data_std_inv = np.zeros((num_known, num_known))
        for i in np.arange(num_known):
            for j in np.arange(num_known):
                known_data_std_inv[i, j] = kernel(explored_configs[i]["config"], explored_configs[j]["config"])

        known_data_std_inv = np.linalg.inv(known_data_std_inv)
        blasYKnown = np.copy(explored_fn_val)

        xyStdData = np.zeros(blasYKnown.shape[0])
        xyStdMatrixShell = np.array([])
        kernelBuffer1 = np.zeros(num_weights)
        kernelBuffer2 = np.zeros(num_weights)
        kernelMatrixShell1 = np.array([])
        kernelMatrixShell2 = np.array([])
        mulBuffer = np.zeros(blasYKnown.shape[0])

        for i in np.arange(len(configs)):
            configs[i]["val"], configs[i]["std"]= predictFnValAndStd(configs[index]["config"], explored_configs,
                                                                     xyStdData, kernelBuffer1, kernelBuffer2,
                                                                     kernelMatrixShell1, kernelMatrixShell2,
                                                                     xyStdMatrixShell, mulBuffer)

        // Early stopping check.
        allStdSmall = true;
        for (int i = 0; i < configs.size(); i++) {
            if (configs.get(i).valueAndStd.std > SMALL_VALUE) {
                allStdSmall = false;
                break;
            }
        }

        iteration++;
    }

    setWeights(bestConfig);
    log.info(String.format("Total number of iterations completed: %d. Stopped early: %s.",
            iteration, (earlyStopping && allStdSmall)));
    log.info("Best config: " + bestConfig);


if __name__ == '__main__':
    srl_method, evaluator, example, fold, seed, study, out_directory = load_wrapper_args(sys.argv)
    main(srl_method, evaluator, example, fold, seed, study, out_directory)
