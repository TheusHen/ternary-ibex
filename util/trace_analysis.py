#!/usr/bin/env python3
# Copyright lowRISC contributors.
# Copyright 2025 MHX™ Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""
MHX™ Trace-Based Analysis Tool

This tool provides comprehensive trace analysis for MHX™ ternary operations,
including:
- Instruction trace parsing and visualization
- Performance hotspot detection
- Pipeline stall analysis
- Memory access pattern analysis
- Neural operation profiling

Usage:
    python3 trace_analysis.py [--input FILE] [--output DIR] [--json]
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime
from collections import defaultdict
import statistics


@dataclass
class TraceEntry:
    """Single trace entry."""
    cycle: int
    pc: int
    instruction: int
    trace_type: str  # 'binary', 'ternary', 'neural', 'memory', 'stall'
    latency: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "cycle": self.cycle,
            "pc": hex(self.pc),
            "instruction": hex(self.instruction),
            "type": self.trace_type,
            "latency": self.latency,
        }


@dataclass
class Hotspot:
    """Performance hotspot."""
    pc: int
    count: int
    total_cycles: int
    instruction_type: str

    @property
    def avg_latency(self) -> float:
        return self.total_cycles / self.count if self.count > 0 else 0.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "pc": hex(self.pc),
            "count": self.count,
            "total_cycles": self.total_cycles,
            "avg_latency": round(self.avg_latency, 2),
            "type": self.instruction_type,
        }


@dataclass
class PipelineAnalysis:
    """Pipeline stall analysis results."""
    total_stalls: int = 0
    data_hazard_stalls: int = 0
    control_hazard_stalls: int = 0
    memory_stalls: int = 0
    structural_stalls: int = 0

    @property
    def stall_breakdown(self) -> Dict[str, float]:
        total = self.total_stalls or 1
        return {
            "data_hazard": round(self.data_hazard_stalls / total * 100, 1),
            "control_hazard": round(self.control_hazard_stalls / total * 100, 1),
            "memory": round(self.memory_stalls / total * 100, 1),
            "structural": round(self.structural_stalls / total * 100, 1),
        }

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_stalls": self.total_stalls,
            "stall_breakdown": self.stall_breakdown,
        }


@dataclass
class MemoryAnalysis:
    """Memory access pattern analysis."""
    total_accesses: int = 0
    read_count: int = 0
    write_count: int = 0
    cache_hits: int = 0
    cache_misses: int = 0
    avg_access_latency: float = 0.0
    access_pattern: str = "unknown"  # 'sequential', 'strided', 'random'

    @property
    def cache_hit_rate(self) -> float:
        total = self.cache_hits + self.cache_misses
        return self.cache_hits / total * 100 if total > 0 else 0.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_accesses": self.total_accesses,
            "read_count": self.read_count,
            "write_count": self.write_count,
            "cache_hit_rate": round(self.cache_hit_rate, 1),
            "avg_access_latency": round(self.avg_access_latency, 2),
            "access_pattern": self.access_pattern,
        }


@dataclass
class NeuralAnalysis:
    """Neural operation profiling."""
    total_ops: int = 0
    neuron_ops: int = 0
    activation_ops: int = 0
    avg_neuron_latency: float = 0.0
    avg_activation_latency: float = 0.0
    throughput_ops_per_cycle: float = 0.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_ops": self.total_ops,
            "neuron_ops": self.neuron_ops,
            "activation_ops": self.activation_ops,
            "avg_neuron_latency": round(self.avg_neuron_latency, 2),
            "avg_activation_latency": round(self.avg_activation_latency, 2),
            "throughput_ops_per_cycle": round(self.throughput_ops_per_cycle, 4),
        }


@dataclass
class TraceAnalysisResults:
    """Complete trace analysis results."""
    trace_entries: List[TraceEntry] = field(default_factory=list)
    hotspots: List[Hotspot] = field(default_factory=list)
    pipeline_analysis: PipelineAnalysis = field(default_factory=PipelineAnalysis)
    memory_analysis: MemoryAnalysis = field(default_factory=MemoryAnalysis)
    neural_analysis: NeuralAnalysis = field(default_factory=NeuralAnalysis)
    total_cycles: int = 0
    total_instructions: int = 0
    ipc: float = 0.0
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())

    def to_dict(self) -> Dict[str, Any]:
        return {
            "timestamp": self.timestamp,
            "summary": {
                "total_cycles": self.total_cycles,
                "total_instructions": self.total_instructions,
                "ipc": round(self.ipc, 3),
            },
            "hotspots": [h.to_dict() for h in self.hotspots[:10]],
            "pipeline_analysis": self.pipeline_analysis.to_dict(),
            "memory_analysis": self.memory_analysis.to_dict(),
            "neural_analysis": self.neural_analysis.to_dict(),
            "instruction_mix": self._get_instruction_mix(),
        }

    def _get_instruction_mix(self) -> Dict[str, int]:
        mix: Dict[str, int] = defaultdict(int)
        for entry in self.trace_entries:
            mix[entry.trace_type] += 1
        return dict(mix)


class TraceAnalyzer:
    """Main trace analyzer class."""

    def __init__(self) -> None:
        self.entries: List[TraceEntry] = []
        self.pc_stats: Dict[int, Dict[str, Any]] = defaultdict(
            lambda: {"count": 0, "total_cycles": 0, "type": "unknown"}
        )

    def parse_trace_file(self, filepath: Path) -> None:
        """Parse trace file (VCD or JSON format)."""
        content = filepath.read_text()

        if filepath.suffix == ".json":
            self._parse_json_trace(content)
        elif filepath.suffix == ".vcd":
            self._parse_vcd_trace(content)
        else:
            # Try to parse as text log
            self._parse_text_trace(content)

    def _parse_json_trace(self, content: str) -> None:
        """Parse JSON trace format."""
        data = json.loads(content)

        for entry in data.get("trace", []):
            self.entries.append(TraceEntry(
                cycle=entry.get("cycle", 0),
                pc=int(entry.get("pc", "0"), 16) if isinstance(entry.get("pc"), str) else entry.get("pc", 0),
                instruction=int(entry.get("instruction", "0"), 16) if isinstance(entry.get("instruction"), str) else entry.get("instruction", 0),
                trace_type=entry.get("type", "binary"),
                latency=entry.get("latency", 0),
            ))

    def _parse_vcd_trace(self, content: str) -> None:
        """Parse VCD trace format (simplified)."""
        # This is a simplified VCD parser for demonstration
        import re

        cycle = 0
        for line in content.split("\n"):
            if line.startswith("#"):
                try:
                    cycle = int(line[1:])
                except ValueError:
                    pass
            elif "pc" in line.lower():
                match = re.search(r"b([01]+)", line)
                if match:
                    pc = int(match.group(1), 2)
                    self.entries.append(TraceEntry(
                        cycle=cycle,
                        pc=pc,
                        instruction=0,
                        trace_type="binary",
                    ))

    def _parse_text_trace(self, content: str) -> None:
        """Parse text log trace format."""
        import re

        # Pattern for trace entries like: [cycle] PC=0x... INSTR=0x... TYPE=...
        pattern = re.compile(
            r"\[(\d+)\]\s*PC=0x([0-9A-Fa-f]+)\s*INSTR=0x([0-9A-Fa-f]+)\s*TYPE=(\w+)"
        )

        for match in pattern.finditer(content):
            self.entries.append(TraceEntry(
                cycle=int(match.group(1)),
                pc=int(match.group(2), 16),
                instruction=int(match.group(3), 16),
                trace_type=match.group(4).lower(),
            ))

    def analyze(self) -> TraceAnalysisResults:
        """Perform complete trace analysis."""
        results = TraceAnalysisResults()
        results.trace_entries = self.entries
        results.total_instructions = len(self.entries)

        if not self.entries:
            return results

        # Calculate total cycles
        if self.entries:
            results.total_cycles = self.entries[-1].cycle - self.entries[0].cycle + 1
            results.ipc = results.total_instructions / results.total_cycles if results.total_cycles > 0 else 0

        # Analyze hotspots
        results.hotspots = self._analyze_hotspots()

        # Analyze pipeline
        results.pipeline_analysis = self._analyze_pipeline()

        # Analyze memory
        results.memory_analysis = self._analyze_memory()

        # Analyze neural operations
        results.neural_analysis = self._analyze_neural()

        return results

    def _analyze_hotspots(self) -> List[Hotspot]:
        """Identify performance hotspots."""
        pc_stats: Dict[int, Dict[str, Any]] = defaultdict(
            lambda: {"count": 0, "total_cycles": 0, "type": "unknown"}
        )

        prev_cycle = 0
        for entry in self.entries:
            latency = entry.cycle - prev_cycle if prev_cycle > 0 else 1
            pc_stats[entry.pc]["count"] += 1
            pc_stats[entry.pc]["total_cycles"] += latency
            pc_stats[entry.pc]["type"] = entry.trace_type
            prev_cycle = entry.cycle

        hotspots = [
            Hotspot(
                pc=pc,
                count=stats["count"],
                total_cycles=stats["total_cycles"],
                instruction_type=stats["type"],
            )
            for pc, stats in pc_stats.items()
        ]

        # Sort by total cycles descending
        hotspots.sort(key=lambda h: h.total_cycles, reverse=True)

        return hotspots

    def _analyze_pipeline(self) -> PipelineAnalysis:
        """Analyze pipeline stalls."""
        analysis = PipelineAnalysis()

        prev_cycle = 0
        for entry in self.entries:
            if prev_cycle > 0:
                gap = entry.cycle - prev_cycle
                if gap > 1:
                    analysis.total_stalls += gap - 1

                    # Classify stall type based on heuristics
                    if entry.trace_type == "memory":
                        analysis.memory_stalls += gap - 1
                    elif entry.trace_type == "stall":
                        analysis.structural_stalls += gap - 1
                    else:
                        # Assume data hazard for other cases
                        analysis.data_hazard_stalls += gap - 1

            prev_cycle = entry.cycle

        return analysis

    def _analyze_memory(self) -> MemoryAnalysis:
        """Analyze memory access patterns."""
        analysis = MemoryAnalysis()

        memory_entries = [e for e in self.entries if e.trace_type == "memory"]
        analysis.total_accesses = len(memory_entries)

        if not memory_entries:
            return analysis

        # Analyze access pattern
        addresses = [e.pc for e in memory_entries]
        if len(addresses) > 1:
            diffs = [addresses[i+1] - addresses[i] for i in range(len(addresses)-1)]
            if all(d == diffs[0] for d in diffs):
                analysis.access_pattern = "strided" if diffs[0] != 4 else "sequential"
            else:
                analysis.access_pattern = "random"

        # Estimate cache behavior (simplified model)
        unique_addresses = len(set(addr >> 6 for addr in addresses))  # 64-byte cache lines
        analysis.cache_hits = analysis.total_accesses - unique_addresses
        analysis.cache_misses = unique_addresses

        return analysis

    def _analyze_neural(self) -> NeuralAnalysis:
        """Analyze neural operations."""
        analysis = NeuralAnalysis()

        neural_entries = [e for e in self.entries if e.trace_type == "neural"]
        ternary_entries = [e for e in self.entries if e.trace_type == "ternary"]

        analysis.total_ops = len(neural_entries) + len(ternary_entries)
        analysis.neuron_ops = len(neural_entries)

        # Calculate latencies
        if neural_entries:
            latencies = []
            prev_cycle = neural_entries[0].cycle
            for entry in neural_entries[1:]:
                latencies.append(entry.cycle - prev_cycle)
                prev_cycle = entry.cycle
            if latencies:
                analysis.avg_neuron_latency = statistics.mean(latencies)

        # Calculate throughput
        if self.entries:
            total_cycles = self.entries[-1].cycle - self.entries[0].cycle + 1
            analysis.throughput_ops_per_cycle = analysis.total_ops / total_cycles if total_cycles > 0 else 0

        return analysis


def generate_synthetic_analysis() -> TraceAnalysisResults:
    """Generate synthetic analysis results for demonstration."""
    results = TraceAnalysisResults()

    # Generate synthetic trace data
    results.total_cycles = 50000
    results.total_instructions = 45000
    results.ipc = 0.9

    # Synthetic hotspots
    results.hotspots = [
        Hotspot(pc=0x1000, count=5000, total_cycles=5000, instruction_type="neural"),
        Hotspot(pc=0x1004, count=4500, total_cycles=4500, instruction_type="ternary"),
        Hotspot(pc=0x1008, count=3000, total_cycles=6000, instruction_type="memory"),
        Hotspot(pc=0x100C, count=2000, total_cycles=2000, instruction_type="binary"),
        Hotspot(pc=0x2000, count=1500, total_cycles=3000, instruction_type="neural"),
    ]

    # Synthetic pipeline analysis
    results.pipeline_analysis = PipelineAnalysis(
        total_stalls=5000,
        data_hazard_stalls=1500,
        control_hazard_stalls=500,
        memory_stalls=2500,
        structural_stalls=500,
    )

    # Synthetic memory analysis
    results.memory_analysis = MemoryAnalysis(
        total_accesses=8000,
        read_count=6000,
        write_count=2000,
        cache_hits=6800,
        cache_misses=1200,
        avg_access_latency=2.5,
        access_pattern="strided",
    )

    # Synthetic neural analysis
    results.neural_analysis = NeuralAnalysis(
        total_ops=15000,
        neuron_ops=12000,
        activation_ops=3000,
        avg_neuron_latency=1.2,
        avg_activation_latency=1.0,
        throughput_ops_per_cycle=0.3,
    )

    return results


def print_report(results: TraceAnalysisResults) -> None:
    """Print human-readable analysis report."""
    print()
    print("=" * 70)
    print("MHX™ Trace-Based Analysis Report")
    print("=" * 70)
    print()

    print("Summary:")
    print(f"  Total Cycles:       {results.total_cycles:,}")
    print(f"  Total Instructions: {results.total_instructions:,}")
    print(f"  IPC:                {results.ipc:.3f}")
    print()

    print("Top Hotspots:")
    for i, hotspot in enumerate(results.hotspots[:5], 1):
        print(f"  {i}. PC={hex(hotspot.pc):12s} Count={hotspot.count:6d} "
              f"Cycles={hotspot.total_cycles:8d} Type={hotspot.instruction_type}")
    print()

    print("Pipeline Analysis:")
    print(f"  Total Stalls: {results.pipeline_analysis.total_stalls:,}")
    breakdown = results.pipeline_analysis.stall_breakdown
    print(f"  Data Hazards:    {breakdown['data_hazard']:.1f}%")
    print(f"  Control Hazards: {breakdown['control_hazard']:.1f}%")
    print(f"  Memory Stalls:   {breakdown['memory']:.1f}%")
    print(f"  Structural:      {breakdown['structural']:.1f}%")
    print()

    print("Memory Analysis:")
    print(f"  Total Accesses:  {results.memory_analysis.total_accesses:,}")
    print(f"  Cache Hit Rate:  {results.memory_analysis.cache_hit_rate:.1f}%")
    print(f"  Access Pattern:  {results.memory_analysis.access_pattern}")
    print()

    print("Neural Operation Analysis:")
    print(f"  Total Neural Ops:    {results.neural_analysis.total_ops:,}")
    print(f"  Avg Neuron Latency:  {results.neural_analysis.avg_neuron_latency:.2f} cycles")
    print(f"  Throughput:          {results.neural_analysis.throughput_ops_per_cycle:.4f} ops/cycle")
    print("=" * 70)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="MHX™ Trace-Based Analysis Tool"
    )
    parser.add_argument(
        "--input", "-i",
        type=Path,
        default=None,
        help="Input trace file (JSON, VCD, or text)",
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=None,
        help="Output directory for results",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output JSON format only",
    )
    parser.add_argument(
        "--synthetic",
        action="store_true",
        help="Generate synthetic analysis (no input file)",
    )
    args = parser.parse_args()

    if args.synthetic or args.input is None:
        results = generate_synthetic_analysis()
    else:
        if not args.input.exists():
            print(f"Error: Input file not found: {args.input}", file=sys.stderr)
            return 1

        analyzer = TraceAnalyzer()
        analyzer.parse_trace_file(args.input)
        results = analyzer.analyze()

    if args.json:
        print(json.dumps(results.to_dict(), indent=2))
    else:
        print_report(results)

    if args.output:
        args.output.mkdir(parents=True, exist_ok=True)
        output_file = args.output / "trace_analysis_results.json"
        with open(output_file, "w") as f:
            json.dump(results.to_dict(), f, indent=2)
        print(f"\nResults saved to: {output_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
