#Usage:
#./bowlSS_learn.sh DATASET_NAME.psl DATASET_NAME.data METRIC_TO_USE
#There are four metrics supported: Categorical, Discrete, Ranking, and Continuous
#Categorical is for Citeseer and Cora only
AVAILABLE_MEM_KB=$(cat /proc/meminfo | grep 'MemTotal' | sed 's/^[^0-9]\+\([0-9]\+\)[^0-9]\+$/\1/')
JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))

java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar psl-cli-2.2.0-SNAPSHOT.jar -learn -model ${5}/${1} -data ${5}/${2} -l org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior -D gpp.kernel=weightedSquaredExp -D random.seed=${3} -D gppker.reldep=1 -D gpp.explore=10 -D gpp.maxiter=50 -D admmreasoner.initialconsensusvalue=ZERO -D weightlearning.evaluator=org.linqs.psl.evaluation.statistics.${4}Evaluator -D categoricalevaluator.defaultpredicate=hasCat -D gppker.space=OS --postgres psl -D log4j.threshold=TRACE | tee ${5}/bowlOS_learn_${2}_${4}.log
