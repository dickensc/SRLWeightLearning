weightlearning_randomweights="false"

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./LME.sh Citeseer.psl Citeseer-learn-${i}.data ${weightlearning_randomweights}; cp Citeseer-learned.psl Citeseer-learned-LME-${i}.psl; ./inference.sh Citeseer-learned-LME-${i}.psl Citeseer-eval-${i}.data Categorical LME; ./inference.sh Citeseer-learned-LME-${i}.psl Citeseer-eval-${i}.data Discrete LME;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./LME.sh Cora.psl Cora-learn-${i}.data ${weightlearning_randomweights}; cp Cora-learned.psl Cora-learned-LME-${i}.psl; ./inference.sh Cora-learned-LME-${i}.psl Cora-eval-${i}.data Categorical LME; ./inference.sh Cora-learned-LME-${i}.psl Cora-eval-${i}.data Discrete LME;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./LME.sh Epinions.psl Epinions-learn-${i}.data ${weightlearning_randomweights}; cp Epinions-learned.psl Epinions-learned-LME-${i}.psl; ./inference.sh Epinions-learned-LME-${i}.psl Epinions-eval-${i}.data Ranking LME; ./inference.sh Epinions-learned-LME-${i}.psl Epinions-eval-${i}.data Discrete LME;done

for i in 0 1 2 3 4 ; do echo "---------------Runnning : $i------------------"; ./LME.sh LastFM.psl LastFM-learn-${i}.data ${weightlearning_randomweights}; cp LastFM-learned.psl LastFM-learned-LME-${i}.psl; ./inference.sh LastFM-learned-LME-${i}.psl LastFM-eval-${i}.data Ranking LME; ./inference.sh LastFM-learned-LME-${i}.psl LastFM-eval-${i}.data Continuous LME;done

for i in 0 1 2 3 4 5 6 7 ; do echo "---------------Runnning : $i------------------"; ./LME.sh Jester.psl Jester-learn-${i}.data ${weightlearning_randomweights}; cp Jester-learned.psl Jester-learned-LME-${i}.psl; ./inference.sh Jester-learned-LME-${i}.psl Jester-eval-${i}.data Ranking LME; ./inference.sh Jester-learned-LME-${i}.psl Jester-eval-${i}.data Continuous LME;done

