# MHX Ternary White Paper

This directory contains the white paper for the MHX Ternary Extension.

## Files

- `mhx_ternary_whitepaper.tex` - Main LaTeX source
- `Makefile` - Build automation
- `figures/` - Diagrams and images

## Building the Paper

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get install texlive-full

# Or minimal installation
sudo apt-get install texlive-latex-base texlive-latex-extra texlive-fonts-recommended
```

### Build Commands

```bash
# Build PDF
make pdf

# Clean build artifacts
make clean

# Watch for changes and rebuild
make watch
```

### Quick Build

```bash
pdflatex mhx_ternary_whitepaper.tex
bibtex mhx_ternary_whitepaper
pdflatex mhx_ternary_whitepaper.tex
pdflatex mhx_ternary_whitepaper.tex
```

## Paper Structure

1. **Introduction** - Motivation and contributions
2. **Background** - Ternary networks, RISC-V extensions
3. **Architecture** - MHX design and ISA
4. **Implementation** - RTL and pipeline integration
5. **Verification** - Formal and simulation testing
6. **Evaluation** - Performance, area, timing
7. **Use Cases** - Edge AI applications
8. **Future Work** - Roadmap
9. **Conclusion** - Summary

## Target Venues

- **Conferences**: ISCA, MICRO, ASPLOS, DAC, DATE
- **Journals**: IEEE TCAD, ACM TECS, IEEE Micro
- **Preprint**: arXiv (cs.AR, cs.LG)

## Citation

```bibtex
@article{mhx2025ternary,
  title={MHX: A Native Ternary Computing Extension for RISC-V},
  author={MHX Neural Research Team},
  journal={arXiv preprint},
  year={2025}
}
```
