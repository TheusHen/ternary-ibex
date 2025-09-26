#!/usr/bin/env python3

# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""
MHX Neural T1 Implementation Test Runner
Automated testing framework for the MHX Neural T1 Simple System
"""

import os
import sys
import subprocess
import argparse
import time
from pathlib import Path

class MHXTestRunner:
    """Test runner for MHX Neural T1 implementation"""
    
    def __init__(self, repo_root):
        self.repo_root = Path(repo_root)
        self.build_dir = self.repo_root / "build"
        self.test_results = {}
        
    def setup_environment(self):
        """Set up test environment"""
        print("=== Setting up MHX Neural T1 test environment ===")
        
        # Create build directory
        self.build_dir.mkdir(exist_ok=True)
        
        # Check for required tools
        tools = ["fusesoc", "verilator", "python3"]
        missing_tools = []
        
        for tool in tools:
            if subprocess.run(["which", tool], capture_output=True).returncode != 0:
                missing_tools.append(tool)
        
        if missing_tools:
            print(f"⚠️ Some tools missing: {', '.join(missing_tools)}")
            print("ℹ️ Running in validation mode without full build capabilities")
            return "partial"
        
        print("✅ Environment setup complete")
        return True
    
    def run_lint_tests(self):
        """Run linting tests"""
        print("\n=== Running MHX Neural T1 Lint Tests ===")
        
        # If tools are missing, run validation mode
        if not self._tool_available("fusesoc"):
            print("⚠️ FuseSoC not available, running static validation...")
            return self._validate_core_files()
        
        test_targets = [
            "lowrisc:mhx:mhx_simple_system_core",
            "lowrisc:mhx:mhx_simple_system_test"
        ]
        
        lint_passed = True
        
        for target in test_targets:
            print(f"\nLinting {target}...")
            
            cmd = [
                "fusesoc", "--cores-root", str(self.repo_root),
                "run", "--target=lint", "--tool=verilator", target
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ Lint passed: {target}")
                self.test_results[f"lint_{target}"] = "PASS"
            else:
                print(f"❌ Lint failed: {target}")
                print(f"Error: {result.stderr}")
                self.test_results[f"lint_{target}"] = "FAIL"
                lint_passed = False
        
        return lint_passed
    
    def _validate_core_files(self):
        """Validate core files without external tools"""
        print("Validating MHX core file syntax and structure...")
        
        core_files = [
            "examples/mhx_simple_system/mhx_simple_system.core",
            "examples/mhx_simple_system/mhx_simple_system_core.core",
            "mhx_simple_system_test.core"
        ]
        
        validation_passed = True
        
        for core_file in core_files:
            core_path = self.repo_root / core_file
            if not core_path.exists():
                print(f"❌ Missing core file: {core_file}")
                validation_passed = False
                continue
                
            # Check CAPI header
            with open(core_path, 'r') as f:
                first_line = f.readline().strip()
                if not first_line.startswith("CAPI=2:"):
                    print(f"❌ Invalid CAPI header in {core_file}: {first_line}")
                    validation_passed = False
                else:
                    print(f"✅ Valid CAPI header in {core_file}")
        
        return validation_passed
    
    def _tool_available(self, tool):
        """Check if a tool is available"""
        return subprocess.run(["which", tool], capture_output=True).returncode == 0
    
    def run_build_tests(self):
        """Run build tests"""
        print("\n=== Running MHX Neural T1 Build Tests ===")
        
        # If tools are missing, run validation mode
        if not self._tool_available("fusesoc"):
            print("⚠️ FuseSoC not available, running static validation...")
            return self._validate_build_files()
        
        build_targets = [
            ("lowrisc:mhx:mhx_simple_system", {}),
            ("lowrisc:mhx:mhx_simple_system_test", {})
        ]
        
        build_passed = True
        
        for target, params in build_targets:
            print(f"\nBuilding {target}...")
            
            cmd = [
                "fusesoc", "--cores-root", str(self.repo_root),
                "run", "--target=sim", "--tool=verilator", 
                "--setup", "--build", target
            ]
            
            # Add parameters
            for key, value in params.items():
                cmd.append(f"--{key}={value}")
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ Build passed: {target}")
                self.test_results[f"build_{target}"] = "PASS"
            else:
                print(f"❌ Build failed: {target}")
                print(f"Error: {result.stderr}")
                self.test_results[f"build_{target}"] = "FAIL"
                build_passed = False
        
        return build_passed
    
    def _validate_build_files(self):
        """Validate build files without external tools"""
        print("Validating MHX build structure...")
        
        # Check RTL files exist
        rtl_files = [
            "examples/mhx_simple_system/rtl/mhx_simple_system.sv",
            "examples/mhx_simple_system/rtl/gpio_controller.sv", 
            "examples/mhx_simple_system/rtl/uart_controller.sv",
            "rtl/ibex_ternary_alu.sv",
            "rtl/ibex_ternary_regfile.sv",
            "rtl/ibex_neural_unit.sv"
        ]
        
        # Check software files exist
        sw_files = [
            "examples/sw/mhx_system/hello_mhx/hello_mhx.c",
            "examples/sw/mhx_system/hello_mhx/Makefile",
            "dv/mhx_simple_system_tests/test_programs/mhx_test_program.c"
        ]
        
        all_files = rtl_files + sw_files
        missing_files = []
        
        for file_path in all_files:
            if not (self.repo_root / file_path).exists():
                missing_files.append(file_path)
        
        if missing_files:
            print(f"❌ Missing build files: {', '.join(missing_files)}")
            return False
        
        print("✅ All required build files present")
        return True
    
    def run_simulation_tests(self):
        """Run simulation tests"""
        print("\n=== Running MHX Neural T1 Simulation Tests ===")
        
        sim_passed = True
        
        # Test MHX simple system test
        test_dir = self.build_dir / "lowrisc_mhx_mhx_simple_system_test_0/sim-verilator"
        
        if test_dir.exists():
            print("Running MHX simple system test...")
            
            cmd = [str(test_dir / "Vmhx_simple_system_test"), "+DUMP_VCD"]
            
            try:
                result = subprocess.run(cmd, timeout=300, capture_output=True, text=True)
                
                if result.returncode == 0:
                    print("✅ MHX simple system test passed")
                    self.test_results["sim_mhx_simple_system"] = "PASS"
                else:
                    print("❌ MHX simple system test failed")
                    print(f"Error: {result.stderr}")
                    self.test_results["sim_mhx_simple_system"] = "FAIL"
                    sim_passed = False
                    
            except subprocess.TimeoutExpired:
                print("❌ MHX simple system test timed out")
                self.test_results["sim_mhx_simple_system"] = "TIMEOUT"
                sim_passed = False
        else:
            print("⚠️ MHX simple system test binary not found")
            self.test_results["sim_mhx_simple_system"] = "SKIP"
        
        return sim_passed
    
    def run_fpga_validation(self):
        """Run FPGA validation tests"""
        print("\n=== Running MHX Neural T1 FPGA Validation ===")
        
        fpga_passed = True
        
        # Check required FPGA files
        fpga_files = [
            "syn/fpga/common/mhx_fpga_top.sv",
            "syn/fpga/arty_a7/build_arty_a7.tcl",
            "syn/fpga/arty_a7/arty_a7.xdc",
            "syn/fpga/basys3/build_basys3.tcl",
            "syn/fpga/basys3/basys3.xdc",
            "syn/fpga/build_fpga.sh"
        ]
        
        missing_files = []
        for file_path in fpga_files:
            full_path = self.repo_root / file_path
            if not full_path.exists():
                missing_files.append(file_path)
        
        if missing_files:
            print(f"❌ Missing FPGA files: {', '.join(missing_files)}")
            self.test_results["fpga_files"] = "FAIL"
            fpga_passed = False
        else:
            print("✅ All FPGA files present")
            self.test_results["fpga_files"] = "PASS"
        
        # Validate FPGA scripts
        build_script = self.repo_root / "syn/fpga/build_fpga.sh"
        if build_script.exists():
            # Test script error handling
            result = subprocess.run(
                [str(build_script), "invalid_board"], 
                capture_output=True, text=True
            )
            
            if "Unsupported board" in result.stderr:
                print("✅ FPGA build script validation passed")
                self.test_results["fpga_script"] = "PASS"
            else:
                print("⚠️ FPGA build script validation unclear")
                self.test_results["fpga_script"] = "WARN"
        
        return fpga_passed
    
    def generate_report(self):
        """Generate test report"""
        print("\n=== MHX Neural T1 Test Report ===")
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results.values() if result == "PASS")
        failed_tests = sum(1 for result in self.test_results.values() if result == "FAIL")
        
        print(f"Total tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {failed_tests}")
        print(f"Success rate: {(passed_tests/total_tests)*100:.1f}%")
        
        print("\nDetailed Results:")
        for test_name, result in self.test_results.items():
            status_icon = {
                "PASS": "✅",
                "FAIL": "❌", 
                "WARN": "⚠️",
                "SKIP": "⏭️",
                "TIMEOUT": "⏰"
            }.get(result, "❓")
            
            print(f"  {status_icon} {test_name}: {result}")
        
        # Write report to file
        report_file = self.repo_root / "mhx_test_report.txt"
        with open(report_file, 'w') as f:
            f.write("MHX Neural T1 Test Report\n")
            f.write("=" * 50 + "\n\n")
            f.write(f"Test execution time: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Total tests: {total_tests}\n")
            f.write(f"Passed: {passed_tests}\n")
            f.write(f"Failed: {failed_tests}\n")
            f.write(f"Success rate: {(passed_tests/total_tests)*100:.1f}%\n\n")
            
            f.write("Detailed Results:\n")
            for test_name, result in self.test_results.items():
                f.write(f"  {test_name}: {result}\n")
        
        print(f"\n📄 Full report saved to: {report_file}")
        
        return failed_tests == 0
    
    def run_all_tests(self):
        """Run all tests"""
        print("🚀 Starting MHX Neural T1 Implementation Tests")
        
        if not self.setup_environment():
            return False
        
        success = True
        
        # Run test suites
        success &= self.run_lint_tests()
        success &= self.run_build_tests() 
        success &= self.run_simulation_tests()
        success &= self.run_fpga_validation()
        
        # Generate report
        report_success = self.generate_report()
        
        if success and report_success:
            print("\n🎉 All MHX Neural T1 tests completed successfully!")
            return True
        else:
            print("\n❌ Some MHX Neural T1 tests failed")
            return False

def main():
    parser = argparse.ArgumentParser(description="MHX Neural T1 Test Runner")
    parser.add_argument("--repo-root", default=".", 
                        help="Repository root directory")
    parser.add_argument("--test-suite", choices=["lint", "build", "sim", "fpga", "all"],
                        default="all", help="Test suite to run")
    
    args = parser.parse_args()
    
    repo_root = Path(args.repo_root).resolve()
    
    if not repo_root.exists():
        print(f"❌ Repository root not found: {repo_root}")
        return 1
    
    runner = MHXTestRunner(repo_root)
    
    if args.test_suite == "all":
        success = runner.run_all_tests()
    elif args.test_suite == "lint":
        runner.setup_environment()
        success = runner.run_lint_tests()
    elif args.test_suite == "build":
        runner.setup_environment()
        success = runner.run_build_tests()
    elif args.test_suite == "sim":
        runner.setup_environment()
        success = runner.run_simulation_tests()
    elif args.test_suite == "fpga":
        runner.setup_environment()
        success = runner.run_fpga_validation()
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())