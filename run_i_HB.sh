# for j in Categorical Discrete; do
#   /usr/bin/time -v --output=Citeseer/Citeseer_HB_learn_time_fold_${1}_metric_${j} ./HB.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${j} Citeseer;
#   cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-HB-${1}-${j}.psl;
#   /usr/bin/time -v --output=Citeseer/Citeseer_HB_inference_time_fold_${1}_metric_${j} ./inference.sh Citeseer-learned-HB-${1}-${j}.psl Citeseer-eval-${1}.data ${j} HB Citeseer;
# done

# for j in Categorical Discrete; do
#   /usr/bin/time -v --output=Cora/Cora_HB_learn_time_fold_${1}_metric_${j} ./HB.sh Cora.psl Cora-learn-${1}.data ${2} ${j} Cora;
#   cp Cora/Cora-learned.psl Cora/Cora-learned-HB-${1}-${j}.psl;
#   /usr/bin/time -v --output=Cora/Cora_HB_inference_time_fold_${1}_metric_${j} ./inference.sh Cora-learned-HB-${1}-${j}.psl Cora-eval-${1}.data ${j} HB Cora;
# done

# for j in Ranking Discrete; do
#   /usr/bin/time -v --output=Epinions/Epinions_HB_learn_time_fold_${1}_metric_${j} ./HB.sh Epinions.psl Epinions-learn-${1}.data ${2} ${j} Epinions;
#   cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-HB-${1}-${j}.psl;
#   /usr/bin/time -v --output=Epinions/Epinions_HB_inference_time_fold_${1}_metric_${j} ./inference.sh Epinions-learned-HB-${1}-${j}.psl Epinions-eval-${1}.data ${j} HB Epinions;
# done

# if ((${1}<=4));
# then
#   for j in Continuous Ranking; do
#     /usr/bin/time -v --output=LastFM/LastFM_HB_learn_time_fold_${1}_metric_${j} ./HB.sh LastFM.psl LastFM-learn-${1}.data ${2} ${j} LastFM;
#     cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-HB-${1}-${j}.psl;
#     /usr/bin/time -v --output=LastFM/LastFM_HB_inference_time_fold_${1}_metric_${j} ./inference.sh LastFM-learned-HB-${1}-${j}.psl LastFM-eval-${1}.data ${j} HB LastFM;
#   done
# fi

# for j in Continuous Ranking; do
#   /usr/bin/time -v --output=Jester/Jester_HB_learn_time_fold_${1}_metric_${j} ./HB.sh Jester.psl Jester-learn-${1}.data ${2} ${j} Jester;
#   cp Jester/Jester-learned.psl Jester/Jester-learned-HB-${1}-${j}.psl;
#   /usr/bin/time -v --output=Jester/Jester_HB_inference_time_fold_${1}_metric_${j} ./inference.sh Jester-learned-HB-${1}-${j}.psl Jester-eval-${1}.data ${j} HB Jester;
# done
 
  for j in Categorical; do
   ./HB.sh Citeseer.psl Citeseer-learn-${1}.data ${2} ${j} Citeseer; 
   cp Citeseer/Citeseer-learned.psl Citeseer/Citeseer-learned-HB-${1}-${j}.psl;
   ./inference.sh Citeseer-learned-HB-${1}-${j}.psl Citeseer-eval-${1}.data ${j} HB Citeseer;
 done

 for j in Categorical; do
   ./HB.sh Cora.psl Cora-learn-${1}.data ${2} ${j} Cora;
   cp Cora/Cora-learned.psl Cora/Cora-learned-HB-${1}-${j}.psl;
   ./inference.sh Cora-learned-HB-${1}-${j}.psl Cora-eval-${1}.data ${j} HB Cora;
 done

 for j in Discrete; do
   ./HB.sh Epinions.psl Epinions-learn-${1}.data ${2} ${j} Epinions;
   cp Epinions/Epinions-learned.psl Epinions/Epinions-learned-HB-${1}-${j}.psl;
   ./inference.sh Epinions-learned-HB-${1}-${j}.psl Epinions-eval-${1}.data ${j} HB Epinions;
 done

if ((${1}<=4));
then
  for j in Continuous; do
    ./HB.sh LastFM.psl LastFM-learn-${1}.data ${2} ${j} LastFM;
    cp LastFM/LastFM-learned.psl LastFM/LastFM-learned-HB-${1}-${j}.psl;
    ./inference.sh LastFM-learned-HB-${1}-${j}.psl LastFM-eval-${1}.data ${j} HB LastFM;
  done
fi

 for j in Continuous; do
   ./HB.sh Jester.psl Jester-learn-${1}.data ${2} ${j} Jester;
   cp Jester/Jester-learned.psl Jester/Jester-learned-HB-${1}-${j}.psl;
   ./inference.sh Jester-learned-HB-${1}-${j}.psl Jester-eval-${1}.data ${j} HB Jester;
 done
