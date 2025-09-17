#!/usr/bin/env python3
"""
Multi-corner Timing Analysis for SkyWater 130nm
Copyright 2025 MHX Neural.

Analyzes timing across different process corners and operating conditions.
"""

import json
from dataclasses import dataclass
from typing import Dict, List

@dataclass
class ProcessCorner:
    """Process corner definition"""
    name: str
    voltage: float      # Volts
    temperature: int    # Celsius  
    process: str        # SS/TT/FF
    description: str

# SkyWater 130nm process corners
SKYWATER_CORNERS = [
    ProcessCorner("SS_125C_1p62V", 1.62, 125, "SS", "Slow-Slow, Hot, Low Voltage (Worst Case)"),
    ProcessCorner("TT_25C_1p8V", 1.8, 25, "TT", "Typical-Typical, Room Temp, Nominal Voltage"),
    ProcessCorner("FF_n40C_1p95V", 1.95, -40, "FF", "Fast-Fast, Cold, High Voltage (Best Case)"),
    ProcessCorner("SF_125C_1p62V", 1.62, 125, "SF", "Slow nFET, Fast pFET, Hot, Low Voltage"),
    ProcessCorner("FS_n40C_1p95V", 1.95, -40, "FS", "Fast nFET, Slow pFET, Cold, High Voltage")
]

# Corner-specific delay multipliers (relative to TT)
CORNER_MULTIPLIERS = {
    "SS": {"min": 1.8, "typ": 2.2, "max": 2.8},  # Worst case
    "TT": {"min": 1.0, "typ": 1.0, "max": 1.0},  # Nominal
    "FF": {"min": 0.4, "typ": 0.5, "max": 0.6},  # Best case
    "SF": {"min": 1.2, "typ": 1.4, "max": 1.7},  # Mixed corner
    "FS": {"min": 0.8, "typ": 1.0, "max": 1.3}   # Mixed corner
}

def analyze_multi_corner_timing():
    """Analyze timing across all process corners"""
    
    # Load baseline timing results (TT corner)
    try:
        with open("timing/timing_analysis_results.json", 'r') as f:
            baseline_results = json.load(f)
    except Exception as e:
        print(f"Error loading baseline results: {e}")
        return
    
    corner_results = {}
    
    print("=== Multi-Corner Timing Analysis ===")
    print("Process: SkyWater 130nm sky130_fd_sc_hd")
    print()
    
    for corner in SKYWATER_CORNERS:
        print(f"📊 {corner.name}: {corner.description}")
        
        # Apply corner-specific multipliers
        multipliers = CORNER_MULTIPLIERS[corner.process]
        corner_data = {}
        
        # Scale operation delays
        for op_name, op_data in baseline_results['operation_delays'].items():
            scaled_delays = {
                'min_delay_ps': op_data['min_delay_ps'] * multipliers['min'],
                'typ_delay_ps': op_data['typ_delay_ps'] * multipliers['typ'], 
                'max_delay_ps': op_data['max_delay_ps'] * multipliers['max']
            }
            
            # Calculate max frequency for this corner
            max_freq = 1000000 / scaled_delays['max_delay_ps']
            
            corner_data[op_name] = {
                **op_data,
                **scaled_delays,
                'max_freq_mhz': max_freq
            }
        
        # Find critical path for this corner
        critical_delay = 0
        critical_op = ""
        for op_name, op_data in corner_data.items():
            if op_data['max_delay_ps'] > critical_delay:
                critical_delay = op_data['max_delay_ps']
                critical_op = op_name
        
        max_freq = 1000000 / critical_delay if critical_delay > 0 else 0
        meets_target = max_freq >= 100
        
        corner_summary = {
            'corner': corner,
            'critical_operation': critical_op,
            'critical_delay_ns': critical_delay / 1000,
            'max_frequency_mhz': max_freq,
            'meets_100mhz': meets_target,
            'timing_margin': (max_freq - 100) / 100 * 100 if meets_target else (100 - max_freq) / 100 * 100,
            'operations': corner_data
        }
        
        corner_results[corner.name] = corner_summary
        
        # Display corner summary
        print(f"  Critical Path: {critical_op}")
        print(f"  Critical Delay: {critical_delay/1000:.2f} ns")
        print(f"  Max Frequency: {max_freq:.1f} MHz")
        print(f"  100 MHz Target: {'✅ PASS' if meets_target else '❌ FAIL'}")
        if meets_target:
            print(f"  Timing Margin: +{corner_summary['timing_margin']:.1f}%")
        else:
            print(f"  Timing Shortfall: -{corner_summary['timing_margin']:.1f}%")
        print()
    
    # Summary across all corners
    print("🎯 Multi-Corner Summary:")
    worst_freq = min(result['max_frequency_mhz'] for result in corner_results.values())
    best_freq = max(result['max_frequency_mhz'] for result in corner_results.values())
    all_pass = all(result['meets_100mhz'] for result in corner_results.values())
    
    print(f"  Frequency Range: {worst_freq:.1f} - {best_freq:.1f} MHz")
    print(f"  100 MHz Target: {'✅ PASS ALL CORNERS' if all_pass else '❌ FAIL SOME CORNERS'}")
    print(f"  Worst Case Margin: {(worst_freq - 100)/100*100:+.1f}%")
    
    # Save multi-corner results
    output_file = "timing/multi_corner_analysis.json"
    with open(output_file, 'w') as f:
        # Convert dataclass to dict for JSON serialization
        serializable_results = {}
        for corner_name, result in corner_results.items():
            serializable_results[corner_name] = {
                **result,
                'corner': {
                    'name': result['corner'].name,
                    'voltage': result['corner'].voltage,
                    'temperature': result['corner'].temperature,
                    'process': result['corner'].process,
                    'description': result['corner'].description
                }
            }
        json.dump(serializable_results, f, indent=2)
    
    print(f"\n📁 Multi-corner results saved to: {output_file}")
    
    return corner_results

def generate_timing_report():
    """Generate comprehensive timing report"""
    
    print("\n" + "="*60)
    print("         MHX TERNARY ALU TIMING REPORT")
    print("         SkyWater 130nm Process")
    print("="*60)
    
    # Load results
    try:
        with open("timing/timing_analysis_results.json", 'r') as f:
            results = json.load(f)
        with open("timing/multi_corner_analysis.json", 'r') as f:
            multi_corner = json.load(f)
    except Exception as e:
        print(f"Error loading results: {e}")
        return
    
    print("\n📋 DESIGN SUMMARY:")
    print(f"  Design: MHX Ternary ALU")
    print(f"  Technology: SkyWater 130nm sky130_fd_sc_hd")
    print(f"  Total Gates: {sum(results['gate_counts'].values())}")
    print(f"  Operations: {len(results['operation_delays'])}")
    
    print("\n⚡ TIMING PERFORMANCE:")
    print(f"  Target Frequency: 100 MHz")
    print(f"  Achieved Frequency (TT): {results['timing_metrics']['maximum_frequency_mhz']:.1f} MHz")
    
    worst_case = min(corner['max_frequency_mhz'] for corner in multi_corner.values())
    best_case = max(corner['max_frequency_mhz'] for corner in multi_corner.values())
    
    print(f"  Frequency Range: {worst_case:.1f} - {best_case:.1f} MHz")
    print(f"  Design Margin: {(worst_case/100-1)*100:+.1f}%")
    
    print("\n📊 GATE UTILIZATION:")
    total_gates = sum(results['gate_counts'].values())
    for gate_type, count in sorted(results['gate_counts'].items()):
        percentage = count / total_gates * 100
        print(f"  {gate_type}: {count:4d} gates ({percentage:5.1f}%)")
    
    print("\n🏆 PERFORMANCE RANKING (by speed):")
    operations = [(op, data['max_freq_mhz']) for op, data in results['operation_delays'].items()]
    operations.sort(key=lambda x: x[1], reverse=True)
    
    for i, (op, freq) in enumerate(operations, 1):
        print(f"  {i}. {op}: {freq:.1f} MHz")
    
    print("\n✅ VERIFICATION STATUS:")
    all_corners_pass = all(corner['meets_100mhz'] for corner in multi_corner.values())
    print(f"  100 MHz Target: {'PASS' if all_corners_pass else 'FAIL'}")
    print(f"  Corners Analyzed: {len(multi_corner)}")
    print(f"  Passing Corners: {sum(1 for c in multi_corner.values() if c['meets_100mhz'])}")
    
    print("\n" + "="*60)
    print("         END OF TIMING REPORT")
    print("="*60)

if __name__ == "__main__":
    # Run multi-corner analysis
    analyze_multi_corner_timing()
    
    # Generate final report
    generate_timing_report()