seed=4

for j in Categorical Discrete; do ./HB.sh Citeseer.psl Citeseer-learn-${1}.data ${seed} ${j}; cp Citeseer-learned.psl Citeseer-learned-HB-${1}-${j}.psl; ./inference.sh Citeseer-learned-HB-${1}-${j}.psl Citeseer-eval-${1}.data ${j} HB; done

for j in Categorical Discrete; do ./HB.sh Cora.psl Cora-learn-${1}.data ${seed} ${j}; cp Cora-learned.psl Cora-learned-HB-${1}-${j}.psl; ./inference.sh Cora-learned-HB-${1}-${j}.psl Cora-eval-${1}.data ${j} HB; done

for j in Ranking Discrete; do ./HB.sh Epinions.psl Epinions-learn-${1}.data ${seed} ${j}; cp Epinions-learned.psl Epinions-learned-HB-${1}-${j}.psl; ./inference.sh Epinions-learned-HB-${1}-${j}.psl Epinions-eval-${1}.data ${j} HB; done

for j in Continuous Ranking; do ./HB.sh LastFM.psl LastFM-learn-${1}.data ${seed} ${j}; cp LastFM-learned.psl LastFM-learned-HB-${1}-${j}.psl; ./inference.sh LastFM-learned-HB-${1}-${j}.psl LastFM-eval-${1}.data ${j} HB; done

for j in Continuous Ranking; do ./HB.sh Jester.psl Jester-learn-${1}.data ${seed} ${j}; cp Jester-learned.psl Jester-learned-HB-${1}-${j}.psl; ./inference.sh Jester-learned-HB-${1}-${j}.psl Jester-eval-${1}.data ${j} HB; done
