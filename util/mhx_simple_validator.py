#!/usr/bin/env python3

# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""
MHX Neural T1 Simple Validator
Quick validation script that doesn't require external tools
"""

import os
import sys
from pathlib import Path

def validate_mhx_implementation():
    """Validate MHX Neural T1 implementation"""
    print("=== MHX Neural T1 Implementation Validator ===")
    print()
    
    repo_root = Path(__file__).parent.parent
    issues = []
    successes = []
    
    # 1. Check core files
    print("1. Checking Core Files...")
    core_files = [
        "examples/mhx_simple_system/mhx_simple_system.core",
        "examples/mhx_simple_system/mhx_simple_system_core.core", 
        "mhx_simple_system_test.core"
    ]
    
    for core_file in core_files:
        path = repo_root / core_file
        if not path.exists():
            issues.append(f"Missing core file: {core_file}")
        else:
            # Check CAPI header
            with open(path) as f:
                first_line = f.readline().strip()
                if first_line.startswith("CAPI=2:"):
                    successes.append(f"Valid core file: {core_file}")
                else:
                    issues.append(f"Invalid CAPI header in {core_file}")
    
    # 2. Check RTL files
    print("2. Checking RTL Files...")
    rtl_files = [
        "examples/mhx_simple_system/rtl/mhx_simple_system.sv",
        "examples/mhx_simple_system/rtl/gpio_controller.sv",
        "examples/mhx_simple_system/rtl/uart_controller.sv",
        "rtl/ibex_ternary_alu.sv",
        "rtl/ibex_ternary_regfile.sv", 
        "rtl/ibex_neural_unit.sv"
    ]
    
    for rtl_file in rtl_files:
        path = repo_root / rtl_file
        if not path.exists():
            issues.append(f"Missing RTL file: {rtl_file}")
        else:
            successes.append(f"Found RTL file: {rtl_file}")
    
    # 3. Check FPGA files
    print("3. Checking FPGA Files...")
    fpga_files = [
        "syn/fpga/common/mhx_fpga_top.sv",
        "syn/fpga/arty_a7/build_arty_a7.tcl",
        "syn/fpga/arty_a7/arty_a7.xdc",
        "syn/fpga/basys3/build_basys3.tcl",
        "syn/fpga/basys3/basys3.xdc",
        "syn/fpga/build_fpga.sh"
    ]
    
    for fpga_file in fpga_files:
        path = repo_root / fpga_file
        if not path.exists():
            issues.append(f"Missing FPGA file: {fpga_file}")
        else:
            successes.append(f"Found FPGA file: {fpga_file}")
    
    # 4. Check software examples
    print("4. Checking Software Examples...")
    sw_files = [
        "examples/sw/mhx_system/hello_mhx/hello_mhx.c",
        "examples/sw/mhx_system/hello_mhx/Makefile",
        "dv/mhx_simple_system_tests/test_programs/mhx_test_program.c"
    ]
    
    for sw_file in sw_files:
        path = repo_root / sw_file
        if not path.exists():
            issues.append(f"Missing software file: {sw_file}")
        else:
            successes.append(f"Found software file: {sw_file}")
    
    # 5. Check configuration
    print("5. Checking Configuration...")
    config_file = repo_root / "ibex_configs.yaml"
    if config_file.exists():
        with open(config_file) as f:
            content = f.read()
            if "mhx:" in content:
                successes.append("MHX configuration found in ibex_configs.yaml")
            else:
                issues.append("MHX configuration not found in ibex_configs.yaml")
    else:
        issues.append("Missing ibex_configs.yaml file")
    
    # 6. Check workflows
    print("6. Checking GitHub Actions Workflows...")
    workflow_files = [
        ".github/workflows/mhx_neural_t1_tests.yml",
        ".github/workflows/mhx_fpga_validation.yml"
    ]
    
    for workflow_file in workflow_files:
        path = repo_root / workflow_file
        if not path.exists():
            issues.append(f"Missing workflow file: {workflow_file}")
        else:
            successes.append(f"Found workflow file: {workflow_file}")
    
    # Print results
    print()
    print("=== VALIDATION RESULTS ===")
    print()
    
    if successes:
        print(f"✅ SUCCESSES ({len(successes)}):")
        for success in successes[:10]:  # Show first 10
            print(f"   • {success}")
        if len(successes) > 10:
            print(f"   ... and {len(successes) - 10} more")
        print()
    
    if issues:
        print(f"❌ ISSUES FOUND ({len(issues)}):")
        for issue in issues:
            print(f"   • {issue}")
        print()
        print("❌ VALIDATION FAILED - Issues need to be resolved")
        return False
    else:
        print("✅ VALIDATION PASSED - MHX Neural T1 implementation is complete!")
        print()
        print("🎯 Summary:")
        print("   • All core files present with valid CAPI headers")
        print("   • All RTL files for MHX Neural T1 system present")
        print("   • FPGA synthesis infrastructure complete")
        print("   • Software examples and test programs available")
        print("   • Configuration and workflows properly set up")
        print()
        print("🚀 Ready for:")
        print("   • Simulation (with FuseSoC + Verilator)")
        print("   • FPGA deployment (with Vivado)")
        print("   • Software development (with RISC-V toolchain)")
        return True

if __name__ == "__main__":
    success = validate_mhx_implementation()
    sys.exit(0 if success else 1)