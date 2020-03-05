weightlearning_randomweights="false"

./MPLE.sh Citeseer.psl Citeseer-learn-${1}.data ${weightlearning_randomweights}; cp Citeseer-learned.psl Citeseer-learned-MPLE-${1}.psl; ./inference.sh Citeseer-learned-MPLE-${1}.psl Citeseer-eval-${1}.data Categorical MPLE; ./inference.sh Citeseer-learned-MPLE-${1}.psl Citeseer-eval-${1}.data Discrete MPLE;

./MPLE.sh Cora.psl Cora-learn-${1}.data ${weightlearning_randomweights}; cp Cora-learned.psl Cora-learned-MPLE-${1}.psl; ./inference.sh Cora-learned-MPLE-${1}.psl Cora-eval-${1}.data Categorical MPLE; ./inference.sh Cora-learned-MPLE-${1}.psl Cora-eval-${1}.data Discrete MPLE;

./MPLE.sh Epinions.psl Epinions-learn-${1}.data ${weightlearning_randomweights}; cp Epinions-learned.psl Epinions-learned-MPLE-${1}.psl; ./inference.sh Epinions-learned-MPLE-${1}.psl Epinions-eval-${1}.data Ranking MPLE; ./inference.sh Epinions-learned-MPLE-${1}.psl Epinions-eval-${1}.data Discrete MPLE;

if ${1}<=4
then
  ./MPLE.sh LastFM.psl LastFM-learn-${1}.data ${weightlearning_randomweights}; cp LastFM-learned.psl LastFM-learned-MPLE-${1}.psl; ./inference.sh LastFM-learned-MPLE-${1}.psl LastFM-eval-${1}.data Ranking MPLE; ./inference.sh LastFM-learned-MPLE-${1}.psl LastFM-eval-${1}.data Continuous MPLE;
fi

./MPLE.sh Jester.psl Jester-learn-${1}.data ${weightlearning_randomweights}; cp Jester-learned.psl Jester-learned-MPLE-${1}.psl; ./inference.sh Jester-learned-MPLE-${1}.psl Jester-eval-${1}.data Ranking MPLE; ./inference.sh Jester-learned-MPLE-${1}.psl Jester-eval-${1}.data Continuous MPLE;

