#Usage:
#./CRGS.sh DATASET_NAME.psl DATASET_NAME.data random.seed Evaluator
JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))

java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar psl-cli-2.2.0-SNAPSHOT.jar -learn org.linqs.psl.application.learning.weight.search.grid.ContinuousRandomGridSearch -D continuousrandomgridsearch.maxlocations=50 -D random.seed=${3} -D weightlearning.evaluator=org.linqs.psl.evaluation.statistics.${4}Evaluator -D categoricalevaluator.defaultpredicate=hasCat -model ${5}/${1} -data ${5}/${2} -l -D admmreasoner.initialconsensusvalue=ZERO --postgres psl | tee ${5}/crgs_learn_${2}_${4}.log