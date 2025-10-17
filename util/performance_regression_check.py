#!/usr/bin/env python3
"""
Performance Regression Check for MHX Ternary Extensions
=======================================================

This script compares performance metrics between baseline and current branches
to detect any performance regressions in ternary operations.
"""

import argparse
import json
import sys
import subprocess
import os
from typing import Dict, List, Tuple


def run_command(cmd: str) -> str | None:
    """Run a shell command and return its stdout, or None on failure."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Command failed: {cmd}")
            if result.stderr:
                print(f"Error: {result.stderr}")
            return None
        return result.stdout.strip()
    except Exception as e:
        print(f"Error running command: {e}")
        return None


def _sanitize_ref_for_path(ref: str) -> str:
    return ref.replace('/', '_').replace('~', '_').replace('^', '_').replace('..', '_')


def get_performance_metrics(git_ref: str) -> Dict | None:
    """Get performance metrics for a specific git reference in an isolated worktree."""
    print(f"Getting performance metrics for {git_ref}")
    worktree_dir = f"/tmp/ternary-ibex-perf-{_sanitize_ref_for_path(git_ref)}"

    # Ensure any previous worktree dir is gone (best-effort)
    run_command(f"git worktree remove -f {worktree_dir} 2>/dev/null || true")

    add_out = run_command(f"git worktree add --force {worktree_dir} {git_ref}")
    if add_out is None:
        print(f"Failed to create worktree for {git_ref}")
        return None

    try:
        # Run performance analysis in the worktree
        output = run_command(
            f"cd {worktree_dir} && python3 util/ternary_performance_analysis.py --json"
        )
        if not output:
            return None

        # Primary parse
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            # Fallback: try to extract JSON payload (in case of stray logs)
            start = output.find('{')
            end = output.rfind('}')
            if start != -1 and end != -1 and end > start:
                try:
                    return json.loads(output[start:end + 1])
                except json.JSONDecodeError:
                    pass
            print(f"Failed to parse JSON output for {git_ref}")
            return None
    finally:
        # Clean up worktree
        run_command(f"git worktree remove -f {worktree_dir}")


def compare_metrics(
    baseline: Dict,
    current: Dict,
    regression_threshold_percent: float = -5.0,
    improvement_threshold_percent: float = 2.0,
) -> Tuple[List[Dict], List[Dict]]:
    """Compare performance metrics and detect regressions/improvements.

    Returns two lists of dicts: (regressions, improvements).
    Each dict contains: metric, baseline, current, change_percent
    """
    regressions: List[Dict] = []
    improvements: List[Dict] = []

    key_metrics = [
        'neural_inference_speedup',
        'matrix_operation_speedup',
        'memory_usage_reduction_percent',
        'power_efficiency_improvement_percent',
    ]

    for metric in key_metrics:
        if metric in baseline and metric in current:
            try:
                baseline_val = float(baseline[metric])
                current_val = float(current[metric])
            except (TypeError, ValueError):
                # Skip non-numeric values
                continue

            if baseline_val != 0:
                change_percent = ((current_val - baseline_val) / baseline_val) * 100.0
            else:
                # If baseline is 0, any positive current is +inf improvement; else 0 change.
                change_percent = float('inf') if current_val > 0 else 0.0

            if change_percent < regression_threshold_percent:
                regressions.append({
                    'metric': metric,
                    'baseline': baseline_val,
                    'current': current_val,
                    'change_percent': change_percent,
                })
            elif change_percent > improvement_threshold_percent:
                improvements.append({
                    'metric': metric,
                    'baseline': baseline_val,
                    'current': current_val,
                    'change_percent': change_percent,
                })

    return regressions, improvements


def generate_report(
    baseline: Dict,
    current: Dict,
    regressions: List[Dict],
    improvements: List[Dict],
) -> str:
    """Generate a human-readable comparison report."""
    lines: List[str] = []
    lines.append("=== Performance Comparison ===")

    key_metrics = [
        'neural_inference_speedup',
        'matrix_operation_speedup',
        'memory_usage_reduction_percent',
        'power_efficiency_improvement_percent',
    ]

    for metric in key_metrics:
        if metric in baseline and metric in current:
            try:
                b = float(baseline[metric])
                c = float(current[metric])
            except (TypeError, ValueError):
                continue
            if b != 0:
                chg = ((c - b) / b) * 100.0
            else:
                chg = float('inf') if c > 0 else 0.0
            lines.append(f"{metric}:")
            lines.append(f"  Baseline: {b:.3f}")
            lines.append(f"  Current:  {c:.3f}")
            # Handle inf printing
            if chg == float('inf'):
                lines.append("  Change:   +inf%")
            else:
                lines.append(f"  Change:   {chg:+.2f}%")

    if regressions:
        lines.append("")
        lines.append(f"Regressions ({len(regressions)}):")
        for r in regressions:
            lines.append(
                f"  - {r['metric']}: {r['baseline']:.3f} -> {r['current']:.3f} ({r['change_percent']:+.2f}%)"
            )

    if improvements:
        lines.append("")
        lines.append(f"Improvements ({len(improvements)}):")
        for r in improvements:
            lines.append(
                f"  - {r['metric']}: {r['baseline']:.3f} -> {r['current']:.3f} ({r['change_percent']:+.2f}%)"
            )

    # Optional summary fields if present
    for label, key in [
        ("Overall score", 'overall_score'),
        ("Status", 'status'),
        ("Integration test passed", 'integration_test_passed'),
    ]:
        if key in current:
            lines.append(f"{label}: {current[key]}")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Check for performance regressions")
    parser.add_argument("--baseline", required=True, help="Baseline git reference")
    parser.add_argument("--current", required=True, help="Current git reference")
    parser.add_argument("--output", help="Output report file")
    parser.add_argument(
        "--threshold", type=float, default=5.0,
        help="Regression threshold in percent (e.g., 5 means -5% or worse is a regression)"
    )

    args = parser.parse_args()

    print("MHX Ternary Performance Regression Check")
    print("=" * 50)

    # Get baseline metrics
    print(f"Analyzing baseline: {args.baseline}")
    baseline_metrics = get_performance_metrics(args.baseline)
    if not baseline_metrics:
        print(f"Failed to get baseline metrics for {args.baseline}")
        return 1

    # Get current metrics
    print(f"Analyzing current: {args.current}")
    current_metrics = get_performance_metrics(args.current)
    if not current_metrics:
        print(f"Failed to get current metrics for {args.current}")
        return 1

    # Compare metrics
    regression_threshold = -abs(args.threshold)
    regressions, improvements = compare_metrics(
        baseline_metrics, current_metrics,
        regression_threshold_percent=regression_threshold,
        improvement_threshold_percent=2.0,
    )

    # Generate report
    report = generate_report(baseline_metrics, current_metrics, regressions, improvements)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(report)
        print(f"Report written to {args.output}")
    else:
        print("\n" + report)

    # Return appropriate exit code
    if regressions:
        print(f"\n❌ {len(regressions)} performance regression(s) detected!")
        return 1
    else:
        print(f"\n✅ No performance regressions detected")
        if improvements:
            print(f"🎉 {len(improvements)} improvement(s) found!")
        return 0


if __name__ == "__main__":
    sys.exit(main())