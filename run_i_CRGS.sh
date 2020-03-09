 for j in Categorical Discrete; do
   ./CRGS.sh Citeseer/Citeseer.psl Citeseer/Citeseer-learn-${1}.data ${2} ${j};
   cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-CRGS-${1}-${j}.psl;
   ./inference.sh Citeseer/Citeseer-learned-CRGS-${1}-${j}.psl Citeseer/Citeseer-eval-${1}.data ${j} CRGS;
 done

 for j in Categorical Discrete; do
   ./CRGS.sh Cora/Cora.psl Cora/Cora-learn-${1}.data ${2} ${j};
   cp Cora/Cora-learned.psl Cora/Cora-learned-CRGS-${1}-${j}.psl;
   ./inference.sh Cora/Cora-learned-CRGS-${1}-${j}.psl Cora/Cora-eval-${1}.data ${j} CRGS;
 done

 for j in Ranking Discrete; do
   ./CRGS.sh Epinions/Epinions.psl Epinions/Epinions-learn-${1}.data ${2} ${j};
   cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-CRGS-${1}-${j}.psl;
   ./inference.sh Epinions/Epinions-learned-CRGS-${1}-${j}.psl Epinions/Epinions-eval-${1}.data ${j} CRGS;
 done

if ((${1}<=4));
then
  for j in Continuous Ranking; do
    ./CRGS.sh LastFM/LastFM.psl LastFM/LastFM-learn-${1}.data ${2} ${j};
    cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-CRGS-${1}-${j}.psl;
    ./inference.sh LastFM/LastFM-learned-CRGS-${1}-${j}.psl LastFM/LastFM-eval-${1}.data ${j} CRGS;
  done
fi

 for j in Continuous Ranking; do
   ./CRGS.sh Jester/Jester.psl Jester/Jester-learn-${1}.data ${2} ${j};
   cp Jester/Jester-learned.psl Jester/Jester-learned-CRGS-${1}-${j}.psl;
   ./inference.sh Jester/Jester-learned-CRGS-${1}-${j}.psl Jester/Jester-eval-${1}.data ${j} CRGS;
 done
