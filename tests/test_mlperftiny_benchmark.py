from util.mlperftiny_benchmark import parse_results


def test_mlperftiny_parse_results_all_benchmarks() -> None:
    log = """
MLPERF_AD binary_cycles=0x10 mhx_cycles=0x08
MLPERF_KWS binary_cycles=0x20 mhx_cycles=0x10
MLPERF_IC binary_cycles=0x30 mhx_cycles=0x0C
MLPERF_PD binary_cycles=0x40 mhx_cycles=0x20
"""

    results = parse_results(log)

    assert results.anomaly_detection is not None
    assert results.keyword_spotting is not None
    assert results.image_classification is not None
    assert results.person_detection is not None

    assert results.anomaly_detection.binary_cycles == 0x10
    assert results.anomaly_detection.mhx_cycles == 0x08
    assert results.anomaly_detection.speedup == 2.0

    assert results.keyword_spotting.speedup == 2.0
    assert results.image_classification.speedup == 0x30 / 0x0C
    assert results.person_detection.speedup == 2.0

    # Geometric mean should be > 0 when benchmarks exist
    assert results.geometric_mean_speedup > 0.0
