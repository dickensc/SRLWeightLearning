seed=4

for j in Categorical Discrete; do ./CRGS.sh Citeseer.psl Citeseer-learn-${1}.data ${seed} ${j}; cp Citeseer-learned.psl Citeseer-learned-CRGS-${1}-${j}.psl; ./inference.sh Citeseer-learned-CRGS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} CRGS; done

for j in Categorical Discrete; do ./CRGS.sh Cora.psl Cora-learn-${1}.data ${seed} ${j}; cp Cora-learned.psl Cora-learned-CRGS-${1}-${j}.psl; ./inference.sh Cora-learned-CRGS-${1}-${j}.psl Cora-eval-${1}.data ${j} CRGS; done

for j in Ranking Discrete; do ./CRGS.sh Epinions.psl Epinions-learn-${1}.data ${seed} ${j}; cp Epinions-learned.psl Epinions-learned-CRGS-${1}-${j}.psl; ./inference.sh Epinions-learned-CRGS-${1}-${j}.psl Epinions-eval-${1}.data ${j} CRGS; done

for j in Continuous Ranking; do ./CRGS.sh LastFM.psl LastFM-learn-${1}.data ${seed} ${j}; cp LastFM-learned.psl LastFM-learned-CRGS-${1}-${j}.psl; ./inference.sh LastFM-learned-CRGS-${1}-${j}.psl LastFM-eval-${1}.data ${j} CRGS; done

for j in Continuous Ranking; do ./CRGS.sh Jester.psl Jester-learn-${1}.data ${seed} ${j}; cp Jester-learned.psl Jester-learned-CRGS-${1}-${j}.psl; ./inference.sh Jester-learned-CRGS-${1}-${j}.psl Jester-eval-${1}.data ${j} CRGS; done
