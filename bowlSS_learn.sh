#Usage:
#./bowlSS_learn.sh DATASET_NAME.psl DATASET_NAME.data METRIC_TO_USE
#There are four metrics supported: Categorical, Discrete, Ranking, and Continuous
#Categorical is for Citeseer and Cora only
#
java -jar psl-cli-2.3.0-SNAPSHOT.jar -learn -model ${1} -data ${2} -l org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior -D gpp.kernel=weightedSquaredExp -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D admmreasoner.initialconsensusvalue=ZERO -D weightlearning.evaluator=org.linqs.psl.evaluation.statistics.${3}Evaluator -D categoricalevaluator.defaultpredicate=hasCat|tee bowlSS_learn_${2}_${3}.log
