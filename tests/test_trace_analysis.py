from pathlib import Path

from util.trace_analysis import TraceAnalyzer


def test_trace_analysis_text_trace_golden(tmp_path: Path) -> None:
    # Build a tiny synthetic trace with deterministic stalls and mixes.
    # Format matches TraceAnalyzer._parse_text_trace
    trace_text = """\
[1] PC=0x1000 INSTR=0x00000013 TYPE=binary
[2] PC=0x1004 INSTR=0x00000013 TYPE=ternary
[4] PC=0x2000 INSTR=0x00000013 TYPE=memory
[5] PC=0x2004 INSTR=0x00000013 TYPE=memory
[8] PC=0x2008 INSTR=0x00000013 TYPE=memory
[9] PC=0x3000 INSTR=0x00000013 TYPE=neural
[12] PC=0xDEAD INSTR=0x00000013 TYPE=stall
"""

    trace_file = tmp_path / "trace.log"
    trace_file.write_text(trace_text)

    analyzer = TraceAnalyzer()
    analyzer.parse_trace_file(trace_file)
    results = analyzer.analyze()

    assert results.total_instructions == 7
    # cycles: 1..12 inclusive
    assert results.total_cycles == 12
    assert results.ipc == 7 / 12

    # Pipeline stalls: gaps (2->4)=1 stall, (5->8)=2 stalls, (9->12)=2 stalls => total 5
    assert results.pipeline_analysis.total_stalls == 5
    assert results.pipeline_analysis.memory_stalls == 3  # from entries at cycle 4 and 8
    assert results.pipeline_analysis.structural_stalls == 2  # from entry at cycle 12 (stall)

    # Memory analysis should detect sequential accesses and a high hit rate
    assert results.memory_analysis.total_accesses == 3
    assert results.memory_analysis.access_pattern == "sequential"
    assert results.memory_analysis.cache_hit_rate > 0.0

    # Neural analysis should see 1 neural op
    assert results.neural_analysis.neuron_ops == 1
    assert results.neural_analysis.total_ops >= 1

    # Hotspots should include the memory PCs
    pcs = {h.pc for h in results.hotspots}
    assert 0x2000 in pcs
    assert 0x2004 in pcs
    assert 0x2008 in pcs
