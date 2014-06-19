2014年 6月2日 update

# ディスプレイの応答速度(処理速度) #

計測ロジック
- FPGA側からディスプレイへ, 黒の映像を流し続けている。  
- 計測開始ボタンを押す事で、FPGA側から流れる映像は白に切り替わる。 
- ディスプレイの左上に取りつけられた、照度センサが白に反応して、stop信号(high)をだす。 
- 100MHzのクロックで、開始から終了までカウントアップ  


## 計測手順

$ cd hdmi-ts/display_measure/boards/atlys/synthesis  
$ make  
$ make load  
  
- 照度センサをディスプレイの左上に固定
- Atlysボードのpushボタン上を押すと計測開始
- LEDでバイナリ値を表示

## 計測対象機器と結果 ##


 ![figure](http://web.sfc.wide.ad.jp/~aom/img/latency_dis_all.png)

*  解像度     1280x720 progressive 60fps   
  Interface  HDMI  

|Display|Maxmum(usec)|Average(usec)|Median(usec)|Standard Deviation|Minimum(usec)|
|-------|------|-------|------|---------|-------|
|LG L246WH|6305.0|4508.9|3809.3|668.5|3637.0|
|LG 22EN43|5773.0|4611.0|4523.9|280.6|4239.0|
|Alienware AW2310|11949.0|11211.3|10833.0|534.3|10205.0|
|BenQ G2420HD|5056.0|3977.0|3792.8|287.1|3731.0|
|BenQ E2200HD|31737.0|17908.7|18124.2|3456.9|13263.0|
|Acer S231HL|11903.0|11879.5|11869.8|15.8|11836.0|
|ASUS VG236H|23079.0|21960.2|21811.2|320.1|21685.0|

 
*  解像度     1920x1080 progressive 60fps   
  Interface  HDMI  

|Display|Maxmum(usec)|Average(usec)|Median(usec)|Standard Deviation|Minimum(usec)|
|-------|------|-------|------|---------|-------|
|LG L246WH|9301.0|5171.9|5362.3|2157.3|872.0|
|LG 22EN43|3731.0|3496.3|3413.4|121.0|3272.0|
|Alienware AW2310|5613.0|5187.2|5539.2|395.2|4487.0|
|BenQ G2420HD|4576.0|3046.5|3020.8|372.6|2606.0|
|BenQ E2200HD|11405.0|9341.9|8746.4|974.8|7865.0|
|Acer S231HL|17517.0|12226.8|11938.9|1416.4|11687.0|
|ASUS VG236H|21079.0|20817.9|20805.1|89.5|20693.0|
|Sharp LC-40H11|63506.0|53937.7|53033.1|2003.0|51877.0|


## まとめ ##

LGおよびBENQのディスプレイは3.6msec ~ 6 msec弱の遅延がある。  
フレームに換算すると1/3フレームほど。  
一方で、Alienwareのディスプレイは, 10msec ~ 12msecとほぼ2/3フレームほど。  
ASUSのディスプレイは21msec ~ 26msec もあり1フレーム以上も遅延がある。


## 統計処理 ##

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


