
for j in Ranking Discrete; do ./bowlSS_learn.sh Epinions.psl Epinions-learn-${1}.data ${j}; cp Epinions-learned.psl Epinions-learned-bowlSS-${1}-${j}.psl; ./inference.sh Epinions-learned-bowlSS-${1}-${j}.psl Epinions-eval-${1}.data ${j} bowlSS;done

for j in Categorical Discrete; do ./bowlSS_learn.sh Citeseer.psl Citeseer-learn-${1}.data ${j}; cp Citeseer-learned.psl Citeseer-learned-bowlSS-${1}-${j}.psl; ./inference.sh Citeseer-learned-bowlSS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} bowlSS;done

for j in Categorical Discrete; do ./bowlSS_learn.sh Cora.psl Cora-learn-${1}.data ${j}; cp Cora-learned.psl Cora-learned-bowlSS-${1}-${j}.psl; ./inference.sh Cora-learned-bowlSS-${1}-${j}.psl Cora-eval-${1}.data ${j} bowlSS;done

for j in Continuous Ranking; do ./bowlSS_learn.sh LastFM.psl LastFM-learn-${1}.data ${j}; cp LastFM-learned.psl LastFM-learned-bowlSS-${1}-${j}.psl; ./inference.sh LastFM-learned-bowlSS-${1}-${j}.psl LastFM-eval-${1}.data ${j} bowlSS;done

for j in Continuous Ranking; do ./bowlSS_learn.sh Jester.psl Jester-learn-${1}.data ${j}; cp Jester-learned.psl Jester-learned-bowlSS-${1}-${j}.psl; ./inference.sh Jester-learned-bowlSS-${1}-${j}.psl Jester-eval-${1}.data ${j} bowlSS;done
