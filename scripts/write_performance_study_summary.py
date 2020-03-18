import pandas as pd
import sys

datasets = {'Jester': {'n_folds': 8,
                       'evaluation_methods': ['MSE', 'AUROC']
                      }, 
            'Epinions': {'n_folds': 8,
                         'evaluation_methods': ['F1', 'AUROC']
                        },
            'Cora': {'n_folds': 8, 
                     'evaluation_methods': ['F1', 'Accuracy']
                    },
            'Citeseer': {'n_folds': 8, 
                         'evaluation_methods': ['F1', 'Accuracy']
                        },
            'LastFM': {'n_folds': 5, 
                       'evaluation_methods': ['MSE', 'AUROC']
                      }
           }

# weight_learning_methods = ["BOWLSS", "BOWLOS", "LME", "MLE",
#            "MPLE", "RGS", "CRGS", "HB"]

weight_learning_methods = ["RGS", "CRGS", "HB"]


# build single dataframe for each dataset
for dataset_name in datasets.keys():
    datasets[dataset_name]["dataframe"] = pd.DataFrame(index=range(datasets[dataset_name]["n_folds"]));
    datasets[dataset_name]["dataframe"].index.name = 'fold'
    for evaluation_method in datasets[dataset_name]["evaluation_methods"]:
        for wl_method in weight_learning_methods:
            results = pd.read_csv(dataset_name + '/' + dataset_name + "-" + wl_method + "-eval-" + evaluation_method + ".csv", header=None).values[0]
            results = results[:datasets[dataset_name]['n_folds']]
            datasets[dataset_name]["dataframe"][evaluation_method + "_" + wl_method] = results

columns=set()
for dataset_name in datasets.keys():
    for evaluation_method in datasets[dataset_name]["evaluation_methods"]:
        columns.add(dataset_name + '_' + evaluation_method + '_mean')
        columns.add(dataset_name + '_' + evaluation_method + '_standardDeviation')

performance_dataframe = pd.DataFrame(index=weight_learning_methods, columns=columns)
for wl_method in weight_learning_methods:
    for dataset_name in datasets.keys():
        for evaluation_method in datasets[dataset_name]["evaluation_methods"]:
            results = pd.read_csv(dataset_name + '/' + dataset_name + "-" + wl_method + "-eval-" + evaluation_method + ".csv", header=None).values[0]
            results = results[:datasets[dataset_name]['n_folds']]
            performance_dataframe.loc[wl_method, dataset_name + '_' + evaluation_method + '_mean'] = results.mean()
            performance_dataframe.loc[wl_method, dataset_name + '_' + evaluation_method + '_standardDeviation'] = results.std()
            
performance_dataframe = performance_dataframe.reindex(sorted(performance_dataframe.columns), axis=1)
performance_dataframe.to_csv("performance_study_results.csv")