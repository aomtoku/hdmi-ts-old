BOARD_SRC=$(wildcard $(BOARD_DIR)/top.v)

COMMON_SRC=$(wildcard $(CORES_DIR)/common/rtl/*.v)
TMDS_RX_SRC=$(wildcard $(CORES_DIR)/tmds_rx/rtl/*.v)
TMDS_TX_SRC=$(wildcard $(CORES_DIR)/tmds_tx/rtl/*.v)
COREGEN_SRC=$(wildcard $(CORES_DIR)/coregen/*.v)
TIMING_SRC=$(wildcard $(CORES_DIR)/timing/rtl/*.v)
UART_SRC=$(wildcard $(CORES_DIR)/uart/rtl/*.v)

CORES_SRC=$(COMMON_SRC) $(TMDS_RX_SRC) $(TMDS_TX_SRC) $(COREGEN_SRC) $(TIMING_SRC) $(UART_SRC)
