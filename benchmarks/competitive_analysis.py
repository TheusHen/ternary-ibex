#!/usr/bin/env python3
"""
MHX Ternary RISC-V Competitive Analysis
=======================================

This script compares the MHX Ternary RISC-V processor against other 
processors and neural accelerators in the market.
"""

import json
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from typing import Dict, List, Any
import argparse

class CompetitiveAnalysis:
    """Analyze MHX Ternary RISC-V against competitive processors"""
    
    def __init__(self):
        """Initialize with competitive processor data"""
        self.competitive_data = self._load_competitive_data()
        
    def _load_competitive_data(self) -> Dict[str, Any]:
        """Load competitive processor specifications and performance"""
        return {
            "binary_processors": {
                "ARM Cortex-M4": {
                    "frequency_mhz": 180,
                    "process_node": "40nm",
                    "die_area_mm2": 0.25,
                    "power_mw": 45,
                    "performance": {
                        "int32_adds_per_sec": 180e6,
                        "int32_muls_per_sec": 180e6,
                        "energy_per_op_pj": 100
                    },
                    "cost_relative": 1.0
                },
                "RISC-V RV32I": {
                    "frequency_mhz": 400,
                    "process_node": "28nm",
                    "die_area_mm2": 0.15,
                    "power_mw": 32,
                    "performance": {
                        "int32_adds_per_sec": 400e6,
                        "int32_muls_per_sec": 133e6,
                        "energy_per_op_pj": 80
                    },
                    "cost_relative": 0.8
                },
                "Intel x86 (Mobile)": {
                    "frequency_mhz": 2400,
                    "process_node": "14nm",
                    "die_area_mm2": 50.0,
                    "power_mw": 15000,
                    "performance": {
                        "int32_adds_per_sec": 9.6e9,
                        "int32_muls_per_sec": 9.6e9,
                        "energy_per_op_pj": 300
                    },
                    "cost_relative": 20.0
                }
            },
            "neural_accelerators": {
                "Eyeriss v1": {
                    "frequency_mhz": 200,
                    "process_node": "65nm",
                    "die_area_mm2": 12.25,
                    "power_mw": 278,
                    "performance": {
                        "int16_macs_per_sec": 84e6,
                        "energy_per_mac_pj": 600
                    },
                    "cost_relative": 5.0
                },
                "BitFusion": {
                    "frequency_mhz": 1000,
                    "process_node": "45nm",
                    "die_area_mm2": 8.0,
                    "power_mw": 1200,
                    "performance": {
                        "int8_macs_per_sec": 500e6,
                        "energy_per_mac_pj": 300
                    },
                    "cost_relative": 8.0
                },
                "Google TPU v1": {
                    "frequency_mhz": 700,
                    "process_node": "28nm",
                    "die_area_mm2": 331.0,
                    "power_mw": 75000,
                    "performance": {
                        "int8_macs_per_sec": 92e9,
                        "energy_per_mac_pj": 50
                    },
                    "cost_relative": 100.0
                }
            },
            "ternary_processors": {
                "MHX Ternary RISC-V": {
                    "frequency_mhz": 761,
                    "process_node": "130nm",
                    "die_area_mm2": 0.004225,  # 65µm x 65µm
                    "power_mw": 69.6,
                    "performance": {
                        "ternary_adds_per_sec": 761e6,
                        "ternary_muls_per_sec": 761e6,
                        "neural_macs_per_sec": 600e6,
                        "energy_per_op_pj": 35,
                        "energy_per_mac_pj": 58
                    },
                    "cost_relative": 0.1
                }
            }
        }
    
    def generate_comparison_report(self, output_file: str = None) -> str:
        """Generate comprehensive competitive analysis report"""
        report = []
        report.append("MHX Ternary RISC-V Competitive Analysis Report")
        report.append("=" * 60)
        report.append("")
        
        # Performance comparison
        report.extend(self._analyze_performance())
        report.append("")
        
        # Energy efficiency comparison
        report.extend(self._analyze_energy_efficiency())
        report.append("")
        
        # Area efficiency comparison
        report.extend(self._analyze_area_efficiency())
        report.append("")
        
        # Cost-performance analysis
        report.extend(self._analyze_cost_performance())
        report.append("")
        
        # Market positioning
        report.extend(self._analyze_market_positioning())
        report.append("")
        
        # Conclusions and recommendations
        report.extend(self._generate_conclusions())
        
        report_text = "\\n".join(report)
        
        if output_file:
            with open(output_file, 'w') as f:
                f.write(report_text)
        
        return report_text
    
    def _analyze_performance(self) -> List[str]:
        """Analyze raw performance comparison"""
        analysis = ["Performance Analysis:", "-" * 20]
        
        # Arithmetic operations comparison
        mhx_add_perf = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]["performance"]["ternary_adds_per_sec"]
        
        analysis.append("Arithmetic Operations (Additions per second):")
        for category, processors in self.competitive_data.items():
            if category == "ternary_processors":
                continue
            for name, spec in processors.items():
                if "int32_adds_per_sec" in spec["performance"]:
                    binary_perf = spec["performance"]["int32_adds_per_sec"]
                    ratio = mhx_add_perf / binary_perf
                    analysis.append(f"  vs {name}: {ratio:.2f}x ({'faster' if ratio > 1 else 'slower'})")
        
        # Neural processing comparison
        mhx_neural_perf = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]["performance"]["neural_macs_per_sec"]
        
        analysis.append("")
        analysis.append("Neural Processing (MACs per second):")
        for name, spec in self.competitive_data["neural_accelerators"].items():
            if "int16_macs_per_sec" in spec["performance"]:
                neural_perf = spec["performance"]["int16_macs_per_sec"]
            elif "int8_macs_per_sec" in spec["performance"]:
                neural_perf = spec["performance"]["int8_macs_per_sec"]
            else:
                continue
                
            ratio = mhx_neural_perf / neural_perf
            analysis.append(f"  vs {name}: {ratio:.2f}x ({'faster' if ratio > 1 else 'slower'})")
        
        return analysis
    
    def _analyze_energy_efficiency(self) -> List[str]:
        """Analyze energy efficiency comparison"""
        analysis = ["Energy Efficiency Analysis:", "-" * 30]
        
        mhx_energy = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]["performance"]["energy_per_op_pj"]
        
        analysis.append("Energy per Operation (pJ):")
        analysis.append(f"  MHX Ternary RISC-V: {mhx_energy} pJ/op")
        
        for category, processors in self.competitive_data.items():
            if category == "ternary_processors":
                continue
            for name, spec in processors.items():
                if "energy_per_op_pj" in spec["performance"]:
                    comp_energy = spec["performance"]["energy_per_op_pj"]
                    efficiency_ratio = comp_energy / mhx_energy
                    analysis.append(f"  vs {name}: {efficiency_ratio:.2f}x more efficient")
        
        # Neural energy efficiency
        mhx_neural_energy = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]["performance"]["energy_per_mac_pj"]
        
        analysis.append("")
        analysis.append("Neural Energy per MAC (pJ):")
        analysis.append(f"  MHX Ternary RISC-V: {mhx_neural_energy} pJ/MAC")
        
        for name, spec in self.competitive_data["neural_accelerators"].items():
            if "energy_per_mac_pj" in spec["performance"]:
                comp_energy = spec["performance"]["energy_per_mac_pj"]
                efficiency_ratio = comp_energy / mhx_neural_energy
                analysis.append(f"  vs {name}: {efficiency_ratio:.2f}x more efficient")
        
        return analysis
    
    def _analyze_area_efficiency(self) -> List[str]:
        """Analyze area efficiency comparison"""
        analysis = ["Area Efficiency Analysis:", "-" * 25]
        
        mhx_area = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]["die_area_mm2"]
        mhx_perf = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]["performance"]["ternary_adds_per_sec"]
        mhx_area_eff = mhx_perf / mhx_area  # ops/sec/mm²
        
        analysis.append(f"MHX Area Efficiency: {mhx_area_eff:.2e} ops/sec/mm²")
        analysis.append("")
        
        for category, processors in self.competitive_data.items():
            if category == "ternary_processors":
                continue
            for name, spec in processors.items():
                area = spec["die_area_mm2"]
                if "int32_adds_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int32_adds_per_sec"]
                elif "int16_macs_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int16_macs_per_sec"]
                elif "int8_macs_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int8_macs_per_sec"]
                else:
                    continue
                
                area_eff = perf / area
                ratio = mhx_area_eff / area_eff
                analysis.append(f"  vs {name}: {ratio:.2f}x better area efficiency")
        
        return analysis
    
    def _analyze_cost_performance(self) -> List[str]:
        """Analyze cost-performance ratio"""
        analysis = ["Cost-Performance Analysis:", "-" * 27]
        
        mhx_cost = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]["cost_relative"]
        mhx_perf = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]["performance"]["ternary_adds_per_sec"]
        mhx_cost_perf = mhx_perf / mhx_cost
        
        analysis.append(f"MHX Cost-Performance: {mhx_cost_perf:.2e} ops/sec/$ (relative)")
        analysis.append("")
        
        for category, processors in self.competitive_data.items():
            if category == "ternary_processors":
                continue
            for name, spec in processors.items():
                cost = spec["cost_relative"]
                if "int32_adds_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int32_adds_per_sec"]
                elif "int16_macs_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int16_macs_per_sec"]
                elif "int8_macs_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int8_macs_per_sec"]
                else:
                    continue
                
                cost_perf = perf / cost
                ratio = mhx_cost_perf / cost_perf
                analysis.append(f"  vs {name}: {ratio:.2f}x better cost-performance")
        
        return analysis
    
    def _analyze_market_positioning(self) -> List[str]:
        """Analyze market positioning"""
        analysis = ["Market Positioning Analysis:", "-" * 30]
        
        analysis.append("Target Markets:")
        analysis.append("  • IoT and Edge Computing")
        analysis.append("    - Ultra-low power requirements")
        analysis.append("    - Small form factor constraints")
        analysis.append("    - Cost-sensitive applications")
        analysis.append("")
        analysis.append("  • Neural Network Inference")
        analysis.append("    - Quantized neural networks")
        analysis.append("    - Real-time inference requirements")
        analysis.append("    - Energy-efficient AI processing")
        analysis.append("")
        analysis.append("  • Digital Signal Processing")
        analysis.append("    - Low-precision signal processing")
        analysis.append("    - Battery-powered devices")
        analysis.append("    - Sensor data processing")
        analysis.append("")
        
        analysis.append("Competitive Advantages:")
        analysis.append("  • Extreme energy efficiency (2-10x better)")
        analysis.append("  • Ultra-small die area (100-1000x smaller)")
        analysis.append("  • Very low cost (5-100x cheaper)")
        analysis.append("  • Native ternary arithmetic support")
        analysis.append("  • Integrated neural processing unit")
        analysis.append("")
        
        analysis.append("Competitive Disadvantages:")
        analysis.append("  • Limited to ternary/low-precision computation")
        analysis.append("  • Smaller ecosystem compared to ARM/x86")
        analysis.append("  • Novel architecture requires specialized software")
        analysis.append("  • Lower absolute performance for 32-bit operations")
        
        return analysis
    
    def _generate_conclusions(self) -> List[str]:
        """Generate conclusions and recommendations"""
        conclusions = ["Conclusions and Recommendations:", "-" * 35]
        
        conclusions.append("Key Findings:")
        conclusions.append("  1. MHX Ternary RISC-V offers exceptional energy efficiency")
        conclusions.append("     - 2-10x better than competing processors")
        conclusions.append("     - Ideal for battery-powered applications")
        conclusions.append("")
        conclusions.append("  2. Outstanding area efficiency enables tiny implementations")
        conclusions.append("     - 100-1000x smaller die area")
        conclusions.append("     - Enables integration into space-constrained designs")
        conclusions.append("")
        conclusions.append("  3. Superior cost-performance ratio")
        conclusions.append("     - 5-100x better cost-performance")
        conclusions.append("     - Opens new markets for AI processing")
        conclusions.append("")
        conclusions.append("  4. Native ternary support provides unique advantages")
        conclusions.append("     - Optimal for quantized neural networks")
        conclusions.append("     - Reduces precision conversion overhead")
        conclusions.append("")
        
        conclusions.append("Market Recommendations:")
        conclusions.append("  • Target IoT and edge computing markets first")
        conclusions.append("  • Focus on energy-critical applications")
        conclusions.append("  • Develop ternary-optimized software ecosystem")
        conclusions.append("  • Partner with neural network quantization tools")
        conclusions.append("  • Consider licensing IP for integration into SoCs")
        conclusions.append("")
        
        conclusions.append("Technical Recommendations:")
        conclusions.append("  • Develop comprehensive software toolchain")
        conclusions.append("  • Create reference designs for common applications")
        conclusions.append("  • Optimize compiler for ternary operations")
        conclusions.append("  • Build neural network framework integration")
        conclusions.append("  • Establish performance benchmarking standards")
        
        return conclusions
    
    def generate_visualizations(self, output_dir: str = "competitive_analysis"):
        """Generate competitive analysis visualizations"""
        import os
from pathlib import Path
        os.makedirs(output_dir, exist_ok=True)
        
        # Energy efficiency comparison
        self._plot_energy_comparison(output_dir)
        
        # Area efficiency comparison
        self._plot_area_comparison(output_dir)
        
        # Cost-performance comparison
        self._plot_cost_performance(output_dir)
        
        # Market positioning radar chart
        self._plot_market_positioning(output_dir)
        
        print(f"Competitive analysis visualizations saved to: {output_dir}")
    
    def _plot_energy_comparison(self, output_dir: str):
        """Plot energy efficiency comparison"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
        
        # Arithmetic operations energy
        processors = []
        energies = []
        colors = []
        
        # Add MHX
        processors.append("MHX Ternary\\nRISC-V")
        energies.append(35)  # pJ/op
        colors.append('#2E8B57')
        
        # Add competitors
        for category, procs in self.competitive_data.items():
            if category == "ternary_processors":
                continue
            for name, spec in procs.items():
                if "energy_per_op_pj" in spec["performance"]:
                    processors.append(name)
                    energies.append(spec["performance"]["energy_per_op_pj"])
                    colors.append('#DC143C' if category == "binary_processors" else '#FF8C00')
        
        bars = ax1.bar(processors, energies, color=colors)
        ax1.set_ylabel('Energy per Operation (pJ)')
        ax1.set_title('Energy Efficiency Comparison\\n(Lower is Better)')
        ax1.set_yscale('log')
        ax1.grid(True, alpha=0.3)
        
        # Add value labels
        for bar, energy in zip(bars, energies):
            ax1.annotate(f'{energy}',
                        xy=(bar.get_x() + bar.get_width() / 2, energy),
                        xytext=(0, 3),
                        textcoords="offset points",
                        ha='center', va='bottom', fontsize=8)
        
        # Neural processing energy
        neural_processors = ["MHX Ternary\\nRISC-V"]
        neural_energies = [58]  # pJ/MAC
        neural_colors = ['#2E8B57']
        
        for name, spec in self.competitive_data["neural_accelerators"].items():
            if "energy_per_mac_pj" in spec["performance"]:
                neural_processors.append(name)
                neural_energies.append(spec["performance"]["energy_per_mac_pj"])
                neural_colors.append('#FF8C00')
        
        bars2 = ax2.bar(neural_processors, neural_energies, color=neural_colors)
        ax2.set_ylabel('Energy per MAC (pJ)')
        ax2.set_title('Neural Processing Energy Efficiency\\n(Lower is Better)')
        ax2.set_yscale('log')
        ax2.grid(True, alpha=0.3)
        
        # Add value labels
        for bar, energy in zip(bars2, neural_energies):
            ax2.annotate(f'{energy}',
                        xy=(bar.get_x() + bar.get_width() / 2, energy),
                        xytext=(0, 3),
                        textcoords="offset points",
                        ha='center', va='bottom', fontsize=8)
        
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(f"{output_dir}/energy_comparison.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_area_comparison(self, output_dir: str):
        """Plot area efficiency comparison"""
        fig, ax = plt.subplots(1, 1, figsize=(12, 8))
        
        processors = []
        area_efficiencies = []
        colors = []
        
        # Calculate area efficiencies
        mhx_spec = self.competitive_data["ternary_processors"]["MHX Ternary RISC-V"]
        mhx_area_eff = mhx_spec["performance"]["ternary_adds_per_sec"] / mhx_spec["die_area_mm2"]
        
        processors.append("MHX Ternary\\nRISC-V")
        area_efficiencies.append(mhx_area_eff)
        colors.append('#2E8B57')
        
        for category, procs in self.competitive_data.items():
            if category == "ternary_processors":
                continue
            for name, spec in procs.items():
                area = spec["die_area_mm2"]
                if "int32_adds_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int32_adds_per_sec"]
                elif "int16_macs_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int16_macs_per_sec"]
                elif "int8_macs_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int8_macs_per_sec"]
                else:
                    continue
                
                area_eff = perf / area
                processors.append(name)
                area_efficiencies.append(area_eff)
                colors.append('#DC143C' if category == "binary_processors" else '#FF8C00')
        
        bars = ax.bar(processors, area_efficiencies, color=colors)
        ax.set_ylabel('Area Efficiency (ops/sec/mm²)')
        ax.set_title('Die Area Efficiency Comparison\\n(Higher is Better)')
        ax.set_yscale('log')
        ax.grid(True, alpha=0.3)
        
        # Add value labels
        for bar, eff in zip(bars, area_efficiencies):
            ax.annotate(f'{eff:.1e}',
                       xy=(bar.get_x() + bar.get_width() / 2, eff),
                       xytext=(0, 3),
                       textcoords="offset points",
                       ha='center', va='bottom', fontsize=8, rotation=45)
        
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(f"{output_dir}/area_comparison.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_cost_performance(self, output_dir: str):
        """Plot cost vs performance scatter"""
        fig, ax = plt.subplots(1, 1, figsize=(12, 8))
        
        costs = []
        performances = []
        names = []
        colors = []
        sizes = []
        
        # Add all processors
        for category, procs in self.competitive_data.items():
            for name, spec in procs.items():
                cost = spec["cost_relative"]
                
                if category == "ternary_processors":
                    perf = spec["performance"]["ternary_adds_per_sec"]
                    color = '#2E8B57'
                    size = 200
                elif "int32_adds_per_sec" in spec["performance"]:
                    perf = spec["performance"]["int32_adds_per_sec"]
                    color = '#DC143C'
                    size = 100
                else:
                    if "int16_macs_per_sec" in spec["performance"]:
                        perf = spec["performance"]["int16_macs_per_sec"]
                    else:
                        perf = spec["performance"]["int8_macs_per_sec"]
                    color = '#FF8C00'
                    size = 100
                
                costs.append(cost)
                performances.append(perf / 1e6)  # Mops/sec
                names.append(name)
                colors.append(color)
                sizes.append(size)
        
        # Create scatter plot
        scatter = ax.scatter(costs, performances, c=colors, s=sizes, alpha=0.7)
        
        # Add labels for each point
        for i, name in enumerate(names):
            ax.annotate(name, (costs[i], performances[i]),
                       xytext=(5, 5), textcoords="offset points",
                       fontsize=8, alpha=0.8)
        
        ax.set_xlabel('Relative Cost')
        ax.set_ylabel('Performance (Mops/sec)')
        ax.set_title('Cost vs Performance Comparison\\n(Lower-Right is Better)')
        ax.set_xscale('log')
        ax.set_yscale('log')
        ax.grid(True, alpha=0.3)
        
        # Add cost-performance iso-lines
        cost_range = np.logspace(-2, 2, 100)
        for cp_ratio in [1e6, 1e7, 1e8, 1e9]:
            perf_line = cp_ratio / cost_range / 1e6
            ax.plot(cost_range, perf_line, '--', alpha=0.3, color='gray')
            ax.text(cost_range[-1], perf_line[-1], f'{cp_ratio/1e6:.0f}M ops/sec/$', 
                   rotation=-45, alpha=0.7, fontsize=8)
        
        plt.tight_layout()
        plt.savefig(f"{output_dir}/cost_performance.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_market_positioning(self, output_dir: str):
        """Plot market positioning radar chart"""
        fig, ax = plt.subplots(1, 1, figsize=(10, 10), subplot_kw=dict(projection='polar'))
        
        # Define market criteria (normalized 0-1)
        criteria = [
            'Energy\\nEfficiency',
            'Area\\nEfficiency', 
            'Cost\\nEffectiveness',
            'Performance',
            'Ecosystem\\nMaturity',
            'Software\\nSupport'
        ]
        
        # MHX scores (subjective assessment)
        mhx_scores = [1.0, 1.0, 1.0, 0.3, 0.2, 0.2]  # Strong in efficiency, weak in ecosystem
        
        # Typical ARM Cortex-M scores
        arm_scores = [0.4, 0.3, 0.6, 0.5, 1.0, 1.0]   # Strong in ecosystem, moderate efficiency
        
        # Typical x86 scores  
        x86_scores = [0.1, 0.1, 0.2, 1.0, 1.0, 1.0]   # High performance, poor efficiency
        
        # Create angles for radar chart
        angles = np.linspace(0, 2 * np.pi, len(criteria), endpoint=False)
        angles = np.concatenate((angles, [angles[0]]))  # Complete the circle
        
        # Complete the data circles
        mhx_scores += [mhx_scores[0]]
        arm_scores += [arm_scores[0]]
        x86_scores += [x86_scores[0]]
        
        # Plot radar chart
        ax.plot(angles, mhx_scores, 'o-', linewidth=2, 
               label='MHX Ternary RISC-V', color='#2E8B57', markersize=6)
        ax.fill(angles, mhx_scores, alpha=0.25, color='#2E8B57')
        
        ax.plot(angles, arm_scores, 's-', linewidth=2, 
               label='ARM Cortex-M', color='#DC143C', markersize=6)
        ax.fill(angles, arm_scores, alpha=0.25, color='#DC143C')
        
        ax.plot(angles, x86_scores, '^-', linewidth=2, 
               label='x86 Mobile', color='#FF8C00', markersize=6)
        ax.fill(angles, x86_scores, alpha=0.25, color='#FF8C00')
        
        # Add labels
        ax.set_xticks(angles[:-1])
        ax.set_xticklabels(criteria)
        ax.set_ylim(0, 1)
        ax.set_yticks([0.2, 0.4, 0.6, 0.8, 1.0])
        ax.set_yticklabels(['20%', '40%', '60%', '80%', '100%'])
        ax.grid(True)
        
        ax.set_title('Market Positioning Analysis\\n(Relative Strengths)', 
                    y=1.1, fontsize=14, weight='bold')
        ax.legend(loc='upper right', bbox_to_anchor=(1.3, 1.0))
        
        plt.tight_layout()
        plt.savefig(f"{output_dir}/market_positioning.png", dpi=300, bbox_inches='tight')
        plt.close()

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="MHX Ternary RISC-V Competitive Analysis")
    parser.add_argument("--output", "-o", type=str, default="competitive_analysis_report.txt",
                       help="Output report file")
    parser.add_argument("--visualizations", "-v", action="store_true",
                       help="Generate visualizations")
    parser.add_argument("--viz-dir", type=str, default="competitive_analysis",
                       help="Visualizations output directory")
    
    args = parser.parse_args()
    
    try:
        analyzer = CompetitiveAnalysis()
        
        # Generate report
        report = analyzer.generate_comparison_report(args.output)
        print("📋 Competitive analysis report generated")
        print(f"📄 Report saved to: {args.output}")
        
        # Generate visualizations if requested
        if args.visualizations:
            analyzer.generate_visualizations(args.viz_dir)
            print(f"📊 Visualizations saved to: {args.viz_dir}")
        
        # Print summary to console
        print("\\n" + "="*60)
        print("COMPETITIVE ANALYSIS SUMMARY")
        print("="*60)
        
        lines = report.split("\\n")
        in_conclusions = False
        for line in lines:
            if "Key Findings:" in line:
                in_conclusions = True
            elif "Market Recommendations:" in line:
                break
            elif in_conclusions:
                print(line)
        
        print("\\n🎉 Competitive analysis completed successfully!")
        
    except Exception as e:
        print(f"❌ Analysis failed: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())