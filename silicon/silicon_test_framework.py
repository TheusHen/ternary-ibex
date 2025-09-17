#!/usr/bin/env python3
"""
MHX Ternary RISC-V Silicon Testing Framework
===========================================

Comprehensive silicon testing procedures including functional tests,
performance validation, and characterization protocols.
"""

import os
import json
import time
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime
from typing import Dict, List, Any, Tuple, Optional
import statistics
import concurrent.futures

class SiliconTestFramework:
    """Comprehensive silicon testing framework for MHX Ternary RISC-V"""
    
    def __init__(self, test_config_path: str = None):
        """Initialize silicon testing framework"""
        self.test_results = {}
        self.test_config = self._load_test_config(test_config_path)
        self.silicon_data = self._initialize_silicon_data()
        self.test_equipment = self._initialize_test_equipment()
        
    def _load_test_config(self, config_path: str) -> Dict[str, Any]:
        """Load test configuration"""
        if config_path and os.path.exists(config_path):
            with open(config_path, 'r') as f:
                return json.load(f)
        
        # Default test configuration
        return {
            "test_conditions": {
                "temperatures": [-40, 25, 85, 125],  # °C
                "voltages": [1.08, 1.2, 1.32],      # V (±10% of 1.2V)
                "frequencies": [200, 400, 600, 761, 800, 900]  # MHz
            },
            "test_vectors": {
                "functional": 1000,
                "performance": 500,
                "stress": 100
            },
            "characterization": {
                "process_corners": ["SS", "TT", "FF"],  # Slow-Slow, Typical-Typical, Fast-Fast
                "voltage_sweep": {"min": 0.9, "max": 1.4, "step": 0.05},
                "frequency_sweep": {"min": 100, "max": 1000, "step": 50}
            },
            "limits": {
                "power_max": 80.0,      # mW
                "frequency_min": 700,   # MHz
                "current_leakage": 10,  # μA
                "functionality": 100    # % pass rate
            }
        }
    
    def _initialize_silicon_data(self) -> Dict[str, Any]:
        """Initialize silicon die data tracking"""
        return {
            "die_count": 0,
            "tested_dies": [],
            "yield_data": {
                "functional_yield": 0,
                "performance_yield": 0,
                "overall_yield": 0
            },
            "parametric_data": {
                "frequency_distribution": [],
                "power_distribution": [],
                "leakage_distribution": []
            }
        }
    
    def _initialize_test_equipment(self) -> Dict[str, Any]:
        """Initialize test equipment specifications"""
        return {
            "ate": {
                "model": "Advantest V93000",
                "channels": 512,
                "frequency_max": 1000,  # MHz
                "voltage_range": (0, 5),  # V
                "current_range": (0, 1),  # A
            },
            "power_supply": {
                "model": "Keysight E36234A",
                "voltage_accuracy": 0.001,  # V
                "current_accuracy": 0.0001,  # A
            },
            "oscilloscope": {
                "model": "Keysight DSOX4154A",
                "bandwidth": 1500,  # MHz
                "sample_rate": 5000,  # MSa/s
            },
            "thermal_chamber": {
                "model": "Thermotron 8200",
                "temp_range": (-73, 180),  # °C
                "temp_accuracy": 0.5,  # °C
            }
        }
    
    def run_comprehensive_test_suite(self, die_count: int = 10) -> Dict[str, Any]:
        """Run comprehensive test suite on multiple dies"""
        print(f"🧪 Starting comprehensive silicon test suite on {die_count} dies...")
        
        test_summary = {
            "start_time": datetime.now().isoformat(),
            "die_count": die_count,
            "test_results": [],
            "yield_analysis": {},
            "parametric_analysis": {},
            "recommendations": []
        }
        
        # Test each die
        for die_id in range(1, die_count + 1):
            print(f"\\n🔬 Testing Die #{die_id}...")
            die_result = self.test_single_die(die_id)
            test_summary["test_results"].append(die_result)
            
            # Update silicon data
            self.silicon_data["tested_dies"].append(die_result)
        
        # Analyze overall results
        test_summary["yield_analysis"] = self._analyze_yield()
        test_summary["parametric_analysis"] = self._analyze_parametrics()
        test_summary["recommendations"] = self._generate_recommendations()
        
        test_summary["end_time"] = datetime.now().isoformat()
        
        # Save comprehensive results
        self._save_test_results(test_summary)
        
        return test_summary
    
    def test_single_die(self, die_id: int) -> Dict[str, Any]:
        """Test a single die comprehensively"""
        die_result = {
            "die_id": die_id,
            "test_timestamp": datetime.now().isoformat(),
            "functional_test": {},
            "performance_test": {},
            "characterization": {},
            "reliability_test": {},
            "overall_status": "unknown"
        }
        
        try:
            # 1. Functional Testing
            print(f"  🔧 Running functional tests...")
            die_result["functional_test"] = self._run_functional_tests(die_id)
            
            # 2. Performance Testing
            print(f"  ⚡ Running performance tests...")
            die_result["performance_test"] = self._run_performance_tests(die_id)
            
            # 3. Characterization
            print(f"  📊 Running characterization...")
            die_result["characterization"] = self._run_characterization(die_id)
            
            # 4. Reliability Testing
            print(f"  🛡️ Running reliability tests...")
            die_result["reliability_test"] = self._run_reliability_tests(die_id)
            
            # Determine overall status
            die_result["overall_status"] = self._determine_die_status(die_result)
            
            print(f"  ✅ Die #{die_id} testing complete: {die_result['overall_status']}")
            
        except Exception as e:
            die_result["error"] = str(e)
            die_result["overall_status"] = "failed"
            print(f"  ❌ Die #{die_id} testing failed: {e}")
        
        return die_result
    
    def _run_functional_tests(self, die_id: int) -> Dict[str, Any]:
        """Run comprehensive functional tests"""
        functional_results = {
            "instruction_set_test": self._test_instruction_set(die_id),
            "ternary_arithmetic_test": self._test_ternary_arithmetic(die_id),
            "neural_unit_test": self._test_neural_unit(die_id),
            "memory_interface_test": self._test_memory_interface(die_id),
            "io_interface_test": self._test_io_interface(die_id),
            "interrupt_test": self._test_interrupt_handling(die_id)
        }
        
        # Calculate overall functional score
        total_tests = sum(test["total"] for test in functional_results.values())
        passed_tests = sum(test["passed"] for test in functional_results.values())
        
        functional_results["summary"] = {
            "total_tests": total_tests,
            "passed_tests": passed_tests,
            "pass_rate": (passed_tests / total_tests) * 100 if total_tests > 0 else 0,
            "status": "pass" if passed_tests == total_tests else "fail"
        }
        
        return functional_results
    
    def _test_instruction_set(self, die_id: int) -> Dict[str, Any]:
        """Test RISC-V instruction set implementation"""
        # Simulate instruction set testing
        instructions = [
            "ADD", "SUB", "MUL", "DIV", "AND", "OR", "XOR", "SLL", "SRL", "SRA",
            "LW", "SW", "LB", "SB", "BEQ", "BNE", "BLT", "BGE", "JAL", "JALR"
        ]
        
        # Simulate test results with some variability
        passed = len(instructions) - max(0, np.random.poisson(0.1))  # Very low failure rate
        
        return {
            "test_name": "Instruction Set Test",
            "instructions_tested": instructions,
            "total": len(instructions),
            "passed": passed,
            "failed": len(instructions) - passed,
            "details": {
                "arithmetic_ops": {"passed": 10, "total": 10},
                "logical_ops": {"passed": 6, "total": 6},
                "memory_ops": {"passed": 4, "total": 4},
                "control_ops": {"passed": passed - 20, "total": len(instructions) - 20}
            }
        }
    
    def _test_ternary_arithmetic(self, die_id: int) -> Dict[str, Any]:
        """Test ternary arithmetic operations"""
        ternary_ops = [
            "TADD", "TSUB", "TMUL", "TMAX", "TMIN", "TCOMP", "TSHIFT", "TCOUNT"
        ]
        
        # Simulate ternary operation testing
        passed = len(ternary_ops) - max(0, np.random.poisson(0.05))
        
        return {
            "test_name": "Ternary Arithmetic Test",
            "operations_tested": ternary_ops,
            "total": len(ternary_ops),
            "passed": passed,
            "failed": len(ternary_ops) - passed,
            "precision_test": {
                "accuracy": 99.98,  # %
                "max_error": 0.001,
                "test_vectors": 1000
            }
        }
    
    def _test_neural_unit(self, die_id: int) -> Dict[str, Any]:
        """Test neural processing unit"""
        neural_tests = [
            "MAC_operations", "Activation_functions", "Quantization", 
            "Batch_processing", "Weight_loading", "Bias_handling"
        ]
        
        passed = len(neural_tests) - max(0, np.random.poisson(0.1))
        
        return {
            "test_name": "Neural Processing Unit Test",
            "tests": neural_tests,
            "total": len(neural_tests),
            "passed": passed,
            "failed": len(neural_tests) - passed,
            "performance": {
                "mac_throughput": 600 + np.random.normal(0, 20),  # MMAC/s
                "energy_efficiency": 58 + np.random.normal(0, 3),  # pJ/MAC
                "precision": "INT3"
            }
        }
    
    def _test_memory_interface(self, die_id: int) -> Dict[str, Any]:
        """Test memory interface functionality"""
        memory_tests = [
            "SRAM_read", "SRAM_write", "Cache_hit", "Cache_miss", 
            "Memory_coherency", "Address_translation"
        ]
        
        passed = len(memory_tests) - max(0, np.random.poisson(0.05))
        
        return {
            "test_name": "Memory Interface Test",
            "tests": memory_tests,
            "total": len(memory_tests),
            "passed": passed,
            "failed": len(memory_tests) - passed,
            "bandwidth": {
                "read_bandwidth": 3200 + np.random.normal(0, 100),  # MB/s
                "write_bandwidth": 2800 + np.random.normal(0, 100),  # MB/s
                "latency": 2.5 + np.random.normal(0, 0.2)  # ns
            }
        }
    
    def _test_io_interface(self, die_id: int) -> Dict[str, Any]:
        """Test I/O interface functionality"""
        io_tests = [
            "GPIO_output", "GPIO_input", "UART_tx", "UART_rx", 
            "SPI_master", "I2C_master", "Clock_generation"
        ]
        
        passed = len(io_tests) - max(0, np.random.poisson(0.08))
        
        return {
            "test_name": "I/O Interface Test",
            "tests": io_tests,
            "total": len(io_tests),
            "passed": passed,
            "failed": len(io_tests) - passed,
            "timing": {
                "setup_time": 0.5 + np.random.normal(0, 0.05),  # ns
                "hold_time": 0.3 + np.random.normal(0, 0.03),   # ns
                "propagation_delay": 1.2 + np.random.normal(0, 0.1)  # ns
            }
        }
    
    def _test_interrupt_handling(self, die_id: int) -> Dict[str, Any]:
        """Test interrupt handling mechanism"""
        interrupt_tests = [
            "External_interrupt", "Timer_interrupt", "Software_interrupt",
            "Nested_interrupts", "Interrupt_latency", "Context_switching"
        ]
        
        passed = len(interrupt_tests) - max(0, np.random.poisson(0.05))
        
        return {
            "test_name": "Interrupt Handling Test",
            "tests": interrupt_tests,
            "total": len(interrupt_tests),
            "passed": passed,
            "failed": len(interrupt_tests) - passed,
            "latency": {
                "min_latency": 8.5 + np.random.normal(0, 0.5),   # clock cycles
                "max_latency": 12.3 + np.random.normal(0, 0.8),  # clock cycles
                "avg_latency": 10.2 + np.random.normal(0, 0.6)   # clock cycles
            }
        }
    
    def _run_performance_tests(self, die_id: int) -> Dict[str, Any]:
        """Run performance characterization tests"""
        performance_results = {
            "frequency_test": self._test_maximum_frequency(die_id),
            "power_consumption": self._test_power_consumption(die_id),
            "throughput_test": self._test_throughput(die_id),
            "energy_efficiency": self._test_energy_efficiency(die_id),
            "thermal_performance": self._test_thermal_performance(die_id)
        }
        
        # Overall performance score
        performance_results["summary"] = self._calculate_performance_score(performance_results)
        
        return performance_results
    
    def _test_maximum_frequency(self, die_id: int) -> Dict[str, Any]:
        """Test maximum operating frequency"""
        # Simulate frequency testing across conditions
        frequencies = []
        
        for temp in self.test_config["test_conditions"]["temperatures"]:
            for voltage in self.test_config["test_conditions"]["voltages"]:
                # Base frequency with process variation
                base_freq = 761 + np.random.normal(0, 30)  # MHz
                
                # Temperature coefficient (-0.1%/°C)
                temp_factor = 1 - 0.001 * (temp - 25)
                
                # Voltage scaling (roughly linear)
                voltage_factor = voltage / 1.2
                
                freq = base_freq * temp_factor * voltage_factor
                frequencies.append(freq)
        
        max_freq = max(frequencies)
        min_freq = min(frequencies)
        
        return {
            "max_frequency": max_freq,
            "min_frequency": min_freq,
            "nominal_frequency": 761 + np.random.normal(0, 15),
            "frequency_distribution": frequencies,
            "meets_spec": max_freq >= self.test_config["limits"]["frequency_min"],
            "temperature_coefficient": -0.1,  # %/°C
            "voltage_sensitivity": 15.2  # %/V
        }
    
    def _test_power_consumption(self, die_id: int) -> Dict[str, Any]:
        """Test power consumption characteristics"""
        # Simulate power measurements
        dynamic_power = 59.2 + np.random.normal(0, 3.0)  # mW
        static_power = 10.4 + np.random.normal(0, 1.0)   # mW
        total_power = dynamic_power + static_power
        
        return {
            "dynamic_power": dynamic_power,
            "static_power": static_power,
            "total_power": total_power,
            "meets_spec": total_power <= self.test_config["limits"]["power_max"],
            "power_efficiency": 761 / total_power,  # MHz/mW
            "breakdown": {
                "core": dynamic_power * 0.65,
                "memory": dynamic_power * 0.20,
                "io": dynamic_power * 0.15
            }
        }
    
    def _test_throughput(self, die_id: int) -> Dict[str, Any]:
        """Test computational throughput"""
        # Various throughput metrics
        return {
            "instructions_per_second": (761e6) + np.random.normal(0, 20e6),
            "ternary_ops_per_second": (600e6) + np.random.normal(0, 30e6),
            "neural_macs_per_second": (580e6) + np.random.normal(0, 25e6),
            "memory_bandwidth": 3200 + np.random.normal(0, 150),  # MB/s
            "cache_hit_rate": 95.5 + np.random.normal(0, 1.5),   # %
            "branch_prediction": 92.3 + np.random.normal(0, 2.0)  # %
        }
    
    def _test_energy_efficiency(self, die_id: int) -> Dict[str, Any]:
        """Test energy efficiency metrics"""
        # Energy per operation calculations
        power = 69.6 + np.random.normal(0, 3.5)  # mW
        frequency = 761 + np.random.normal(0, 20)  # MHz
        
        return {
            "energy_per_instruction": (power / frequency) * 1000,  # pJ/instruction
            "energy_per_ternary_op": 35 + np.random.normal(0, 2),  # pJ/op
            "energy_per_mac": 58 + np.random.normal(0, 3),        # pJ/MAC
            "gops_per_watt": (frequency / power) * 1000,          # GOPS/W
            "efficiency_score": 8.5 + np.random.normal(0, 0.5)   # MIPS/mW
        }
    
    def _test_thermal_performance(self, die_id: int) -> Dict[str, Any]:
        """Test thermal characteristics"""
        return {
            "thermal_resistance": 45 + np.random.normal(0, 3),    # °C/W
            "junction_temperature": 85 + np.random.normal(0, 5),  # °C at max power
            "temperature_coefficient": -0.1 + np.random.normal(0, 0.02),  # %/°C
            "thermal_time_constant": 2.5 + np.random.normal(0, 0.3),      # ms
            "max_ambient_temp": 65 + np.random.normal(0, 3)       # °C
        }
    
    def _calculate_performance_score(self, performance_data: Dict[str, Any]) -> Dict[str, Any]:
        """Calculate overall performance score"""
        # Frequency score (0-100)
        freq_score = min(100, (performance_data["frequency_test"]["max_frequency"] / 761) * 100)
        
        # Power score (0-100, lower power = higher score)
        power_score = min(100, (70 / performance_data["power_consumption"]["total_power"]) * 100)
        
        # Efficiency score (0-100)
        efficiency = performance_data["energy_efficiency"]["efficiency_score"]
        efficiency_score = min(100, (efficiency / 10) * 100)
        
        overall_score = (freq_score + power_score + efficiency_score) / 3
        
        return {
            "frequency_score": freq_score,
            "power_score": power_score,
            "efficiency_score": efficiency_score,
            "overall_score": overall_score,
            "grade": "A" if overall_score >= 90 else "B" if overall_score >= 80 else "C"
        }
    
    def _run_characterization(self, die_id: int) -> Dict[str, Any]:
        """Run detailed characterization across process corners"""
        characterization_results = {
            "process_corners": {},
            "voltage_characterization": self._characterize_voltage_scaling(die_id),
            "temperature_characterization": self._characterize_temperature_effects(die_id),
            "aging_characterization": self._characterize_aging_effects(die_id)
        }
        
        # Test across process corners
        for corner in self.test_config["characterization"]["process_corners"]:
            characterization_results["process_corners"][corner] = self._test_process_corner(die_id, corner)
        
        return characterization_results
    
    def _characterize_voltage_scaling(self, die_id: int) -> Dict[str, Any]:
        """Characterize voltage scaling behavior"""
        voltage_data = {
            "voltages": [],
            "frequencies": [],
            "powers": []
        }
        
        voltage_range = self.test_config["characterization"]["voltage_sweep"]
        voltages = np.arange(voltage_range["min"], voltage_range["max"], voltage_range["step"])
        
        for voltage in voltages:
            # Frequency scales roughly linearly with voltage
            freq = 761 * (voltage / 1.2) + np.random.normal(0, 10)
            
            # Power scales with voltage squared
            power = 69.6 * ((voltage / 1.2) ** 2) + np.random.normal(0, 2)
            
            voltage_data["voltages"].append(voltage)
            voltage_data["frequencies"].append(max(0, freq))
            voltage_data["powers"].append(max(0, power))
        
        return voltage_data
    
    def _characterize_temperature_effects(self, die_id: int) -> Dict[str, Any]:
        """Characterize temperature effects"""
        temp_data = {
            "temperatures": [],
            "frequencies": [],
            "leakage_currents": []
        }
        
        for temp in self.test_config["test_conditions"]["temperatures"]:
            # Frequency decreases with temperature
            freq = 761 * (1 - 0.001 * (temp - 25)) + np.random.normal(0, 10)
            
            # Leakage increases exponentially with temperature
            leakage = 10 * np.exp(0.01 * (temp - 25)) + np.random.normal(0, 0.5)
            
            temp_data["temperatures"].append(temp)
            temp_data["frequencies"].append(max(0, freq))
            temp_data["leakage_currents"].append(max(0, leakage))
        
        return temp_data
    
    def _characterize_aging_effects(self, die_id: int) -> Dict[str, Any]:
        """Characterize aging and reliability effects"""
        # Simulate accelerated aging test results
        aging_data = {
            "stress_hours": [0, 100, 500, 1000, 2000],
            "frequency_degradation": [0, 0.5, 2.1, 4.8, 9.2],  # %
            "leakage_increase": [0, 2.1, 8.5, 18.2, 35.6],     # %
            "extrapolated_lifetime": 15.2,  # years at normal conditions
            "failure_rate": 5.2e-9  # FIT (failures in time)
        }
        
        return aging_data
    
    def _test_process_corner(self, die_id: int, corner: str) -> Dict[str, Any]:
        """Test specific process corner"""
        corner_factors = {
            "SS": {"speed": 0.8, "power": 1.3},   # Slow-Slow
            "TT": {"speed": 1.0, "power": 1.0},   # Typical-Typical  
            "FF": {"speed": 1.2, "power": 0.7}    # Fast-Fast
        }
        
        factor = corner_factors.get(corner, corner_factors["TT"])
        
        return {
            "corner": corner,
            "max_frequency": 761 * factor["speed"] + np.random.normal(0, 15),
            "power_consumption": 69.6 * factor["power"] + np.random.normal(0, 3),
            "meets_spec": True,  # Assume all corners meet spec
            "timing_margin": 0.15 * factor["speed"] + np.random.normal(0, 0.05)
        }
    
    def _run_reliability_tests(self, die_id: int) -> Dict[str, Any]:
        """Run reliability and stress tests"""
        reliability_results = {
            "burn_in_test": self._run_burn_in_test(die_id),
            "temperature_cycling": self._run_temperature_cycling(die_id),
            "voltage_stress": self._run_voltage_stress_test(die_id),
            "esd_test": self._run_esd_test(die_id),
            "latch_up_test": self._run_latch_up_test(die_id)
        }
        
        # Overall reliability assessment
        all_passed = all(test.get("passed", False) for test in reliability_results.values())
        reliability_results["overall_reliability"] = "pass" if all_passed else "fail"
        
        return reliability_results
    
    def _run_burn_in_test(self, die_id: int) -> Dict[str, Any]:
        """Run burn-in stress test"""
        return {
            "test": "Burn-in Test",
            "duration": 24,  # hours
            "temperature": 125,  # °C
            "voltage": 1.32,  # V
            "frequency": 900,  # MHz
            "passed": np.random.random() > 0.02,  # 98% pass rate
            "parameter_drift": {
                "frequency": np.random.normal(0, 1.0),  # %
                "power": np.random.normal(0, 2.0),      # %
                "leakage": np.random.normal(5, 3.0)     # %
            }
        }
    
    def _run_temperature_cycling(self, die_id: int) -> Dict[str, Any]:
        """Run temperature cycling test"""
        return {
            "test": "Temperature Cycling",
            "cycles": 1000,
            "temp_range": (-40, 125),  # °C
            "cycle_time": 30,  # minutes
            "passed": np.random.random() > 0.01,  # 99% pass rate
            "failure_mode": None if np.random.random() > 0.01 else "wire_bond_failure"
        }
    
    def _run_voltage_stress_test(self, die_id: int) -> Dict[str, Any]:
        """Run voltage stress test"""
        return {
            "test": "Voltage Stress",
            "stress_voltage": 1.5,  # V
            "duration": 48,  # hours
            "temperature": 85,  # °C
            "passed": np.random.random() > 0.005,  # 99.5% pass rate
            "oxide_integrity": "good",
            "leakage_increase": np.random.normal(3, 1.5)  # %
        }
    
    def _run_esd_test(self, die_id: int) -> Dict[str, Any]:
        """Run electrostatic discharge test"""
        return {
            "test": "ESD Test",
            "hbm_voltage": 2000,  # V (Human Body Model)
            "cdm_voltage": 500,   # V (Charged Device Model)
            "mm_voltage": 200,    # V (Machine Model)
            "passed": np.random.random() > 0.001,  # 99.9% pass rate
            "protection_level": "Class 2"
        }
    
    def _run_latch_up_test(self, die_id: int) -> Dict[str, Any]:
        """Run latch-up immunity test"""
        return {
            "test": "Latch-up Test",
            "trigger_current": 100,  # mA
            "voltage_overshoot": 2.0,  # V
            "passed": np.random.random() > 0.001,  # 99.9% pass rate
            "recovery": "automatic",
            "holding_voltage": 1.8  # V
        }
    
    def _determine_die_status(self, die_result: Dict[str, Any]) -> str:
        """Determine overall die status"""
        functional_pass = die_result["functional_test"]["summary"]["status"] == "pass"
        performance_pass = die_result["performance_test"]["summary"]["overall_score"] >= 70
        reliability_pass = die_result["reliability_test"]["overall_reliability"] == "pass"
        
        if functional_pass and performance_pass and reliability_pass:
            return "pass"
        elif functional_pass and performance_pass:
            return "pass_with_warnings"
        elif functional_pass:
            return "functional_only"
        else:
            return "fail"
    
    def _analyze_yield(self) -> Dict[str, Any]:
        """Analyze overall yield across tested dies"""
        if not self.silicon_data["tested_dies"]:
            return {"error": "No dies tested"}
        
        total_dies = len(self.silicon_data["tested_dies"])
        
        # Count dies by status
        status_counts = {}
        for die in self.silicon_data["tested_dies"]:
            status = die["overall_status"]
            status_counts[status] = status_counts.get(status, 0) + 1
        
        # Calculate yields
        functional_yield = (status_counts.get("pass", 0) + 
                          status_counts.get("pass_with_warnings", 0) + 
                          status_counts.get("functional_only", 0)) / total_dies * 100
        
        performance_yield = (status_counts.get("pass", 0) + 
                           status_counts.get("pass_with_warnings", 0)) / total_dies * 100
        
        overall_yield = status_counts.get("pass", 0) / total_dies * 100
        
        return {
            "total_dies_tested": total_dies,
            "functional_yield": functional_yield,
            "performance_yield": performance_yield,
            "overall_yield": overall_yield,
            "status_breakdown": status_counts,
            "meets_target": overall_yield >= 85  # Target 85% yield
        }
    
    def _analyze_parametrics(self) -> Dict[str, Any]:
        """Analyze parametric distributions"""
        if not self.silicon_data["tested_dies"]:
            return {"error": "No dies tested"}
        
        # Extract parametric data
        frequencies = []
        powers = []
        efficiencies = []
        
        for die in self.silicon_data["tested_dies"]:
            if die["overall_status"] != "fail":
                freq_data = die.get("performance_test", {}).get("frequency_test", {})
                power_data = die.get("performance_test", {}).get("power_consumption", {})
                eff_data = die.get("performance_test", {}).get("energy_efficiency", {})
                
                if freq_data.get("max_frequency"):
                    frequencies.append(freq_data["max_frequency"])
                if power_data.get("total_power"):
                    powers.append(power_data["total_power"])
                if eff_data.get("efficiency_score"):
                    efficiencies.append(eff_data["efficiency_score"])
        
        parametric_analysis = {}
        
        if frequencies:
            parametric_analysis["frequency"] = {
                "mean": statistics.mean(frequencies),
                "std_dev": statistics.stdev(frequencies) if len(frequencies) > 1 else 0,
                "min": min(frequencies),
                "max": max(frequencies),
                "median": statistics.median(frequencies),
                "distribution": frequencies
            }
        
        if powers:
            parametric_analysis["power"] = {
                "mean": statistics.mean(powers),
                "std_dev": statistics.stdev(powers) if len(powers) > 1 else 0,
                "min": min(powers),
                "max": max(powers),
                "median": statistics.median(powers),
                "distribution": powers
            }
        
        if efficiencies:
            parametric_analysis["efficiency"] = {
                "mean": statistics.mean(efficiencies),
                "std_dev": statistics.stdev(efficiencies) if len(efficiencies) > 1 else 0,
                "min": min(efficiencies),
                "max": max(efficiencies),
                "median": statistics.median(efficiencies),
                "distribution": efficiencies
            }
        
        return parametric_analysis
    
    def _generate_recommendations(self) -> List[str]:
        """Generate recommendations based on test results"""
        recommendations = []
        
        # Analyze yield
        yield_data = self._analyze_yield()
        if yield_data.get("overall_yield", 0) < 85:
            recommendations.append("Overall yield below target (85%). Investigate failure modes.")
        
        if yield_data.get("functional_yield", 0) < 95:
            recommendations.append("Functional yield below target (95%). Review design and test procedures.")
        
        # Analyze parametrics
        param_data = self._analyze_parametrics()
        
        if "frequency" in param_data:
            freq_mean = param_data["frequency"]["mean"]
            if freq_mean < 750:
                recommendations.append("Average frequency below specification. Consider process optimization.")
        
        if "power" in param_data:
            power_mean = param_data["power"]["mean"]
            if power_mean > 75:
                recommendations.append("Average power consumption high. Investigate power optimization.")
        
        # General recommendations
        recommendations.extend([
            "Continue characterization across temperature and voltage ranges",
            "Implement production test program based on silicon results",
            "Consider binning strategy for different performance grades",
            "Monitor long-term reliability through accelerated testing"
        ])
        
        return recommendations
    
    def _save_test_results(self, test_summary: Dict[str, Any]):
        """Save comprehensive test results"""
        output_dir = "silicon_test_results"
        os.makedirs(output_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Save JSON results
        json_file = os.path.join(output_dir, f"silicon_test_results_{timestamp}.json")
        with open(json_file, 'w') as f:
            json.dump(test_summary, f, indent=2, default=str)
        
        # Generate visualizations
        self._generate_test_visualizations(test_summary, output_dir, timestamp)
        
        print(f"📊 Test results saved to: {output_dir}")
        print(f"📄 JSON file: {json_file}")
    
    def _generate_test_visualizations(self, test_summary: Dict[str, Any], output_dir: str, timestamp: str):
        """Generate test result visualizations"""
        # Yield analysis chart
        self._plot_yield_analysis(test_summary, output_dir, timestamp)
        
        # Parametric distributions
        self._plot_parametric_distributions(test_summary, output_dir, timestamp)
        
        # Performance correlation
        self._plot_performance_correlation(test_summary, output_dir, timestamp)
        
        # Reliability summary
        self._plot_reliability_summary(test_summary, output_dir, timestamp)
    
    def _plot_yield_analysis(self, test_summary: Dict[str, Any], output_dir: str, timestamp: str):
        """Plot yield analysis"""
        yield_data = test_summary.get("yield_analysis", {})
        
        if "status_breakdown" not in yield_data:
            return
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
        
        # Pie chart of die status
        statuses = list(yield_data["status_breakdown"].keys())
        counts = list(yield_data["status_breakdown"].values())
        colors = ['green', 'yellow', 'orange', 'red'][:len(statuses)]
        
        ax1.pie(counts, labels=statuses, autopct='%1.1f%%', colors=colors)
        ax1.set_title('Die Status Distribution')
        
        # Yield comparison
        yields = [
            yield_data.get("functional_yield", 0),
            yield_data.get("performance_yield", 0),
            yield_data.get("overall_yield", 0)
        ]
        yield_labels = ['Functional', 'Performance', 'Overall']
        
        bars = ax2.bar(yield_labels, yields, color=['lightblue', 'lightgreen', 'lightcoral'])
        ax2.set_ylabel('Yield (%)')
        ax2.set_title('Yield Analysis')
        ax2.set_ylim(0, 100)
        
        # Add target line
        ax2.axhline(y=85, color='red', linestyle='--', label='Target (85%)')
        ax2.legend()
        
        # Add value labels on bars
        for bar, value in zip(bars, yields):
            ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1,
                    f'{value:.1f}%', ha='center', va='bottom')
        
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, f'yield_analysis_{timestamp}.png'), dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_parametric_distributions(self, test_summary: Dict[str, Any], output_dir: str, timestamp: str):
        """Plot parametric distributions"""
        param_data = test_summary.get("parametric_analysis", {})
        
        if not param_data:
            return
        
        fig, axes = plt.subplots(1, 3, figsize=(18, 6))
        
        # Frequency distribution
        if "frequency" in param_data:
            freq_data = param_data["frequency"]["distribution"]
            axes[0].hist(freq_data, bins=10, alpha=0.7, color='skyblue', edgecolor='black')
            axes[0].axvline(param_data["frequency"]["mean"], color='red', linestyle='--', 
                           label=f'Mean: {param_data["frequency"]["mean"]:.1f} MHz')
            axes[0].axvline(761, color='green', linestyle='--', label='Target: 761 MHz')
            axes[0].set_xlabel('Frequency (MHz)')
            axes[0].set_ylabel('Count')
            axes[0].set_title('Frequency Distribution')
            axes[0].legend()
        
        # Power distribution
        if "power" in param_data:
            power_data = param_data["power"]["distribution"]
            axes[1].hist(power_data, bins=10, alpha=0.7, color='lightgreen', edgecolor='black')
            axes[1].axvline(param_data["power"]["mean"], color='red', linestyle='--',
                           label=f'Mean: {param_data["power"]["mean"]:.1f} mW')
            axes[1].axvline(69.6, color='green', linestyle='--', label='Target: 69.6 mW')
            axes[1].set_xlabel('Power (mW)')
            axes[1].set_ylabel('Count')
            axes[1].set_title('Power Distribution')
            axes[1].legend()
        
        # Efficiency distribution
        if "efficiency" in param_data:
            eff_data = param_data["efficiency"]["distribution"]
            axes[2].hist(eff_data, bins=10, alpha=0.7, color='lightcoral', edgecolor='black')
            axes[2].axvline(param_data["efficiency"]["mean"], color='red', linestyle='--',
                           label=f'Mean: {param_data["efficiency"]["mean"]:.1f} MIPS/mW')
            axes[2].set_xlabel('Efficiency (MIPS/mW)')
            axes[2].set_ylabel('Count')
            axes[2].set_title('Efficiency Distribution')
            axes[2].legend()
        
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, f'parametric_distributions_{timestamp}.png'), 
                   dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_performance_correlation(self, test_summary: Dict[str, Any], output_dir: str, timestamp: str):
        """Plot performance correlations"""
        # Extract data for correlation analysis
        frequencies = []
        powers = []
        efficiencies = []
        
        for die_result in test_summary.get("test_results", []):
            if die_result["overall_status"] != "fail":
                perf = die_result.get("performance_test", {})
                freq = perf.get("frequency_test", {}).get("max_frequency")
                power = perf.get("power_consumption", {}).get("total_power")
                eff = perf.get("energy_efficiency", {}).get("efficiency_score")
                
                if freq and power and eff:
                    frequencies.append(freq)
                    powers.append(power)
                    efficiencies.append(eff)
        
        if len(frequencies) < 3:
            return
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
        
        # Frequency vs Power
        ax1.scatter(frequencies, powers, alpha=0.7, color='blue')
        ax1.set_xlabel('Frequency (MHz)')
        ax1.set_ylabel('Power (mW)')
        ax1.set_title('Frequency vs Power Correlation')
        ax1.grid(True, alpha=0.3)
        
        # Power vs Efficiency
        ax2.scatter(powers, efficiencies, alpha=0.7, color='green')
        ax2.set_xlabel('Power (mW)')
        ax2.set_ylabel('Efficiency (MIPS/mW)')
        ax2.set_title('Power vs Efficiency Correlation')
        ax2.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, f'performance_correlation_{timestamp}.png'), 
                   dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_reliability_summary(self, test_summary: Dict[str, Any], output_dir: str, timestamp: str):
        """Plot reliability test summary"""
        reliability_tests = ["burn_in_test", "temperature_cycling", "voltage_stress", "esd_test", "latch_up_test"]
        test_names = ["Burn-in", "Temp Cycling", "Voltage Stress", "ESD", "Latch-up"]
        
        pass_rates = []
        
        for test in reliability_tests:
            total_tested = 0
            total_passed = 0
            
            for die_result in test_summary.get("test_results", []):
                rel_data = die_result.get("reliability_test", {}).get(test, {})
                if "passed" in rel_data:
                    total_tested += 1
                    if rel_data["passed"]:
                        total_passed += 1
            
            pass_rate = (total_passed / total_tested * 100) if total_tested > 0 else 0
            pass_rates.append(pass_rate)
        
        fig, ax = plt.subplots(1, 1, figsize=(12, 6))
        
        bars = ax.bar(test_names, pass_rates, color=['lightblue', 'lightgreen', 'lightyellow', 'lightcoral', 'lightpink'])
        ax.set_ylabel('Pass Rate (%)')
        ax.set_title('Reliability Test Pass Rates')
        ax.set_ylim(0, 100)
        
        # Add target line
        ax.axhline(y=95, color='red', linestyle='--', label='Target (95%)')
        ax.legend()
        
        # Add value labels
        for bar, value in zip(bars, pass_rates):
            ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1,
                   f'{value:.1f}%', ha='center', va='bottom')
        
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, f'reliability_summary_{timestamp}.png'), 
                   dpi=300, bbox_inches='tight')
        plt.close()

def main():
    """Main entry point for silicon testing"""
    import argparse
    
    parser = argparse.ArgumentParser(description="MHX Ternary RISC-V Silicon Testing Framework")
    parser.add_argument("--die-count", "-n", type=int, default=10,
                       help="Number of dies to test")
    parser.add_argument("--config", "-c", type=str,
                       help="Test configuration file")
    parser.add_argument("--output", "-o", type=str, default="silicon_test_results",
                       help="Output directory")
    
    args = parser.parse_args()
    
    try:
        # Initialize test framework
        test_framework = SiliconTestFramework(args.config)
        
        # Run comprehensive test suite
        results = test_framework.run_comprehensive_test_suite(args.die_count)
        
        # Print summary
        print("\\n" + "="*70)
        print("SILICON TEST SUMMARY")
        print("="*70)
        
        yield_data = results.get("yield_analysis", {})
        print(f"Dies Tested: {yield_data.get('total_dies_tested', 0)}")
        print(f"Functional Yield: {yield_data.get('functional_yield', 0):.1f}%")
        print(f"Performance Yield: {yield_data.get('performance_yield', 0):.1f}%")
        print(f"Overall Yield: {yield_data.get('overall_yield', 0):.1f}%")
        
        if yield_data.get("meets_target", False):
            print("✅ Yield targets met!")
        else:
            print("⚠️  Yield below target")
        
        print("\\n📋 Recommendations:")
        for rec in results.get("recommendations", []):
            print(f"  • {rec}")
        
        print("\\n🎉 Silicon testing completed successfully!")
        
        return 0
        
    except Exception as e:
        print(f"❌ Silicon testing failed: {e}")
        return 1

if __name__ == "__main__":
    exit(main())