import pandas as pd
import sys

f = sys.argv[1]

x = pd.read_csv(f, header=None)
x.dropna(axis="columns", inplace=True)

print("mean: {}, std: {}".format(x.T.mean()[0], x.T.std()[0]))

