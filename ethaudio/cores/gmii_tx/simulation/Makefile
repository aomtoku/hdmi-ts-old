SRC = tb_gmiisend.v ../rtl/gmii_tx.v ../../crc/rtl/crc_gen.v ../../timing/rtl/timing_gen.v

tb_system: $(SRC)
	iverilog -o tb_system $(SRC)

sim: 
	./tb_system
	gtkwave test.vcd


clean: 
	rm -f tb_system verilog.log test.vcd

.PHONY: clean isim wave
