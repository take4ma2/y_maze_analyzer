# Y maze test analyzer

## はじめに

Y mazeのテストデータを利用して解析を行うためのruby製ツール。

解析時間を8分に固定して設定してあります。

変えたいときは、

`ymaze.rb`をテキストエディタ等で開き、 

```
6  EXP_TERMINATE = 8.0 * 60.0  # Experiment terminated at. (sec)
```

6行目の`EXP_TERMINATE`を設定したい解析時間(sec.)に変更し、保存してご使用ください。


