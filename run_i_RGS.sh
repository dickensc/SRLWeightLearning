for j in Categorical Discrete; do
  ./RGS.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${j} Citeseer;
  cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-RGS-${1}-${j}.psl;
  ./inference.sh Citeseer-learned-RGS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} RGS Citeseer;
done

for j in Categorical Discrete; do
  ./RGS.sh Cora.psl Cora-learn-${1}.data ${2} ${j} Cora;
  cp Cora/Cora-learned.psl Cora/Cora-learned-RGS-${1}-${j}.psl;
  ./inference.sh Cora-learned-RGS-${1}-${j}.psl Cora-eval-${1}.data ${j} RGS Cora;
done

for j in Ranking Discrete; do
  ./RGS.sh Epinions.psl Epinions-learn-${1}.data ${2} ${j} Epinions;
  cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-RGS-${1}-${j}.psl;
  ./inference.sh Epinions-learned-RGS-${1}-${j}.psl Epinions-eval-${1}.data ${j} RGS Epinions;
done

if ((${1}<=4));
then
  for j in Continuous Ranking; do
    ./RGS.sh LastFM.psl LastFM-learn-${1}.data ${2} ${j} LastFM;
    cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-RGS-${1}-${j}.psl;
    ./inference.sh LastFM-learned-RGS-${1}-${j}.psl LastFM-eval-${1}.data ${j} RGS LastFM;
  done
fi

for j in Continuous Ranking; do
  ./RGS.sh Jester.psl Jester-learn-${1}.data ${2} ${j} Jester;
  cp Jester/Jester-learned.psl Jester/Jester-learned-RGS-${1}-${j}.psl;
  ./inference.sh Jester-learned-RGS-${1}-${j}.psl Jester-eval-${1}.data ${j} RGS Jester;
done
