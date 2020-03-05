for j in Ranking Discrete; do ./bowlOS_learn.sh Epinions.psl Epinions-learn-${1}.data ${j}; cp Epinions-learned.psl Epinions-learned-bowlOS-${1}-${j}.psl; ./inference.sh Epinions-learned-bowlOS-${1}-${j}.psl Epinions-eval-${1}.data ${j} bowlOS;done

for j in Categorical Discrete; do ./bowlOS_learn.sh Citeseer.psl Citeseer-learn-${1}.data ${j}; cp Citeseer-learned.psl Citeseer-learned-bowlOS-${1}-${j}.psl; ./inference.sh Citeseer-learned-bowlOS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} bowlOS;done

for j in Categorical Discrete; do ./bowlOS_learn.sh Cora.psl Cora-learn-${1}.data ${j}; cp Cora-learned.psl Cora-learned-bowlOS-${1}-${j}.psl; ./inference.sh Cora-learned-bowlOS-${1}-${j}.psl Cora-eval-${1}.data ${j} bowlOS;done

if ${1}<=4
then
  for j in Continuous Ranking; do ./bowlOS_learn.sh LastFM.psl LastFM-learn-${1}.data ${j}; cp LastFM-learned.psl LastFM-learned-bowlOS-${1}-${j}.psl; ./inference.sh LastFM-learned-bowlOS-${1}-${j}.psl LastFM-eval-${1}.data ${j} bowlOS;done
fi

for j in Continuous Ranking; do ./bowlOS_learn.sh Jester.psl Jester-learn-${1}.data ${j}; cp Jester-learned.psl Jester-learned-bowlOS-${1}-${j}.psl; ./inference.sh Jester-learned-bowlOS-${1}-${j}.psl Jester-eval-${1}.data ${j} bowlOS;done
