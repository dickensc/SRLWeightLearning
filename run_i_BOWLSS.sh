 for j in Ranking Discrete; do
   ./bowlSS_learn.sh Epinions/Epinions.psl Epinions/Epinions-learn-${1}.data ${j};
   cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-bowlSS-${1}-${j}.psl;
   ./inference.sh Epinions/Epinions-learned-bowlSS-${1}-${j}.psl Epinions/Epinions-eval-${1}.data ${j} bowlSS;
done

 for j in Categorical Discrete; do
   ./bowlSS_learn.sh Citeseer/Citeseer.psl Citeseer/Citeseer-learn-${1}.data ${j};
   cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-bowlSS-${1}-${j}.psl;
   ./inference.sh Citeseer/Citeseer-learned-bowlSS-${1}-${j}.psl Citeseer/Citeseer-eval-${1}.data ${j} bowlSS;
 done

 for j in Categorical Discrete; do
   ./bowlSS_learn.sh Cora/Cora.psl Cora/Cora-learn-${1}.data ${j};
   cp Cora/Cora-learned.psl Cora/Cora-learned-bowlSS-${1}-${j}.psl;
   ./inference.sh Cora/Cora-learned-bowlSS-${1}-${j}.psl Cora/Cora-eval-${1}.data ${j} bowlSS;
 done

if ((${1}<=4));
then
  for j in Continuous Ranking; do
    ./bowlSS_learn.sh LastFM/LastFM.psl LastFM/LastFM-learn-${1}.data ${j};
    cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-bowlSS-${1}-${j}.psl;
    ./inference.sh LastFM/LastFM-learned-bowlSS-${1}-${j}.psl LastFM/LastFM-eval-${1}.data ${j} bowlSS;
  done
fi

 for j in Continuous Ranking; do
   ./bowlSS_learn.sh Jester/Jester.psl Jester/Jester-learn-${1}.data ${j};
   cp Jester/Jester-learned.psl Jester/Jester-learned-bowlSS-${1}-${j}.psl;
   ./inference.sh Jester/Jester-learned-bowlSS-${1}-${j}.psl Jester/Jester-eval-${1}.data ${j} bowlSS;
 done
