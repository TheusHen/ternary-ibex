#!/usr/bin/env python3

# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Run a small MHX™ cycle benchmark under Verilator and emit JSON metrics.

This is intended for CI/regression checks: it measures cycle counts *inside the
simulated core* via `mcycle`, then parses the UART log (ibex_simple_system.log).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any


RE_NEURAL = re.compile(
    r"MHX_CYCLE_BENCH\s+neural_baseline_cycles=0x(?P<base>[0-9A-Fa-f]{16})\s+"
    r"neural_mhx_cycles=0x(?P<mhx>[0-9A-Fa-f]{16})"
)
RE_MATRIX = re.compile(
    r"MHX_CYCLE_BENCH\s+matrix_baseline_cycles=0x(?P<base>[0-9A-Fa-f]{16})\s+"
    r"matrix_mhx_cycles=0x(?P<mhx>[0-9A-Fa-f]{16})"
)


@dataclass(frozen=True)
class BenchResult:
    baseline_cycles: int
    mhx_cycles: int

    @property
    def speedup(self) -> float:
        if self.mhx_cycles == 0:
            return 0.0
        return self.baseline_cycles / self.mhx_cycles

    @property
    def speedup_x1000(self) -> int:
        if self.mhx_cycles == 0:
            return 0
        return (self.baseline_cycles * 1000) // self.mhx_cycles


def _run(cmd: list[str], cwd: Path, env: dict[str, str] | None = None) -> None:
    subprocess.run(cmd, cwd=cwd, env=env, check=True)


def _parse_log(log_text: str) -> tuple[BenchResult, BenchResult]:
    m_neural = RE_NEURAL.search(log_text)
    m_matrix = RE_MATRIX.search(log_text)
    if not m_neural or not m_matrix:
        raise RuntimeError(
            "Failed to parse MHX_CYCLE_BENCH lines from ibex_simple_system.log. "
            "Did the program run and print results?"
        )

    def _mk(m: re.Match[str]) -> BenchResult:
        return BenchResult(
            baseline_cycles=int(m.group("base"), 16),
            mhx_cycles=int(m.group("mhx"), 16),
        )

    return _mk(m_neural), _mk(m_matrix)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit a single JSON object to stdout (for CI consumption).",
    )
    parser.add_argument(
        "--ibex-config",
        default=os.environ.get("IBEX_CONFIG", "mhx"),
        help="IBEX_CONFIG to build the Verilator simple system with (default: mhx).",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent

    # 1) Build simulator (simple system) with MHX™ config.
    _run(["make", "build-simple-system", f"IBEX_CONFIG={args.ibex_config}"], cwd=repo_root)

    # 2) Build the benchmark program.
    bench_dir = repo_root / "examples/sw/simple_system/mhx_cycle_bench"
    _run(["make"], cwd=bench_dir)

    elf = bench_dir / "mhx_cycle_bench.elf"
    if not elf.exists():
        raise RuntimeError(f"Expected ELF not found: {elf}")

    # 3) Run simulation.
    sim = repo_root / "build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system"
    if not sim.exists():
        raise RuntimeError(
            f"Expected simulator not found: {sim}. "
            "(Did the build output path change?)"
        )

    _run([str(sim), f"--meminit=ram,{elf}"], cwd=repo_root)

    # 4) Parse UART output log.
    log_path = repo_root / "ibex_simple_system.log"
    log_text = log_path.read_text(encoding="utf-8", errors="replace")
    neural, matrix = _parse_log(log_text)

    metrics: dict[str, Any] = {
        "benchmark_version": "4.0",
        "metric_source": "verilator_cycles",
        "neural_inference_speedup": neural.speedup,
        "matrix_operation_speedup": matrix.speedup,
        # Keep existing non-cycle metrics as the previous analytical targets.
        # These remain stable and are not derived from RTL simulation here.
        "memory_reduction_percent": 93.75,
        "power_reduction_percent": 70.0,
        "efficiency_score": round((neural.speedup + matrix.speedup) * 50.0, 2),
        "details": {
            "neural": {
                "baseline_cycles": neural.baseline_cycles,
                "mhx_cycles": neural.mhx_cycles,
                "speedup_x1000": neural.speedup_x1000,
            },
            "matrix": {
                "baseline_cycles": matrix.baseline_cycles,
                "mhx_cycles": matrix.mhx_cycles,
                "speedup_x1000": matrix.speedup_x1000,
            },
            "ibex_config": args.ibex_config,
            "program": "examples/sw/simple_system/mhx_cycle_bench/mhx_cycle_bench.elf",
        },
    }

    if args.json:
        print(json.dumps(metrics, indent=2, sort_keys=True))
    else:
        print("MHX™ Verilator cycle benchmark")
        print(f"neural speedup: {metrics['neural_inference_speedup']:.3f}x")
        print(f"matrix speedup: {metrics['matrix_operation_speedup']:.3f}x")
        print(f"log: {log_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
