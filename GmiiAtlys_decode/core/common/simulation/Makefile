SRC = tb_apple_out.v ../apple_out.v ../../gmii2fifo48/rtl/gmii_rec.v

tb_system: $(SRC)
	iverilog -o tb_system $(SRC)

clean: 
	rm -f tb_system verilog.log test.vcd

.PHONY: clean isim wave
