# Toolchain (override on the command line if needed, e.g. make CXX=clang++)
CXX      ?= g++
VLIB     ?= vlib
VLOG     ?= vlog
VSIM     ?= vsim

CXXFLAGS ?= -std=c++20 -Wall -Wextra -pedantic
SVFLAGS  ?= -sv

BUILD_DIR := build
WORK_LIB  := $(BUILD_DIR)/work
CPP_DIR   := $(BUILD_DIR)/cpp

CPP_SOURCES := $(wildcard *.cpp)

ifeq ($(OS),Windows_NT)
EXE := .exe
MKDIR_BUILD = if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
MKDIR_CPP   = if not exist "$(CPP_DIR)" mkdir "$(CPP_DIR)"
CLEAN_BUILD = if exist "$(BUILD_DIR)" rmdir /S /Q "$(BUILD_DIR)"
else
EXE :=
MKDIR_BUILD = mkdir -p "$(BUILD_DIR)"
MKDIR_CPP   = mkdir -p "$(CPP_DIR)"
CLEAN_BUILD = rm -rf "$(BUILD_DIR)"
endif

CPP_BINS := $(patsubst %.cpp,$(CPP_DIR)/%$(EXE),$(CPP_SOURCES))

# example.sv includes sv_comm.sv, so compile only the top-level source here.
SV_SOURCES := example.sv
TOP        ?= example

.PHONY: all cpp sv run clean

all: cpp sv

cpp: $(CPP_BINS)

$(CPP_DIR)/%$(EXE): %.cpp
	@$(MKDIR_CPP)
	$(CXX) $(CXXFLAGS) $< -o $@

sv: $(WORK_LIB)/_info

$(WORK_LIB)/_info: $(SV_SOURCES) sv_comm.sv
	@$(MKDIR_BUILD)
	$(VLIB) $(WORK_LIB)
	$(VLOG) -work $(WORK_LIB) $(SVFLAGS) $(SV_SOURCES)

run: sv
	$(VSIM) -c -lib $(WORK_LIB) $(TOP) -do "run -all; quit -f"

clean:
	@$(CLEAN_BUILD)
