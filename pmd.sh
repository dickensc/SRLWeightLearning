echo "------Citeseer-------"
echo "*F1*"
grep -o "F1: ......." run_eval_${1}_Citeseer-eval-*.data_Discrete.out|grep -o "F1: ......."|sed "s/F1: //g"|tr "\n" ",">"Citeseer-${1}-eval-F1.csv";
python print_mean_std.py "Citeseer-${1}-eval-F1.csv"
echo "*Accuracy*"
grep -o "Accuracy: ......." run_eval_${1}_Citeseer-eval-*.data_Categorical.out|grep -o "Accuracy: ......."|sed "s/Accuracy: //g"|tr "\n" ","> "Citeseer-${1}-eval-Accuracy.csv";
python print_mean_std.py "Citeseer-${1}-eval-Accuracy.csv"
echo "------Cora-------"
echo "*F1*"
grep -o "F1: ......." run_eval_${1}_Cora-eval-*.data_Discrete.out|grep -o "F1: ......."|sed "s/F1: //g"|tr "\n" ",">"Cora-${1}-eval-F1.csv";
python print_mean_std.py "Cora-${1}-eval-F1.csv"
echo "*Accuracy*"
grep -o "Accuracy: ......." run_eval_${1}_Cora-eval-*.data_Categorical.out|grep -o "Accuracy: ......."|sed "s/Accuracy: //g"|tr "\n" ",">"Cora-${1}-eval-Accuracy.csv";
python print_mean_std.py "Cora-${1}-eval-F1.csv"
echo "------Epinions-------"
echo "*F1*"
grep -o "F1: ......." run_eval_${1}_Epinions-eval-*.data_Discrete.out|grep -o "F1: ......."|sed "s/F1: //g"|tr "\n" ",">"Epinions-${1}-eval-F1.csv"; 
python print_mean_std.py "Epinions-${1}-eval-F1.csv"
echo "*AUROC*"
grep -o "AUROC: ......." run_eval_${1}_Epinions-eval-*.data_Ranking.out|grep -o "AUROC: ......."|sed "s/AUROC: //g"|tr "\n" ",">"Epinions-${1}-eval-AUROC.csv";
python print_mean_std.py "Epinions-${1}-eval-AUROC.csv"
echo "------LastFM-------"
echo "*MSE*"
grep -o "MSE: ......." run_eval_${1}_LastFM-eval-*.data_Continuous.out|grep -o "MSE: ......."|sed "s/MSE: //g"|tr "\n" ",">"LastFM-${1}-eval-MSE.csv";
python print_mean_std.py "LastFM-${1}-eval-MSE.csv"
echo "*AUROC*"
grep -o "AUROC: ......." run_eval_${1}_LastFM-eval-*.data_Ranking.out|grep -o "AUROC: ......."|sed "s/AUROC: //g"|tr "\n" ",">"LastFM-${1}-eval-AUROC.csv"; 
python print_mean_std.py "LastFM-${1}-eval-AUROC.csv"
echo "------Jester-------"
echo "*MSE*"
grep -o "MSE: ......." run_eval_${1}_Jester-eval-*.data_Continuous.out|grep -o "MSE: ......."|sed "s/MSE: //g"|tr "\n" ",">"Jester-${1}-eval-MSE.csv";
python print_mean_std.py "Jester-${1}-eval-MSE.csv"
echo "*AUROC*"
grep -o "AUROC: ......." run_eval_${1}_Jester-eval-*.data_Ranking.out|grep -o "AUROC: ......."|sed "s/AUROC: //g"|tr "\n" ",">"Jester-${1}-eval-AUROC.csv";
python print_mean_std.py "Jester-${1}-eval-AUROC.csv"
