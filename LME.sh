#Usage:
#./LME.sh DATASET_NAME.psl DATASET_NAME.data 
java -jar psl-cli-max-margin.jar -learn org.linqs.psl.application.learning.weight.maxmargin.FrankWolfe -model ${5}/${1} -data ${5}/${2} -l -D random.seed=${4} -D admmreasoner.initialconsensusvalue=ZERO -D frankwolfe.maxiter=100 -D weightlearning.randomweights=${3}|tee ${5}/lme_learn_${2}.log