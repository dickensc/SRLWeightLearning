#Usage:
#./MPLE.sh DATASET_NAME.psl DATASET_NAME.data weightlearning.randomweights
java -jar psl-cli-2.2.0-SNAPSHOT.jar -learn org.linqs.psl.application.learning.weight.maxlikelihood.MaxPseudoLikelihood -model ${5}/${1} -data ${5}/${2} -l -D random.seed=${4} -D admmreasoner.initialconsensusvalue=ZERO -D votedperceptron.numsteps=100 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=${3} --postgres psl | tee ${5}/mple_learn_${2}.log
