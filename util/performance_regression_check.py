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

def run_command(cmd):
    """Run shell command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Command failed: {cmd}")
            print(f"Error: {result.stderr}")
            return None
        return result.stdout.strip()
    except Exception as e:
        print(f"Error running command: {e}")
        return None

def get_performance_metrics(git_ref):
    """Get performance metrics for a specific git reference"""
    print(f"Getting performance metrics for {git_ref}")
    
    # Checkout the reference
    run_command(f"git checkout {git_ref}")
    
    # Run performance analysis
    output = run_command("python3 util/ternary_performance_analysis.py --json")
    
    if output:
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            print(f"Failed to parse JSON output for {git_ref}")
            return None
    return None

def compare_metrics(baseline, current):
    """Compare performance metrics and detect regressions"""
    regressions = []
    improvements = []
    
    key_metrics = [
        'neural_inference_speedup',
        'matrix_operation_speedup', 
        'memory_usage_reduction_percent',
        'power_efficiency_improvement_percent'
    ]
    
    print("\\n=== Performance Comparison ===")
    
    for metric in key_metrics:
        if metric in baseline and metric in current:
            baseline_val = baseline[metric]
            current_val = current[metric]
            
            # Calculate percentage change
            if baseline_val != 0:
                change_percent = ((current_val - baseline_val) / baseline_val) * 100
            else:
                change_percent = float('inf') if current_val > 0 else 0
            
            print(f"{metric}:")
            print(f"  Baseline: {baseline_val:.3f}")
            print(f"  Current:  {current_val:.3f}")
            print(f"  Change:   {change_percent:+.2f}%")
            
            # Define regression thresholds
            regression_threshold = -5.0  # 5% decrease is considered regression
            improvement_threshold = 2.0   # 2% increase is notable improvement
            
            if change_percent < regression_threshold:
                regressions.append({
                    'metric': metric,
                    'baseline': baseline_val,
                    'current': current_val,
                    'change_percent': change_percent
                })
                print(f"  ❌ REGRESSION DETECTED")
            elif change_percent > improvement_threshold:
                improvements.append({
                    'metric': metric,
                    'baseline': baseline_val,
                    'current': current_val,
                    'change_percent': change_percent
                })
                print(f"  ✅ IMPROVEMENT")
            else:
                print(f"  ➡️  STABLE")
            
            print()
    
    return regressions, improvements

def generate_report(regressions, improvements):
    """Generate performance regression report"""
    report = []
    report.append("# MHX Ternary Performance Regression Report\\n")
    
    if regressions:
        report.append("## ❌ Performance Regressions Detected\\n")
        for reg in regressions:
            report.append(f"- **{reg['metric']}**: {reg['change_percent']:+.2f}% change")
            report.append(f"  - Baseline: {reg['baseline']:.3f}")
            report.append(f"  - Current: {reg['current']:.3f}")
        report.append("")
    
    if improvements:
        report.append("## ✅ Performance Improvements\\n")
        for imp in improvements:
            report.append(f"- **{imp['metric']}**: {imp['change_percent']:+.2f}% improvement")
            report.append(f"  - Baseline: {imp['baseline']:.3f}")
            report.append(f"  - Current: {imp['current']:.3f}")
        report.append("")
    
    if not regressions and not improvements:
        report.append("## ➡️ Performance Stable\\n")
        report.append("No significant performance changes detected.\\n")
    
    return "\\n".join(report)

def main():
    parser = argparse.ArgumentParser(description="Check for performance regressions")
    parser.add_argument("--baseline", required=True, help="Baseline git reference")
    parser.add_argument("--current", required=True, help="Current git reference")
    parser.add_argument("--output", help="Output report file")
    parser.add_argument("--threshold", type=float, default=5.0, help="Regression threshold (%)")
    
    args = parser.parse_args()
    
    print("MHX Ternary Performance Regression Check")
    print("=" * 50)
    
    # Save current branch
    current_branch = run_command("git branch --show-current")
    
    try:
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
        regressions, improvements = compare_metrics(baseline_metrics, current_metrics)
        
        # Generate report
        report = generate_report(regressions, improvements)
        
        if args.output:
            with open(args.output, 'w') as f:
                f.write(report)
            print(f"Report written to {args.output}")
        else:
            print("\\n" + report)
        
        # Return appropriate exit code
        if regressions:
            print(f"\\n❌ {len(regressions)} performance regression(s) detected!")
            return 1
        else:
            print(f"\\n✅ No performance regressions detected")
            if improvements:
                print(f"🎉 {len(improvements)} improvement(s) found!")
            return 0
    
    finally:
        # Restore original branch
        if current_branch:
            run_command(f"git checkout {current_branch}")

if __name__ == "__main__":
    sys.exit(main())