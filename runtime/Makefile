.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> VER=<host_cl/host_xrt>"
	$(ECHO) "      Command to pick the specific files and generates the design for specified Target and Device."
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO) "  make check TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) ""
	$(ECHO) " make exe VER=<host_cl/host_xrt>"
	$(ECHO) ""

# compiler tools
XILINX_VITIS ?= /tools/Xilinx/Vitis/2021.1
XILINX_XRT ?= /opt/xilinx/xrt
VPP := v++
CXX ?= g++


RM = rm -f
RMDIR = rm -rf

TARGET := hw
DEVICE := xilinx_u280_xdma_201920_3
KERNEL_NAME := gnn_0
VER ?= host_cl

BUILD_DIR := ./_x.$(TARGET)
XCLBIN := ./xclbin

# host compiler global settings
# The below are compile flags are passed to the C++ Compiler
CXXFLAGS += -std=c++1y -DVITIS_PLATFORM=$(DEVICE) -D__USE_XOPEN2K8 -I$(XILINX_XRT)/include/ -I/tools/Xilinx/Vivado/2021.1/include/ -O2 -g -Wall -fmessage-length=0
# The below are linking flags for C++ Comnpiler openCL
opencl_LDFLAGS += -lxilinxopencl -lpthread -lrt -lstdc++ -L$(XILINX_XRT)/lib/ -Wl,-rpath-link,$(XILINX_XRT)/lib
# The below are linking flags for C++ Comnpiler XRT
xrt_LDFLAGS += -lxrt_core -lhiredis -ldl -luuid -lxrt_coreutil -lxilinxopencl -pthread -lpthread -lrt -lstdc++ -L$(XILINX_XRT)/lib/ -Wl,-rpath-link,$(XILINX_XRT)/lib

ifeq ($(VER),host_xrt)
LDFLAGS += $(xrt_LDFLAGS)
else
LDFLAGS += $(opencl_LDFLAGS)
endif

# kernel compiler global settings
VPP_FLAGS = -t $(TARGET) --platform $(DEVICE) -g --save-temps --config design.cfg
# VPP_FLAGS = -t hw --platform $(DEVICE) -g --save-temps 

EXECUTABLE = $(VER).exe
HOST_CL_SRCS += host/host_cl.cpp
HOST_CL_HDRS +=  
HOST_XRT_SRCS += host/host_xrt.cpp
HOST_XRT_HDRS += 

BINARY_CONTAINERS += $(XCLBIN)/$(KERNEL_NAME).$(TARGET).xclbin
BINARY_CONTAINER_OBJS += GNN_kernels/src/vitis_rtl_kernel/gnn_0/gnn_0.xo


# make rules
.PHONY: all clean cleanall check exe
all: $(host_change) $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig Makefile check-devices check_xrt

host_change: $(VER)

exe: $(EXECUTABLE)

# Building Kernel
$(BINARY_CONTAINERS): $(BINARY_CONTAINER_OBJS)
	mkdir -p $(XCLBIN)
	$(VPP) $(VPP_FLAGS) -l $(BINARY_CONTAINER_OBJS) -o "$@" --temp_dir $(BUILD_DIR) 

# Building Host
ifeq ($(VER),host_xrt)
$(EXECUTABLE): $(HOST_XRT_SRCS) # $(HOST_XRT_HDRS)
	mkdir -p $(XCLBIN)
	$(CXX) $(CXXFLAGS) $(HOST_XRT_SRCS) -o '$@' $(LDFLAGS)
else
$(EXECUTABLE): $(HOST_CL_SRCS) # $(HOST_OPENCL_HDRS)
	mkdir -p $(XCLBIN)
	$(CXX) $(CXXFLAGS) -I/usr/local/include/yaml-cpp/ $(HOST_CL_SRCS) -o '$@' $(LDFLAGS) -L/usr/local/lib/libyaml-cpp.so -lyaml-cpp
endif

# for emulatiom
emconfig:
	emconfigutil --platform $(DEVICE)

# run
check: all # run
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) $(XCLBIN)/$(KERNEL_NAME).$(TARGET).xclbin
else
	unset XCL_EMULATION_MODE 
	./$(EXECUTABLE) $(XCLBIN)/$(KERNEL_NAME).$(TARGET).xclbin
endif

check-devices:
ifndef DEVICE
	$(error DEVICE not set. Please set the DEVICE properly and rerun. Run "make help" for more details.)
endif

check_xrt:
ifndef XILINX_XRT
	$(error XILINX_XRT variable is not set, please set correctly and rerun)
endif

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE) $(XCLBIN)/{*sw_emu*,*hw_emu*}
	-$(RMDIR) TempConfig system_estimate.xtxt *.rpt
	-$(RMDIR) *.protoinst _v++_* .Xil emconfig.json dltmp* xmltmp* *.log *.jou *.csv *.wcfg *.wdb

cleanall: clean
	-$(RMDIR) $(XCLBIN)
	-$(RMDIR) _x.*
