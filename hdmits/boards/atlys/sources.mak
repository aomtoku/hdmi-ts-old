BOARD_SRC=$(wildcard $(BOARD_DIR)/*.v)

COMMON_SRC=$(wildcard $(CORES_DIR)/common/rtl/*.v)
GMII2FIFO_SRC=$(wildcard $(CORES_DIR)/gmii2fifo/rtl/*.v)
TIMING_SRC=$(wildcard $(CORES_DIR)/timing/rtl/*.v)
TMDS_TX_SRC=$(wildcard $(CORES_DIR)/tmds_tx/rtl/*.v)
COREGEN_SRC=$(wildcard $(CORES_DIR)/coregen/*.v)

CORES_SRC=$(COMMON_SRC) $(GMII2FIFO_SRC) $(TIMING_SRC) $(TMDS_TX_SRC) $(COREGEN_SRC)
