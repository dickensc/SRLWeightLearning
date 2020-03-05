seed=4

for j in Categorical Discrete; do ./RGS.sh Citeseer.psl Citeseer-learn-${1}.data ${seed} ${j}; cp Citeseer-learned.psl Citeseer-learned-RGS-${1}-${j}.psl; ./inference.sh Citeseer-learned-RGS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} RGS; done

for j in Categorical Discrete; do ./RGS.sh Cora.psl Cora-learn-${1}.data ${seed} ${j}; cp Cora-learned.psl Cora-learned-RGS-${1}-${j}.psl; ./inference.sh Cora-learned-RGS-${1}-${j}.psl Cora-eval-${1}.data ${j} RGS; done

for j in Ranking Discrete; do ./RGS.sh Epinions.psl Epinions-learn-${1}.data ${seed} ${j}; cp Epinions-learned.psl Epinions-learned-RGS-${1}-${j}.psl; ./inference.sh Epinions-learned-RGS-${1}-${j}.psl Epinions-eval-${1}.data ${j} RGS; done

for j in Continuous Ranking; do ./RGS.sh LastFM.psl LastFM-learn-${1}.data ${seed} ${j}; cp LastFM-learned.psl LastFM-learned-RGS-${1}-${j}.psl; ./inference.sh LastFM-learned-RGS-${1}-${j}.psl LastFM-eval-${1}.data ${j} RGS; done

for j in Continuous Ranking; do ./RGS.sh Jester.psl Jester-learn-${1}.data ${seed} ${j}; cp Jester-learned.psl Jester-learned-RGS-${1}-${j}.psl; ./inference.sh Jester-learned-RGS-${1}-${j}.psl Jester-eval-${1}.data ${j} RGS; done
