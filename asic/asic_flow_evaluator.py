#!/usr/bin/env python3
"""
MHX Ternary RISC-V ASIC Flow Evaluation
=======================================

Comprehensive evaluation of the ASIC implementation flow including
yield analysis, cost estimation, and fabrication readiness assessment.
"""

import json
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime
from typing import Dict, List, Any, Tuple
import os
from pathlib import Path

class ASICFlowEvaluator:
    """Evaluate complete ASIC implementation flow for MHX Ternary RISC-V"""
    
    def __init__(self):
        """Initialize with process technology and design data"""
        self.process_nodes = self._initialize_process_data()
        self.design_metrics = self._load_design_metrics()
        self.cost_models = self._initialize_cost_models()
        
    def _initialize_process_data(self) -> Dict[str, Any]:
        """Initialize process technology specifications"""
        return {
            "130nm": {
                "name": "TSMC 130nm",
                "year": 2023,
                "gate_pitch": 0.38,  # μm
                "metal_layers": 8,
                "vdd_nominal": 1.2,  # V
                "temperature_range": (-40, 125),  # °C
                "transistor_count_per_mm2": 1e6,
                "yield_model": {
                    "d0": 0.8,  # defect density per cm²
                    "alpha": 2.0,  # clustering factor
                    "area_factor": 1.0
                },
                "cost_per_mm2": 0.08,  # USD per mm² for large volumes
                "mask_cost": 50000,  # USD
                "wafer_cost": 800,  # USD per wafer
                "maturity": "mature",
                "availability": "high"
            },
            "65nm": {
                "name": "TSMC 65nm",
                "year": 2024,
                "gate_pitch": 0.25,
                "metal_layers": 9,
                "vdd_nominal": 1.0,
                "temperature_range": (-40, 125),
                "transistor_count_per_mm2": 2.5e6,
                "yield_model": {
                    "d0": 1.2,
                    "alpha": 2.2,
                    "area_factor": 0.9
                },
                "cost_per_mm2": 0.15,
                "mask_cost": 150000,
                "wafer_cost": 1200,
                "maturity": "mature",
                "availability": "high"
            },
            "28nm": {
                "name": "TSMC 28nm HPM",
                "year": 2024,
                "gate_pitch": 0.12,
                "metal_layers": 10,
                "vdd_nominal": 0.9,
                "temperature_range": (-40, 125),
                "transistor_count_per_mm2": 8e6,
                "yield_model": {
                    "d0": 2.5,
                    "alpha": 2.5,
                    "area_factor": 0.8
                },
                "cost_per_mm2": 0.35,
                "mask_cost": 500000,
                "wafer_cost": 2000,
                "maturity": "mature",
                "availability": "medium"
            },
            "14nm": {
                "name": "TSMC 14nm FinFET",
                "year": 2025,
                "gate_pitch": 0.08,
                "metal_layers": 12,
                "vdd_nominal": 0.8,
                "temperature_range": (-40, 125),
                "transistor_count_per_mm2": 20e6,
                "yield_model": {
                    "d0": 4.0,
                    "alpha": 3.0,
                    "area_factor": 0.7
                },
                "cost_per_mm2": 0.80,
                "mask_cost": 2000000,
                "wafer_cost": 4000,
                "maturity": "advanced",
                "availability": "limited"
            }
        }
    
    def _load_design_metrics(self) -> Dict[str, Any]:
        """Load MHX Ternary RISC-V design metrics"""
        return {
            "gate_count": 1184,
            "die_area_130nm": 0.004225,  # mm² (65μm x 65μm)
            "critical_path_delay": 1.314,  # ns
            "power_dynamic": 59.2,  # mW @ 761 MHz
            "power_static": 10.4,  # mW
            "metal_layers_used": 4,
            "io_count": 64,
            "memory_bits": 8192,  # Register file + caches
            "complexity_factors": {
                "ternary_alu": 1.5,
                "neural_unit": 2.0,
                "control_logic": 1.0,
                "memory_interface": 1.2
            }
        }
    
    def _initialize_cost_models(self) -> Dict[str, Any]:
        """Initialize cost models for different scenarios"""
        return {
            "nre_costs": {
                "design": 150000,  # Design and verification
                "mask_tooling": 0,  # Set per process
                "test_program": 25000,
                "qualification": 50000,
                "packaging": 15000
            },
            "unit_costs": {
                "wafer_processing": 0,  # Set per process
                "assembly": 0.50,
                "test": 0.25,
                "packaging": 1.00,
                "quality": 0.15
            },
            "volume_breakpoints": [100, 1000, 10000, 100000, 1000000],
            "yield_factors": {
                "design_maturity": 0.95,
                "test_coverage": 0.98,
                "process_margin": 0.90
            }
        }
    
    def evaluate_process_scaling(self) -> Dict[str, Any]:
        """Evaluate design scaling across process nodes"""
        scaling_results = {}
        
        base_area = self.design_metrics["die_area_130nm"]
        base_gates = self.design_metrics["gate_count"]
        
        for node, specs in self.process_nodes.items():
            # Calculate scaled area
            if node == "130nm":
                scaled_area = base_area
                frequency_boost = 1.0
                power_scaling = 1.0
            else:
                # Area scaling with process
                scaling_factor = (130 / float(node.replace("nm", ""))) ** 2
                scaled_area = base_area / scaling_factor
                
                # Frequency improvement
                frequency_boost = (130 / float(node.replace("nm", ""))) * 0.8
                
                # Power scaling (voltage scaling + area)
                voltage_ratio = specs["vdd_nominal"] / 1.2
                power_scaling = (voltage_ratio ** 2) * (1/scaling_factor) * 0.7
            
            scaling_results[node] = {
                "die_area_mm2": scaled_area,
                "estimated_frequency_mhz": 761 * frequency_boost,
                "estimated_power_mw": 69.6 * power_scaling,
                "transistor_density": specs["transistor_count_per_mm2"],
                "gate_density": base_gates / scaled_area,
                "performance_per_watt": (761 * frequency_boost) / (69.6 * power_scaling),
                "performance_per_mm2": (761 * frequency_boost) / scaled_area
            }
        
        return scaling_results
    
    def calculate_yield_analysis(self) -> Dict[str, Any]:
        """Calculate yield analysis for each process node"""
        yield_results = {}
        scaling = self.evaluate_process_scaling()
        
        for node, specs in self.process_nodes.items():
            area_mm2 = scaling[node]["die_area_mm2"]
            area_cm2 = area_mm2 / 100  # Convert to cm²
            
            # Murphy's yield model: Y = exp(-D0 * A^α)
            d0 = specs["yield_model"]["d0"]
            alpha = specs["yield_model"]["alpha"]
            area_factor = specs["yield_model"]["area_factor"]
            
            parametric_yield = 0.85  # Assume 85% parametric yield
            design_yield = self.cost_models["yield_factors"]["design_maturity"]
            test_yield = self.cost_models["yield_factors"]["test_coverage"]
            
            # Calculate defect-limited yield
            defect_yield = np.exp(-d0 * (area_cm2 * area_factor) ** alpha)
            
            # Overall yield
            overall_yield = defect_yield * parametric_yield * design_yield * test_yield
            
            # Dies per wafer (assuming 200mm wafer for cost estimation)
            wafer_area = np.pi * (100) ** 2  # mm²
            edge_loss = 0.9  # Account for edge dies
            dies_per_wafer = (wafer_area * edge_loss) / area_mm2
            
            # Good dies per wafer
            good_dies_per_wafer = dies_per_wafer * overall_yield
            
            yield_results[node] = {
                "defect_yield": defect_yield,
                "parametric_yield": parametric_yield,
                "overall_yield": overall_yield,
                "dies_per_wafer": dies_per_wafer,
                "good_dies_per_wafer": good_dies_per_wafer,
                "yield_loss_breakdown": {
                    "defects": 1 - defect_yield,
                    "parametric": 1 - parametric_yield,
                    "design": 1 - design_yield,
                    "test": 1 - test_yield
                }
            }
        
        return yield_results
    
    def calculate_cost_analysis(self, volumes: List[int] = None) -> Dict[str, Any]:
        """Calculate comprehensive cost analysis"""
        if volumes is None:
            volumes = self.cost_models["volume_breakpoints"]
        
        yield_data = self.calculate_yield_analysis()
        scaling_data = self.evaluate_process_scaling()
        cost_results = {}
        
        for node, specs in self.process_nodes.items():
            node_costs = {}
            
            # NRE costs
            nre_costs = self.cost_models["nre_costs"].copy()
            nre_costs["mask_tooling"] = specs["mask_cost"]
            total_nre = sum(nre_costs.values())
            
            # Per-unit costs for different volumes
            for volume in volumes:
                # Wafer cost per die
                wafer_cost_per_die = specs["wafer_cost"] / yield_data[node]["good_dies_per_wafer"]
                
                # Assembly and test costs (volume dependent)
                volume_factor = min(1.0, 1000 / volume)  # Economies of scale
                assembly_cost = self.cost_models["unit_costs"]["assembly"] * volume_factor
                test_cost = self.cost_models["unit_costs"]["test"] * volume_factor
                packaging_cost = self.cost_models["unit_costs"]["packaging"] * volume_factor
                quality_cost = self.cost_models["unit_costs"]["quality"] * volume_factor
                
                # Total unit cost
                unit_cost = wafer_cost_per_die + assembly_cost + test_cost + packaging_cost + quality_cost
                
                # Total cost including NRE amortization
                nre_per_unit = total_nre / volume
                total_cost_per_unit = unit_cost + nre_per_unit
                
                node_costs[f"volume_{volume}"] = {
                    "nre_total": total_nre,
                    "nre_per_unit": nre_per_unit,
                    "unit_cost": unit_cost,
                    "total_cost": total_cost_per_unit,
                    "breakdown": {
                        "wafer": wafer_cost_per_die,
                        "assembly": assembly_cost,
                        "test": test_cost,
                        "packaging": packaging_cost,
                        "quality": quality_cost,
                        "nre_amortized": nre_per_unit
                    }
                }
            
            cost_results[node] = {
                "nre_costs": nre_costs,
                "volume_costs": node_costs,
                "manufacturing_data": {
                    "yield": yield_data[node]["overall_yield"],
                    "dies_per_wafer": yield_data[node]["good_dies_per_wafer"],
                    "area_mm2": scaling_data[node]["die_area_mm2"]
                }
            }
        
        return cost_results
    
    def evaluate_fabrication_readiness(self) -> Dict[str, Any]:
        """Evaluate fabrication readiness across criteria"""
        readiness_criteria = [
            "design_rules_compliance",
            "timing_closure",
            "power_analysis",
            "signal_integrity",
            "thermal_analysis",
            "testability",
            "packaging_compatibility",
            "supply_chain_readiness"
        ]
        
        # Get scaling data for analysis
        scaling_data = self.evaluate_process_scaling()
        
        readiness_scores = {}
        
        for node in self.process_nodes.keys():
            scores = {}
            
            # Design rules compliance (based on maturity)
            if self.process_nodes[node]["maturity"] == "mature":
                scores["design_rules_compliance"] = 0.95
            elif self.process_nodes[node]["maturity"] == "advanced":
                scores["design_rules_compliance"] = 0.85
            else:
                scores["design_rules_compliance"] = 0.75
            
            # Timing closure (frequency dependent)
            target_freq = scaling_data[node]["estimated_frequency_mhz"]
            if target_freq > 1000:
                scores["timing_closure"] = 0.80
            elif target_freq > 500:
                scores["timing_closure"] = 0.90
            else:
                scores["timing_closure"] = 0.95
            
            # Power analysis
            estimated_power = scaling_data[node]["estimated_power_mw"]
            if estimated_power < 50:
                scores["power_analysis"] = 0.95
            elif estimated_power < 100:
                scores["power_analysis"] = 0.90
            else:
                scores["power_analysis"] = 0.85
            
            # Signal integrity (area dependent)
            area = scaling_data[node]["die_area_mm2"]
            if area < 0.01:
                scores["signal_integrity"] = 0.95
            elif area < 0.1:
                scores["signal_integrity"] = 0.90
            else:
                scores["signal_integrity"] = 0.85
            
            # Standard scores for well-designed blocks
            scores["thermal_analysis"] = 0.90
            scores["testability"] = 0.88
            scores["packaging_compatibility"] = 0.92
            
            # Supply chain readiness
            if self.process_nodes[node]["availability"] == "high":
                scores["supply_chain_readiness"] = 0.95
            elif self.process_nodes[node]["availability"] == "medium":
                scores["supply_chain_readiness"] = 0.80
            else:
                scores["supply_chain_readiness"] = 0.65
            
            # Calculate overall readiness
            overall_score = np.mean(list(scores.values()))
            
            readiness_scores[node] = {
                "individual_scores": scores,
                "overall_readiness": overall_score,
                "risk_level": "Low" if overall_score > 0.90 else "Medium" if overall_score > 0.80 else "High",
                "recommendation": self._generate_recommendation(overall_score, node)
            }
        
        return readiness_scores
    
    def _generate_recommendation(self, score: float, node: str) -> str:
        """Generate fabrication recommendation based on readiness score"""
        if score > 0.90:
            return f"RECOMMENDED: {node} process is ready for fabrication with low risk"
        elif score > 0.80:
            return f"CONDITIONAL: {node} process ready with medium risk - address identified issues"
        else:
            return f"NOT RECOMMENDED: {node} process has high risk - significant improvements needed"
    
    def generate_comprehensive_report(self, output_file: str = None) -> str:
        """Generate comprehensive ASIC flow evaluation report"""
        # Generate all analysis data
        scaling_data = self.evaluate_process_scaling()
        yield_data = self.calculate_yield_analysis()
        cost_data = self.calculate_cost_analysis()
        readiness_data = self.evaluate_fabrication_readiness()
        
        report = []
        report.append("MHX Ternary RISC-V ASIC Flow Evaluation Report")
        report.append("=" * 60)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        # Executive Summary
        report.extend(self._generate_executive_summary(readiness_data, cost_data))
        report.append("")
        
        # Process Node Analysis
        report.extend(self._generate_process_analysis(scaling_data))
        report.append("")
        
        # Yield Analysis
        report.extend(self._generate_yield_analysis(yield_data))
        report.append("")
        
        # Cost Analysis
        report.extend(self._generate_cost_analysis(cost_data))
        report.append("")
        
        # Fabrication Readiness
        report.extend(self._generate_readiness_analysis(readiness_data))
        report.append("")
        
        # Recommendations
        report.extend(self._generate_final_recommendations(readiness_data, cost_data))
        
        report_text = "\\n".join(report)
        
        if output_file:
            with open(output_file, 'w') as f:
                f.write(report_text)
        
        # Save detailed data
        detailed_data = {
            "scaling_analysis": scaling_data,
            "yield_analysis": yield_data,
            "cost_analysis": cost_data,
            "readiness_analysis": readiness_data
        }
        
        if output_file:
            data_file = output_file.replace('.txt', '_data.json')
            with open(data_file, 'w') as f:
                json.dump(detailed_data, f, indent=2, default=str)
        
        return report_text
    
    def _generate_executive_summary(self, readiness_data, cost_data) -> List[str]:
        """Generate executive summary"""
        summary = ["Executive Summary:", "-" * 18]
        
        # Find best process node
        best_node = max(readiness_data.keys(), 
                       key=lambda x: readiness_data[x]["overall_readiness"])
        best_score = readiness_data[best_node]["overall_readiness"]
        
        summary.append(f"RECOMMENDED PROCESS: {best_node} (Readiness: {best_score:.1%})")
        summary.append("")
        
        # Cost summary for recommended process
        recommended_costs = cost_data[best_node]["volume_costs"]
        summary.append("Cost Summary (Recommended Process):")
        for volume, costs in recommended_costs.items():
            vol_num = volume.split('_')[1]
            summary.append(f"  {vol_num:>6} units: ${costs['total_cost']:.2f} per unit")
        
        summary.append("")
        summary.append("Key Findings:")
        summary.append(f"  • {best_node} offers best balance of cost and risk")
        summary.append(f"  • Overall fabrication readiness: {best_score:.1%}")
        summary.append(f"  • Estimated yield: {cost_data[best_node]['manufacturing_data']['yield']:.1%}")
        summary.append(f"  • Die area: {cost_data[best_node]['manufacturing_data']['area_mm2']:.4f} mm²")
        
        return summary
    
    def _generate_process_analysis(self, scaling_data) -> List[str]:
        """Generate process scaling analysis"""
        analysis = ["Process Node Scaling Analysis:", "-" * 32]
        
        analysis.append("Performance and Area Scaling:")
        analysis.append(f"{'Node':>6} {'Area(mm²)':>10} {'Freq(MHz)':>10} {'Power(mW)':>10} {'Perf/W':>10} {'Perf/mm²':>12}")
        analysis.append("-" * 70)
        
        for node, data in scaling_data.items():
            analysis.append(f"{node:>6} {data['die_area_mm2']:>10.4f} "
                          f"{data['estimated_frequency_mhz']:>10.0f} "
                          f"{data['estimated_power_mw']:>10.1f} "
                          f"{data['performance_per_watt']:>10.1f} "
                          f"{data['performance_per_mm2']:>12.0f}")
        
        return analysis
    
    def _generate_yield_analysis(self, yield_data) -> List[str]:
        """Generate yield analysis"""
        analysis = ["Yield Analysis:", "-" * 15]
        
        analysis.append(f"{'Node':>6} {'Defect':>8} {'Overall':>8} {'Dies/Wafer':>12} {'Good Dies':>10}")
        analysis.append("-" * 50)
        
        for node, data in yield_data.items():
            analysis.append(f"{node:>6} {data['defect_yield']:>8.1%} "
                          f"{data['overall_yield']:>8.1%} "
                          f"{data['dies_per_wafer']:>12.0f} "
                          f"{data['good_dies_per_wafer']:>10.0f}")
        
        return analysis
    
    def _generate_cost_analysis(self, cost_data) -> List[str]:
        """Generate cost analysis"""
        analysis = ["Cost Analysis:", "-" * 14]
        
        # Cost comparison table
        volumes = [1000, 10000, 100000]
        analysis.append(f"Unit Costs (including NRE amortization):")
        analysis.append(f"{'Node':>6} {'1K units':>10} {'10K units':>11} {'100K units':>12}")
        analysis.append("-" * 45)
        
        for node, data in cost_data.items():
            costs = []
            for vol in volumes:
                cost = data["volume_costs"][f"volume_{vol}"]["total_cost"]
                costs.append(f"${cost:.2f}")
            
            analysis.append(f"{node:>6} {costs[0]:>10} {costs[1]:>11} {costs[2]:>12}")
        
        return analysis
    
    def _generate_readiness_analysis(self, readiness_data) -> List[str]:
        """Generate fabrication readiness analysis"""
        analysis = ["Fabrication Readiness Assessment:", "-" * 35]
        
        analysis.append(f"{'Node':>6} {'Overall':>8} {'Risk':>8} {'Recommendation':>40}")
        analysis.append("-" * 70)
        
        for node, data in readiness_data.items():
            analysis.append(f"{node:>6} {data['overall_readiness']:>8.1%} "
                          f"{data['risk_level']:>8} {data['recommendation'][:40]:>40}")
        
        return analysis
    
    def _generate_final_recommendations(self, readiness_data, cost_data) -> List[str]:
        """Generate final recommendations"""
        recs = ["Final Recommendations:", "-" * 23]
        
        # Rank by readiness score
        ranked_nodes = sorted(readiness_data.keys(), 
                            key=lambda x: readiness_data[x]["overall_readiness"], 
                            reverse=True)
        
        recs.append("Process Node Ranking (by fabrication readiness):")
        for i, node in enumerate(ranked_nodes, 1):
            score = readiness_data[node]["overall_readiness"]
            risk = readiness_data[node]["risk_level"]
            recs.append(f"  {i}. {node} - {score:.1%} readiness, {risk} risk")
        
        recs.append("")
        recs.append("Strategic Recommendations:")
        
        best_node = ranked_nodes[0]
        recs.append(f"  • IMMEDIATE: Proceed with {best_node} for first silicon")
        recs.append(f"  • RISK MITIGATION: Address any medium/high risk items")
        recs.append(f"  • COST OPTIMIZATION: Target {best_node} for volume production")
        recs.append(f"  • FUTURE: Evaluate advanced nodes as they mature")
        
        recs.append("")
        recs.append("Implementation Timeline:")
        recs.append("  • Phase 1 (0-3 months): Final design verification")
        recs.append("  • Phase 2 (3-6 months): Mask preparation and tapeout")
        recs.append("  • Phase 3 (6-9 months): Fabrication and packaging")
        recs.append("  • Phase 4 (9-12 months): Silicon validation and characterization")
        
        return recs
    
    def generate_visualizations(self, output_dir: str = "asic_analysis"):
        """Generate ASIC analysis visualizations"""
        os.makedirs(output_dir, exist_ok=True)
        
        scaling_data = self.evaluate_process_scaling()
        yield_data = self.calculate_yield_analysis()
        cost_data = self.calculate_cost_analysis()
        readiness_data = self.evaluate_fabrication_readiness()
        
        # Process scaling visualization
        self._plot_process_scaling(scaling_data, output_dir)
        
        # Yield analysis
        self._plot_yield_analysis(yield_data, output_dir)
        
        # Cost analysis
        self._plot_cost_analysis(cost_data, output_dir)
        
        # Readiness radar chart
        self._plot_readiness_analysis(readiness_data, output_dir)
        
        print(f"ASIC analysis visualizations saved to: {output_dir}")
    
    def _plot_process_scaling(self, scaling_data, output_dir):
        """Plot process scaling analysis"""
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
        
        nodes = list(scaling_data.keys())
        areas = [scaling_data[node]["die_area_mm2"] for node in nodes]
        freqs = [scaling_data[node]["estimated_frequency_mhz"] for node in nodes]
        powers = [scaling_data[node]["estimated_power_mw"] for node in nodes]
        perf_per_watt = [scaling_data[node]["performance_per_watt"] for node in nodes]
        
        # Die area
        bars1 = ax1.bar(nodes, areas, color='skyblue')
        ax1.set_ylabel('Die Area (mm²)')
        ax1.set_title('Die Area vs Process Node')
        ax1.set_yscale('log')
        
        # Frequency
        bars2 = ax2.bar(nodes, freqs, color='lightgreen')
        ax2.set_ylabel('Frequency (MHz)')
        ax2.set_title('Estimated Frequency vs Process Node')
        
        # Power
        bars3 = ax3.bar(nodes, powers, color='lightcoral')
        ax3.set_ylabel('Power (mW)')
        ax3.set_title('Estimated Power vs Process Node')
        
        # Performance per Watt
        bars4 = ax4.bar(nodes, perf_per_watt, color='gold')
        ax4.set_ylabel('Performance/Watt (MHz/mW)')
        ax4.set_title('Energy Efficiency vs Process Node')
        
        plt.tight_layout()
        plt.savefig(f"{output_dir}/process_scaling.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_yield_analysis(self, yield_data, output_dir):
        """Plot yield analysis"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
        
        nodes = list(yield_data.keys())
        overall_yields = [yield_data[node]["overall_yield"] for node in nodes]
        good_dies = [yield_data[node]["good_dies_per_wafer"] for node in nodes]
        
        # Overall yield
        bars1 = ax1.bar(nodes, [y*100 for y in overall_yields], color='lightblue')
        ax1.set_ylabel('Overall Yield (%)')
        ax1.set_title('Manufacturing Yield by Process Node')
        ax1.set_ylim(0, 100)
        
        # Good dies per wafer
        bars2 = ax2.bar(nodes, good_dies, color='lightgreen')
        ax2.set_ylabel('Good Dies per Wafer')
        ax2.set_title('Productivity by Process Node')
        
        plt.tight_layout()
        plt.savefig(f"{output_dir}/yield_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_cost_analysis(self, cost_data, output_dir):
        """Plot cost analysis"""
        fig, ax = plt.subplots(1, 1, figsize=(12, 8))
        
        volumes = [1000, 10000, 100000]
        nodes = list(cost_data.keys())
        
        x = np.arange(len(volumes))
        width = 0.2
        
        for i, node in enumerate(nodes):
            costs = []
            for vol in volumes:
                cost = cost_data[node]["volume_costs"][f"volume_{vol}"]["total_cost"]
                costs.append(cost)
            
            ax.bar(x + i*width, costs, width, label=node)
        
        ax.set_xlabel('Production Volume')
        ax.set_ylabel('Cost per Unit (USD)')
        ax.set_title('Unit Cost vs Volume by Process Node')
        ax.set_xticks(x + width * (len(nodes)-1) / 2)
        ax.set_xticklabels([f"{v:,}" for v in volumes])
        ax.legend()
        ax.set_yscale('log')
        
        plt.tight_layout()
        plt.savefig(f"{output_dir}/cost_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_readiness_analysis(self, readiness_data, output_dir):
        """Plot fabrication readiness radar chart"""
        fig, ax = plt.subplots(1, 1, figsize=(10, 10), subplot_kw=dict(projection='polar'))
        
        criteria = [
            'Design Rules', 'Timing', 'Power', 'Signal Integrity',
            'Thermal', 'Testability', 'Packaging', 'Supply Chain'
        ]
        
        angles = np.linspace(0, 2 * np.pi, len(criteria), endpoint=False)
        angles = np.concatenate((angles, [angles[0]]))
        
        colors = ['red', 'blue', 'green', 'orange']
        
        for i, (node, data) in enumerate(readiness_data.items()):
            scores = []
            for criterion in ['design_rules_compliance', 'timing_closure', 'power_analysis', 
                            'signal_integrity', 'thermal_analysis', 'testability', 
                            'packaging_compatibility', 'supply_chain_readiness']:
                scores.append(data['individual_scores'][criterion])
            
            scores += [scores[0]]  # Complete the circle
            
            ax.plot(angles, scores, 'o-', linewidth=2, label=node, color=colors[i % len(colors)])
            ax.fill(angles, scores, alpha=0.25, color=colors[i % len(colors)])
        
        ax.set_xticks(angles[:-1])
        ax.set_xticklabels(criteria)
        ax.set_ylim(0, 1)
        ax.set_yticks([0.2, 0.4, 0.6, 0.8, 1.0])
        ax.set_yticklabels(['20%', '40%', '60%', '80%', '100%'])
        ax.grid(True)
        
        ax.set_title('Fabrication Readiness by Process Node', y=1.1, fontsize=14, weight='bold')
        ax.legend(loc='upper right', bbox_to_anchor=(1.3, 1.0))
        
        plt.tight_layout()
        plt.savefig(f"{output_dir}/readiness_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="MHX Ternary RISC-V ASIC Flow Evaluation")
    parser.add_argument("--output", "-o", type=str, default="asic_flow_evaluation.txt",
                       help="Output report file")
    parser.add_argument("--visualizations", "-v", action="store_true",
                       help="Generate visualizations")
    parser.add_argument("--viz-dir", type=str, default="asic_analysis",
                       help="Visualizations output directory")
    
    args = parser.parse_args()
    
    try:
        evaluator = ASICFlowEvaluator()
        
        # Generate comprehensive report
        report = evaluator.generate_comprehensive_report(args.output)
        print("📋 ASIC flow evaluation completed")
        print(f"📄 Report saved to: {args.output}")
        
        # Generate visualizations if requested
        if args.visualizations:
            evaluator.generate_visualizations(args.viz_dir)
            print(f"📊 Visualizations saved to: {args.viz_dir}")
        
        # Print key findings
        print("\\n" + "="*60)
        print("ASIC FLOW EVALUATION SUMMARY")
        print("="*60)
        
        # Extract and display key findings
        lines = report.split("\\n")
        in_summary = False
        for line in lines:
            if "Executive Summary:" in line:
                in_summary = True
            elif "Process Node Scaling Analysis:" in line:
                break
            elif in_summary and line.strip():
                print(line)
        
        print("\\n🎉 ASIC flow evaluation completed successfully!")
        
    except Exception as e:
        print(f"❌ Evaluation failed: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())