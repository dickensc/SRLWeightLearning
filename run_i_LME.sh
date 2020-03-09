 ./LME.sh Citeseer/Citeseer.psl Citeseer/Citeseer-learn-${1}.data ${2} ${3};
 cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-LME-${1}.psl;
 ./inference.sh Citeseer/Citeseer-learned-LME-${1}.psl Citeseer/Citeseer-eval-${1}.data Categorical LME;
 ./inference.sh Citeseer/Citeseer-learned-LME-${1}.psl Citeseer/Citeseer-eval-${1}.data Discrete LME;

 ./LME.sh Cora/Cora.psl Cora-learn-${1}.data ${2} ${3};
 cp Cora/Cora-learned.psl Cora/Cora-learned-LME-${1}.psl;
 ./inference.sh Cora/Cora-learned-LME-${1}.psl Cora/Cora-eval-${1}.data Categorical LME;
 ./inference.sh Cora/Cora-learned-LME-${1}.psl Cora/Cora-eval-${1}.data Discrete LME;

 ./LME.sh Epinions/Epinions.psl Epinions/Epinions-learn-${1}.data ${2} ${3};
 cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-LME-${1}.psl;
 ./inference.sh Epinions/Epinions-learned-LME-${1}.psl Epinions/Epinions-eval-${1}.data Ranking LME;
 ./inference.sh Epinions/Epinions-learned-LME-${1}.psl Epinions/Epinions-eval-${1}.data Discrete LME;

if ((${1}<=4));
then
  ./LME.sh LastFM/LastFM.psl LastFM/LastFM-learn-${1}.data ${2} ${3};
  cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-LME-${1}.psl;
  ./inference.sh LastFM/LastFM-learned-LME-${1}.psl LastFM/LastFM-eval-${1}.data Ranking LME;
  ./inference.sh LastFM/LastFM-learned-LME-${1}.psl LastFM/LastFM-eval-${1}.data Continuous LME;
fi

 ./LME.sh Jester/Jester.psl Jester/Jester-learn-${1}.data ${2} ${3};
 cp Jester/Jester-learned.psl Jester/Jester-learned-LME-${1}.psl;
 ./inference.sh Jester/Jester-learned-LME-${1}.psl Jester/Jester-eval-${1}.data Ranking LME;
 ./inference.sh Jester/Jester-learned-LME-${1}.psl Jester/Jester-eval-${1}.data Continuous LME;