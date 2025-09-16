# MHX Neural T1 Implementation Tests

This directory contains comprehensive tests for the MHX Neural T1 Simple System implementation, including automated testing frameworks and continuous integration workflows.

## Test Structure

### Test Directories

```
dv/mhx_simple_system_tests/    # SystemVerilog testbenches
├── mhx_simple_system_test.sv  # Main system testbench
├── test_programs/             # C test programs
└── verilator_waiver.vlt       # Lint waivers

util/mhx_tests/                # Test automation
├── mhx_test_runner.py         # Python test framework
└── run_mhx_tests.sh          # Shell test runner

.github/workflows/             # CI/CD workflows
├── mhx_neural_t1_tests.yml   # Main test workflow
└── mhx_fpga_validation.yml   # FPGA validation
```

### Test Categories

#### 1. Code Quality Tests
- **SystemVerilog Linting**: Verilator and Verible syntax checking
- **RTL Quality**: Signal naming, module structure validation
- **Code Style**: Consistency with project standards

#### 2. Unit Tests
- **GPIO Controller**: 8-bit bidirectional GPIO functionality
- **UART Controller**: 115200 baud serial communication
- **Memory Subsystem**: 1MB RAM with dual-port access
- **System Integration**: Inter-component communication

#### 3. Simulation Tests
- **Functional Testing**: Core system functionality
- **Interface Testing**: Peripheral register access
- **Timing Validation**: Clock and reset behavior
- **End-to-End Testing**: Complete system operation

#### 4. FPGA Validation
- **Synthesis Readiness**: Script and constraint validation
- **Board Support**: Arty A7 and Basys3 configuration
- **Pin Mapping**: Constraint file verification
- **Build Infrastructure**: TCL script validation

## Running Tests

### Using Make Targets

```bash
# Run all MHX tests
make test-mhx-all

# Run specific test categories
make test-mhx-lint    # Code quality
make test-mhx-build   # Build tests
make test-mhx-sim     # Simulation tests
make test-mhx-fpga    # FPGA validation
```

### Using Test Runner Scripts

```bash
# Python test runner (recommended)
util/mhx_tests/mhx_test_runner.py --test-suite all

# Shell test runner (basic)
util/mhx_tests/run_mhx_tests.sh all
```

### Manual Testing

```bash
# Build MHX system
fusesoc --cores-root . run --target=sim --setup --build lowrisc:mhx:mhx_simple_system

# Run MHX system test
fusesoc --cores-root . run --target=sim --tool=verilator lowrisc:mhx:mhx_simple_system_test
```

## Test Components

### SystemVerilog Testbenches

#### MHX Simple System Test (`mhx_simple_system_test.sv`)
- Comprehensive system-level testing
- GPIO functionality validation
- UART communication testing
- System integration verification
- Timeout and error handling

#### Test Programs (`test_programs/`)
- Minimal C programs for hardware validation
- Memory-mapped peripheral access
- Basic functionality demonstration
- Simulation control integration

### Automation Framework

#### Python Test Runner (`mhx_test_runner.py`)
- Automated test execution
- Result collection and reporting
- Environment validation
- Detailed logging and error reporting

#### CI/CD Workflows
- **Main Test Workflow**: Complete testing pipeline
- **FPGA Validation**: Synthesis infrastructure validation
- **Automated Reporting**: Test result artifacts
- **Multi-stage Validation**: Lint → Build → Test → Validate

## Test Results

### Success Criteria
- ✅ All SystemVerilog modules pass linting
- ✅ All components build successfully
- ✅ System simulation completes without errors
- ✅ FPGA synthesis files are valid and complete
- ✅ GPIO and UART interfaces function correctly

### Failure Modes
- ❌ Lint errors in RTL code
- ❌ Build failures due to missing dependencies
- ❌ Simulation timeouts or assertion failures
- ❌ Missing or invalid FPGA synthesis files
- ❌ Interface timing violations

## Continuous Integration

### GitHub Actions Workflows

#### MHX Neural T1 Tests (`mhx_neural_t1_tests.yml`)
- **Triggers**: Push to branches, pull requests, manual dispatch
- **Jobs**: Lint, Build, Unit Tests, Integration Tests, Reporting
- **Artifacts**: Test results, simulation traces, reports
- **Duration**: ~15-20 minutes for full test suite

#### FPGA Validation (`mhx_fpga_validation.yml`)
- **Triggers**: Changes to FPGA synthesis files
- **Jobs**: File validation, syntax checking, constraint validation
- **Artifacts**: Validation reports
- **Duration**: ~5-10 minutes

### Test Artifacts
- **Simulation Traces**: VCD/FST files for debugging
- **Build Logs**: Detailed compilation output
- **Test Reports**: Comprehensive markdown reports
- **Coverage Data**: Code coverage metrics (when available)

## Prerequisites

### Required Tools
- **FuseSoC**: HDL package manager and build system
- **Verilator**: SystemVerilog simulator and linter
- **Python 3.6+**: Test automation framework
- **RISC-V Toolchain**: For compiling test programs (optional)

### Optional Tools
- **Verible**: Additional SystemVerilog linting
- **GTKWave**: Waveform viewer for debugging
- **Vivado**: For actual FPGA synthesis (not required for validation)

### Environment Setup
```bash
# Install Python dependencies
pip3 install --user fusesoc

# Check tool availability
util/mhx_tests/run_mhx_tests.sh lint
```

## Test Development

### Adding New Tests

1. **SystemVerilog Tests**: Add to `dv/mhx_simple_system_tests/`
2. **Python Tests**: Extend `mhx_test_runner.py`
3. **CI Integration**: Update workflow YAML files
4. **Documentation**: Update this README

### Test Guidelines
- **Modularity**: Test individual components separately
- **Coverage**: Aim for comprehensive functionality coverage
- **Reproducibility**: Tests should be deterministic
- **Performance**: Keep test execution time reasonable
- **Documentation**: Document test purpose and expected behavior

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check environment
fusesoc --version
verilator --version

# Clean build directory
rm -rf build/
```

#### Simulation Failures
```bash
# Enable debug output
export VERILATOR_OPTIONS="--trace --trace-structs"

# Check simulation logs
find build/ -name "*.log" -exec cat {} \;
```

#### FPGA Validation Issues
```bash
# Check file existence
ls -la syn/fpga/*/

# Validate script syntax
bash -n syn/fpga/build_fpga.sh
```

## Future Enhancements

### Planned Improvements
- [ ] **Formal Verification**: PSL/SVA assertions for critical paths
- [ ] **Performance Testing**: Benchmark ternary operations
- [ ] **Coverage Analysis**: Detailed code coverage reporting
- [ ] **Hardware-in-the-Loop**: Actual FPGA board testing
- [ ] **Regression Testing**: Automated test suite for releases

### Contributing
1. Write tests for new features
2. Ensure tests pass in CI
3. Update documentation
4. Follow existing test patterns
5. Add appropriate error handling

---

**MHX Neural T1**: Comprehensive testing ensures reliable ternary-enhanced neural processing hardware 🧠⚡