 ./MPLE.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${3} Citeseer;
 cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-MPLE-${1}.psl;
 ./inference.sh Citeseer-learned-MPLE-${1}.psl Citeseer-eval-${1}.data Categorical MPLE Citeseer;
 ./inference.sh Citeseer-learned-MPLE-${1}.psl Citeseer-eval-${1}.data Discrete MPLE Citeseer;

 ./MPLE.sh Cora.psl Cora-learn-${1}.data ${2} ${3} Cora;
 cp Cora/Cora-learned.psl Cora/Cora-learned-MPLE-${1}.psl;
 ./inference.sh Cora-learned-MPLE-${1}.psl Cora-eval-${1}.data Categorical MPLE Cora;
 ./inference.sh Cora-learned-MPLE-${1}.psl Cora-eval-${1}.data Discrete MPLE Cora;

 ./MPLE.sh Epinions.psl Epinions-learn-${1}.data ${2} ${3} Epinions;
 cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-MPLE-${1}.psl;
 ./inference.sh Epinions-learned-MPLE-${1}.psl Epinions-eval-${1}.data Ranking MPLE Epinions;
 ./inference.sh Epinions-learned-MPLE-${1}.psl Epinions-eval-${1}.data Discrete MPLE Epinions;

if ((${1}<=4));
then
  ./MPLE.sh LastFM.psl LastFM-learn-${1}.data ${2} ${3} LastFM;
  cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-MPLE-${1}.psl;
  ./inference.sh LastFM-learned-MPLE-${1}.psl LastFM-eval-${1}.data Ranking MPLE LastFM;
  ./inference.sh LastFM-learned-MPLE-${1}.psl LastFM-eval-${1}.data Continuous MPLE LastFM;
fi

 ./MPLE.sh Jester.psl Jester-learn-${1}.data ${2} ${3} Jester;
 cp Jester/Jester-learned.psl Jester/Jester-learned-MPLE-${1}.psl;
 ./inference.sh Jester-learned-MPLE-${1}.psl Jester-eval-${1}.data Ranking MPLE Jester;
 ./inference.sh Jester-learned-MPLE-${1}.psl Jester-eval-${1}.data Continuous MPLE Jester;

