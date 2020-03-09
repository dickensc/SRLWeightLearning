#Usage:
#./CRGS.sh DATASET_NAME.psl DATASET_NAME.data random.seed Evaluator
java -jar psl-cli-2.2.0-SNAPSHOT.jar -learn org.linqs.psl.application.learning.weight.search.grid.ContinuousRandomGridSearch -D continuousrandomgridsearch.maxlocations=50 -D random.seed=${3} -D weightlearning.evaluator=org.linqs.psl.evaluation.statistics.${4}Evaluator -D categoricalevaluator.defaultpredicate=hasCat -model ${1} -data ${2} -l -D admmreasoner.initialconsensusvalue=ZERO --postgres psl | tee crgs_learn_${2}.log