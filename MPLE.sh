#Usage:
#./MPLE.sh DATASET_NAME.psl DATASET_NAME.data weightlearning.randomweights
java -jar psl-cli-2.3.0-SNAPSHOT.jar -learn org.linqs.psl.application.learning.weight.maxlikelihood.MaxPseudoLikelihood -model ${1} -data ${2} -l -D admmreasoner.initialconsensusvalue=ZERO -D votedperceptron.numsteps=100 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=${3}|tee mple_learn_${2}.log
