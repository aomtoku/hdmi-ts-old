SRC = tb_hdmioverip.v ../../../cores/common/rtl/datacontroller.v  ../../../cores/gmii2fifo/rtl/gmii_rec.v ../../../cores/fifo/test/asfifo.v ../../../cores/fifo/test/afifo48.v ../../../cores/fifo/test/graycounter.v ../../../cores/timing/rtl/timing.v 

tb_system: $(SRC)
	iverilog -o tb_system $(SRC)

clean: 
	rm -f tb_system verilog.log test.vcd

.PHONY: clean isim wave
