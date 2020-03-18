This folder contains all the code to run the SRL weight Learning Experiments.

# Simple Execution
All experiments can be reproduced using the `run.sh` script in the top level of this repository
```
.\run.sh
```

# File explanation:

* `run.sh`
    * The `run.sh` script will fetch the necessary data and models and then run the PSL weight learing performance experiments and the PSL weight learning robustness experiments on the PSL example datasets citeseer, cora, epinions, lastfm, and jester

* `scripts/run_weight_learning_performance_experiments.sh`
    * This script will run the weight learning performance experiments on the datasets who's paths where provided via the command line argument
    * Weight learning and evaluation is completed across each of the example folds and the evaluation performance, inferred-predicates, and timing is recorded
    * Example Directories can be among: citeseer cora epinions jester lastfm
    
* `scripts/run_weight_learning_robustness_experiments.sh`
    * This script will run the weight learning robustness experiments on the datasets who's paths where provided via the command line argument
    * 100 iterations of weight learning on the 0^th fold of each dataset will be run and the resulting evaluation set performance and learned weights are recorded  
    * Example Directories can be among: citeseer cora epinions jester lastfm
    
* `scripts/setup_psl_examples.sh`
    * Fetches the PSL examples and modifies the CLI configuration for theses experiments
    
* `*.psl`
    * PSL model files. e.g. Citeseer.psl, Cora.psl, ...
    * fetched from 'https://github.com/linqs/psl-examples.git' repository in `scripts/setup_psl_examples.sh`
    
* `*.data`
    * data file required to run PSL. e.g. Citeseer-learn-0.data, Citeseer-eval-0.data,...
    * fetched from 'https://github.com/linqs/psl-examples.git' repository in `scripts/setup_psl_examples.sh`
    
    
* `data/`
    * folder containing all data.
    * fetched in the run scripts of the PSL examples in 'https://github.com/linqs/psl-examples.git'
    
* `psl-cli-2.2.0.jar` Jar file compiled using the code in psl_code.zip
