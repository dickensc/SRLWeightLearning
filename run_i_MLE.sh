 ./MLE.sh Citeseer/Citeseer.psl Citeseer/Citeseer-learn-${1}.data ${2} ${3};
 cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-MLE-${1}.psl;
 ./inference.sh Citeseer/Citeseer-learned-MLE-${1}.psl Citeseer/Citeseer-eval-${1}.data Categorical MLE;
 ./inference.sh Citeseer/Citeseer-learned-MLE-${1}.psl Citeseer/Citeseer-eval-${1}.data Discrete MLE;

 ./MLE.sh Cora/Cora.psl Cora/Cora-learn-${1}.data ${2} ${3};
 cp Cora/Cora-learned.psl Cora/Cora-learned-MLE-${1}.psl;
 ./inference.sh Cora/Cora-learned-MLE-${1}.psl Cora/Cora-eval-${1}.data Categorical MLE;
 ./inference.sh Cora/Cora-learned-MLE-${1}.psl Cora/Cora-eval-${1}.data Discrete MLE;

 ./MLE.sh Epinions/Epinions.psl Epinions/Epinions-learn-${1}.data ${2} ${3};
 cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-MLE-${1}.psl;
 ./inference.sh Epinions/Epinions-learned-MLE-${1}.psl Epinions/Epinions-eval-${1}.data Ranking MLE;
 ./inference.sh Epinions/Epinions-learned-MLE-${1}.psl Epinions/Epinions-eval-${1}.data Discrete MLE;

if ((${1}<=4));
then
  ./MLE.sh LastFM/LastFM.psl LastFM/LastFM-learn-${1}.data ${2} ${3};
  cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-MLE-${1}.psl;
  ./inference.sh LastFM/LastFM-learned-MLE-${1}.psl LastFM/LastFM-eval-${1}.data Ranking MLE;
  ./inference.sh LastFM/LastFM-learned-MLE-${1}.psl LastFM/LastFM-eval-${1}.data Continuous MLE;
fi

 ./MLE.sh Jester/Jester.psl Jester/Jester-learn-${1}.data ${2} ${3};
 cp Jester/Jester-learned.psl Jester-learned-MLE-${1}.psl;
 ./inference.sh Jester/Jester-learned-MLE-${1}.psl Jester/Jester-eval-${1}.data Ranking MLE;
 ./inference.sh Jester/Jester-learned-MLE-${1}.psl Jester/Jester-eval-${1}.data Continuous MLE;
