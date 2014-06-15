2014年 6月15日 update

# HDMI-TS Decode Encode間の伝送遅延 #

計測ロジック
- FPGA側からディスプレイへ, 黒の映像を流し続けている。  
- 計測開始ボタンを押す事で、FPGA側から流れる映像は白に切り替わる。 
- 受信側で白を認識後、GPIOピンからhighを流す。
- ピクセルクロックで、開始から終了までカウントアップ  


## 計測手順

$ cd hdmi-ts/display_measure/boards/atlys/synthesis  
$ make  
$ make load  
  
- 照度センサをディスプレイの左上に固定
- Atlysボードのpushボタン上を押すと計測開始
- LEDでバイナリ値を表示

## 結果 ##


*  解像度     1280x720 progressive 60fps   
  Interface  HDMI -> 1m, 2m  

16 クロックサイクル (クロック74.25MHz)
  --> 215.5 ns

*  解像度     1920x1080 progressive 60fps   
  Interface  HDMI -> 1m, 2m  

18 クロックサイクル (クロック148.5MHz)
  --> 121.212 ns

## まとめ ##

TMDSのデコード - エンコード間でのlatencyを計測した。
この計測では、HDMIケーブルの長さにより、数ns影響を与える。
しかし、1m, 2mの変化では、結果は変わらなかった。
1m, 2mのHDMIケーブルでは、720pで215.5 ns 程の遅延があった。
16クロックサイクル程度。
1080pでは121.212nsの遅延があった。
18クロックサイクル程度。


## 補足(個人メモ) ##

- 1280x720 progressive 60fps   
  1フレーム -> 16.666 msec  
  1ライン   -> 22.222 μsec  
  1ピクセル -> 13.468 nsec 
- 1920x1080 progressive 60fps  
  1フレーム -> 16.666 msec  
  1ライン   -> 14.814 μsec  
  1ピクセル ->  6.734 nsec 


