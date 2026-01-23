# Reproducibility Guide for MHX™ Core T1 (paper-v1.1)

This document records the exact environment used for the MHX™ Core T1 paper results and provides step-by-step reproduction instructions.

## Commit and tag

- Tag: `paper-v1.1`

## Environment details

### Compiler

- Toolchain: lowRISC prebuilt RISC-V GCC toolchain
- Release: `20220210-1`
- Variant: `lowrisc-toolchain-gcc-rv32imcb`
- Compiler binary: `riscv32-unknown-elf-gcc`
- Source of truth: `ci/vars.env`

### Simulator

- Simulator: Verilator `v4.210`
- Accuracy model: cycle-accurate RTL simulation, zero-delay timing; performance derived from `mcycle` counters in the RTL
- Source of truth: `ci/vars.env` and `tool_requirements.py`

### FPGA tools

- Vendor/tool: Xilinx Vivado `2023.1`
- Board: Digilent Arty A7-35T (part `xc7a35tcsg324-1`)
- Demo clock: 50 MHz (as reported in the paper FPGA table)
- Source of truth: `syn/fpga/README.md` and `examples/mhx_simple_system/syn/tcl/build_vivado.tcl`

### ASIC tools

- PDK: SkyWater SKY130
- Synthesis (area estimates): Yosys `0.33`
- OpenLane flow (Sky130): configuration in `syn/asic/openlane_config.tcl`
  - Clock port: `clk_i`
  - Clock period: `10.0` ns (100 MHz)
- Source of truth: `syn/asic/synth_standalone.sh` and `syn/asic/openlane_config.tcl`

### MLPerf Tiny

- Suite: MLPerfTiny `v1.0` (adapted for MHX)
- Implementation: `examples/sw/simple_system/mlperftiny_bench/mlperftiny_bench.c`
- Dataset: synthetic pseudo-random patterns generated in the benchmark source (no external dataset)
- Dataset commit/hash: not applicable (no external dataset)

## Reproduce paper results

1. Check out the paper tag:

   ```bash
   git checkout paper-v1.1
   ```

2. Install the required tools and make sure they are on your `PATH`:
   - Verilator `v4.210`
   - lowRISC RISC-V GCC toolchain release `20220210-1` (variant `lowrisc-toolchain-gcc-rv32imcb`)
   - Python 3.x

3. Install Python dependencies:

   ```bash
   python3 -m pip install -r python-requirements.txt
   ```

4. Regenerate the benchmark tables used in the paper:

   ```bash
   python3 util/generate_benchmark_data.py --output build/benchmark_data --format all
   ```

5. Build the paper PDF:

   ```bash
   make -C paper pdf
   ```

6. Re-run MLPerfTiny (simulation):

   ```bash
   python3 util/mlperftiny_benchmark.py --json
   ```

   To save JSON output to disk:

   ```bash
   python3 util/mlperftiny_benchmark.py --output build/benchmark_data
   ```

7. Trace analysis (cycle-accurate flow):

   ```bash
   python3 util/trace_analysis.py --synthetic --json
   ```

   For real traces, follow the workflow in `doc/mhx_cycle_accurate_trace_analysis.md` and pass the generated trace JSON to `util/trace_analysis.py`.

8. FPGA resource utilization (Arty A7-35T, Vivado):

   ```bash
   cd syn/fpga
   make arty
   ```

9. ASIC synthesis (area estimates and Sky130 flow):

   ```bash
   cd syn/asic
   ./run_synthesis.sh
   ```

   For OpenLane Sky130 runs, use:

   ```bash
   make synth_openlane
   ```
