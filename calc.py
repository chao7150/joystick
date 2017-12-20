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

#グラフのサイズを決める
plt.figure(figsize=(15,6))
#グラフの間隔・余白を決めるはずだがなぜか効かない
plt.subplots_adjust(hspace=0.4)
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
    #1行3列でグラフを並べるためのコマンド
    plt.subplot(1, 3, block + 1)
    #グラフの縦軸の範囲を決める。上限は便宜上100にしてあるが変えてもいい
    plt.ylim([0, 100])
    #点の色を黒にした。サイズはsオプション、点の形はmarkerオプションで指定する
    #参考:http://ailaby.com/plot_marker/
    plt.scatter(x, err, color='black', marker='*', s=5)
    #近似曲線は太めにした
    plt.plot(x, y, color='black', linewidth=3.0)
    #軸の数字のサイズを大きくした
    plt.tick_params(labelsize=18)
    '''
    #matplotlibで日本語を扱うのは結構面倒なのでwordやペイントで上から乗せたほうが楽だと思う
    plt.xlabel(u'試行')
    plt.ylabel(u'error(deg)')
    plt.title(u'learning curve')
    '''
plt.show()