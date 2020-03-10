 for j in Ranking Discrete; do
   ./bowlSS_learn.sh Epinions.psl Epinions-learn-${1}.data ${j} Epinions;
   cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-bowlSS-${1}-${j}.psl;
   ./inference.sh Epinions-learned-bowlSS-${1}-${j}.psl Epinions-eval-${1}.data ${j} bowlSS Epinions;
done

 for j in Categorical Discrete; do
   ./bowlSS_learn.sh Citeseer.psl Citeseer-learn-${1}.data ${j} Citeseer;
   cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-bowlSS-${1}-${j}.psl;
   ./inference.sh Citeseer-learned-bowlSS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} bowlSS Citeseer;
 done

 for j in Categorical Discrete; do
   ./bowlSS_learn.sh Cora.psl Cora-learn-${1}.data ${j} Cora;
   cp Cora/Cora-learned.psl Cora/Cora-learned-bowlSS-${1}-${j}.psl;
   ./inference.sh Cora-learned-bowlSS-${1}-${j}.psl Cora-eval-${1}.data ${j} bowlSS Cora;
 done

if ((${1}<=4));
then
  for j in Continuous Ranking; do
    ./bowlSS_learn.sh LastFM.psl LastFM-learn-${1}.data ${j} LastFM;
    cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-bowlSS-${1}-${j}.psl;
    ./inference.sh LastFM-learned-bowlSS-${1}-${j}.psl LastFM-eval-${1}.data ${j} bowlSS LastFM;
  done
fi

 for j in Continuous Ranking; do
   ./bowlSS_learn.sh Jester.psl Jester-learn-${1}.data ${j} Jester;
   cp Jester/Jester-learned.psl Jester/Jester-learned-bowlSS-${1}-${j}.psl;
   ./inference.sh Jester-learned-bowlSS-${1}-${j}.psl Jester-eval-${1}.data ${j} bowlSS Jester;
 done
