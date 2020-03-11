echo "------Citeseer-------"
echo "*F1*"
grep -o "F1: ......." Citeseer/run_eval_${1}_Citeseer-eval-*.data_Discrete.out|grep -o "F1: ......."|sed "s/F1: //g"|tr "\n" "," > "Citeseer/Citeseer-${1}-eval-F1.csv";
python print_mean_std.py "Citeseer/Citeseer-${1}-eval-F1.csv"
echo "*Accuracy*"
grep -o "Accuracy: ......." Citeseer/run_eval_${1}_Citeseer-eval-*.data_Categorical.out|grep -o "Accuracy: ......."|sed "s/Accuracy: //g"|tr "\n" ","> "Citeseer/Citeseer-${1}-eval-Accuracy.csv";
python print_mean_std.py "Citeseer/Citeseer-${1}-eval-Accuracy.csv"
echo "------Cora-------"
echo "*F1*"
grep -o "F1: ......." Cora/run_eval_${1}_Cora-eval-*.data_Discrete.out|grep -o "F1: ......."|sed "s/F1: //g"|tr "\n" ",">"Cora/Cora-${1}-eval-F1.csv";
python print_mean_std.py "Cora/Cora-${1}-eval-F1.csv"
echo "*Accuracy*"
grep -o "Accuracy: ......." Cora/run_eval_${1}_Cora-eval-*.data_Categorical.out|grep -o "Accuracy: ......."|sed "s/Accuracy: //g"|tr "\n" ",">"Cora/Cora-${1}-eval-Accuracy.csv";
python print_mean_std.py "Cora/Cora-${1}-eval-F1.csv"
echo "------Epinions-------"
echo "*F1*"
grep -o "F1: ......." Epinions/run_eval_${1}_Epinions-eval-*.data_Discrete.out|grep -o "F1: ......."|sed "s/F1: //g"|tr "\n" ",">"Epinions/Epinions-${1}-eval-F1.csv"; 
python print_mean_std.py "Epinions/Epinions-${1}-eval-F1.csv"
echo "*AUROC*"
grep -o "AUROC: ......." Epinions/run_eval_${1}_Epinions-eval-*.data_Ranking.out|grep -o "AUROC: ......."|sed "s/AUROC: //g"|tr "\n" ",">"Epinions/Epinions-${1}-eval-AUROC.csv";
python print_mean_std.py "Epinions/Epinions-${1}-eval-AUROC.csv"
echo "------LastFM-------"
echo "*MSE*"
grep -o "MSE: ......." LastFM/run_eval_${1}_LastFM-eval-*.data_Continuous.out|grep -o "MSE: ......."|sed "s/MSE: //g"|tr "\n" ",">"LastFM/LastFM-${1}-eval-MSE.csv";
python print_mean_std.py "LastFM/LastFM-${1}-eval-MSE.csv"
echo "*AUROC*"
grep -o "AUROC: ......." LastFM/run_eval_${1}_LastFM-eval-*.data_Ranking.out|grep -o "AUROC: ......."|sed "s/AUROC: //g"|tr "\n" ",">"LastFM/LastFM-${1}-eval-AUROC.csv"; 
python print_mean_std.py "LastFM/LastFM-${1}-eval-AUROC.csv"
echo "------Jester-------"
echo "*MSE*"
grep -o "MSE: ......." Jester/run_eval_${1}_Jester-eval-*.data_Continuous.out|grep -o "MSE: ......."|sed "s/MSE: //g"|tr "\n" ",">"Jester/Jester-${1}-eval-MSE.csv";
python print_mean_std.py "Jester/Jester-${1}-eval-MSE.csv"
echo "*AUROC*"
grep -o "AUROC: ......." Jester/run_eval_${1}_Jester-eval-*.data_Ranking.out|grep -o "AUROC: ......."|sed "s/AUROC: //g"|tr "\n" ",">"Jester/Jester-${1}-eval-AUROC.csv";
python print_mean_std.py "Jester/Jester-${1}-eval-AUROC.csv"
