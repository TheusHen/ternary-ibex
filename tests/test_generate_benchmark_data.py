import json
from util.generate_benchmark_data import (
    ComprehensiveBenchmarkData,
    generate_latex_tables,
    generate_markdown_report,
)


def test_benchmark_data_json_schema_shape() -> None:
    data = ComprehensiveBenchmarkData().to_dict()

    # Top-level keys
    for key in (
        "version",
        "generated_at",
        "cycle_accurate_metrics",
        "trace_analysis_metrics",
        "mlperftiny_metrics",
        "area_metrics",
        "power_metrics",
        "timing_metrics",
        "summary",
    ):
        assert key in data

    # JSON round-trip should work
    json_text = json.dumps(data)
    loaded = json.loads(json_text)
    assert loaded["version"] == data["version"]

    # A couple of key fields sanity
    assert loaded["mlperftiny_metrics"]["geometric_mean_speedup"] > 0
    assert "x" in loaded["summary"]["neural_inference_speedup"]


def test_benchmark_data_latex_contains_expected_tables() -> None:
    latex = generate_latex_tables(ComprehensiveBenchmarkData())
    assert "\\label{tab:mlperftiny_results}" in latex
    assert "\\label{tab:cycle_latencies}" in latex
    assert "\\label{tab:trace_analysis}" in latex


def test_benchmark_data_markdown_contains_expected_sections() -> None:
    md = generate_markdown_report(ComprehensiveBenchmarkData())
    assert "# MHX™ Ternary Extension Benchmark Results" in md
    assert "## MLPerfTiny Benchmark Results" in md
    assert "## Cycle-Accurate Operation Latencies" in md
    assert "## Trace-Based Analysis" in md
