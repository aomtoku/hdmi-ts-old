SRC = tb_adpcm.v ../rtl/adpcm.v

tb_system: $(SRC)
	iverilog -o tb_system $(SRC)

clean: 
		rm -f tb_system test.vcd

.PHONY: clean isim wave
