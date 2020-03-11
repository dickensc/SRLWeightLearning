#Usage:
#./MLE.sh DATASET_NAME.psl DATASET_NAME.data weightlearning.randomweights
AVAILABLE_MEM_KB=$(cat /proc/meminfo | grep 'MemTotal' | sed 's/^[^0-9]\+\([0-9]\+\)[^0-9]\+$/\1/')
JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))

java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar psl-cli-2.2.0-SNAPSHOT.jar -learn -model ${5}/${1} -data ${5}/${2} -l -D random.seed=${4} -D admmreasoner.initialconsensusvalue=ZERO -D votedperceptron.numsteps=100 -D votedperceptron.stepsize=1.0 -D weightlearning.randomweights=${3} --postgres psl -D log4j.threshold=TRACE | tee ${5}/mle_learn_${2}.log