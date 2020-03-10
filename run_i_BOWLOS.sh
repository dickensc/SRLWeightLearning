 for j in Ranking Discrete; do
   ./bowlOS_learn.sh Epinions.psl Epinions-learn-${1}.data ${j} Epinions;
   cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-bowlOS-${1}-${j}.psl;
   ./inference.sh Epinions-learned-bowlOS-${1}-${j}.psl Epinions-eval-${1}.data ${j} bowlOS Epinions;
 done

 for j in Categorical Discrete; do
   ./bowlOS_learn.sh Citeseer.psl Citeseer-learn-${1}.data ${j} Citeseer;
   cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-bowlOS-${1}-${j}.psl;
   ./inference.sh Citeseer-learned-bowlOS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} bowlOS Citeseer;
 done

 for j in Categorical Discrete;
   do ./bowlOS_learn.sh Cora.psl Cora-learn-${1}.data ${j} Cora;
   cp Cora/Cora-learned.psl Cora/Cora-learned-bowlOS-${1}-${j}.psl;
   ./inference.sh Cora-learned-bowlOS-${1}-${j}.psl Cora-eval-${1}.data ${j} bowlOS Cora;
 done

if ((${1}<=4));
then
  for j in Continuous Ranking; do
    ./bowlOS_learn.sh LastFM.psl LastFM-learn-${1}.data ${j} LastFM;
    cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-bowlOS-${1}-${j}.psl;
    ./inference.sh LastFM-learned-bowlOS-${1}-${j}.psl LastFM-eval-${1}.data ${j} bowlOS LastFM;
  done
fi

 for j in Continuous Ranking; do
   ./bowlOS_learn.sh Jester.psl Jester-learn-${1}.data ${j} Jester;
   cp Jester/ester-learned.psl Jester/Jester-learned-bowlOS-${1}-${j}.psl;
   ./inference.sh Jester-learned-bowlOS-${1}-${j}.psl Jester-eval-${1}.data ${j} bowlOS Jester;
 done
