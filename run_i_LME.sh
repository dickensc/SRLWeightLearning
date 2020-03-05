./LME.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${3}; cp Citeseer-learned.psl Citeseer-learned-LME-${1}.psl; ./inference.sh Citeseer-learned-LME-${1}.psl Citeseer-eval-${1}.data Categorical LME; ./inference.sh Citeseer-learned-LME-${1}.psl Citeseer-eval-${1}.data Discrete LME;

./LME.sh Cora.psl Cora-learn-${1}.data ${2} ${3}; cp Cora-learned.psl Cora-learned-LME-${1}.psl; ./inference.sh Cora-learned-LME-${1}.psl Cora-eval-${1}.data Categorical LME; ./inference.sh Cora-learned-LME-${1}.psl Cora-eval-${1}.data Discrete LME;

./LME.sh Epinions.psl Epinions-learn-${1}.data ${2} ${3}; cp Epinions-learned.psl Epinions-learned-LME-${1}.psl; ./inference.sh Epinions-learned-LME-${1}.psl Epinions-eval-${1}.data Ranking LME; ./inference.sh Epinions-learned-LME-${1}.psl Epinions-eval-${1}.data Discrete LME;

if ${1}<=4
then
  ./LME.sh LastFM.psl LastFM-learn-${1}.data ${2} ${3}; cp LastFM-learned.psl LastFM-learned-LME-${1}.psl; ./inference.sh LastFM-learned-LME-${1}.psl LastFM-eval-${1}.data Ranking LME; ./inference.sh LastFM-learned-LME-${1}.psl LastFM-eval-${1}.data Continuous LME;
fi

./LME.sh Jester.psl Jester-learn-${1}.data ${2} ${3}; cp Jester-learned.psl Jester-learned-LME-${1}.psl; ./inference.sh Jester-learned-LME-${1}.psl Jester-eval-${1}.data Ranking LME; ./inference.sh Jester-learned-LME-${1}.psl Jester-eval-${1}.data Continuous LME;