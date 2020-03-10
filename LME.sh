#Usage:
#./LME.sh DATASET_NAME.psl DATASET_NAME.data
AVAILABLE_MEM_KB=$(cat /proc/meminfo | grep 'MemTotal' | sed 's/^[^0-9]\+\([0-9]\+\)[^0-9]\+$/\1/')
JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))

java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar psl-cli-max-margin.jar -learn org.linqs.psl.application.learning.weight.maxmargin.FrankWolfe -model ${5}/${1} -data ${5}/${2} -l -D random.seed=${4} -D admmreasoner.initialconsensusvalue=ZERO -D frankwolfe.maxiter=100 -D weightlearning.randomweights=${3}|tee ${5}/lme_learn_${2}.log