weightlearning_randomweights="false"

./MLE.sh Citeseer.psl Citeseer-learn-${1}.data ${weightlearning_randomweights}; cp Citeseer-learned.psl Citeseer-learned-MLE-${1}.psl; ./inference.sh Citeseer-learned-MLE-${1}.psl Citeseer-eval-${1}.data Categorical MLE; ./inference.sh Citeseer-learned-MLE-${1}.psl Citeseer-eval-${1}.data Discrete MLE;

./MLE.sh Cora.psl Cora-learn-${1}.data ${weightlearning_randomweights}; cp Cora-learned.psl Cora-learned-MLE-${1}.psl; ./inference.sh Cora-learned-MLE-${1}.psl Cora-eval-${1}.data Categorical MLE; ./inference.sh Cora-learned-MLE-${1}.psl Cora-eval-${1}.data Discrete MLE;

./MLE.sh Epinions.psl Epinions-learn-${1}.data ${weightlearning_randomweights}; cp Epinions-learned.psl Epinions-learned-MLE-${1}.psl; ./inference.sh Epinions-learned-MLE-${1}.psl Epinions-eval-${1}.data Ranking MLE; ./inference.sh Epinions-learned-MLE-${1}.psl Epinions-eval-${1}.data Discrete MLE;

if ${1}<=4
then
  ./MLE.sh LastFM.psl LastFM-learn-${1}.data ${weightlearning_randomweights}; cp LastFM-learned.psl LastFM-learned-MLE-${1}.psl; ./inference.sh LastFM-learned-MLE-${1}.psl LastFM-eval-${1}.data Ranking MLE; ./inference.sh LastFM-learned-MLE-${1}.psl LastFM-eval-${1}.data Continuous MLE;
fi

./MLE.sh Jester.psl Jester-learn-${1}.data ${weightlearning_randomweights}; cp Jester-learned.psl Jester-learned-MLE-${1}.psl; ./inference.sh Jester-learned-MLE-${1}.psl Jester-eval-${1}.data Ranking MLE; ./inference.sh Jester-learned-MLE-${1}.psl Jester-eval-${1}.data Continuous MLE;
