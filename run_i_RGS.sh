# for j in Categorical Discrete; do
#   /usr/bin/time -v --output=Citeseer/Citeseer_RGS_learn_time_fold_${1}_metric_${j} ./RGS.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${j} Citeseer;
#   cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-RGS-${1}-${j}.psl;
#   /usr/bin/time -v --output=Citeseer/Citeseer_RGS_inference_time_fold_${1}_metric_${j} ./inference.sh Citeseer-learned-RGS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} RGS Citeseer;
# done

# for j in Categorical Discrete; do
#   /usr/bin/time -v --output=Cora/Cora_RGS_learn_time_fold_${1}_metric_${j} ./RGS.sh Cora.psl Cora-learn-${1}.data ${2} ${j} Cora;
#   cp Cora/Cora-learned.psl Cora/Cora-learned-RGS-${1}-${j}.psl;
#   /usr/bin/time -v --output=Cora/Cora_RGS_inference_time_fold_${1}_metric_${j} ./inference.sh Cora-learned-RGS-${1}-${j}.psl Cora-eval-${1}.data ${j} RGS Cora;
# done

# for j in Ranking Discrete; do
#   /usr/bin/time -v --output=Epinions/Epinions_RGS_learn_time_fold_${1}_metric_${j} ./RGS.sh Epinions.psl Epinions-learn-${1}.data ${2} ${j} Epinions;
#   cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-RGS-${1}-${j}.psl;
#   /usr/bin/time -v --output=Epinions/Epinions_RGS_inference_time_fold_${1}_metric_${j} ./inference.sh Epinions-learned-RGS-${1}-${j}.psl Epinions-eval-${1}.data ${j} RGS Epinions;
# done

# if ((${1}<=4));
# then
#   for j in Continuous Ranking; do
#     /usr/bin/time -v --output=LastFM/LastFM_RGS_learn_time_fold_${1}_metric_${j} ./RGS.sh LastFM.psl LastFM-learn-${1}.data ${2} ${j} LastFM;
#     cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-RGS-${1}-${j}.psl;
#     /usr/bin/time -v --output=LastFM/LastFM_RGS_inference_time_fold_${1}_metric_${j} ./inference.sh LastFM-learned-RGS-${1}-${j}.psl LastFM-eval-${1}.data ${j} RGS LastFM;
#   done
# fi

# for j in Continuous Ranking; do
#   /usr/bin/time -v --output=Jester/Jester_RGS_learn_time_fold_${1}_metric_${j} ./RGS.sh Jester.psl Jester-learn-${1}.data ${2} ${j} Jester;
#   cp Jester/Jester-learned.psl Jester/Jester-learned-RGS-${1}-${j}.psl;
#   /usr/bin/time -v --output=Jester/Jester_RGS_inference_time_fold_${1}_metric_${j} ./inference.sh Jester-learned-RGS-${1}-${j}.psl Jester-eval-${1}.data ${j} RGS Jester;
# done

for j in Categorical; do
  ./RGS.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${j} Citeseer;
  cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-RGS-${1}-${j}.psl;
  ./inference.sh Citeseer-learned-RGS-${1}-${j}.psl Citeseer-eval-${1}.data ${j} RGS Citeseer;
done

for j in Categorical; do
  ./RGS.sh Cora.psl Cora-learn-${1}.data ${2} ${j} Cora;
  cp Cora/Cora-learned.psl Cora/Cora-learned-RGS-${1}-${j}.psl;
  ./inference.sh Cora-learned-RGS-${1}-${j}.psl Cora-eval-${1}.data ${j} RGS Cora;
done

for j in Discrete; do
  ./RGS.sh Epinions.psl Epinions-learn-${1}.data ${2} ${j} Epinions;
  cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-RGS-${1}-${j}.psl;
  ./inference.sh Epinions-learned-RGS-${1}-${j}.psl Epinions-eval-${1}.data ${j} RGS Epinions;
done

if ((${1}<=4));
then
  for j in Continuous; do
    ./RGS.sh LastFM.psl LastFM-learn-${1}.data ${2} ${j} LastFM;
    cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-RGS-${1}-${j}.psl;
    ./inference.sh LastFM-learned-RGS-${1}-${j}.psl LastFM-eval-${1}.data ${j} RGS LastFM;
  done
fi

for j in Continuous; do
  ./RGS.sh Jester.psl Jester-learn-${1}.data ${2} ${j} Jester;
  cp Jester/Jester-learned.psl Jester/Jester-learned-RGS-${1}-${j}.psl;
  ./inference.sh Jester-learned-RGS-${1}-${j}.psl Jester-eval-${1}.data ${j} RGS Jester;
done
