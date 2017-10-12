import pandas
from scipy import optimize as opt
import matplotlib.pyplot as plt
import numpy as np

def logcurve(x, a, b, c):
    return a + b * np.exp((-c) * x)

filename = input("input file path: ")
dataframe = pandas.read_csv(filename)

BLOCK_NUM = dataframe["block"].max() + 1
CYCLE_NUM = dataframe["cycle"].max() + 1

for block in range(BLOCK_NUM):
    blockdata = dataframe.query("block == @block")
    err = blockdata["errordeg"].values.flatten()
    x = list(range(1, 121))
    res = opt.curve_fit(logcurve, x, err)
    params = res[0]
    print(params)
    y = []
    for s in x:
        y.append(logcurve(s, *params))
    plt.plot(x, err)
    plt.plot(x, y)
    plt.show()