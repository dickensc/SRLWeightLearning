readonly PSL_VERSION='2.3.0-SNAPSHOT'
readonly JAR_PATH="./psl-cli-${PSL_VERSION}.jar"
snapshotJARPath="$HOME/.m2/repository/org/linqs/psl-cli/${PSL_VERSION}/psl-cli-${PSL_VERSION}.jar"
cp "${snapshotJARPath}" "${JAR_PATH}"
tar -zxf y4rceuzg
rm y4rceuzg
wget -q https://tinyurl.com/y6hqz57a
mv y6hqz57a psl-cli-2.2.0-SNAPSHOT.jar
wget -q https://tinyurl.com/y5s8vacr
mv y5s8vacr psl-cli-max-margin.jar
