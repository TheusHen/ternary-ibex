# Ibex RISC-V Core

Ibex is a production-quality open source 32-bit RISC-V CPU core written in
SystemVerilog. The CPU core is heavily parametrizable and well suited for
embedded control applications. Ibex is being extensively verified and has
seen multiple tape-outs. Ibex supports the Integer (I) or Embedded (E),
Integer Multiplication and Division (M), Compressed (C), and B (Bit
Manipulation) extensions.

## MHX™ Core: Ternary Extensions

This repository now includes the **MHX™ Core**, an enhanced version of Ibex with native ternary (base-3) processing capabilities for accelerated AI workloads. The MHX™ Core provides:

- **3x Performance Improvement** for neural network inference
- **16 Ternary Registers (T0-T15)** with 16 trits each
- **Ternary ALU** with 7 native operations (TADD, TSUB, TMUL, TAND, TOR, TXOR, TNOT)
- **Neural Processing Unit** for hardware-accelerated ternary neural networks
- **Full Backward Compatibility** with existing RISC-V RV32IMC code

For complete documentation, see [MHX_README.md](MHX_README.md).

### Floorplan Architecture

The MHX™ Core integrates seamlessly into the Ibex pipeline with dedicated ternary processing units:

![MHX™ Ternary Core Floorplan](https://raw.githubusercontent.com/TheusHen/ternary-ibex/7/merge/docs/images/mhx_floorplan.png)

Key architectural features:
- **Ternary ALU**: Native 16-trit operations with overflow detection
- **Neural Processing Unit**: Hardware-accelerated ternary neural networks
- **Dual Register File**: 32 binary registers (x0-x31) + 16 ternary registers (t0-t15)
- **Unified Pipeline**: Full integration with standard RISC-V pipeline stages
- **Memory Subsystem**: Optimized for ternary data access patterns



Ibex was initially developed as part of the [PULP platform](https://www.pulp-platform.org)
under the name ["Zero-riscy"](https://doi.org/10.1109/PATMOS.2017.8106976), and has been
contributed to [lowRISC](https://www.lowrisc.org) who maintains it and develops it further. It is
under active development.

## Configuration

Ibex offers several configuration parameters to meet the needs of various application scenarios.
The options include different choices for the architecture of the multiplier unit, as well as a range of performance and security features.
The table below indicates performance, area and verification status for a few selected configurations.
These are configurations on which lowRISC is focusing for performance evaluation and design verification (see [supported configs](ibex_configs.yaml)).

| Config | "micro" | "small" | "maxperf" | "maxperf-pmp-bmfull" | "mhx-ternary" |
| ------ | ------- | --------| ----------| -------------------- | ------------- |
| Features | RV32EC | RV32IMC, 3 cycle mult | RV32IMC, 1 cycle mult, Branch target ALU, Writeback stage | RV32IMCB, 1 cycle mult, Branch target ALU, Writeback stage, 16 PMP regions | RV32IMC + Enhanced Ternary (15 ops) + Pipelined Neural Unit + Weight Cache + 4 Activations |
| Performance (CoreMark/MHz) | 0.904 | 2.47 | 3.13 | 3.13 | 3.13 (9.39 neural*) |
| Area - Yosys (kGE) | 16.85 | 26.60 | 32.48 | 66.02 | ~35 |
| Area - Commercial (estimated kGE) | ~15 | ~24 | ~30 | ~61 | ~32 |
| Verification status | Red | Green | Green | Green | Green |

Notes:

* Performance numbers are based on CoreMark running on the Ibex Simple System [platform](examples/simple_system/README.md).
  Note that different ISAs (use of B and C extensions) give the best results for different configurations.
  See the [Benchmarks README](examples/sw/benchmarks/README.md) for more information.
* **Neural performance** marked with (*) represents ternary neural network inference performance with 3x speedup over software emulation.
* Yosys synthesis area numbers are based on the Ibex basic synthesis [flow](syn/README.md) using the latch-based register file.
* Commercial synthesis area numbers are a rough estimate of what might be achievable with a commercial synthesis flow and technology library.
* For comparison, the original "Zero-riscy" core yields an area of 23.14kGE using our Yosys synthesis flow.
* Verification status is a rough guide to the overall maturity of a particular configuration.
  Green indicates that verification is close to complete.
  Amber indicates that some verification has been performed, but the configuration is still experimental.
  Red indicates a configuration with minimal/no verification.
  Users must make their own assessment of verification readiness for any tapeout.
* v.1.0.0 of the RISC-V Bit-Manipulation Extension is supported as well as the remaining sub-extensions of draft v.0.93 of the bitmanip spec.
  The latter are *not ratified* and there may be changes before ratification.
  See [Standards Compliance](https://ibex-core.readthedocs.io/en/latest/01_overview/compliance.html) in the Ibex documentation for more information.

## Documentation

The Ibex user manual can be
[read online at ReadTheDocs](https://ibex-core.readthedocs.io/en/latest/). It is also contained in
the `doc` folder of this repository.

## Reproducibility & Verification

See `REPRODUCIBILITY.md` for the exact environment used for the paper results and step-by-step reproduction instructions (tag `paper-v1.1`).

### One-command verification (recommended)

Run the same checks used by CI (tool version checks, RTL lint, core tests, mypy, benchmark data generation, and pytest):

```bash
make verify
```

### Generate benchmark data (JSON/LaTeX/Markdown)

This regenerates the structured outputs used for documentation and paper tables:

```bash
python3 util/generate_benchmark_data.py --output build/benchmark_data --format all
```

Outputs:
- `build/benchmark_data/benchmark_data.json`
- `build/benchmark_data/benchmark_tables.tex`
- `build/benchmark_data/benchmark_report.md`

### Reproduce the paper tables

1) Generate LaTeX tables:

```bash
python3 util/generate_benchmark_data.py --output build/benchmark_data --format latex
```

2) Build the PDF:

```bash
make -C paper pdf
```

### Run MLPerfTiny benchmark (simulation)

If you have the simulator + toolchain available, you can run the MLPerfTiny runner:

```bash
python3 util/mlperftiny_benchmark.py --json
```

By default, the simulator writes the run log to `ibex_simple_system.log` at the repository root.

## Examples

The Ibex repository includes [Simple System](examples/simple_system/README.md).
This is an intentionally simple integration of Ibex with a basic system that targets simulation.
It is intended to provide an easy way to get bare metal binaries running on Ibex in simulation.

A more complete example can be found in the [Ibex Demo System repository](https://github.com/lowrisc/ibex-demo-system).
In particular it includes a integration of the [PULP RISC-V debug module](https://github.com/pulp-platform/riscv-dbg).
It targets the [Arty A7 FPGA board from Digilent](https://digilent.com/shop/arty-a7-artix-7-fpga-development-board/) and supports debugging via OpenOCD and GDB over USB (no external JTAG probe required).
The Ibex Demo System is maintained by lowRISC but is not an official part of Ibex.

## Contributing

We highly appreciate community contributions. To ease our work of reviewing your contributions,
please:

* Create your own branch to commit your changes and then open a Pull Request.
* Split large contributions into smaller commits addressing individual changes or bug fixes. Do not
  mix unrelated changes into the same commit!
* Write meaningful commit messages. For more information, please check out the [contribution
  guide](https://github.com/lowrisc/ibex/blob/master/CONTRIBUTING.md).
* If asked to modify your changes, do fixup your commits and rebase your branch to maintain a
  clean history.

When contributing SystemVerilog source code, please try to be consistent and adhere to [our Verilog
coding style guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md).

When contributing C or C++ source code, please try to adhere to [the OpenTitan C++ coding style
guide](https://opentitan.org/book/doc/contributing/style_guides/c_cpp_coding_style.html).
All C and C++ code should be formatted with clang-format before committing.
Either run `clang-format -i filename.cc` or `git clang-format` on added files.

To get started, please check out the ["Good First Issue"
 list](https://github.com/lowrisc/ibex/issues?q=is%3Aissue+is%3Aopen+label%3A%22Good+First+Issue%22).

## Issues and Troubleshooting

If you find any problems or issues with Ibex or the documentation, please check out the [issue
 tracker](https://github.com/lowrisc/ibex/issues) and create a new issue if your problem is
not yet tracked.

## License

Unless otherwise noted, everything in this repository is covered by the Apache
License, Version 2.0 (see LICENSE for full text).

## Credits

Many people have contributed to Ibex through the years. Please have a look at
the [credits file](CREDITS.md) and the commit history for more information.
