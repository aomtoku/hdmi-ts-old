BOARD_SRC=$(wildcard $(BOARD_DIR)/top.v)

COMMON_SRC=$(wildcard $(CORES_DIR)/common/rtl/*.v)
TMDS_RX_SRC=$(wildcard $(CORES_DIR)/rx/rtl/*.v)
TMDS_TX_SRC=$(wildcard $(CORES_DIR)/tx/rtl/*.v)
COREGEN_SRC=$(wildcard $(CORES_DIR)/coregen/*.v)

CORES_SRC=$(COMMON_SRC) $(TMDS_RX_SRC) $(TMDS_TX_SRC) $(COREGEN_SRC)
