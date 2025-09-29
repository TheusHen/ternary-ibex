# MHX Ternary UVM Testbench Makefile
# Comprehensive makefile for UVM simulation with different simulators

# Default simulator
SIM ?= questa

# Test selection
TEST ?= mhx_ternary_basic_test

# Simulation options
WAVES ?= 1
COVERAGE ?= 1
SEED ?= 1
VERBOSITY ?= UVM_MEDIUM

# Directories
RTL_DIR = ../../rtl
TB_DIR = .
BUILD_DIR = ./build
LOG_DIR = ./logs
COV_DIR = ./coverage

# Create directories
$(shell mkdir -p $(BUILD_DIR) $(LOG_DIR) $(COV_DIR))

# RTL files
RTL_FILES = \
    $(RTL_DIR)/ibex_pkg.sv \
    $(RTL_DIR)/ibex_alu.sv \
    $(RTL_DIR)/ibex_branch_predict.sv \
    $(RTL_DIR)/ibex_compressed_decoder.sv \
    $(RTL_DIR)/ibex_controller.sv \
    $(RTL_DIR)/ibex_counter.sv \
    $(RTL_DIR)/ibex_cs_registers.sv \
    $(RTL_DIR)/ibex_csr.sv \
    $(RTL_DIR)/ibex_decoder.sv \
    $(RTL_DIR)/ibex_dummy_instr.sv \
    $(RTL_DIR)/ibex_ex_block.sv \
    $(RTL_DIR)/ibex_fetch_fifo.sv \
    $(RTL_DIR)/ibex_icache.sv \
    $(RTL_DIR)/ibex_id_stage.sv \
    $(RTL_DIR)/ibex_if_stage.sv \
    $(RTL_DIR)/ibex_load_store_unit.sv \
    $(RTL_DIR)/ibex_lockstep.sv \
    $(RTL_DIR)/ibex_multdiv_fast.sv \
    $(RTL_DIR)/ibex_multdiv_slow.sv \
    $(RTL_DIR)/ibex_pmp.sv \
    $(RTL_DIR)/ibex_prefetch_buffer.sv \
    $(RTL_DIR)/ibex_register_file_ff.sv \
    $(RTL_DIR)/ibex_register_file_fpga.sv \
    $(RTL_DIR)/ibex_register_file_latch.sv \
    $(RTL_DIR)/ibex_ternary_alu.sv \
    $(RTL_DIR)/ibex_neural_unit.sv \
    $(RTL_DIR)/ibex_ternary_regfile.sv \
    $(RTL_DIR)/ibex_core.sv \
    $(RTL_DIR)/ibex_top.sv \
    $(RTL_DIR)/ibex_top_tracing.sv

# UVM testbench files
TB_FILES = \
    $(TB_DIR)/mhx_ternary_pkg.sv \
    $(TB_DIR)/mhx_ternary_if.sv \
    $(TB_DIR)/mhx_ternary_tb_top.sv

# Simulator-specific settings
ifeq ($(SIM), questa)
    COMP = vlog
    SIM_CMD = vsim
    COMP_OPTS = -sv +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
    SIM_OPTS = -c -do "run -all; quit -f"
    COV_OPTS = +cover=bcfst
    WAVE_OPTS = +DUMP_WAVES
endif

ifeq ($(SIM), vcs)
    COMP = vlogan
    SIM_CMD = simv
    COMP_OPTS = -sverilog +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
    SIM_OPTS = 
    COV_OPTS = -cm line+cond+fsm+branch+tgl
    WAVE_OPTS = +vcs+dumpvars+mhx_ternary_waves.vcd
endif

ifeq ($(SIM), xcelium)
    COMP = xmvlog
    SIM_CMD = xmsim
    COMP_OPTS = -sv +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
    SIM_OPTS = 
    COV_OPTS = -coverage all
    WAVE_OPTS = +DUMP_WAVES
endif

# Test arguments
TEST_ARGS = +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=$(VERBOSITY) \
            +ntb_random_seed=$(SEED)

# Wave arguments
ifeq ($(WAVES), 1)
    WAVE_ARGS = $(WAVE_OPTS)
else
    WAVE_ARGS =
endif

# Coverage arguments
ifeq ($(COVERAGE), 1)
    COV_ARGS = $(COV_OPTS)
else
    COV_ARGS =
endif

# Default target
all: compile run

# Compilation
compile:
	@echo "=== Compiling RTL and Testbench ==="
	$(COMP) $(COMP_OPTS) $(COV_ARGS) \
		-work work \
		$(RTL_FILES) $(TB_FILES) \
		-l $(LOG_DIR)/compile.log

# Simulation
run:
	@echo "=== Running Test: $(TEST) ==="
	$(SIM_CMD) $(SIM_OPTS) \
		work.mhx_ternary_tb_top \
		$(TEST_ARGS) $(WAVE_ARGS) $(COV_ARGS) \
		-l $(LOG_DIR)/$(TEST)_$(SEED).log

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)/* $(LOG_DIR)/* $(COV_DIR)/*
	rm -rf work/ transcript vsim.wlf *.vcd

# Test targets for different test types
test_basic:
	$(MAKE) TEST=mhx_ternary_basic_test run

test_random:
	$(MAKE) TEST=mhx_ternary_random_test run

test_corner:
	$(MAKE) TEST=mhx_ternary_corner_test run

test_coverage:
	$(MAKE) TEST=mhx_ternary_coverage_test run

test_stress:
	$(MAKE) TEST=mhx_ternary_stress_test run

test_error:
	$(MAKE) TEST=mhx_ternary_error_test run

test_performance:
	$(MAKE) TEST=mhx_ternary_performance_test run

test_regression:
	$(MAKE) TEST=mhx_ternary_regression_test run

# Run all tests
test_all: test_basic test_random test_corner test_coverage test_stress test_error test_performance test_regression

# Regression with multiple seeds
regression:
	@echo "=== Running Regression Suite ==="
	@for seed in 1 2 3 4 5; do \
		echo "Running regression with seed $$seed"; \
		$(MAKE) TEST=mhx_ternary_regression_test SEED=$$seed run || exit 1; \
	done
	@echo "=== Regression Complete ==="

# Coverage analysis (simulator-specific)
coverage_report:
ifeq ($(SIM), questa)
	vcover report $(COV_DIR)/coverage.ucdb -html -htmldir $(COV_DIR)/html_report
endif
ifeq ($(SIM), vcs)
	urg -dir $(COV_DIR)/simv.vdb -report $(COV_DIR)/coverage_report
endif
ifeq ($(SIM), xcelium)
	imc -load $(COV_DIR)/cov_work/scope/test -execcmd "report -summary"
endif

# Debug targets
debug:
	$(MAKE) WAVES=1 VERBOSITY=UVM_HIGH run

# Lint check (if available)
lint:
	verilator --lint-only -Wall \
		+incdir+$(RTL_DIR) \
		$(RTL_FILES)

# Help target
help:
	@echo "MHX Ternary UVM Testbench Makefile"
	@echo "=================================="
	@echo ""
	@echo "Usage: make [target] [options]"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Compile and run default test"
	@echo "  compile          - Compile RTL and testbench"
	@echo "  run              - Run simulation"
	@echo "  clean            - Clean build artifacts"
	@echo "  test_basic       - Run basic functionality test"
	@echo "  test_random      - Run random test"
	@echo "  test_corner      - Run corner case test"
	@echo "  test_coverage    - Run coverage-driven test"
	@echo "  test_stress      - Run stress test"
	@echo "  test_error       - Run error injection test"
	@echo "  test_performance - Run performance test"
	@echo "  test_regression  - Run comprehensive regression test"
	@echo "  test_all         - Run all test types"
	@echo "  regression       - Run regression with multiple seeds"
	@echo "  coverage_report  - Generate coverage report"
	@echo "  debug            - Run with waves and high verbosity"
	@echo "  lint             - Run lint check"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Options:"
	@echo "  SIM=<simulator>  - Simulator (questa/vcs/xcelium) [default: questa]"
	@echo "  TEST=<testname>  - Test to run [default: mhx_ternary_basic_test]"
	@echo "  SEED=<number>    - Random seed [default: 1]"
	@echo "  WAVES=<0|1>      - Enable waveform dump [default: 1]"
	@echo "  COVERAGE=<0|1>   - Enable coverage [default: 1]"
	@echo "  VERBOSITY=<level>- UVM verbosity [default: UVM_MEDIUM]"
	@echo ""
	@echo "Examples:"
	@echo "  make test_basic SIM=questa SEED=42"
	@echo "  make test_coverage WAVES=0 COVERAGE=1"
	@echo "  make regression SIM=vcs"

.PHONY: all compile run clean test_basic test_random test_corner test_coverage test_stress test_error test_performance test_regression test_all regression coverage_report debug lint help