weightlearning_randomweights="false"

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./MPLE.sh Citeseer.psl Citeseer-learn-${i}.data ${weightlearning_randomweights}; cp Citeseer-learned.psl Citeseer-learned-MPLE-${i}.psl; ./inference.sh Citeseer-learned-MPLE-${i}.psl Citeseer-eval-${i}.data Categorical MPLE; ./inference.sh Citeseer-learned-MPLE-${i}.psl Citeseer-eval-${i}.data Discrete MPLE;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./MPLE.sh Cora.psl Cora-learn-${i}.data ${weightlearning_randomweights}; cp Cora-learned.psl Cora-learned-MPLE-${i}.psl; ./inference.sh Cora-learned-MPLE-${i}.psl Cora-eval-${i}.data Categorical MPLE; ./inference.sh Cora-learned-MPLE-${i}.psl Cora-eval-${i}.data Discrete MPLE;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./MPLE.sh Epinions.psl Epinions-learn-${i}.data ${weightlearning_randomweights}; cp Epinions-learned.psl Epinions-learned-MPLE-${i}.psl; ./inference.sh Epinions-learned-MPLE-${i}.psl Epinions-eval-${i}.data Ranking MPLE; ./inference.sh Epinions-learned-MPLE-${i}.psl Epinions-eval-${i}.data Discrete MPLE;done

for i in 0 1 2 3 4 ; do echo "---------------Runnning : $i------------------"; ./MPLE.sh LastFM.psl LastFM-learn-${i}.data ${weightlearning_randomweights}; cp LastFM-learned.psl LastFM-learned-MPLE-${i}.psl; ./inference.sh LastFM-learned-MPLE-${i}.psl LastFM-eval-${i}.data Ranking MPLE; ./inference.sh LastFM-learned-MPLE-${i}.psl LastFM-eval-${i}.data Continuous MPLE;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./MPLE.sh Jester.psl Jester-learn-${i}.data ${weightlearning_randomweights}; cp Jester-learned.psl Jester-learned-MPLE-${i}.psl; ./inference.sh Jester-learned-MPLE-${i}.psl Jester-eval-${i}.data Ranking MPLE; ./inference.sh Jester-learned-MPLE-${i}.psl Jester-eval-${i}.data Continuous MPLE;done

