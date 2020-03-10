 ./LME.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${3} Citeseer;
 cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-LME-${1}.psl;
 ./inference.sh Citeseer-learned-LME-${1}.psl Citeseer-eval-${1}.data Categorical LME Citeseer;
 ./inference.sh Citeseer-learned-LME-${1}.psl Citeseer-eval-${1}.data Discrete LME Citeseer;

 ./LME.sh Cora.psl Cora-learn-${1}.data ${2} ${3} Cora;
 cp Cora/Cora-learned.psl Cora/Cora-learned-LME-${1}.psl;
 ./inference.sh Cora-learned-LME-${1}.psl Cora-eval-${1}.data Categorical LME Cora;
 ./inference.sh Cora-learned-LME-${1}.psl Cora-eval-${1}.data Discrete LME Cora;

 ./LME.sh Epinions.psl Epinions-learn-${1}.data ${2} ${3} Epinions;
 cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-LME-${1}.psl;
 ./inference.sh Epinions-learned-LME-${1}.psl Epinions-eval-${1}.data Ranking LME Epinions;
 ./inference.sh Epinions-learned-LME-${1}.psl Epinions-eval-${1}.data Discrete LME Epinions;

if ((${1}<=4));
then
  ./LME.sh LastFM.psl LastFM-learn-${1}.data ${2} ${3} LastFM;
  cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-LME-${1}.psl;
  ./inference.sh LastFM-learned-LME-${1}.psl LastFM-eval-${1}.data Ranking LME LastFM;
  ./inference.sh LastFM-learned-LME-${1}.psl LastFM-eval-${1}.data Continuous LME LastFM;
fi

 ./LME.sh Jester.psl Jester-learn-${1}.data ${2} ${3} Jester;
 cp Jester/Jester-learned.psl Jester/Jester-learned-LME-${1}.psl;
 ./inference.sh Jester-learned-LME-${1}.psl Jester-eval-${1}.data Ranking LME Jester;
 ./inference.sh Jester-learned-LME-${1}.psl Jester-eval-${1}.data Continuous LME Jester;