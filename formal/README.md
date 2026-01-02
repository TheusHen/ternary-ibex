# MHX Ternary Extension - Formal Verification

This directory contains formal verification infrastructure for the MHX Ternary Extension to the Ibex RISC-V core.

## Overview

The formal verification uses **SymbiYosys** (SBY) with **Yosys** for formal model generation and SMT solvers (Z3, Yices) for property checking.

## Directory Structure

```
formal/
├── ternary_alu/           # Ternary ALU verification
│   ├── ternary_alu.sby    # SymbiYosys configuration
│   └── ternary_alu_formal.sv  # Formal properties
├── neural_unit/           # Neural Unit verification
│   ├── neural_unit.sby    # SymbiYosys configuration
│   └── neural_unit_formal.sv  # Formal properties
├── ternary_regfile/       # Register File verification
│   ├── ternary_regfile.sby    # SymbiYosys configuration
│   └── ternary_regfile_formal.sv  # Formal properties
└── README.md              # This file
```

## Prerequisites

Install the required tools:

```bash
# Ubuntu/Debian
sudo apt-get install yosys
pip install sby

# Or use OSS CAD Suite (recommended)
# https://github.com/YosysHQ/oss-cad-suite-build
```

## Running Verification

### Ternary ALU

```bash
cd formal/ternary_alu
sby -f ternary_alu.sby prove    # Run proof
sby -f ternary_alu.sby cover    # Run coverage
sby -f ternary_alu.sby bmc      # Run bounded model checking
```

### Neural Unit

```bash
cd formal/neural_unit
sby -f neural_unit.sby prove
sby -f neural_unit.sby cover
sby -f neural_unit.sby bmc
```

### Ternary Register File

```bash
cd formal/ternary_regfile
sby -f ternary_regfile.sby prove
sby -f ternary_regfile.sby cover
sby -f ternary_regfile.sby bmc
```

### Run All

```bash
cd formal
./run_all_formal.sh
```

## Properties Verified

### Ternary ALU (40+ Properties)

| Category | Properties |
|----------|------------|
| **Encoding Validity** | All result trits use valid encoding (00, 01, 10) |
| **Arithmetic Correctness** | ADD, SUB, MUL, AND, OR, XOR, NOT |
| **Algebraic Properties** | Commutativity, Identity elements |
| **Overflow Detection** | Correct overflow for ADD/SUB, no overflow for MUL |
| **Involution** | NOT(NOT(x)) == x |
| **Timing** | ALU is always ready (combinational) |

### Neural Unit (30+ Properties)

| Category | Properties |
|----------|------------|
| **Valid Operations** | Output only valid for known operations |
| **Accumulator Bounds** | Result bounded to [-16, +16] |
| **Activation Function** | Sign activation is correct |
| **Learning** | Weight updates produce valid trits |
| **Symmetry** | Dot product is commutative |
| **Determinism** | Same inputs produce same outputs |

### Register File (25+ Properties)

| Category | Properties |
|----------|------------|
| **T0 Convention** | T0 always reads as zero, writes ignored |
| **Write Consistency** | Written values are readable |
| **Reset Behavior** | All registers reset to zero |
| **Port Independence** | Read ports don't interfere |
| **Timing** | Read is combinational, write is 1-cycle |
| **Security** | Constant-time operations |

## Expected Results

When verification passes:

```
SBY [ternary_alu_prove] PASS
SBY [ternary_alu_cover] PASS
SBY [neural_unit_prove] PASS
SBY [neural_unit_cover] PASS
SBY [ternary_regfile_prove] PASS
SBY [ternary_regfile_cover] PASS
```

## Coverage Metrics

The formal verification includes coverage points for:

- All 7 ternary ALU operations
- All 4 neural operations
- All 9 trit value combinations
- Overflow/no-overflow conditions
- Edge cases (all-zero inputs, T0 access, etc.)

## Integration with CI

The formal verification is integrated into the CI pipeline:

```yaml
formal-verification:
  script:
    - cd formal/ternary_alu && sby -f ternary_alu.sby prove
    - cd formal/neural_unit && sby -f neural_unit.sby prove
    - cd formal/ternary_regfile && sby -f ternary_regfile.sby prove
```

## Troubleshooting

### SMT Solver Timeout

Increase the depth limit or use a different solver:

```
[options]
prove: timeout 3600  # 1 hour timeout
```

### Missing prim_assert.sv

Ensure the vendor directory is properly initialized:

```bash
git submodule update --init --recursive
```

## References

- [SymbiYosys Documentation](https://symbiyosys.readthedocs.io/)
- [Yosys Manual](https://yosyshq.readthedocs.io/)
- [SVA Reference](https://www.systemverilog.io/sva)
