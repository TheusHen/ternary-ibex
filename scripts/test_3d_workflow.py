#!/usr/bin/env python3
"""
Test script for 3D chip model generation workflow
Validates that all components work together correctly.

Copyright 2025 MHX Neural.
Licensed under the Apache License, Version 2.0.
"""

import os
import sys
import tempfile
import json
import subprocess
from pathlib import Path

def test_script_availability():
    """Test that the 3D model generation script is available and executable."""
    script_path = Path(__file__).parent / "generate_3d_chip_model.py"
    
    if not script_path.exists():
        print("❌ FAIL: generate_3d_chip_model.py not found")
        return False
    
    if not os.access(script_path, os.X_OK):
        print("❌ FAIL: generate_3d_chip_model.py is not executable")
        return False
    
    print("✅ PASS: 3D model generation script is available and executable")
    return True

def test_help_output():
    """Test that the script shows help correctly."""
    try:
        result = subprocess.run([
            sys.executable, "scripts/generate_3d_chip_model.py", "--help"
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode != 0:
            print("❌ FAIL: Script help command failed")
            print(f"stderr: {result.stderr}")
            return False
        
        if "Generate 3D model of MHX T1 Prototype chip" not in result.stdout:
            print("❌ FAIL: Help output missing expected content")
            return False
        
        print("✅ PASS: Help output is correct")
        return True
        
    except subprocess.TimeoutExpired:
        print("❌ FAIL: Help command timed out")
        return False
    except Exception as e:
        print(f"❌ FAIL: Help command failed with exception: {e}")
        return False

def test_basic_generation():
    """Test basic 3D model generation functionality."""
    with tempfile.TemporaryDirectory() as temp_dir:
        try:
            result = subprocess.run([
                sys.executable, "scripts/generate_3d_chip_model.py",
                "--output-dir", temp_dir,
                "--formats", "obj", "stl"
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode != 0:
                print("❌ FAIL: Basic generation failed")
                print(f"stdout: {result.stdout}")
                print(f"stderr: {result.stderr}")
                return False
            
            # Check expected output files
            expected_files = [
                "mhx_t1_prototype.obj",
                "mhx_t1_prototype.stl", 
                "model_summary.json"
            ]
            
            for filename in expected_files:
                filepath = Path(temp_dir) / filename
                if not filepath.exists():
                    print(f"❌ FAIL: Expected file {filename} not generated")
                    return False
                
                if filepath.stat().st_size == 0:
                    print(f"❌ FAIL: Generated file {filename} is empty")
                    return False
            
            # Validate model summary
            summary_path = Path(temp_dir) / "model_summary.json"
            with open(summary_path) as f:
                summary = json.load(f)
            
            required_keys = ["chip_name", "generated_by", "model_stats"]
            for key in required_keys:
                if key not in summary:
                    print(f"❌ FAIL: Model summary missing key: {key}")
                    return False
            
            if summary["chip_name"] != "MHX T1 Prototype":
                print("❌ FAIL: Incorrect chip name in summary")
                return False
            
            print("✅ PASS: Basic generation completed successfully")
            return True
            
        except subprocess.TimeoutExpired:
            print("❌ FAIL: Basic generation timed out")
            return False
        except Exception as e:
            print(f"❌ FAIL: Basic generation failed with exception: {e}")
            return False

def test_rtl_directory_access():
    """Test that RTL directory can be accessed."""
    rtl_dir = Path("examples/mhx_simple_system/rtl")
    
    if not rtl_dir.exists():
        print("❌ FAIL: RTL directory does not exist")
        return False
    
    expected_files = ["mhx_simple_system_top.sv"]
    for filename in expected_files:
        filepath = rtl_dir / filename
        if not filepath.exists():
            print(f"❌ FAIL: Expected RTL file {filename} not found")
            return False
    
    print("✅ PASS: RTL directory accessible with required files")
    return True

def test_synthesis_directory_access():
    """Test that synthesis directory can be accessed."""
    syn_dir = Path("examples/mhx_simple_system/syn")
    
    if not syn_dir.exists():
        print("❌ FAIL: Synthesis directory does not exist")
        return False
    
    expected_subdirs = ["yosys", "tcl", "constraints"]
    for dirname in expected_subdirs:
        dirpath = syn_dir / dirname
        if not dirpath.exists():
            print(f"❌ FAIL: Expected synthesis subdirectory {dirname} not found")
            return False
    
    # Check for build script
    build_script = syn_dir / "yosys" / "build_yosys.sh"
    if not build_script.exists():
        print("❌ FAIL: Yosys build script not found")
        return False
    
    print("✅ PASS: Synthesis directory accessible with required components")
    return True

def test_file_formats():
    """Test that different file formats are generated correctly."""
    with tempfile.TemporaryDirectory() as temp_dir:
        try:
            # Test OBJ format
            result = subprocess.run([
                sys.executable, "scripts/generate_3d_chip_model.py",
                "--output-dir", temp_dir,
                "--formats", "obj"
            ], capture_output=True, text=True, timeout=20)
            
            if result.returncode != 0:
                print("❌ FAIL: OBJ format generation failed")
                return False
            
            obj_file = Path(temp_dir) / "mhx_t1_prototype.obj"
            if not obj_file.exists():
                print("❌ FAIL: OBJ file not generated")
                return False
            
            # Check OBJ file content
            with open(obj_file) as f:
                content = f.read()
                if not content.startswith("# MHX T1 Prototype Chip Model"):
                    print("❌ FAIL: OBJ file missing expected header")
                    return False
                if "v " not in content or "f " not in content:
                    print("❌ FAIL: OBJ file missing vertices or faces")
                    return False
            
            print("✅ PASS: File format generation works correctly")
            return True
            
        except Exception as e:
            print(f"❌ FAIL: File format test failed with exception: {e}")
            return False

def main():
    """Run all tests."""
    print("MHX T1 Prototype 3D Workflow Test Suite")
    print("=" * 50)
    
    tests = [
        ("Script Availability", test_script_availability),
        ("Help Output", test_help_output),
        ("RTL Directory Access", test_rtl_directory_access),
        ("Synthesis Directory Access", test_synthesis_directory_access),
        ("Basic Generation", test_basic_generation),
        ("File Formats", test_file_formats),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\nRunning: {test_name}")
        if test_func():
            passed += 1
        else:
            print(f"Test '{test_name}' failed!")
    
    print("\n" + "=" * 50)
    print(f"Test Results: {passed}/{total} passed")
    
    if passed == total:
        print("🎉 All tests passed! Workflow is ready.")
        return 0
    else:
        print("💥 Some tests failed. Please check the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())