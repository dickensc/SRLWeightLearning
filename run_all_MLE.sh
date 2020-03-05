weightlearning_randomweights="false"

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./MLE.sh Citeseer.psl Citeseer-learn-${i}.data ${weightlearning_randomweights}; cp Citeseer-learned.psl Citeseer-learned-MLE-${i}.psl; ./inference.sh Citeseer-learned-MLE-${i}.psl Citeseer-eval-${i}.data Categorical MLE; ./inference.sh Citeseer-learned-MLE-${i}.psl Citeseer-eval-${i}.data Discrete MLE;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./MLE.sh Cora.psl Cora-learn-${i}.data ${weightlearning_randomweights}; cp Cora-learned.psl Cora-learned-MLE-${i}.psl; ./inference.sh Cora-learned-MLE-${i}.psl Cora-eval-${i}.data Categorical MLE; ./inference.sh Cora-learned-MLE-${i}.psl Cora-eval-${i}.data Discrete MLE;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./MLE.sh Epinions.psl Epinions-learn-${i}.data ${weightlearning_randomweights}; cp Epinions-learned.psl Epinions-learned-MLE-${i}.psl; ./inference.sh Epinions-learned-MLE-${i}.psl Epinions-eval-${i}.data Ranking MLE; ./inference.sh Epinions-learned-MLE-${i}.psl Epinions-eval-${i}.data Discrete MLE;done

for i in 0 1 2 3 4 ; do echo "---------------Runnning : $i------------------"; ./MLE.sh LastFM.psl LastFM-learn-${i}.data ${weightlearning_randomweights}; cp LastFM-learned.psl LastFM-learned-MLE-${i}.psl; ./inference.sh LastFM-learned-MLE-${i}.psl LastFM-eval-${i}.data Ranking MLE; ./inference.sh LastFM-learned-MLE-${i}.psl LastFM-eval-${i}.data Continuous MLE;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./MLE.sh Jester.psl Jester-learn-${i}.data ${weightlearning_randomweights}; cp Jester-learned.psl Jester-learned-MLE-${i}.psl; ./inference.sh Jester-learned-MLE-${i}.psl Jester-eval-${i}.data Ranking MLE; ./inference.sh Jester-learned-MLE-${i}.psl Jester-eval-${i}.data Continuous MLE;done
