#!/bin/sh

echo "Compiling..."
mvn compile > /dev/null
mvn dependency:build-classpath -Dmdep.outputFile=classpath.out > /dev/null
mkdir output > /dev/null

#echo "Running MRF on Citeseer..."
#java -Xmx10g -cp ./target/classes:`cat classpath.out` edu.umd.cs.bachuai13.CollectiveClassification citeseer bool 0 > output/citeseer.mrf.out

echo "Running MRF on Cora..."
java -Xmx10g -cp ./target/classes:`cat classpath.out` edu.umd.cs.bachuai13.CollectiveClassification cora bool 0 > output/cora.mrf.out

echo "Processing results..."
cd src/main/matlab
matlab -nodesktop -nosplash -r parse_cc
