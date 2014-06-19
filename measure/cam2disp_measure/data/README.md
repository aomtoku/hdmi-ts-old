2014年 6月2日 update

# カメラの応答速度(処理速度) #

計測ロジック
- FPGA側からディスプレイへ, 黒の映像を流し続けている。  
- 計測開始ボタンを押す事で、FPGA側から流れる映像は白に切り替わる。 
- ディスプレイの左上に取りつけられた、照度センサが白に反応して、stop信号(high)をだす。 
- 100MHzのクロックで、開始から終了までカウントアップ  


## 計測手順

$ cd hdmi-ts/measure/cam2disp/boards/atlys/synthesis  
$ make  
$ make load  
  
- 照度センサをディスプレイの左上に固定
- Atlysボードのpushボタン上を押すと計測開始
- UARTで結果表示 (Baud Rate 1000000)

## 計測対象機器と結果 ##




## まとめ ##

LGおよびBENQのディスプレイは3.6msec ~ 6 msec弱の遅延がある。  
フレームに換算すると1/3フレームほど。  
一方で、Alienwareのディスプレイは, 10msec ~ 12msecとほぼ2/3フレームほど。  
ASUSのディスプレイは21msec ~ 26msec もあり1フレーム以上も遅延がある。


## 統計処理 ##

\# 改行コード処理(Windows -> Unix)
```
$ nkf -Lu input.txt > output.txt
```

\# バイナリ値から整数変換  
```
$ bash bc.sh input.txt > output.txt  
```

\# 統計処理  
```
$ ruby stat.rb output.txt  
```
計測結果  
  最大値/平均/中央値/標準偏差/最小値 



## 補足(個人メモ) ##

- 1280x720 progressive 60fps   
  1フレーム -> 16.666 msec  
  1ライン   -> 22.222 μsec  
  1ピクセル -> 13.468 nsec 
- 1920x1080 progressive 60fps  
  1フレーム -> 16.666 msec  
  1ライン   -> 14.814 μsec  
  1ピクセル ->  6.734 nsec 


