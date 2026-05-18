# MHX™ Core: Ternary Extensions for Ibex RISC-V

This repository contains the MHX™ Core, an enhanced Ibex RISC-V core with native
ternary (base-3) processing capabilities for edge AI workloads. The MHX™-specific
documentation is aligned to the paper source of truth
(`paper/mhx_ternary_whitepaper.tex`, tag `paper-v1.1`). This README is the
complete, project-wide index for MHX™ + Ibex content.

## Index

- [Project Scope](#project-scope)
- [Quick Start](#quick-start)
- [Repository Map](#repository-map)
- [Ibex Baseline](#ibex-baseline)
- [MHX™ Extension Overview](#mhx-extension-overview)
- [Ternary Data Representation](#ternary-data-representation)
- [Instruction Encoding](#instruction-encoding)
- [RTL Modules](#rtl-modules)
- [Performance, Area, and Timing](#performance-area-and-timing)
- [Configurations](#configurations)
- [Build, Run, and Test](#build-run-and-test)
- [Verification and Formal](#verification-and-formal)
- [Debugging and Trace Analysis](#debugging-and-trace-analysis)
- [Integration (SoC/FPGA/ASIC)](#integration-socfpgaasic)
- [Software Toolchain and Examples](#software-toolchain-and-examples)
- [Benchmarks and Reports](#benchmarks-and-reports)
- [Reproducibility](#reproducibility)
- [Documentation and Website](#documentation-and-website)
- [Paper and Citation](#paper-and-citation)
- [Security](#security)
- [Contributing and Support](#contributing-and-support)
- [License and Credits](#license-and-credits)

## Project Scope

MHX™ is a research-grade extension to the Ibex 32-bit RISC-V core that adds
ternary arithmetic and neural acceleration. This repository includes:

- The full Ibex RTL, configuration system, and verification flows.
- The MHX™ extension RTL, documentation, examples, and benchmarks.
- A reproducibility package for the paper results (`paper-v1.1`).
- Example systems, software, and FPGA/ASIC flows for integration.

If you only need the baseline Ibex documentation, see the standard Ibex manuals
in `doc/` and the upstream Ibex README in `README.md`.

## Quick Start

### 1) One-command verification (recommended)

```bash
make verify
```

This runs the same checks used by CI (tool version checks, RTL lint, core tests,
mypy, benchmark data generation, and pytest).

### 2) Generate benchmark data (JSON/LaTeX/Markdown)

```bash
python3 util/generate_benchmark_data.py --output build/benchmark_data --format all
```

Outputs:
- `build/benchmark_data/benchmark_data.json`
- `build/benchmark_data/benchmark_tables.tex`
- `build/benchmark_data/benchmark_report.md`

### 3) Rebuild the paper PDF

```bash
make -C paper pdf
```

### 4) Run MLPerfTiny (simulation)

```bash
python3 util/mlperftiny_benchmark.py --json
```

For full reproduction instructions and exact tool versions, see
`REPRODUCIBILITY.md`.

## Repository Map

Top-level structure and why it exists:

- `rtl/`: Ibex RTL with MHX™ integration hooks and extension blocks.
- `doc/`: Ibex documentation + MHX™ formal spec, debug guide, integration guide,
  security analysis, and cycle-accurate trace guide.
- `docs/`: Additional documentation assets (images, diagrams).
- `dv/`: Verification infrastructure (UVM, compliance, trace analysis, Verilator).
- `formal/`: Formal verification harnesses and helpers.
- `syn/`: Synthesis flows (Yosys/OpenSTA, FPGA, ASIC).
- `examples/`: Simple systems, MHX™ demo system, and software examples.
- `examples/sw/`: Benchmarks and bare-metal programs (incl. MLPerfTiny).
- `util/`: Tooling for configs, benchmark generation, trace analysis, and
  toolchain helpers.
- `paper/`: Paper sources and build scripts.
- `website/`: Project website sources and docs mirror.
- `vendor/`: External dependencies (riscv tests, lowRISC IP, etc.).
- `ci/`: CI and validation scripts.
- `.core` files: FuseSoC core descriptions for modular integration.

## Ibex Baseline

Ibex is a production-quality open source 32-bit RISC-V CPU core written in
SystemVerilog. It is heavily parameterizable and suited for embedded control
applications. Ibex supports RV32 I/E, M, C, and B extensions.

For Ibex-specific configuration, compliance, and design details:
- `README.md` (repository overview)
- `doc/` (full user manual and specs)
- `ibex_configs.yaml` (supported configurations)

## MHX™ Extension Overview

MHX™ adds native ternary compute and neural acceleration while preserving full
binary RV32IMC software compatibility. Summary of the core extension:

- 32 ternary registers (T0-T31), 16 trits per register (32-bit packed).
- Ternary ALU with 7 operations: TADD, TSUB, TMUL, TAND, TOR, TXOR, TNOT.
- Neural processing unit: 16-element dot product + activation functions
  (sign, ReLU, sigmoid approximation, tanh approximation).
- 16-entry weight cache and skip-zero optimization.
- Single-cycle latency for all ternary and neural operations.
- ~2,873 additional SystemVerilog RTL lines; ~5 kGE area overhead (approx 10-17%).

See the formal spec at `doc/mhx_ternary_formal_spec.md`.

## Ternary Data Representation

MHX™ uses balanced ternary with 2-bit packed trits:

- `00` = -1
- `01` =  0
- `10` = +1
- `11` = invalid (treated as 0 in software utilities)

See:
- `doc/application_notes/programming_guide.md`
- `util/toolchain/mhx_ternary.h`

## Instruction Encoding

MHX™ ternary ALU instructions use the RISC-V `custom-0` opcode (`0x0B`); neural instructions use `custom-1` (`0x2B`). Reserved `funct7` encodings are illegal and must not update ternary architectural state.

R-type format (ternary registers):

```
31        25 24    20 19    15 14    12 11     7 6     0
[ funct7 ] [ ts2  ] [ ts1  ] [ fn3  ] [ td   ] [ 0x0B/0x2B ]
```

Instruction table (paper-v1.1):

| Instruction | funct3 | funct7 | Notes |
|-------------|--------|--------|------|
| TADD td, ts1, ts2 | 000 | 0000000 | Ternary add |
| TSUB td, ts1, ts2 | 001 | 0000000 | Ternary subtract |
| TMUL td, ts1, ts2 | 010 | 0000000 | Ternary multiply |
| TAND td, ts1, ts2 | 011 | 0000000 | Ternary AND (min) |
| TOR td, ts1, ts2  | 100 | 0000000 | Ternary OR (max) |
| TXOR td, ts1, ts2 | 101 | 0000000 | Ternary XOR (add mod 3) |
| TNOT td, ts1      | 110 | 0000000 | Ternary negation |
| NEURON td, ts1, ts2 | 000 | 0000001 | 16-element dot product |
| ACTIVATE td, ts1  | 001 | 0000001 | Activation function |
| LEARN td, ts1, ts2 | 010 | 0000001 | Reserved / future work |

## RTL Modules

The MHX™ extension adds 10 SystemVerilog modules (2,873 lines total):

| Module | Lines | Function |
|--------|-------|----------|
| ibex_ternary_alu | 261 | 7-operation ternary ALU |
| ibex_ternary_regfile | 172 | 32x16-trit register file |
| ibex_neural_unit | 181 | Basic neural processing |
| ibex_neural_unit_enhanced | 322 | Pipelined neural unit |
| ibex_ternary_advanced | 287 | Dot product, distance |
| ibex_ternary_conv_pool | 392 | 3x3 convolution, pooling |
| ibex_ternary_dma | 386 | 4-channel DMA controller |
| ibex_ternary_lsu | 229 | Ternary load/store unit |
| ibex_ternary_perf_counters | 278 | 12 CSR counters |
| ibex_ternary_debug | 365 | Debug interface |
| **Total** | **2,873** | |

## Performance, Area, and Timing

### MLPerfTiny v1.0 (cycle-accurate)

| Benchmark | Binary Cycles | MHX™ Cycles | Speedup |
|-----------|--------------|------------|---------|
| Anomaly Detection | 1,250,000 | 520,000 | 2.40x |
| Keyword Spotting | 2,100,000 | 780,000 | 2.69x |
| Image Classification | 3,500,000 | 1,250,000 | 2.80x |
| Person Detection | 8,200,000 | 2,850,000 | 2.88x |
| **Geometric Mean** | -- | -- | **2.68x** |

Additional paper metrics:
- Memory reduction for ternary weights: 93.75%
- Estimated power reduction vs software emulation: ~70%

### Area and Timing (paper summary)

- Additional area: ~5 kGE (approx 10-17% overhead vs base Ibex).
- Estimated max frequency (SkyWater 130nm): 200-250 MHz.
- FPGA demo (Arty A7): 50 MHz.
- All ternary and neural operations complete in one cycle.

## Configurations

Configuration data lives in `ibex_configs.yaml` and FuseSoC `.core` files at the
repository root. The MHX™-enabled config is named `mhx-ternary`.

For baseline Ibex configurations and verification status see `README.md` and
`ibex_configs.yaml`.

## Build, Run, and Test

Key entry points in this repo:

- `Makefile`: common build and verification targets (e.g., `make verify`).
- `run_ternary_tests.sh`: quick local runner for MHX™-specific tests.
- `lint_ternary.sh`: Verilator linting for MHX™ extensions.
- `ci/`: CI scripts for validation, benchmarks, formal verification, and audits.

For tool requirements, see:
- `tool_requirements.py`
- `check_tool_requirements.core`
- `python-requirements.txt`

## Verification and Formal

Verification is organized into dedicated folders and flows:

- `dv/`: simulation, UVM, compliance, and trace-based testing.
- `dv/uvm/`: full MHX™ UVM testbench and regression suite.
- `dv/formal/`: formal checks and protocol verification hooks.
- `formal/`: formal verification harnesses for MHX™ blocks.
- `dv/riscv_compliance/`: RISC-V compliance integration.
- `vendor/riscv-tests` and `vendor/riscv-arch-tests`: upstream test suites.

For details, see:
- `formal/README.md`
- `dv/uvm/README.md`
- `dv/riscv_compliance/README.md`

## Debugging and Trace Analysis

MHX™ includes dedicated debug and analysis guidance:

- `doc/mhx_ternary_debug_guide.md`: debug environment, signals, and checklists.
- `doc/mhx_cycle_accurate_trace_analysis.md`: cycle-accurate simulation and
  trace-based analysis workflows.
- `dv/trace_analysis/`: trace analyzer RTL and tests.
- `util/trace_analysis.py`: Python trace processing utilities.

## Integration (SoC/FPGA/ASIC)

Integration guidance and flows:

- `doc/integration_guide.md`: SoC integration, memory maps, interrupts, debug.
- `examples/simple_system/`: baseline Ibex simple system.
- `examples/mhx_simple_system/`: MHX™-enabled system with firmware and FPGA flow.
- `syn/`: synthesis flows and reports.
  - `syn/README.md`: Yosys/OpenSTA flow.
  - `syn/fpga/README.md`: FPGA synthesis and board flows.
  - `syn/asic/`: ASIC-oriented scripts and OpenLane configuration.

## Software Toolchain and Examples

Software support and reference programs:

- `util/toolchain/mhx_ternary.h`: MHX™ intrinsic and helper APIs.
- `examples/mhx_demo.s`: MHX™ assembly demo and instruction reference.
- `examples/sw/ternary_math_validation/`: correctness tests for ternary math.
- `examples/sw/ternary_performance_bench/`: microbenchmarks.
- `examples/sw/simple_system/mlperftiny_bench/`: MLPerfTiny suite.

See also:
- `doc/application_notes/programming_guide.md`

## Benchmarks and Reports

Benchmark tooling and reports live in:

- `util/generate_benchmark_data.py`: paper tables + machine-readable outputs.
- `util/mlperftiny_benchmark.py`: MLPerfTiny runs and JSON output.
- `util/ternary_performance_analysis.py`: performance analysis helpers.
- `util/performance_regression_check.py`: CI regression checks.
- `doc/mhx_cycle_accurate_trace_analysis.md`: trace-driven analysis workflow.

## Reproducibility

All paper results are tracked under tag `paper-v1.1`. The exact environment and
step-by-step reproduction instructions are in `REPRODUCIBILITY.md`.

## Documentation and Website

- Ibex documentation: `doc/` and the upstream Ibex manual.
- MHX™ docs: `doc/mhx_ternary_formal_spec.md`,
  `doc/mhx_ternary_debug_guide.md`, `doc/mhx_ternary_security_analysis.md`,
  `doc/mhx_cycle_accurate_trace_analysis.md`, `doc/integration_guide.md`,
  `doc/application_notes/programming_guide.md`.
- Images and diagrams: `docs/images/`.
- Website sources: `website/`.

## Paper and Citation

Paper sources live in `paper/`. To rebuild the PDF:

```bash
make -C paper pdf
```

Citation:

```bibtex
@misc{mhx_ternary_extension,
  title={MHX™: A Native Ternary Computing Extension for RISC-V},
  author={TheusHen},
  year={2025},
  howpublished={https://github.com/TheusHen/ternary-ibex}
}
```

## Security

Security considerations and threat modeling for MHX™ are documented in:

- `SECURITY.md`
- `doc/mhx_ternary_security_analysis.md`

## Contributing and Support

- Contribution guidance: `CONTRIBUTING.md`
- Issues/bugs: see the project issue tracker and `SECURITY.md` for disclosure
  guidance.

## License and Credits

- License: Apache 2.0 (see `LICENSE`)
- Credits: `CREDITS.md`
