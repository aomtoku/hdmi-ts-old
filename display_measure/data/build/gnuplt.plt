########################################################################################
#
#        Gnuplot Template
#           Author : Yuta Tokusashi
#           Date   : 24th, May 2014
# 
#         You can use this with commenting out, depending on ocation.
#        This Reference by
#           http://www.ss.scphys.kyoto-u.ac.jp/person/yonezawa/contents/program/gnuplot/index.html
########################################################################################

#########################################################################################
# Define Multi Plot
### set multiplot layout (縦の図の数),(横の図の数)
### #you need 3 plot sentences below setence.
#########################################################################################
#set multiplot layout 3,1


#########################################################################################
# Define png OUTPUT style
#########################################################################################
#set term png
#set output 'latency_dis.png'

#########################################################################################
### Define eps OUTPUT style
###    you can change Font and Font's SIZE
###       色付き --> color
###       白黒   --> monochrome
###       グレー --> gray
###         上付き添字や下付き添字、ギリシャ文字を使いたいなら --> enhanced
###       使用できるフォントは以下をチェック
###         PATH --> "/System/Library/Fonts!" "/Library/Fonts!" "/Users/toku1938/Library/Fonts!" 
###        Microsoft ---> "/Library/Fonts/Microsoft"
###         - "Arial", "Times New Roman"
###         - "MS Gothic"
##########################################################################################
set terminal postscript eps color enhanced "Arial" 20
set output 'latency_disp.eps'


#########################################################################################
# Define Graph TITLE (Entire)
#########################################################################################
set title "Measurement of Display Response Time"

#########################################################################################
# Define histogram
#    you need plot with boxes
#########################################################################################
#set style data histograms
#set style histogram clustered

#########################################################################################
# Define boxwidth
#########################################################################################
set boxwidth 0.5

#########################################################################################
# Define boxwidth
#########################################################################################
#set logscale   ## setting LogLog Scale
#set logscale x ## setting log scale only X

#########################################################################################
# Define Graph Range
#########################################################################################
set xrange [-0.5:5]
#set yrange [0:1200]

#########################################################################################
# Define TIME FORMAT
#     2004/4/6    --> %Y/%m/%d
#     2004/Jan    --> %Y/%b
#     December/96 --> %B/%y
#     1970/240    --> %Y/%j
#     02:45:03	  --> %H:%M:%S
#########################################################################################
#set xdata time
#set timefmt "%H:%M:%S"

#########################################################################################
# Define Label
#########################################################################################
set xlabel "Display Model Number"
set ylabel "Latency (usec)"

#########################################################################################
# Define Grid enable
#########################################################################################
set grid y
#set grid x

#########################################################################################
### X軸の項目を回転させる offsetで文字を横にずらすことができる
#########################################################################################
#set xtics rotate by -90 offset first 0.1, 0

#########################################################################################
### X軸,Y軸の目盛りを変更
#########################################################################################
#set xtics 2000
#set mxtics 1000
#set format x '%.3f' # x軸の目盛の表示形式を変更する

#########################################################################################
### Title Position
#########################################################################################
set key left top
set style fill solid
set bars large
#########################################################################################
# Define Plot
#########################################################################################

#plot "res.txt" using 0:3:xtic(1) with boxes title "max min", \

plot "res.txt" using 0:2:2:6:6:xtic(1) with candlesticks title "value range", \
"res.txt" using 0:3:5 with e title "stddev", \
"res.txt" using 0:4 with p title "median"
#plot "template.txt" using 1:2 with linespoints notitle
#plot "template.txt" using 1:2 with lines notitle
#plot "template.txt" using 1:($2/300) title ’requests’ with steps
