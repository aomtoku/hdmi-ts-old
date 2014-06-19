SRC = tb_uart.v ../rtl/nuart.v  ../rtl/nuart_clkgen.v  ../rtl/nuart_rx.v  ../rtl/nuart_tx.v

tb_system: $(SRC)
	iverilog -o tb_system $(SRC)

clean: 
	rm -f tb_system verilog.log test.vcd

.PHONY: clean isim wave
