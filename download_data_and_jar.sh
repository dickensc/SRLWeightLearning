readonly PSL_VERSION='2.3.0-SNAPSHOT'
readonly JAR_PATH="./psl-cli-${PSL_VERSION}.jar"
snapshotJARPath="$HOME/.m2/repository/org/linqs/psl-cli/${PSL_VERSION}/psl-cli-${PSL_VERSION}.jar"
cp "${snapshotJARPath}" "${JAR_PATH}"
wget -q https://tinyurl.com/y4rceuzg
tar -zxf y4rceuzg
rm y4rceuzg
wget -q https://tinyurl.com/y5s8vacr
mv y5s8vacr psl-cli-max-margin.jar