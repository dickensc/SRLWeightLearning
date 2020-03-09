 ./MPLE.sh Citeseer/Citeseer.psl Citeseer/Citeseer-learn-${1}.data ${2} ${3};
 cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-MPLE-${1}.psl;
 ./inference.sh Citeseer/Citeseer-learned-MPLE-${1}.psl Citeseer/Citeseer-eval-${1}.data Categorical MPLE;
 ./inference.sh Citeseer/Citeseer-learned-MPLE-${1}.psl Citeseer/Citeseer-eval-${1}.data Discrete MPLE;

 ./MPLE.sh Cora/Cora.psl Cora/Cora-learn-${1}.data ${2} ${3};
 cp Cora/Cora-learned.psl Cora/Cora-learned-MPLE-${1}.psl;
 ./inference.sh Cora/Cora-learned-MPLE-${1}.psl Cora-eval-${1}.data Categorical MPLE;
 ./inference.sh Cora/Cora-learned-MPLE-${1}.psl Cora-eval-${1}.data Discrete MPLE;

 ./MPLE.sh Epinions/Epinions.psl Epinions/Epinions-learn-${1}.data ${2} ${3};
 cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-MPLE-${1}.psl;
 ./inference.sh Epinions/Epinions-learned-MPLE-${1}.psl Epinions/Epinions-eval-${1}.data Ranking MPLE;
 ./inference.sh Epinions/Epinions-learned-MPLE-${1}.psl Epinions/Epinions-eval-${1}.data Discrete MPLE;

if ((${1}<=4));
then
  ./MPLE.sh LastFM/LastFM.psl LastFM/LastFM-learn-${1}.data ${2} ${3};
  cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-MPLE-${1}.psl;
  ./inference.sh LastFM/LastFM-learned-MPLE-${1}.psl LastFM/LastFM-eval-${1}.data Ranking MPLE;
  ./inference.sh LastFM/LastFM-learned-MPLE-${1}.psl LastFM/LastFM-eval-${1}.data Continuous MPLE;
fi

 ./MPLE.sh Jester/Jester.psl Jester/Jester-learn-${1}.data ${2} ${3};
 cp Jester/Jester-learned.psl Jester/Jester-learned-MPLE-${1}.psl;
 ./inference.sh Jester/Jester-learned-MPLE-${1}.psl Jester/Jester-eval-${1}.data Ranking MPLE;
 ./inference.sh Jester/Jester-learned-MPLE-${1}.psl Jester/Jester-eval-${1}.data Continuous MPLE;

