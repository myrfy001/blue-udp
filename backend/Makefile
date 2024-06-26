ROOT_DIR = $(abspath ../)
SCRIPTS_DIR = $(ROOT_DIR)/scripts
include $(SCRIPTS_DIR)/Makefile.base
LOCALSRCDIR = $(ROOT_DIR)/src:$(ROOT_DIR)/src/includes
LIB_CRC_DIR = $(ROOT_DIR)/lib/blue-crc/src
LIB_WRAPPER_DIR = $(ROOT_DIR)/lib/blue-wrapper/src
LIBSRCDIR = $(LIB_CRC_DIR):$(LIB_WRAPPER_DIR)
CRC_TAB_SCRIPT = $(ROOT_DIR)/lib/blue-crc/scripts/gen_crc_tab.py

PWD = $(shell pwd)
VLOGDIR = generated
OUTPUTDIR = output_ooc
ONLYSYNTH = 0
CLK = main_clock

TARGET = UdpIpArpEthRxTx
TARGET_FILE ?= $(ROOT_DIR)/src/$(TARGET).bsv
TOPMODULE ?= mkRaw$(TARGET)
SUPPORT_RDMA ?= True

export TOP = $(TOPMODULE)
export RTL = $(VLOGDIR)
export XDC = $(PWD)
export OUTPUT = $(OUTPUTDIR)
export SYNTHONLY = $(ONLYSYNTH)
export CLOCKS = $(CLK)

MACROFLAGS = -D IS_SUPPORT_RDMA=$(SUPPORT_RDMA)

table:
ifeq ($(SUPPORT_RDMA), True)
	python3 $(CRC_TAB_SCRIPT) $(SCRIPTS_DIR)/crc_ieee_32_1024.json $(PWD)
endif

compile:
	mkdir -p $(BUILDDIR)
	bsc -elab -sim -verbose $(BLUESIMFLAGS) $(DEBUGFLAGS) $(DIRFLAGS) $(MISCFLAGS) $(RECOMPILEFLAGS) $(RUNTIMEFLAGS) $(SCHEDFLAGS) $(TRANSFLAGS) $(MACROFLAGS) -g $(TOPMODULE) $(TARGET_FILE)

verilog: compile
	mkdir -p $(VLOGDIR)
	bsc $(VERILOGFLAGS) $(DIRFLAGS) $(MISCFLAGS) $(RECOMPILEFLAGS) $(RUNTIMEFLAGS) $(TRANSFLAGS) $(MACROFLAGS) -g $(TOPMODULE) $(TARGET_FILE)
	bluetcl $(SCRIPTS_DIR)/listVlogFiles.tcl -bdir $(BUILDDIR) -vdir $(BUILDDIR) $(TOPMODULE) $(TOPMODULE) | grep -i '\.v' | xargs -I {} cp {} $(VLOGDIR)

vivado: verilog table
	vivado -mode batch -source non_project_build.tcl 2>&1 | tee ./run.log

clean:
	rm -rf $(BUILDDIR) $(VLOGDIR) $(OUTPUTDIR) .Xil *.jou *.log *.mem

.PHONY: compile verilog clean vivado
.DEFAULT_GOAL := vivado
