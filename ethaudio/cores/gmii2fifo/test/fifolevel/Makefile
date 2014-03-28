SRC = tb_gmii2fifo.v ../../rtl/gmii_rec.v ../../../crc/rtl/crc_gen.v ../../../timing/rtl/tmds_timing.v ../../../fifo/test/afifo48.v ../../../fifo/test/asfifo.v ../../../fifo/test/graycounter.v ../../../fifo/test/afifo12.v ../../../timing/rtl/timing_gen.v ../../../gmii_tx/rtl/gmii_tx.v ../../../fifo/test/afifo29.v ../../../common/rtl/datacontroller.v

tb_system: $(SRC)
	iverilog -o tb_system $(SRC)

sim: 
	./tb_system
	gtkwave test.vcd

mem: 
	cd ./gen_mem && gcc gen_amem.c -o gen_amem
	./gen_mem/gen_amem > ./arequest.mem
	cd ./gen_mem && gcc gen_vmem.c -o gen_vmem
	./gen_mem/gen_vmem > ./vrequest.mem

clean: 
	rm -f tb_system verilog.log test.vcd

.PHONY: clean isim wave
