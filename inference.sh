##Usage:
#./inference.sh DATASET_NAME.psl DATASET_NAME.data METRIC_TO_USE ADD_STR_OUTPUT
#There are four metrics supported: Categorical, Discrete, Ranking, and Continuous
#Categorical is for Citeseer and Cora only
#
java -jar psl-cli-2.3.0-SNAPSHOT.jar -infer -model ${1} -data ${2} -output inferred-predicates -D admmreasoner.initialconsensusvalue=ZERO -e org.linqs.psl.evaluation.statistics.${3}Evaluator -D categoricalevaluator.defaultpredicate=hasCat |tee run_eval_${4}_${2}_${3}.out
