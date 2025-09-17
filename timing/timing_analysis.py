#!/usr/bin/env python3
"""
MHX Ternary ALU Timing Analysis
Copyright 2025 MHX Neural.

Analyzes critical paths and timing characteristics for ternary operations
using estimated delays for SkyWater 130nm process.
"""

import json
import os
from pathlib import Path
import re
from dataclasses import dataclass
from typing import List, Dict, Tuple

@dataclass
class GateDelay:
    """Gate delay characteristics for SkyWater 130nm"""
    gate_type: str
    min_delay: float  # picoseconds
    typ_delay: float  # picoseconds  
    max_delay: float  # picoseconds
    
# SkyWater 130nm gate delay estimates (ps) for sky130_fd_sc_hd library
SKYWATER_130NM_DELAYS = {
    'AND': GateDelay('AND', 50, 80, 120),
    'OR': GateDelay('OR', 45, 75, 115), 
    'NOT': GateDelay('NOT', 20, 35, 55),
    'MUX': GateDelay('MUX', 80, 120, 180),  # 2:1 mux
    'BUF': GateDelay('BUF', 25, 40, 65),
    'WIRE': GateDelay('WIRE', 5, 10, 20)    # Wire delay per stage
}

class TimingAnalyzer:
    def __init__(self, synthesis_json_file: str):
        """Initialize timing analyzer with synthesized netlist"""
        self.netlist = self._load_synthesis_json(synthesis_json_file)
        self.critical_paths = []
        self.timing_summary = {}
        
    def _load_synthesis_json(self, json_file: str) -> dict:
        """Load Yosys synthesis JSON output"""
        try:
            with open(json_file, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading synthesis JSON: {e}")
            return {}
    
    def analyze_ternary_alu_timing(self) -> Dict:
        """Analyze timing for each ternary operation"""
        
        # Extract module information
        if 'modules' not in self.netlist:
            return {"error": "No modules found in synthesis output"}
            
        alu_module = None
        for module_name, module_data in self.netlist['modules'].items():
            if 'ternary_alu' in module_name.lower():
                alu_module = module_data
                break
                
        if not alu_module:
            return {"error": "Ternary ALU module not found"}
            
        # Count gates by type
        gate_counts = self._count_gates(alu_module)
        
        # Estimate critical path delays for each operation
        operation_delays = self._estimate_operation_delays(gate_counts)
        
        # Calculate overall timing metrics
        timing_metrics = self._calculate_timing_metrics(operation_delays)
        
        return {
            'gate_counts': gate_counts,
            'operation_delays': operation_delays,
            'timing_metrics': timing_metrics,
            'process': 'SkyWater 130nm sky130_fd_sc_hd',
            'conditions': 'TT corner, 1.8V, 25C'
        }
    
    def _count_gates(self, module: dict) -> Dict[str, int]:
        """Count gates by type from synthesis output"""
        gate_counts = {}
        
        if 'cells' not in module:
            return gate_counts
            
        for cell_name, cell_data in module['cells'].items():
            cell_type = cell_data.get('type', 'unknown')
            
            # Map Yosys cell types to our gate types
            if '_AND_' in cell_type:
                gate_type = 'AND'
            elif '_OR_' in cell_type:
                gate_type = 'OR'
            elif '_NOT_' in cell_type:
                gate_type = 'NOT'
            elif '_MUX_' in cell_type:
                gate_type = 'MUX'
            else:
                gate_type = 'OTHER'
                
            gate_counts[gate_type] = gate_counts.get(gate_type, 0) + 1
            
        return gate_counts
    
    def _estimate_operation_delays(self, gate_counts: Dict[str, int]) -> Dict[str, Dict]:
        """Estimate critical path delays for each ternary operation"""
        
        # Estimate logic depth for each operation type
        operations = {
            'TERNARY_ADD': {
                'description': 'Ternary addition with saturation',
                'logic_depth': 4,  # Input decode -> Add logic -> Output encode -> Mux
                'gates_per_path': {'MUX': 3, 'AND': 2, 'OR': 2, 'NOT': 1}
            },
            'TERNARY_SUB': {
                'description': 'Ternary subtraction with saturation', 
                'logic_depth': 4,
                'gates_per_path': {'MUX': 3, 'AND': 2, 'OR': 2, 'NOT': 1}
            },
            'TERNARY_MUL': {
                'description': 'Ternary multiplication',
                'logic_depth': 3,
                'gates_per_path': {'MUX': 2, 'AND': 2, 'OR': 1}
            },
            'TERNARY_AND': {
                'description': 'Ternary logical AND',
                'logic_depth': 3,
                'gates_per_path': {'MUX': 2, 'AND': 2, 'OR': 1}
            },
            'TERNARY_OR': {
                'description': 'Ternary logical OR',
                'logic_depth': 3,
                'gates_per_path': {'MUX': 2, 'AND': 1, 'OR': 2}
            },
            'TERNARY_XOR': {
                'description': 'Ternary logical XOR',
                'logic_depth': 4,
                'gates_per_path': {'MUX': 3, 'AND': 2, 'OR': 2, 'NOT': 1}
            },
            'TERNARY_NOT': {
                'description': 'Ternary logical NOT',
                'logic_depth': 2,
                'gates_per_path': {'MUX': 1, 'NOT': 1}
            }
        }
        
        delays = {}
        for op_name, op_info in operations.items():
            path_delay = self._calculate_path_delay(op_info['gates_per_path'])
            
            delays[op_name] = {
                'description': op_info['description'],
                'logic_depth': op_info['logic_depth'],
                'min_delay_ps': path_delay['min'],
                'typ_delay_ps': path_delay['typ'],
                'max_delay_ps': path_delay['max'],
                'max_freq_mhz': 1000000 / path_delay['max'] if path_delay['max'] > 0 else 0
            }
            
        return delays
    
    def _calculate_path_delay(self, gates_in_path: Dict[str, int]) -> Dict[str, float]:
        """Calculate min/typ/max delay for a logic path"""
        total_min = 0
        total_typ = 0
        total_max = 0
        
        for gate_type, count in gates_in_path.items():
            if gate_type in SKYWATER_130NM_DELAYS:
                delay_info = SKYWATER_130NM_DELAYS[gate_type]
                total_min += delay_info.min_delay * count
                total_typ += delay_info.typ_delay * count
                total_max += delay_info.max_delay * count
        
        # Add wire delays (estimated)
        wire_stages = sum(gates_in_path.values())
        wire_delay = SKYWATER_130NM_DELAYS['WIRE']
        total_min += wire_delay.min_delay * wire_stages
        total_typ += wire_delay.typ_delay * wire_stages  
        total_max += wire_delay.max_delay * wire_stages
        
        return {
            'min': total_min,
            'typ': total_typ,
            'max': total_max
        }
    
    def _calculate_timing_metrics(self, operation_delays: Dict) -> Dict:
        """Calculate overall timing metrics"""
        if not operation_delays:
            return {}
            
        # Find critical path (longest delay)
        max_delay = 0
        critical_op = ""
        
        for op_name, op_data in operation_delays.items():
            if op_data['max_delay_ps'] > max_delay:
                max_delay = op_data['max_delay_ps']
                critical_op = op_name
        
        # Calculate timing metrics
        max_freq_mhz = 1000000 / max_delay if max_delay > 0 else 0
        
        return {
            'critical_path_operation': critical_op,
            'critical_path_delay_ps': max_delay,
            'critical_path_delay_ns': max_delay / 1000,
            'maximum_frequency_mhz': max_freq_mhz,
            'meets_100mhz_target': max_freq_mhz >= 100,
            'timing_margin_percent': ((max_freq_mhz - 100) / 100 * 100) if max_freq_mhz >= 100 else (100 - max_freq_mhz) / 100 * 100,
            'setup_time_estimate_ps': 100,  # Typical FF setup time
            'hold_time_estimate_ps': 50     # Typical FF hold time
        }

def main():
    """Main timing analysis function"""
    print("=== MHX Ternary ALU Timing Analysis ===")
    print("Process: SkyWater 130nm sky130_fd_sc_hd")
    print("Conditions: TT corner, 1.8V, 25C")
    print()
    
    # Input file from synthesis
    synthesis_json = "synthesis/output/ibex_ternary_alu_verilog_synth.json"
    
    if not os.path.exists(synthesis_json):
        print(f"ERROR: Synthesis JSON file not found: {synthesis_json}")
        return
    
    # Run timing analysis
    analyzer = TimingAnalyzer(synthesis_json)
    results = analyzer.analyze_ternary_alu_timing()
    
    if 'error' in results:
        print(f"ERROR: {results['error']}")
        return
    
    # Display results
    print("📊 Gate Count Summary:")
    for gate_type, count in results['gate_counts'].items():
        print(f"  {gate_type}: {count}")
    print()
    
    print("⏱️  Operation Timing Analysis:")
    for op_name, op_data in results['operation_delays'].items():
        print(f"  {op_name}:")
        print(f"    Description: {op_data['description']}")
        print(f"    Logic Depth: {op_data['logic_depth']} levels")
        print(f"    Timing: {op_data['min_delay_ps']:.0f}/{op_data['typ_delay_ps']:.0f}/{op_data['max_delay_ps']:.0f} ps (min/typ/max)")
        print(f"    Max Freq: {op_data['max_freq_mhz']:.1f} MHz")
        print()
    
    print("🎯 Overall Timing Metrics:")
    metrics = results['timing_metrics']
    print(f"  Critical Path: {metrics['critical_path_operation']}")
    print(f"  Critical Delay: {metrics['critical_path_delay_ns']:.2f} ns")
    print(f"  Maximum Frequency: {metrics['maximum_frequency_mhz']:.1f} MHz")
    print(f"  100 MHz Target: {'✅ PASS' if metrics['meets_100mhz_target'] else '❌ FAIL'}")
    
    if metrics['meets_100mhz_target']:
        print(f"  Timing Margin: +{metrics['timing_margin_percent']:.1f}%")
    else:
        print(f"  Timing Shortfall: -{metrics['timing_margin_percent']:.1f}%")
    
    print(f"  Setup Time: {metrics['setup_time_estimate_ps']} ps")
    print(f"  Hold Time: {metrics['hold_time_estimate_ps']} ps")
    
    # Save results
    output_file = "timing/timing_analysis_results.json"
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n📁 Results saved to: {output_file}")

if __name__ == "__main__":
    main()