# 2.2.0
wget -q https://tinyurl.com/y6hqz57a
mv y6hqz57a psl-cli-2.2.0-SNAPSHOT.jar

wget -q https://tinyurl.com/y4rceuzg
tar -zxf y4rceuzg
rm y4rceuzg
wget -q https://tinyurl.com/y5s8vacr
mv y5s8vacr psl-cli-max-margin.jar

# move data into dataset directories
rm -r ./Citeseer/data; mkdir ./Citeseer/data
mv ./data/citeseer ./Citeseer/data/citeseer/

rm -r ./Cora/data; mkdir ./Cora/data
mv ./data/cora ./Cora/data/cora/

rm -r ./Epinions/data; mkdir ./Epinions/data
mv ./data/epinions ./Epinions/data/epinions/

rm -r ./Jester/data; mkdir ./Jester/data
mv ./data/jester ./Jester/data/jester/

rm -r ./LastFM/data; mkdir ./LastFM/data
mv ./data/lastfm ./LastFM/data/lastfm/