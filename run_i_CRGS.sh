 for j in Categorical Discrete; do
   ./CRGS.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${j} Citeseer;
   cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-CRGS-${1}-${j}.psl;
   ./inference.sh Citeseer-learned-CRGS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} CRGS Citeseer;
 done

 for j in Categorical Discrete; do
   ./CRGS.sh Cora.psl Cora-learn-${1}.data ${2} ${j} Cora;
   cp Cora/Cora-learned.psl Cora/Cora-learned-CRGS-${1}-${j}.psl;
   ./inference.sh Cora-learned-CRGS-${1}-${j}.psl Cora-eval-${1}.data ${j} CRGS Cora;
 done

 for j in Ranking Discrete; do
   ./CRGS.sh Epinions.psl Epinions-learn-${1}.data ${2} ${j} Epinions;
   cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-CRGS-${1}-${j}.psl;
   ./inference.sh Epinions-learned-CRGS-${1}-${j}.psl Epinions-eval-${1}.data ${j} CRGS Epinions;
 done

if ((${1}<=4));
then
  for j in Continuous Ranking; do
    ./CRGS.sh LastFM.psl LastFM-learn-${1}.data ${2} ${j} Epinions;
    cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-CRGS-${1}-${j}.psl;
    ./inference.sh LastFM-learned-CRGS-${1}-${j}.psl LastFM-eval-${1}.data ${j} CRGS LastFM;
  done
fi

 for j in Continuous Ranking; do
   ./CRGS.sh Jester.psl Jester-learn-${1}.data ${2} ${j} Jester;
   cp Jester/Jester-learned.psl Jester/Jester-learned-CRGS-${1}-${j}.psl;
   ./inference.sh Jester-learned-CRGS-${1}-${j}.psl Jester-eval-${1}.data ${j} CRGS Jester;
 done
