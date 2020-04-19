#!/usr/bin/python
import pandas as pd
import numpy as np
import sys
import os

# generic helpers
from helpers import load_truth_frame
from helpers import load_observed_frame
from helpers import load_target_frame

# helpers for experiment specific processing
from tuffy_scripts.helpers import load_prediction_frame as load_tuffy_prediction_frame
from psl_scripts.helpers import load_prediction_frame as load_psl_prediction_frame

# evaluators implemented for this study
from evaluators import evaluate_accuracy
from evaluators import evaluate_f1
from evaluators import evaluate_mse
from evaluators import evaluate_roc_auc_score

dataset_properties = {'jester': {'evaluation_predicate': 'rating'},
                      'epinions': {'evaluation_predicate': 'trusts'},
                      'cora': {'evaluation_predicate': 'hasCat'},
                      'citeseer': {'evaluation_predicate': 'hasCat'},
                      'lastfm': {'evaluation_predicate': 'rating'}}

evaluator_name_to_method = {
    'Categorical': evaluate_accuracy,
    'Discrete': evaluate_f1,
    'Continuous': evaluate_mse,
    'Ranking': evaluate_roc_auc_score
}


def main(method):
    # in results/weightlearning/{}/performance_study write 
    # a performance.csv file with columns 
    # Dataset | WL_Method | Evaluation_Method | Mean | Standard_Deviation
    
    # we are going to overwrite the file with all the most up to date information
    
    performance_frame = pd.DataFrame(columns=['Dataset', 'Wl_Method', 'Evaluation_Method',
                                              'Mean', 'Standard_Deviation'])
    
    # extract all the files that are in the results directory
    # path to this file relative to caller
    dirname = os.path.dirname(__file__)
    path = '{}/../results/weightlearning/{}/performance_study'.format(dirname, method)
    datasets = [dataset for dataset in os.listdir(path) if os.path.isdir(os.path.join(path, dataset))]
    
    # iterate over all datasets adding the results to the performance_frame
    for dataset in datasets:
        # extract all the wl_methods that are in the directory
        path = '{}/../results/weightlearning/{}/performance_study/{}'.format(dirname, method, dataset)
        wl_methods = [wl_method for wl_method in os.listdir(path) if os.path.isdir(os.path.join(path, wl_method))]
        
        for wl_method in wl_methods:
            # extract all the metrics that are in the directory
            path = '{}/../results/weightlearning/{}/performance_study/{}/{}'.format(dirname, method, dataset, wl_method)
            evaluators = [evaluator for evaluator in os.listdir(path) if os.path.isdir(os.path.join(path, evaluator))]

            for evaluator in evaluators:
                # extract all the folds that are in the directory
                path = '{}/../results/weightlearning/{}/performance_study/{}/{}/{}'.format(dirname, method, dataset, wl_method, evaluator)
                folds = [fold for fold in os.listdir(path) if os.path.isdir(os.path.join(path, fold))]
                
                # initialize the experiment list that will be populated in the following for 
                # loop with the performance outcome of each fold
                experiment_performance = np.array([])

                for fold in folds:
                    # load the prediction dataframe
                    try:
                        # prediction dataframe
                        if method == 'psl':
                            predicted_df = load_psl_prediction_frame(dataset, wl_method, evaluator, fold,
                                                                     "performance_study",
                                                                     dataset_properties[dataset]['evaluation_predicate'])
                        elif method == 'tuffy':
                            predicted_df = load_tuffy_prediction_frame(dataset, wl_method, evaluator, fold,
                                                                       "performance_study",
                                                                       dataset_properties[dataset]['evaluation_predicate'])
                        else:
                            raise ValueError("{} not supported. Try: ['psl', 'tuffy']".format(method))
                    except FileNotFoundError as err:
                        print(err)
                        continue
                    
                    # truth dataframe 
                    truth_df = load_truth_frame(dataset, fold, dataset_properties[dataset]['evaluation_predicate'])
                    # observed dataframe
                    observed_df = load_observed_frame(dataset, fold, dataset_properties[dataset]['evaluation_predicate'])
                    # target dataframe
                    target_df = load_target_frame(dataset, fold, dataset_properties[dataset]['evaluation_predicate'])

                    experiment_performance = np.append(experiment_performance, 
                                                       evaluator_name_to_method[evaluator](predicted_df,
                                                                                           truth_df,
                                                                                           observed_df,
                                                                                           target_df))
    
                # update the performance_frame
                performance_series = pd.Series(index=['Dataset', 'Wl_Method', 'Evaluation_Method',
                                                      'Mean', 'Standard_Deviation'],
                                               dtype=float)
                performance_series['Dataset'] = dataset
                performance_series['Wl_Method'] = wl_method
                performance_series['Evaluation_Method'] = evaluator
                performance_series['Mean'] = experiment_performance.mean()
                performance_series['Standard_Deviation'] = experiment_performance.std()
                
                performance_frame = performance_frame.append(performance_series, ignore_index=True)
    
    # add the percent increase for each dataset and evaluator
    performance_frame['PCT_Increase'] = 0
    for dataset in performance_frame.Dataset.unique():
        dataset_performance = performance_frame[performance_results.Dataset == dataset]
        for Evaluation_Method in dataset_performance.Evaluation_Method.unique():
            evaluator_performance = dataset_performance[dataset_performance.Evaluation_Method == Evaluation_Method]
            Uniform_performance = evaluator_performance[evaluator_performance.Wl_Method == "UNIFORM"].Mean.values[0]
            pct_increase = ((evaluator_performance.Mean - Uniform_performance) / Uniform_performance) * 100
            performance_frame.loc[evaluator_performance.index, "PCT_Improved"] = pct_increase
    
    # write results frame to results/weightlearning/{}/performance_study
    performance_frame.to_csv('{}/../results/weightlearning/{}/performance_study/{}_performance.csv'.format(dirname, method, method),
                             index=False)


def _load_args(args):
    executable = args.pop(0)
    if len(args) != 1 or ({'h', 'help'} & {arg.lower().strip().replace('-', '') for arg in args}):
        print("USAGE: python3 {} <SRL method>".format(executable), file = sys.stderr)
        sys.exit(1)

    method = args.pop(0)

    return method


if __name__ == '__main__':
    method = _load_args(sys.argv)
    main(method)
