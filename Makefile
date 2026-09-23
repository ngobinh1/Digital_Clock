#===============================================================================
# Makefile for HMS_Timer IP Core Verification
# Toolchain: QuestaSim / ModelSim / VCS / Verilator
# Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
#===============================================================================

# Simulator configuration
QUESTA_BIN ?= /home/ngobinh/Questasim/questasim/linux_x86_64
VLOG       = $(QUESTA_BIN)/vlog
VSIM       = $(QUESTA_BIN)/vsim
VLIB       = $(QUESTA_BIN)/vlib
VMAP       = $(QUESTA_BIN)/vmap
VCOVER     = $(QUESTA_BIN)/vcover

# Working directory and library
SIM_DIR    = sim
WORK_LIB   = $(SIM_DIR)/work

# Source directories
RTL_DIR    = rtl
TB_DIR     = tb

# RTL Source Files
RTL_SRCS   = $(RTL_DIR)/button_debouncer.sv \
             $(RTL_DIR)/prescaler_1hz.sv \
             $(RTL_DIR)/mode_controller.sv \
             $(RTL_DIR)/second_counter.sv \
             $(RTL_DIR)/minute_counter.sv \
             $(RTL_DIR)/hour_counter.sv \
             $(RTL_DIR)/hms_timer.sv

# Testbench Source Files
TB_SRCS    = $(TB_DIR)/hms_timer_types_pkg.sv \
             $(TB_DIR)/hms_timer_if.sv \
             $(TB_DIR)/tb_hms_timer.sv

# Top Testbench Module
TB_TOP     = tb_hms_timer

# Compilation flags
VLOG_FLAGS = -sv -timescale "1ns/1ps" +acc -lint +incdir+$(TB_DIR) -work $(WORK_LIB)
COV_FLAGS  = +cover=bcesf

# Simulation flags
VSIM_FLAGS = -c -work $(WORK_LIB) $(TB_TOP) -do "run -all; quit -f"

.PHONY: all compile sim run wave cov clean help verilator_test

all: compile sim

# Display help menu
help:
	@echo "================================================================="
	@echo "                     HMS_Timer Build System                      "
	@echo "================================================================="
	@echo "  make compile   : Compile RTL and SystemVerilog TB using QuestaSim"
	@echo "  make sim       : Run batch simulation and display test scorecard"
	@echo "  make all       : Compile and run simulation (default)"
	@echo "  make wave      : Run simulation with waveform viewer (GUI mode)"
	@echo "  make cov       : Compile with code/func coverage and gen report"
	@echo "  make clean     : Clean up simulation work directory and logs"
	@echo "================================================================="

# Create working library
$(WORK_LIB):
	@mkdir -p $(SIM_DIR)
	@$(VLIB) $(WORK_LIB)
	@$(VMAP) work $(WORK_LIB)

# Compile RTL and Testbench
compile: $(WORK_LIB)
	@echo "-----------------------------------------------------------------"
	@echo ">>> Compiling RTL and Testbench with QuestaSim vlog... <<<"
	@echo "-----------------------------------------------------------------"
	$(VLOG) $(VLOG_FLAGS) $(RTL_SRCS) $(TB_SRCS) | tee $(SIM_DIR)/compile.log

# Run batch simulation
sim: $(WORK_LIB)
	@echo "-----------------------------------------------------------------"
	@echo ">>> Running Simulation with QuestaSim vsim... <<<"
	@echo "-----------------------------------------------------------------"
	$(VSIM) -c -work $(WORK_LIB) $(TB_TOP) -do "run -all; quit -f" -l $(SIM_DIR)/sim.log

run: sim

# Run simulation with GUI Waveform viewer
wave: $(WORK_LIB)
	@echo "-----------------------------------------------------------------"
	@echo ">>> Launching QuestaSim GUI Waveform Viewer... <<<"
	@echo "-----------------------------------------------------------------"
	$(VSIM) -gui -work $(WORK_LIB) $(TB_TOP) &

# Compile and run with Functional & Code Coverage
cov: $(WORK_LIB)
	@echo "-----------------------------------------------------------------"
	@echo ">>> Compiling with Coverage Enabled... <<<"
	@echo "-----------------------------------------------------------------"
	$(VLOG) $(VLOG_FLAGS) $(COV_FLAGS) $(RTL_SRCS) $(TB_SRCS)
	@echo ">>> Running Simulation with Coverage Collection... <<<"
	$(VSIM) -c -coverage -work $(WORK_LIB) $(TB_TOP) -do "coverage save -onexit $(SIM_DIR)/hms_cov.ucdb; run -all; quit -f" -l $(SIM_DIR)/sim_cov.log
	@echo ">>> Generating HTML Coverage Report... <<<"
	$(VCOVER) report -html -htmldir $(SIM_DIR)/cov_html $(SIM_DIR)/hms_cov.ucdb

# Verilator lint check
verilator_test:
	verilator --lint-only -Wall -sv $(RTL_SRCS)

# Clean build artifacts
clean:
	@echo ">>> Cleaning build artifacts... <<<"
	rm -rf $(SIM_DIR) transcript *.wlf *.vcd covhtmlreport vsim.wlf
