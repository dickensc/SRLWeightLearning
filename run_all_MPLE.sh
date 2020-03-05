weightlearning_randomweights="false"
seed=4

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./run_i_MPLE.sh ${i} ${weightlearning_randomweights} ${seed};done