import pandas as pd
import sys

# datasets = {'Jester': {'n_folds': 8,
#                        'evaluation_methods': ['MSE', 'AUROC']
#                       }, 
#             'Epinions': {'n_folds': 8,
#                          'evaluation_methods': ['F1', 'AUROC']
#                         },
#             'Cora': {'n_folds': 8, 
#                      'evaluation_methods': ['F1', 'Accuracy']
#                     },
#             'Citeseer': {'n_folds': 8, 
#                          'evaluation_methods': ['F1', 'Accuracy']
#                         },
#             'LastFM': {'n_folds': 5, 
#                        'evaluation_methods': ['MSE', 'AUROC']
#                       }
#            }

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
                        }
           }

# weight_learning_methods = ["BOWLSS", "BOWLOS", "LME", "MLE",
#            "MPLE", "RGS", "CRGS", "HB"]

weight_learning_methods = ["RGS", "CRGS", "HB"]


# build single dataframe for each dataset
for wl_method in weight_learning_methods:
    for dataset_name in datasets.keys():
        datasets[dataset_name]["dataframe"] = pd.DataFrame(index=range(datasets[dataset_name]["n_folds"]));
        for evaluation_method in datasets[dataset_name]["evaluation_methods"]:
            for wl_method in weight_learning_methods:
                results = pd.read_csv(dataset_name + "-" + wl_method + "-eval-" + evaluation_method + ".csv", header=None).values[0]
                results = results[:datasets[dataset_name]['n_folds']]
                datasets[dataset_name]["dataframe"][wl_method + "_" + evaluation_method] = results