#!/usr/bin/python
import pandas as pd
import numpy as np
import sys
import os
import csv

# evaluators implemented for this study
from evaluators import evaluate_accuracy
from evaluators import evaluate_f1
from evaluators import evaluate_mse
from evaluators import evaluate_roc_auc_score

dataset_properties = {'jester': {'evaluation_predicate': 'rating'},
                      'epinions': {'evaluation_predicate': 'trusts'},
                      'cora': {'evaluation_predicate': 'hasCat'},
                      'citeseer': {'evaluation_predicate': 'hasCat'},
                      'lastFM': {'evaluation_predicate': 'rating'}}

evaluator_name_to_method = {
    'Categorical': evaluate_accuracy,
    'Discrete': evaluate_f1,
    'Continuous': evaluate_mse,
    'Ranking': evaluate_roc_auc_score
}


def load_truth_frame(dataset, fold, predicate):
    # truth dataframe 
    truth_path = "../psl-examples/{}/data/{}/{}/eval/{}_truth.txt".format(dataset, dataset, fold, predicate)
    truth_df = pd.read_csv(truth_path, sep='\t', header=None)
    
    # clean up column names and set multi-index for predicate
    arg_columns = ['arg_' + str(col) for col in truth_df.columns[:-1]]
    value_column = ['val']
    truth_df.columns = arg_columns + value_column
    truth_df = truth_df.astype({col: int for col in arg_columns})
    truth_df = truth_df.set_index(arg_columns)
    
    return truth_df


def load_observed_frame(dataset, fold, predicate):
    # observed dataframe 
    observed_path = "../psl-examples/{}/data/{}/{}/eval/{}_obs.txt".format(dataset, dataset, fold, predicate)
    observed_df = pd.read_csv(observed_path, sep='\t', header=None)
    
    # clean up column names and set multi-index for predicate
    arg_columns = ['arg_' + str(col) for col in observed_df.columns[:-1]]
    value_column = ['val']
    observed_df.columns = arg_columns + value_column
    observed_df = observed_df.astype({col: int for col in arg_columns})
    observed_df = observed_df.set_index(arg_columns)
    
    return observed_df


def load_psl_prediction_frame(dataset, wl_method, evaluation_metric, fold, predicate):
    
    # predicted dataframe 
    predicted_path = "../results/weightlearning/psl/performance_study/{}/{}/{}/{}/inferred-predicates/{}.txt".format(
        dataset, wl_method, evaluation_metric, fold, predicate.upper())
    predicted_df = pd.read_csv(predicted_path, sep='\t', header=None)

    # clean up column names and set multi-index for predicate
    arg_columns = ['arg_' + str(col) for col in predicted_df.columns[:-1]]
    value_column = ['val']
    predicted_df.columns = arg_columns + value_column
    predicted_df = predicted_df.astype({col: int for col in arg_columns})
    predicted_df = predicted_df.set_index(arg_columns)

    return predicted_df


def load_file(filename):
    output = []

    with open(filename, 'r') as tsvfile:
        reader = csv.reader(tsvfile, delimiter='\t')
        for line in reader:
            output.append(line)

    return output


def load_tuffy_results(tuffy_dir):
    results_path = os.path.join(tuffy_dir, 'inferred-predicates.txt')
    results_tmp = load_file(results_path)
    results = []
    
    for result in results_tmp:
        if len(result) == 1:
            # then we did not run in marginal mode, i.e. outputs in this file are all "true" or 1
            predicate = result[0][result[0].find("(")+1:result[0].find(")")].replace(' ', '').split(',')
            predicate.append(1.0)
            results.append(predicate)
        else:
            # we ran this experiment in marginal mode, i.e., the marginal probability precedes the ground atom
            predicate = result[1][result[1].find("(")+1:result[1].find(")")].replace(' ', '').split(',')
            predicate.append(result[0])
            results.append(predicate)

    return results


def load_tuffy_prediction_frame(dataset, wl_method, evaluation_metric, fold, predicate):
    
    # read inferred and truth data
    tuffy_experiment_directory = "../results/weightlearning/tuffy/performance_study/{}/{}/{}/{}".format(
        dataset, wl_method, evaluation_metric, fold)

    results = load_tuffy_results(tuffy_experiment_directory)
    predicted_df = pd.DataFrame(results)

    # clean up column names and set multi-index for predicate
    arg_columns = ['arg_' + str(col) for col in predicted_df.columns[:-1]]
    value_column = ['val']
    predicted_df.columns = arg_columns + value_column
    predicted_df = predicted_df.astype({col: int for col in arg_columns})
    predicted_df = predicted_df.set_index(arg_columns)

    return predicted_df


def main(method):
    # in results/weightlearning/{}/performance_study write 
    # a performance.csv file with columns 
    # Dataset | WL_Method | Evaluation_Method | Mean | Standard_Deviation
    
    # we are going to overwrite the file with all the most up to date information
    
    performance_frame = pd.DataFrame(columns=['Dataset', 'Wl_Method', 'Evaluation_Method',
                                              'Mean', 'Standard_Deviation'])
    
    # extract all the files that are in the results directory
    path = '../results/weightlearning/{}/performance_study'.format(method)
    datasets = [dataset for dataset in os.listdir(path) if os.path.isdir(os.path.join(path, dataset))]
    
    # iterate over all datasets adding the results to the performance_frame
    for dataset in datasets:
        # extract all the wl_methods that are in the directory
        path = '../results/weightlearning/{}/performance_study/{}'.format(method, dataset)
        wl_methods = [wl_method for wl_method in os.listdir(path) if os.path.isdir(os.path.join(path, wl_method))]
        
        for wl_method in wl_methods:
            # extract all the metrics that are in the directory
            path = '../results/weightlearning/{}/performance_study/{}/{}'.format(method, dataset, wl_method)
            evaluators = [evaluator for evaluator in os.listdir(path) if os.path.isdir(os.path.join(path, evaluator))]

            for evaluator in evaluators:
                # extract all the folds that are in the directory
                path = '../results/weightlearning/{}/performance_study/{}/{}/{}'.format(method, dataset, wl_method, evaluator)
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
                                                                     dataset_properties[dataset]['evaluation_predicate'])
                        elif method == 'tuffy':
                            predicted_df = load_tuffy_prediction_frame(dataset, wl_method, evaluator, fold, 
                                                                       dataset_properties[dataset]['evaluation_predicate'])
                        else:
                            raise IllegalArgumentError("{} not supported. Try: ['psl', 'tuffy']".format(method))
                    except FileNotFoundError as err:
                        print(err)
                        continue
                    
                    # truth dataframe 
                    truth_df = load_truth_frame(dataset, fold, dataset_properties[dataset]['evaluation_predicate'])
                    # observed dataframe
                    observed_df = load_observed_frame(dataset, fold, dataset_properties[dataset]['evaluation_predicate'])
                    
                    experiment_performance = np.append(experiment_performance, 
                                                       evaluator_name_to_method[evaluator](predicted_df, truth_df, observed_df))
    
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
                
    # write results frame to results/weightlearning/{}/performance_study
    performance_frame.to_csv('../results/weightlearning/{}/performance_study/{}_performance.csv'.format(method, method),
                             index=False)


def _load_args(args):
    executable = args.pop(0)
    if len(args) != 1 or ({'h', 'help'} & {arg.lower().strip().replace('-', '') for arg in args}):
        print("USAGE: python3 {} <method>".format(executable), file = sys.stderr)
        sys.exit(1)

    method = args.pop(0)

    return method


if (__name__ == '__main__'):
    method = _load_args(sys.argv)
    main(method)
