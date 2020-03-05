./download_data_and_jar.sh
echo "Running all methods. This might take a few days to finish...."
#./run_all_BOWLSS.sh
#./run_all_BOWLOS.sh
#./run_all_LME.sh
#./run_all_MLE.sh
#./run_all_MPLE.sh
./run_all_RGS.sh
./run_all_CRGS.sh
./run_all_HB.sh

echo "Finished running all experiments. Printing results next"
#echo "******--------BOWLSS--------******"
#./pmd.sh bowlSS
#echo "******--------BOWLOS--------******"
#./pmd.sh bowlOS
#echo "******--------LME--------******"
#./pmd.sh LME
#echo "******--------MPLE--------******"
#./pmd.sh MPLE
#echo "******--------MLE--------******"
#./pmd.sh MLE
echo "******--------RGS--------******"
./pmd.sh RGS
echo "******--------CRGS--------******"
./pmd.sh CRGS
echo "******--------HB--------******"
./pmd.sh HB
