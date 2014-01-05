setMode -pff
setPreference -pref StartupClock:Auto_Correction
setSubmode -pffspi
addDesign -version 0 -name "0"
addDeviceChain -index 0
addDevice -spi N25Q128 -p 1 -file top.bit
generate -format mcs -generic -spi -fillvalue FF -output top.mcs

setMode -bs
setCable -port auto
Identify -inferir
attachflash -position 1 -spi N25Q128
assignfiletoattachedflash -position 1 -file top.mcs
Program -p 1 -dataWidth 1 -spionly -e -v -loadfpga
quit
