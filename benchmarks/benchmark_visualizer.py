#!/usr/bin/env python3
"""
MHX Ternary RISC-V Benchmark Visualization Suite
===============================================

This script generates comprehensive visualizations of benchmark results
comparing ternary vs binary operations, performance scaling, and energy efficiency.
"""

import json
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import seaborn as sns
from typing import Dict, List, Any, Tuple
import argparse
import os
from pathlib import Path
from datetime import datetime

# Set up plotting style
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")

class BenchmarkVisualizer:
    """Generate comprehensive visualizations of benchmark results"""
    
    def __init__(self, results_file: str):
        """Initialize with benchmark results"""
        self.results_file = results_file
        self.results_data = self._load_results()
        self.output_dir = "benchmark_visualizations"
        os.makedirs(self.output_dir, exist_ok=True)
        
    def _load_results(self) -> Dict[str, Any]:
        """Load benchmark results from JSON file"""
        with open(self.results_file, 'r') as f:
            return json.load(f)
    
    def generate_all_visualizations(self):
        """Generate complete set of visualizations"""
        print("🎨 Generating benchmark visualizations...")
        
        # Performance comparison charts
        self._plot_throughput_comparison()
        self._plot_energy_efficiency_comparison()
        self._plot_performance_vs_energy()
        
        # Scalability analysis
        self._plot_scalability_analysis()
        self._plot_frequency_scaling()
        
        # Workload analysis
        self._plot_workload_breakdown()
        self._plot_neural_performance()
        
        # Memory system analysis
        self._plot_memory_bandwidth()
        self._plot_cache_performance()
        
        # Comparative analysis
        self._plot_ternary_vs_binary_summary()
        self._plot_energy_efficiency_radar()
        
        # System overview
        self._plot_system_overview()
        
        print(f"✅ All visualizations saved to: {self.output_dir}/")
    
    def _plot_throughput_comparison(self):
        """Plot throughput comparison between ternary and binary operations"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
        
        # Extract throughput data
        ternary_results = [r for r in self.results_data["results"] if "ternary" in r["test_name"]]
        binary_results = [r for r in self.results_data["results"] if "binary" in r["test_name"]]
        
        # Arithmetic operations throughput
        arithmetic_ternary = [r for r in ternary_results if any(op in r["test_name"] for op in ["add", "mul", "matrix"])]
        arithmetic_binary = [r for r in binary_results if any(op in r["test_name"] for op in ["add", "mul", "matrix"])]
        
        if arithmetic_ternary and arithmetic_binary:
            operations = []
            ternary_throughput = []
            binary_throughput = []
            
            for t_result in arithmetic_ternary:
                operation = t_result["test_name"].split("_")[1]
                operations.append(operation)
                ternary_throughput.append(t_result["throughput_ops_per_sec"] / 1e6)  # Mops/sec
                
                # Find matching binary result
                matching_binary = next((b for b in arithmetic_binary if operation in b["test_name"]), None)
                if matching_binary:
                    binary_throughput.append(matching_binary["throughput_ops_per_sec"] / 1e6)
                else:
                    binary_throughput.append(0)
            
            x = np.arange(len(operations))
            width = 0.35
            
            bars1 = ax1.bar(x - width/2, ternary_throughput, width, label='Ternary', color='#2E8B57')
            bars2 = ax1.bar(x + width/2, binary_throughput, width, label='Binary', color='#DC143C')
            
            ax1.set_xlabel('Operation Type')
            ax1.set_ylabel('Throughput (Mops/sec)')
            ax1.set_title('Arithmetic Operations Throughput Comparison')
            ax1.set_xticks(x)
            ax1.set_xticklabels(operations, rotation=45)
            ax1.legend()
            ax1.grid(True, alpha=0.3)
            
            # Add value labels on bars
            for bar in bars1:
                height = bar.get_height()
                ax1.annotate(f'{height:.1f}',
                           xy=(bar.get_x() + bar.get_width() / 2, height),
                           xytext=(0, 3),
                           textcoords="offset points",
                           ha='center', va='bottom', fontsize=8)
            
            for bar in bars2:
                height = bar.get_height()
                if height > 0:
                    ax1.annotate(f'{height:.1f}',
                               xy=(bar.get_x() + bar.get_width() / 2, height),
                               xytext=(0, 3),
                               textcoords="offset points",
                               ha='center', va='bottom', fontsize=8)
        
        # Neural operations throughput
        neural_ternary = [r for r in ternary_results if "neural" in r["test_name"]]
        neural_binary = [r for r in binary_results if "neural" in r["test_name"]]
        
        if neural_ternary and neural_binary:
            neural_t_throughput = [r["throughput_ops_per_sec"] / 1e6 for r in neural_ternary]
            neural_b_throughput = [r["throughput_ops_per_sec"] / 1e6 for r in neural_binary]
            
            categories = ['Neural Inference']
            x = np.arange(len(categories))
            
            bars1 = ax2.bar(x - width/2, [np.mean(neural_t_throughput)], width, 
                           label='Ternary', color='#2E8B57')
            bars2 = ax2.bar(x + width/2, [np.mean(neural_b_throughput)], width, 
                           label='Binary', color='#DC143C')
            
            ax2.set_xlabel('Operation Type')
            ax2.set_ylabel('Throughput (Mops/sec)')
            ax2.set_title('Neural Processing Throughput Comparison')
            ax2.set_xticks(x)
            ax2.set_xticklabels(categories)
            ax2.legend()
            ax2.grid(True, alpha=0.3)
            
            # Add improvement annotation
            improvement = np.mean(neural_t_throughput) / np.mean(neural_b_throughput)
            ax2.annotate(f'{improvement:.1f}x faster',
                        xy=(x[0], max(np.mean(neural_t_throughput), np.mean(neural_b_throughput))),
                        xytext=(10, 10),
                        textcoords="offset points",
                        ha='left', va='bottom',
                        bbox=dict(boxstyle="round,pad=0.3", facecolor="yellow", alpha=0.7),
                        fontsize=10, weight='bold')
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/throughput_comparison.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_energy_efficiency_comparison(self):
        """Plot energy efficiency comparison"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
        
        # Extract energy efficiency data
        ternary_results = [r for r in self.results_data["results"] if "ternary" in r["test_name"]]
        binary_results = [r for r in self.results_data["results"] if "binary" in r["test_name"]]
        
        # Filter results with valid efficiency data
        ternary_eff = [r for r in ternary_results if r["efficiency_ops_per_uj"] > 0]
        binary_eff = [r for r in binary_results if r["efficiency_ops_per_uj"] > 0]
        
        if ternary_eff and binary_eff:
            # Group by operation type
            operation_types = set()
            for r in ternary_eff:
                op_type = r["test_name"].split("_")[1] if "_" in r["test_name"] else "unknown"
                operation_types.add(op_type)
            
            operation_types = sorted(list(operation_types))
            
            ternary_efficiencies = []
            binary_efficiencies = []
            
            for op_type in operation_types:
                t_ops = [r["efficiency_ops_per_uj"] for r in ternary_eff if op_type in r["test_name"]]
                b_ops = [r["efficiency_ops_per_uj"] for r in binary_eff if op_type in r["test_name"]]
                
                ternary_efficiencies.append(np.mean(t_ops) if t_ops else 0)
                binary_efficiencies.append(np.mean(b_ops) if b_ops else 0)
            
            x = np.arange(len(operation_types))
            width = 0.35
            
            bars1 = ax1.bar(x - width/2, ternary_efficiencies, width, 
                           label='Ternary', color='#228B22')
            bars2 = ax1.bar(x + width/2, binary_efficiencies, width, 
                           label='Binary', color='#B22222')
            
            ax1.set_xlabel('Operation Type')
            ax1.set_ylabel('Energy Efficiency (ops/µJ)')
            ax1.set_title('Energy Efficiency by Operation Type')
            ax1.set_xticks(x)
            ax1.set_xticklabels(operation_types, rotation=45)
            ax1.legend()
            ax1.grid(True, alpha=0.3)
            
            # Calculate and display improvement factors
            for i, (t_eff, b_eff) in enumerate(zip(ternary_efficiencies, binary_efficiencies)):
                if b_eff > 0:
                    improvement = t_eff / b_eff
                    ax1.annotate(f'{improvement:.1f}x',
                               xy=(x[i], max(t_eff, b_eff)),
                               xytext=(0, 5),
                               textcoords="offset points",
                               ha='center', va='bottom',
                               fontsize=8, weight='bold')
        
        # Overall efficiency distribution
        all_ternary_eff = [r["efficiency_ops_per_uj"] for r in ternary_eff]
        all_binary_eff = [r["efficiency_ops_per_uj"] for r in binary_eff]
        
        if all_ternary_eff and all_binary_eff:
            ax2.hist(all_ternary_eff, bins=20, alpha=0.7, label='Ternary', color='#228B22', density=True)
            ax2.hist(all_binary_eff, bins=20, alpha=0.7, label='Binary', color='#B22222', density=True)
            
            ax2.axvline(np.mean(all_ternary_eff), color='#228B22', linestyle='--', 
                       label=f'Ternary Mean: {np.mean(all_ternary_eff):.2f}')
            ax2.axvline(np.mean(all_binary_eff), color='#B22222', linestyle='--', 
                       label=f'Binary Mean: {np.mean(all_binary_eff):.2f}')
            
            ax2.set_xlabel('Energy Efficiency (ops/µJ)')
            ax2.set_ylabel('Density')
            ax2.set_title('Energy Efficiency Distribution')
            ax2.legend()
            ax2.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/energy_efficiency_comparison.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_performance_vs_energy(self):
        """Plot performance vs energy consumption scatter plot"""
        fig, ax = plt.subplots(1, 1, figsize=(12, 8))
        
        ternary_results = [r for r in self.results_data["results"] if "ternary" in r["test_name"]]
        binary_results = [r for r in self.results_data["results"] if "binary" in r["test_name"]]
        
        # Extract data for scatter plot
        ternary_performance = [r["throughput_ops_per_sec"] / 1e6 for r in ternary_results]
        ternary_energy = [r["energy_consumption_uj"] for r in ternary_results]
        
        binary_performance = [r["throughput_ops_per_sec"] / 1e6 for r in binary_results]
        binary_energy = [r["energy_consumption_uj"] for r in binary_results]
        
        # Create scatter plot
        scatter1 = ax.scatter(ternary_energy, ternary_performance, 
                             s=100, alpha=0.7, c='#2E8B57', label='Ternary', marker='o')
        scatter2 = ax.scatter(binary_energy, binary_performance, 
                             s=100, alpha=0.7, c='#DC143C', label='Binary', marker='s')
        
        # Add efficiency iso-lines (constant ops/µJ)
        energy_range = np.linspace(0, max(max(ternary_energy), max(binary_energy)), 100)
        for efficiency in [0.5, 1.0, 2.0, 5.0, 10.0]:
            performance_line = efficiency * energy_range
            ax.plot(energy_range, performance_line, '--', alpha=0.3, color='gray')
            ax.text(energy_range[-1], performance_line[-1], f'{efficiency} ops/µJ', 
                   rotation=45, alpha=0.7, fontsize=8)
        
        ax.set_xlabel('Energy Consumption (µJ)')
        ax.set_ylabel('Performance (Mops/sec)')
        ax.set_title('Performance vs Energy Consumption\\n(Higher and Left is Better)')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # Add annotations for best points
        if ternary_results:
            best_ternary_idx = np.argmax([r["efficiency_ops_per_uj"] for r in ternary_results])
            best_ternary = ternary_results[best_ternary_idx]
            ax.annotate(f'Best Ternary\\n{best_ternary["test_name"]}',
                       xy=(ternary_energy[best_ternary_idx], ternary_performance[best_ternary_idx]),
                       xytext=(10, 10), textcoords="offset points",
                       bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgreen", alpha=0.7),
                       fontsize=8)
        
        if binary_results:
            best_binary_idx = np.argmax([r["efficiency_ops_per_uj"] for r in binary_results])
            best_binary = binary_results[best_binary_idx]
            ax.annotate(f'Best Binary\\n{best_binary["test_name"]}',
                       xy=(binary_energy[best_binary_idx], binary_performance[best_binary_idx]),
                       xytext=(-10, 10), textcoords="offset points",
                       bbox=dict(boxstyle="round,pad=0.3", facecolor="lightcoral", alpha=0.7),
                       fontsize=8)
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/performance_vs_energy.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_scalability_analysis(self):
        """Plot performance scalability analysis"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
        
        # Data size scalability
        vector_results = [r for r in self.results_data["results"] if "vector" in r["test_name"]]
        matrix_results = [r for r in self.results_data["results"] if "matrix" in r["test_name"]]
        
        if vector_results:
            # Group by ternary/binary and extract sizes
            ternary_vector = [r for r in vector_results if "ternary" in r["test_name"]]
            binary_vector = [r for r in vector_results if "binary" in r["test_name"]]
            
            if ternary_vector and binary_vector:
                # Extract sizes and throughputs
                ternary_sizes = []
                ternary_throughputs = []
                binary_sizes = []
                binary_throughputs = []
                
                for result in ternary_vector:
                    if "additional_metrics" in result and "vector_size" in result["additional_metrics"]:
                        ternary_sizes.append(result["additional_metrics"]["vector_size"])
                        ternary_throughputs.append(result["throughput_ops_per_sec"] / 1e6)
                
                for result in binary_vector:
                    if "additional_metrics" in result and "vector_size" in result["additional_metrics"]:
                        binary_sizes.append(result["additional_metrics"]["vector_size"])
                        binary_throughputs.append(result["throughput_ops_per_sec"] / 1e6)
                
                if ternary_sizes and binary_sizes:
                    # Sort by size
                    ternary_data = sorted(zip(ternary_sizes, ternary_throughputs))
                    binary_data = sorted(zip(binary_sizes, binary_throughputs))
                    
                    ternary_sizes, ternary_throughputs = zip(*ternary_data)
                    binary_sizes, binary_throughputs = zip(*binary_data)
                    
                    ax1.plot(ternary_sizes, ternary_throughputs, 'o-', 
                            label='Ternary', color='#2E8B57', linewidth=2, markersize=6)
                    ax1.plot(binary_sizes, binary_throughputs, 's-', 
                            label='Binary', color='#DC143C', linewidth=2, markersize=6)
                    
                    ax1.set_xscale('log')
                    ax1.set_xlabel('Vector Size')
                    ax1.set_ylabel('Throughput (Mops/sec)')
                    ax1.set_title('Vector Operation Scalability')
                    ax1.legend()
                    ax1.grid(True, alpha=0.3)
        
        # Frequency scaling (if available)
        freq_results = [r for r in self.results_data["results"] if "frequency" in r["test_name"]]
        if freq_results and freq_results[0].get("additional_metrics", {}).get("frequencies_mhz"):
            freq_data = freq_results[0]["additional_metrics"]
            frequencies = freq_data["frequencies_mhz"]
            performance_points = freq_data["performance_points"]
            
            # Normalize to show scaling efficiency
            normalized_perf = [p / performance_points[4] for p in performance_points]  # Normalize to 761 MHz
            normalized_freq = [f / 761 for f in frequencies]
            
            ax2.plot(normalized_freq, normalized_perf, 'o-', 
                    label='Actual Scaling', color='#2E8B57', linewidth=2, markersize=6)
            ax2.plot([0, max(normalized_freq)], [0, max(normalized_freq)], '--', 
                    label='Linear Scaling', color='gray', alpha=0.7)
            
            ax2.set_xlabel('Normalized Frequency')
            ax2.set_ylabel('Normalized Performance')
            ax2.set_title('Frequency Scaling Efficiency')
            ax2.legend()
            ax2.grid(True, alpha=0.3)
            
            # Calculate scaling efficiency
            scaling_eff = freq_data.get("scaling_efficiency", 0)
            ax2.text(0.1, 0.9, f'Scaling Efficiency: {scaling_eff:.3f}', 
                    transform=ax2.transAxes,
                    bbox=dict(boxstyle="round,pad=0.3", facecolor="lightyellow", alpha=0.7))
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/scalability_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_workload_breakdown(self):
        """Plot performance breakdown by workload type"""
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # Group results by workload type
        workload_types = {
            'arithmetic': ['vector', 'matrix', 'add', 'mul'],
            'neural': ['neural'],
            'memory': ['memory', 'cache', 'sequential', 'random'],
            'mixed': ['image', 'signal', 'ml']
        }
        
        workload_performance = {}
        workload_energy = {}
        
        for workload, keywords in workload_types.items():
            perf_ternary = []
            perf_binary = []
            energy_ternary = []
            energy_binary = []
            
            for result in self.results_data["results"]:
                if any(keyword in result["test_name"] for keyword in keywords):
                    if "ternary" in result["test_name"]:
                        perf_ternary.append(result["throughput_ops_per_sec"] / 1e6)
                        energy_ternary.append(result["efficiency_ops_per_uj"])
                    elif "binary" in result["test_name"]:
                        perf_binary.append(result["throughput_ops_per_sec"] / 1e6)
                        energy_binary.append(result["efficiency_ops_per_uj"])
            
            workload_performance[workload] = {
                'ternary': np.mean(perf_ternary) if perf_ternary else 0,
                'binary': np.mean(perf_binary) if perf_binary else 0
            }
            workload_energy[workload] = {
                'ternary': np.mean(energy_ternary) if energy_ternary else 0,
                'binary': np.mean(energy_binary) if energy_binary else 0
            }
        
        # Performance comparison by workload
        workloads = list(workload_performance.keys())
        ternary_perf = [workload_performance[w]['ternary'] for w in workloads]
        binary_perf = [workload_performance[w]['binary'] for w in workloads]
        
        x = np.arange(len(workloads))
        width = 0.35
        
        bars1 = ax1.bar(x - width/2, ternary_perf, width, label='Ternary', color='#2E8B57')
        bars2 = ax1.bar(x + width/2, binary_perf, width, label='Binary', color='#DC143C')
        
        ax1.set_xlabel('Workload Type')
        ax1.set_ylabel('Throughput (Mops/sec)')
        ax1.set_title('Performance by Workload Type')
        ax1.set_xticks(x)
        ax1.set_xticklabels(workloads)
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Energy efficiency by workload
        ternary_energy = [workload_energy[w]['ternary'] for w in workloads]
        binary_energy = [workload_energy[w]['binary'] for w in workloads]
        
        bars3 = ax2.bar(x - width/2, ternary_energy, width, label='Ternary', color='#228B22')
        bars4 = ax2.bar(x + width/2, binary_energy, width, label='Binary', color='#B22222')
        
        ax2.set_xlabel('Workload Type')
        ax2.set_ylabel('Energy Efficiency (ops/µJ)')
        ax2.set_title('Energy Efficiency by Workload Type')
        ax2.set_xticks(x)
        ax2.set_xticklabels(workloads)
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        # Speedup factors
        speedup_factors = []
        efficiency_factors = []
        
        for workload in workloads:
            if workload_performance[workload]['binary'] > 0:
                speedup = workload_performance[workload]['ternary'] / workload_performance[workload]['binary']
                speedup_factors.append(speedup)
            else:
                speedup_factors.append(0)
                
            if workload_energy[workload]['binary'] > 0:
                eff_factor = workload_energy[workload]['ternary'] / workload_energy[workload]['binary']
                efficiency_factors.append(eff_factor)
            else:
                efficiency_factors.append(0)
        
        bars5 = ax3.bar(workloads, speedup_factors, color='#4169E1')
        ax3.axhline(y=1, color='gray', linestyle='--', alpha=0.7)
        ax3.set_xlabel('Workload Type')
        ax3.set_ylabel('Speedup Factor (Ternary/Binary)')
        ax3.set_title('Ternary Speedup by Workload')
        ax3.grid(True, alpha=0.3)
        
        # Add value labels
        for bar, value in zip(bars5, speedup_factors):
            if value > 0:
                ax3.annotate(f'{value:.2f}x',
                           xy=(bar.get_x() + bar.get_width() / 2, value),
                           xytext=(0, 3),
                           textcoords="offset points",
                           ha='center', va='bottom')
        
        bars6 = ax4.bar(workloads, efficiency_factors, color='#32CD32')
        ax4.axhline(y=1, color='gray', linestyle='--', alpha=0.7)
        ax4.set_xlabel('Workload Type')
        ax4.set_ylabel('Efficiency Factor (Ternary/Binary)')
        ax4.set_title('Ternary Energy Efficiency Improvement')
        ax4.grid(True, alpha=0.3)
        
        # Add value labels
        for bar, value in zip(bars6, efficiency_factors):
            if value > 0:
                ax4.annotate(f'{value:.2f}x',
                           xy=(bar.get_x() + bar.get_width() / 2, value),
                           xytext=(0, 3),
                           textcoords="offset points",
                           ha='center', va='bottom')
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/workload_breakdown.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_neural_performance(self):
        """Plot detailed neural processing performance"""
        fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(18, 6))
        
        neural_results = [r for r in self.results_data["results"] if "neural" in r["test_name"]]
        
        if neural_results:
            # Neural throughput comparison
            ternary_neural = [r for r in neural_results if "ternary" in r["test_name"]]
            binary_neural = [r for r in neural_results if "binary" in r["test_name"]]
            
            if ternary_neural and binary_neural:
                throughput_t = [r["throughput_ops_per_sec"] / 1e6 for r in ternary_neural]
                throughput_b = [r["throughput_ops_per_sec"] / 1e6 for r in binary_neural]
                
                ax1.bar(['Ternary', 'Binary'], [np.mean(throughput_t), np.mean(throughput_b)], 
                       color=['#2E8B57', '#DC143C'])
                ax1.set_ylabel('Throughput (Mops/sec)')
                ax1.set_title('Neural Processing Throughput')
                ax1.grid(True, alpha=0.3)
                
                # Add improvement annotation
                improvement = np.mean(throughput_t) / np.mean(throughput_b)
                ax1.text(0.5, max(np.mean(throughput_t), np.mean(throughput_b)) * 0.8,
                        f'{improvement:.1f}x faster',
                        ha='center', va='center',
                        bbox=dict(boxstyle="round,pad=0.3", facecolor="yellow", alpha=0.7),
                        fontsize=12, weight='bold')
            
            # Energy per inference
            if ternary_neural and binary_neural:
                energy_per_inf_t = []
                energy_per_inf_b = []
                
                for result in ternary_neural:
                    if result["operation_count"] > 0:
                        energy_per_inf_t.append(result["energy_consumption_uj"] / 
                                              (result["operation_count"] / 1000))  # Energy per 1k ops
                
                for result in binary_neural:
                    if result["operation_count"] > 0:
                        energy_per_inf_b.append(result["energy_consumption_uj"] / 
                                              (result["operation_count"] / 1000))
                
                if energy_per_inf_t and energy_per_inf_b:
                    ax2.bar(['Ternary', 'Binary'], 
                           [np.mean(energy_per_inf_t), np.mean(energy_per_inf_b)], 
                           color=['#228B22', '#B22222'])
                    ax2.set_ylabel('Energy per 1K Operations (µJ)')
                    ax2.set_title('Neural Processing Energy Efficiency')
                    ax2.grid(True, alpha=0.3)
                    
                    # Add efficiency improvement
                    efficiency_imp = np.mean(energy_per_inf_b) / np.mean(energy_per_inf_t)
                    ax2.text(0.5, max(np.mean(energy_per_inf_t), np.mean(energy_per_inf_b)) * 0.8,
                            f'{efficiency_imp:.1f}x more efficient',
                            ha='center', va='center',
                            bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgreen", alpha=0.7),
                            fontsize=12, weight='bold')
            
            # Neural architecture comparison (if available)
            network_architectures = set()
            for result in neural_results:
                if "additional_metrics" in result and "network_architecture" in result["additional_metrics"]:
                    arch = result["additional_metrics"]["network_architecture"]
                    if isinstance(arch, list):
                        network_architectures.add(str(arch))
            
            if network_architectures:
                arch_performance = {}
                for arch in network_architectures:
                    arch_results = [r for r in neural_results 
                                  if r.get("additional_metrics", {}).get("network_architecture") and
                                     str(r["additional_metrics"]["network_architecture"]) == arch]
                    
                    if arch_results:
                        perf = np.mean([r["throughput_ops_per_sec"] / 1e6 for r in arch_results])
                        arch_performance[arch] = perf
                
                if arch_performance:
                    architectures = list(arch_performance.keys())
                    performances = list(arch_performance.values())
                    
                    bars = ax3.bar(range(len(architectures)), performances, color='#4169E1')
                    ax3.set_xlabel('Network Architecture')
                    ax3.set_ylabel('Throughput (Mops/sec)')
                    ax3.set_title('Performance by Network Architecture')
                    ax3.set_xticks(range(len(architectures)))
                    ax3.set_xticklabels([arch[:10] + '...' if len(arch) > 10 else arch 
                                       for arch in architectures], rotation=45)
                    ax3.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/neural_performance.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_memory_bandwidth(self):
        """Plot memory system performance"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
        
        memory_results = [r for r in self.results_data["results"] if "memory" in r["test_name"] or "cache" in r["test_name"]]
        
        if memory_results:
            # Memory bandwidth by access pattern
            access_patterns = {}
            for result in memory_results:
                if "additional_metrics" in result and "access_pattern" in result["additional_metrics"]:
                    pattern = result["additional_metrics"]["access_pattern"]
                    if pattern not in access_patterns:
                        access_patterns[pattern] = []
                    access_patterns[pattern].append(result["memory_bandwidth_gbps"])
            
            if access_patterns:
                patterns = list(access_patterns.keys())
                bandwidths = [np.mean(access_patterns[p]) for p in patterns]
                
                bars = ax1.bar(patterns, bandwidths, color=['#FF6347', '#4169E1', '#32CD32'])
                ax1.set_xlabel('Access Pattern')
                ax1.set_ylabel('Bandwidth (GB/s)')
                ax1.set_title('Memory Bandwidth by Access Pattern')
                ax1.grid(True, alpha=0.3)
                
                # Add value labels
                for bar, value in zip(bars, bandwidths):
                    ax1.annotate(f'{value:.2f}',
                               xy=(bar.get_x() + bar.get_width() / 2, value),
                               xytext=(0, 3),
                               textcoords="offset points",
                               ha='center', va='bottom')
            
            # Cache hit rates
            cache_results = [r for r in memory_results if "cache" in r["test_name"]]
            if cache_results:
                hit_rates = [r["cache_hit_rate"] for r in cache_results]
                test_names = [r["test_name"].replace("_", " ").title() for r in cache_results]
                
                bars = ax2.bar(range(len(test_names)), hit_rates, color='#FF8C00')
                ax2.set_xlabel('Test Type')
                ax2.set_ylabel('Cache Hit Rate (%)')
                ax2.set_title('Cache Performance')
                ax2.set_xticks(range(len(test_names)))
                ax2.set_xticklabels(test_names, rotation=45)
                ax2.set_ylim(0, 100)
                ax2.grid(True, alpha=0.3)
                
                # Add target line
                ax2.axhline(y=90, color='red', linestyle='--', alpha=0.7, label='Target: 90%')
                ax2.legend()
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/memory_bandwidth.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_ternary_vs_binary_summary(self):
        """Plot comprehensive ternary vs binary summary"""
        fig, ax = plt.subplots(1, 1, figsize=(12, 8))
        
        # Calculate overall metrics
        ternary_results = [r for r in self.results_data["results"] if "ternary" in r["test_name"]]
        binary_results = [r for r in self.results_data["results"] if "binary" in r["test_name"]]
        
        metrics = {
            'Throughput\\n(Mops/sec)': {
                'ternary': np.mean([r["throughput_ops_per_sec"] / 1e6 for r in ternary_results]),
                'binary': np.mean([r["throughput_ops_per_sec"] / 1e6 for r in binary_results])
            },
            'Energy Efficiency\\n(ops/µJ)': {
                'ternary': np.mean([r["efficiency_ops_per_uj"] for r in ternary_results if r["efficiency_ops_per_uj"] > 0]),
                'binary': np.mean([r["efficiency_ops_per_uj"] for r in binary_results if r["efficiency_ops_per_uj"] > 0])
            },
            'Memory Bandwidth\\n(GB/s)': {
                'ternary': np.mean([r["memory_bandwidth_gbps"] for r in ternary_results if r["memory_bandwidth_gbps"] > 0]),
                'binary': np.mean([r["memory_bandwidth_gbps"] for r in binary_results if r["memory_bandwidth_gbps"] > 0])
            }
        }
        
        # Normalize metrics for comparison (binary = 1.0)
        normalized_metrics = {}
        for metric, values in metrics.items():
            if values['binary'] > 0:
                normalized_metrics[metric] = {
                    'ternary': values['ternary'] / values['binary'],
                    'binary': 1.0
                }
        
        if normalized_metrics:
            metric_names = list(normalized_metrics.keys())
            ternary_normalized = [normalized_metrics[m]['ternary'] for m in metric_names]
            
            x = np.arange(len(metric_names))
            width = 0.35
            
            bars1 = ax.bar(x - width/2, ternary_normalized, width, 
                          label='Ternary (normalized)', color='#2E8B57')
            bars2 = ax.bar(x + width/2, [1.0] * len(metric_names), width, 
                          label='Binary (baseline)', color='#DC143C')
            
            ax.axhline(y=1, color='gray', linestyle='--', alpha=0.7, label='Baseline (1.0x)')
            
            ax.set_xlabel('Performance Metrics')
            ax.set_ylabel('Relative Performance (Binary = 1.0x)')
            ax.set_title('Ternary vs Binary Overall Performance Comparison')
            ax.set_xticks(x)
            ax.set_xticklabels(metric_names)
            ax.legend()
            ax.grid(True, alpha=0.3)
            
            # Add improvement factors as text
            for i, (bar, value) in enumerate(zip(bars1, ternary_normalized)):
                ax.annotate(f'{value:.2f}x',
                           xy=(bar.get_x() + bar.get_width() / 2, value),
                           xytext=(0, 5),
                           textcoords="offset points",
                           ha='center', va='bottom',
                           fontsize=12, weight='bold')
            
            # Add summary text box
            avg_improvement = np.mean(ternary_normalized)
            summary_text = f'Average Improvement: {avg_improvement:.2f}x\\n'
            summary_text += f'Best Metric: {metric_names[np.argmax(ternary_normalized)]}\\n'
            summary_text += f'Max Improvement: {max(ternary_normalized):.2f}x'
            
            ax.text(0.02, 0.98, summary_text,
                   transform=ax.transAxes,
                   verticalalignment='top',
                   bbox=dict(boxstyle="round,pad=0.5", facecolor="lightyellow", alpha=0.8),
                   fontsize=10)
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/ternary_vs_binary_summary.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_energy_efficiency_radar(self):
        """Plot radar chart of energy efficiency across different operations"""
        fig, ax = plt.subplots(1, 1, figsize=(10, 10), subplot_kw=dict(projection='polar'))
        
        # Define operation categories
        operation_categories = {
            'Vector Add': 'vector_add',
            'Matrix Mul': 'matrix_mul', 
            'Neural Inf': 'neural_inference',
            'Memory Seq': 'sequential_memory',
            'Memory Rand': 'random_memory',
            'Image Proc': 'image_processing',
            'Signal Proc': 'signal_processing'
        }
        
        ternary_efficiencies = []
        binary_efficiencies = []
        
        for category, keyword in operation_categories.items():
            # Find matching results
            ternary_matches = [r for r in self.results_data["results"] 
                             if "ternary" in r["test_name"] and keyword in r["test_name"]]
            binary_matches = [r for r in self.results_data["results"] 
                            if "binary" in r["test_name"] and keyword in r["test_name"]]
            
            ternary_eff = np.mean([r["efficiency_ops_per_uj"] for r in ternary_matches 
                                 if r["efficiency_ops_per_uj"] > 0]) if ternary_matches else 0
            binary_eff = np.mean([r["efficiency_ops_per_uj"] for r in binary_matches 
                                if r["efficiency_ops_per_uj"] > 0]) if binary_matches else 0
            
            ternary_efficiencies.append(ternary_eff)
            binary_efficiencies.append(binary_eff)
        
        # Normalize to maximum for radar chart
        max_efficiency = max(max(ternary_efficiencies), max(binary_efficiencies))
        if max_efficiency > 0:
            ternary_normalized = [e / max_efficiency for e in ternary_efficiencies]
            binary_normalized = [e / max_efficiency for e in binary_efficiencies]
            
            # Create angles for radar chart
            angles = np.linspace(0, 2 * np.pi, len(operation_categories), endpoint=False)
            angles = np.concatenate((angles, [angles[0]]))  # Complete the circle
            
            ternary_normalized = ternary_normalized + [ternary_normalized[0]]
            binary_normalized = binary_normalized + [binary_normalized[0]]
            
            # Plot radar chart
            ax.plot(angles, ternary_normalized, 'o-', linewidth=2, 
                   label='Ternary', color='#2E8B57', markersize=6)
            ax.fill(angles, ternary_normalized, alpha=0.25, color='#2E8B57')
            
            ax.plot(angles, binary_normalized, 's-', linewidth=2, 
                   label='Binary', color='#DC143C', markersize=6)
            ax.fill(angles, binary_normalized, alpha=0.25, color='#DC143C')
            
            # Add labels
            ax.set_xticks(angles[:-1])
            ax.set_xticklabels(operation_categories.keys())
            ax.set_ylim(0, 1)
            ax.set_yticks([0.2, 0.4, 0.6, 0.8, 1.0])
            ax.set_yticklabels(['20%', '40%', '60%', '80%', '100%'])
            ax.grid(True)
            
            ax.set_title('Energy Efficiency Comparison\\n(Normalized to Maximum)', 
                        y=1.1, fontsize=14, weight='bold')
            ax.legend(loc='upper right', bbox_to_anchor=(1.3, 1.0))
        
        plt.tight_layout()
        plt.savefig(f"{self.output_dir}/energy_efficiency_radar.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _plot_system_overview(self):
        """Plot system overview with key specifications"""
        fig = plt.figure(figsize=(16, 10))
        
        # Create a grid layout
        gs = fig.add_gridspec(3, 4, hspace=0.3, wspace=0.3)
        
        # System specifications
        ax_specs = fig.add_subplot(gs[0, :2])
        ax_specs.axis('off')
        
        system_info = self.results_data.get("system_info", {})
        
        specs_text = f"""MHX Ternary RISC-V Processor Specifications
        
• Processor: {system_info.get('processor', 'MHX Ternary RISC-V v1.0')}
• Frequency: {system_info.get('frequency_mhz', 761)} MHz
• Process Node: {system_info.get('process_node', 'SkyWater 130nm')}
• Die Area: {system_info.get('die_area_um2', 4225)} µm²
• Gate Count: {system_info.get('gate_count', 1184)} gates
• Memory: {system_info.get('memory_size_kb', 32)} KB
• Ternary Unit: {'✓' if system_info.get('ternary_unit_present', True) else '✗'}
• Neural Unit: {'✓' if system_info.get('neural_unit_present', True) else '✗'}"""
        
        ax_specs.text(0.05, 0.95, specs_text, transform=ax_specs.transAxes,
                     fontsize=12, verticalalignment='top',
                     bbox=dict(boxstyle="round,pad=0.5", facecolor="lightblue", alpha=0.8))
        
        # Performance summary
        ax_perf = fig.add_subplot(gs[0, 2:])
        ax_perf.axis('off')
        
        # Calculate key performance metrics
        ternary_results = [r for r in self.results_data["results"] if "ternary" in r["test_name"]]
        
        if ternary_results:
            avg_throughput = np.mean([r["throughput_ops_per_sec"] for r in ternary_results]) / 1e6
            avg_efficiency = np.mean([r["efficiency_ops_per_uj"] for r in ternary_results if r["efficiency_ops_per_uj"] > 0])
            max_throughput = max([r["throughput_ops_per_sec"] for r in ternary_results]) / 1e6
            
            perf_text = f"""Performance Summary
            
• Average Throughput: {avg_throughput:.1f} Mops/sec
• Peak Throughput: {max_throughput:.1f} Mops/sec
• Average Efficiency: {avg_efficiency:.2f} ops/µJ
• Total Tests: {len(self.results_data['results'])}
• Test Date: {datetime.fromtimestamp(system_info.get('timestamp', 0)).strftime('%Y-%m-%d')}"""
            
            ax_perf.text(0.05, 0.95, perf_text, transform=ax_perf.transAxes,
                        fontsize=12, verticalalignment='top',
                        bbox=dict(boxstyle="round,pad=0.5", facecolor="lightgreen", alpha=0.8))
        
        # Mini throughput chart
        ax_mini_throughput = fig.add_subplot(gs[1, :2])
        
        operation_types = ['Vector Add', 'Matrix Mul', 'Neural Inf']
        throughputs = []
        
        for op_type in operation_types:
            matching_results = []
            if op_type == 'Vector Add':
                matching_results = [r for r in ternary_results if "vector_add" in r["test_name"]]
            elif op_type == 'Matrix Mul':
                matching_results = [r for r in ternary_results if "matrix_mul" in r["test_name"]]
            elif op_type == 'Neural Inf':
                matching_results = [r for r in ternary_results if "neural" in r["test_name"]]
            
            if matching_results:
                avg_throughput = np.mean([r["throughput_ops_per_sec"] / 1e6 for r in matching_results])
                throughputs.append(avg_throughput)
            else:
                throughputs.append(0)
        
        bars = ax_mini_throughput.bar(operation_types, throughputs, color=['#FF6347', '#4169E1', '#32CD32'])
        ax_mini_throughput.set_ylabel('Throughput (Mops/sec)')
        ax_mini_throughput.set_title('Key Operation Performance')
        ax_mini_throughput.grid(True, alpha=0.3)
        
        # Mini efficiency chart
        ax_mini_efficiency = fig.add_subplot(gs[1, 2:])
        
        efficiencies = []
        for op_type in operation_types:
            matching_results = []
            if op_type == 'Vector Add':
                matching_results = [r for r in ternary_results if "vector_add" in r["test_name"]]
            elif op_type == 'Matrix Mul':
                matching_results = [r for r in ternary_results if "matrix_mul" in r["test_name"]]
            elif op_type == 'Neural Inf':
                matching_results = [r for r in ternary_results if "neural" in r["test_name"]]
            
            if matching_results:
                avg_efficiency = np.mean([r["efficiency_ops_per_uj"] for r in matching_results if r["efficiency_ops_per_uj"] > 0])
                efficiencies.append(avg_efficiency)
            else:
                efficiencies.append(0)
        
        bars = ax_mini_efficiency.bar(operation_types, efficiencies, color=['#FF6347', '#4169E1', '#32CD32'])
        ax_mini_efficiency.set_ylabel('Efficiency (ops/µJ)')
        ax_mini_efficiency.set_title('Energy Efficiency')
        ax_mini_efficiency.grid(True, alpha=0.3)
        
        # Architecture diagram (simplified)
        ax_arch = fig.add_subplot(gs[2, :])
        ax_arch.set_xlim(0, 10)
        ax_arch.set_ylim(0, 3)
        ax_arch.axis('off')
        
        # Draw simplified processor architecture
        # CPU Core
        cpu_rect = patches.Rectangle((0.5, 1), 2, 1, linewidth=2, edgecolor='black', facecolor='lightblue')
        ax_arch.add_patch(cpu_rect)
        ax_arch.text(1.5, 1.5, 'RISC-V\\nCore', ha='center', va='center', fontweight='bold')
        
        # Ternary ALU
        ternary_rect = patches.Rectangle((3, 1.5), 1.5, 0.8, linewidth=2, edgecolor='green', facecolor='lightgreen')
        ax_arch.add_patch(ternary_rect)
        ax_arch.text(3.75, 1.9, 'Ternary\\nALU', ha='center', va='center', fontweight='bold', fontsize=9)
        
        # Neural Unit
        neural_rect = patches.Rectangle((3, 0.7), 1.5, 0.8, linewidth=2, edgecolor='purple', facecolor='plum')
        ax_arch.add_patch(neural_rect)
        ax_arch.text(3.75, 1.1, 'Neural\\nUnit', ha='center', va='center', fontweight='bold', fontsize=9)
        
        # Memory
        mem_rect = patches.Rectangle((5.5, 1), 1.5, 1, linewidth=2, edgecolor='orange', facecolor='peachpuff')
        ax_arch.add_patch(mem_rect)
        ax_arch.text(6.25, 1.5, 'Memory\\n32KB', ha='center', va='center', fontweight='bold', fontsize=9)
        
        # Cache
        cache_rect = patches.Rectangle((7.5, 1), 1.5, 1, linewidth=2, edgecolor='red', facecolor='mistyrose')
        ax_arch.add_patch(cache_rect)
        ax_arch.text(8.25, 1.5, 'L1 Cache\\n16KB', ha='center', va='center', fontweight='bold', fontsize=9)
        
        # Connections
        ax_arch.arrow(2.5, 1.5, 0.4, 0, head_width=0.1, head_length=0.1, fc='black', ec='black')
        ax_arch.arrow(4.5, 1.5, 0.9, 0, head_width=0.1, head_length=0.1, fc='black', ec='black')
        ax_arch.arrow(7, 1.5, 0.4, 0, head_width=0.1, head_length=0.1, fc='black', ec='black')
        
        ax_arch.set_title('MHX Ternary RISC-V Architecture Overview', fontsize=14, fontweight='bold', y=0.9)
        
        plt.suptitle('MHX Ternary RISC-V Benchmark Results Overview', fontsize=16, fontweight='bold')
        plt.savefig(f"{self.output_dir}/system_overview.png", dpi=300, bbox_inches='tight')
        plt.close()

def main():
    """Main entry point for visualization script"""
    parser = argparse.ArgumentParser(description="MHX Ternary RISC-V Benchmark Visualization")
    parser.add_argument("results_file", type=str, help="JSON results file from benchmark")
    parser.add_argument("--output-dir", "-o", type=str, default="benchmark_visualizations",
                       help="Output directory for visualizations")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.results_file):
        print(f"❌ Results file not found: {args.results_file}")
        return 1
    
    try:
        visualizer = BenchmarkVisualizer(args.results_file)
        visualizer.output_dir = args.output_dir
        visualizer.generate_all_visualizations()
        
        print(f"🎉 All visualizations generated successfully!")
        print(f"📂 Output directory: {args.output_dir}")
        
        return 0
        
    except Exception as e:
        print(f"❌ Visualization failed: {e}")
        return 1

if __name__ == "__main__":
    exit(main())