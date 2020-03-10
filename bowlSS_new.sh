#Usage:
#./bowlSS_learn.sh DATASET_NAME.psl DATASET_NAME.data METRIC_TO_USE
#There are four metrics supported: Categorical, Discrete, Ranking, and Continuous
#Categorical is for Citeseer and Cora only
#
JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))

java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar psl-cli-2.2.0-SNAPSHOT.jar -learn -model ${5}/${1} -data ${5}/${2} -l org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior -D gpp.kernel=weightedSquaredExp -D random.seed=${3} -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D admmreasoner.initialconsensusvalue=ZERO -D weightlearning.evaluator=org.linqs.psl.evaluation.statistics.${4}Evaluator -D categoricalevaluator.defaultpredicate=hasCat -D gpp.acqFun=${4} -D random.seed=100 --postgres psl | tee ${5}/bowlSS_new_learn.log
