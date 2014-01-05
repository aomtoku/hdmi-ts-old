setMode -bs
setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Identify -inferir 
identifyMPM 
attachflash -position 1 -spi "N25Q128"
assignfiletoattachedflash -position 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/Untitled.mcs"
Program -p 1 -dataWidth 1 -spionly -e -v -loadfpga 
Program -p 1 -dataWidth 4 -spionly -e -v -loadfpga 
setMode -pff
setMode -pff
addConfigDevice  -name "Untitled" -path "/home/aom/Work/Lx9Proto/boards/atlys/synthesis/build"
setSubmode -pffspi
setAttribute -configdevice -attr multibootBpiType -value ""
addDesign -version 0 -name "0"
setMode -pff
addDeviceChain -index 0
setMode -pff
addDeviceChain -index 0
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr autoSize -value "FALSE"
setAttribute -configdevice -attr fileFormat -value "mcs"
setAttribute -configdevice -attr fillValue -value "FF"
setAttribute -configdevice -attr swapBit -value "FALSE"
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr spiSelected -value "TRUE"
setAttribute -configdevice -attr spiSelected -value "TRUE"
addPromDevice -p 1 -size 512 -name 512K
setMode -pff
setMode -pff
setMode -pff
setMode -pff
addDeviceChain -index 0
setMode -pff
addDeviceChain -index 0
setSubmode -pffspi
setMode -pff
setAttribute -design -attr name -value "0000"
addDevice -p 1 -file "/home/aom/Work/Lx9Proto/boards/atlys/synthesis/build/top.bit"
addPromDevice -p 2 -size 1024 -name 1M
deletePromDevice -position 1
addPromDevice -p 2 -size 2048 -name 2M
deletePromDevice -position 1
cutDevice -p 1
addPromDevice -p 2 -size 512 -name 512K
deletePromDevice -position 1
setMode -pff
addDevice -p 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/top.bit"
setMode -pff
setSubmode -pffspi
generate
setCurrentDesign -version 0
setMode -pff
setSubmode -pffspi
generate
setCurrentDesign -version 0
setMode -bs
setMode -bs
setMode -bs
Identify -inferir 
identifyMPM 
attachflash -position 1 -spi "N25Q128"
assignfiletoattachedflash -position 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/Untitled.mcs"
Program -p 1 -dataWidth 1 -spionly -e -v -loadfpga 
Program -p 1 -dataWidth 1 -spionly -e -v -loadfpga 
ReadStatusRegister -p 1 -spi 
ReadUsercode -p 1 
ReadIdcode -p 1 
Checksum -p 1 -spionly 
ReadStatusRegister -p 1 -spionly 
ReadStatusRegister -p 1 -spionly 
BlankCheck -p 1 -spionly 
Erase -p 1 -spionly 
Verify -p 1 -spionly 
attachflash -position 1 -spi "N25Q256"
assignfiletoattachedflash -position 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/Untitled.mcs"
Checksum -p 1 -spionly 
ReadStatusRegister -p 1 -spionly 
attachflash -position 1 -spi "N25Q128"
assignfiletoattachedflash -position 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/Untitled.mcs"
ReadStatusRegister -p 1 -spionly 
Checksum -p 1 -spionly 
Program -p 1 -dataWidth 4 -spionly -e -v -loadfpga 
attachflash -position 1 -spi "N25Q128"
assignfiletoattachedflash -position 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/top.mcs"
Program -p 1 -dataWidth 1 -spionly -e -v -loadfpga 
attachflash -position 1 -spi "N25Q128"
assignfiletoattachedflash -position 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/top.mcs"
Program -p 1 -dataWidth 4 -spionly -e -v -loadfpga 
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/top.bit"
attachflash -position 1 -spi "N25Q128"
assignfiletoattachedflash -position 1 -file "/home/aom/Work/ver/Atlys/Lx9Proto/boards/atlys/synthesis/build/top.mcs"
attachflash -position 1 -spi "N25Q128"
Program -p 1 -dataWidth 1 -spionly -e -v 
setMode -pff
setSubmode -pffspi
setSubmode -pffspi
setMode -bs
setMode -bs
setMode -bs
setMode -pff
setSubmode -pffspi
setSubmode -pffspi
setMode -bs
setMode -bs
setMode -bs
setMode -pff
set