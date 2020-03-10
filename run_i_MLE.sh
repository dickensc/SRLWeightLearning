 ./MLE.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${3} Citeseer;
 cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-MLE-${1}.psl;
 ./inference.sh Citeseer-learned-MLE-${1}.psl Citeseer-eval-${1}.data Categorical MLE Citeseer;
 ./inference.sh Citeseer-learned-MLE-${1}.psl Citeseer-eval-${1}.data Discrete MLE Citeseer;

#  ./MLE.sh Cora.psl Cora-learn-${1}.data ${2} ${3} Cora;
#  cp Cora/Cora-learned.psl Cora/Cora-learned-MLE-${1}.psl;
#  ./inference.sh Cora-learned-MLE-${1}.psl Cora-eval-${1}.data Categorical MLE Cora;
#  ./inference.sh Cora-learned-MLE-${1}.psl Cora-eval-${1}.data Discrete MLE Cora;

#  ./MLE.sh Epinions.psl Epinions-learn-${1}.data ${2} ${3} Epinions;
#  cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-MLE-${1}.psl;
#  ./inference.sh Epinions-learned-MLE-${1}.psl Epinions-eval-${1}.data Ranking MLE Epinions; 
#  ./inference.sh Epinions-learned-MLE-${1}.psl Epinions-eval-${1}.data Discrete MLE Epinions;

# if ((${1}<=4));
# then
#   ./MLE.sh LastFM.psl LastFM-learn-${1}.data ${2} ${3} LastFM;
#   cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-MLE-${1}.psl;
#   ./inference.sh LastFM-learned-MLE-${1}.psl LastFM-eval-${1}.data Ranking MLE LastFM;
#   ./inference.sh LastFM-learned-MLE-${1}.psl LastFM-eval-${1}.data Continuous MLE LastFM;
# fi

#  ./MLE.sh Jester.psl Jester-learn-${1}.data ${2} ${3} Jester;
#  cp Jester/Jester-learned.psl Jester-learned-MLE-${1}.psl;
#  ./inference.sh Jester-learned-MLE-${1}.psl Jester/Jester-eval-${1}.data Ranking MLE Jester;
#  ./inference.sh Jester-learned-MLE-${1}.psl Jester/Jester-eval-${1}.data Continuous MLE Jester;
