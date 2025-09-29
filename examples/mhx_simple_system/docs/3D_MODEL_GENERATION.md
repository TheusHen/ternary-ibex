# MHX T1 Prototype - 3D Chip Model Generation

This document describes the 3D chip model generation process for the MHX T1 Prototype based on the MHX Simple System design.

## Overview

The 3D chip model generation workflow creates accurate, detailed 3D models of the chip based on RTL synthesis results. The models include:

- **Realistic package geometry** (15mm x 15mm BGA package)
- **Color-coded functional areas** based on RTL modules
- **Text engraving** with "MHX T1 Prototype" 
- **MHX Neural logo** placement
- **Debug information overlay** with synthesis metrics
- **Multiple export formats** (OBJ, STL, PNG)

## Functional Areas

The 3D model represents the following functional blocks from the RTL:

| Block | Description | Color | RTL Module |
|-------|-------------|-------|------------|
| CPU Core | Main Ibex RISC-V processor | Red (#FF6B6B) | `ibex_core` |
| Memory | RAM and cache structures | Teal (#4ECDC4) | `ram_1p_scr` |
| UART | Serial communication interface | Blue (#45B7D1) | `uart_core` |
| GPIO | General purpose I/O | Green (#96CEB4) | `gpio_core` |
| SPI | Serial peripheral interface | Yellow (#FFEAA7) | `spi_core` |
| Debug | Debug and trace infrastructure | Purple (#DDA0DD) | `debug_module` |

## Package Specifications

- **Package Type**: BGA (Ball Grid Array)
- **Package Dimensions**: 15mm × 15mm × 1.2mm
- **Die Dimensions**: 8mm × 8mm × 0.3mm
- **Package Material**: Standard IC package substrate
- **Die Technology**: Simulated silicon process

## Generation Process

### 1. RTL Analysis
The workflow analyzes the RTL files in `examples/mhx_simple_system/rtl/`:
- `mhx_simple_system_top.sv` - Top-level module
- `mhx_simple_system.sv` - Core system module

### 2. Synthesis Execution
Runs FPGA synthesis using:
- **Primary Tool**: Yosys + NextPNR (open-source)
- **Target Boards**: Arty A7-35T, Basys3
- **Output**: Netlist, utilization reports, timing analysis

### 3. Data Extraction
Extracts key metrics:
- Logic utilization (LUTs, flip-flops)
- Memory usage (Block RAMs)
- Timing results (maximum frequency)
- Resource distribution by functional block

### 4. 3D Model Generation
Creates 3D geometry using Python:
- **Geometry Engine**: Custom Python implementation
- **Visualization**: Matplotlib (optional)
- **Export Formats**: OBJ, STL, PNG

## Usage

### Automatic Generation (GitHub Actions)

The workflow runs automatically on:
- Push to `main` or `develop` branches
- Pull requests affecting MHX Simple System files
- Manual workflow dispatch

```bash
# Manual trigger with custom parameters
gh workflow run "Generate 3D Chip Model" \
  -f board_target=arty_a7_35t \
  -f model_formats="obj stl png"
```

### Local Generation

```bash
# Install dependencies
pip install -r scripts/requirements_3d.txt

# Generate 3D model
python scripts/generate_3d_chip_model.py \
  --rtl-dir examples/mhx_simple_system/rtl \
  --syn-dir examples/mhx_simple_system/syn \
  --output-dir my_3d_model \
  --formats obj stl png
```

### Parameters

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `--rtl-dir` | RTL source directory | `examples/mhx_simple_system/rtl` | Path |
| `--syn-dir` | Synthesis directory | `examples/mhx_simple_system/syn` | Path |
| `--output-dir` | Output directory | `3d_model_output` | Path |
| `--formats` | Export formats | `obj stl png` | `obj`, `stl`, `png` |

## Output Files

### 3D Model Files
- **`mhx_t1_prototype.obj`** - Wavefront OBJ format
  - Compatible with Blender, Maya, 3ds Max, MeshLab
  - Includes vertex colors and face definitions
  - Text format, human-readable

- **`mhx_t1_prototype.stl`** - STL format
  - Standard format for 3D printing
  - Triangle mesh representation
  - ASCII format for compatibility

- **`mhx_t1_prototype_3d.png`** - 3D visualization
  - High-resolution render of the model
  - Multiple viewing angles available
  - Suitable for documentation and presentations

### Documentation
- **`model_summary.json`** - Model specifications and metrics
- **`README.md`** - Usage instructions and technical details

### Reference Files
- **`rtl_reference/`** - Original RTL source files
- **`synthesis_results/`** - Synthesis reports and logs

## Viewing and Using Models

### 3D Software Compatibility

| Software | OBJ | STL | Notes |
|----------|-----|-----|-------|
| Blender | ✓ | ✓ | Full feature support |
| MeshLab | ✓ | ✓ | Mesh analysis tools |
| FreeCAD | ✓ | ✓ | CAD/engineering focus |
| Online Viewers | ✓ | ✓ | No software installation needed |

### 3D Printing

The STL files are optimized for 3D printing:
- **Recommended Scale**: 10:1 (150mm × 150mm × 12mm)
- **Minimum Feature Size**: 0.4mm (scaled)
- **Support Material**: Required for overhangs
- **Print Orientation**: Package face down recommended

### Visualization Tips

1. **Color Display**: OBJ files include color information
2. **Lighting**: Use ambient lighting to see all functional areas
3. **Camera Angles**: Isometric view shows best overall detail
4. **Animation**: Rotate around Z-axis for presentation videos

## Technical Details

### Model Complexity
- **Vertices**: ~500-800 (depends on detail level)
- **Faces**: ~400-600 (mostly quads, some triangles)
- **File Sizes**: 
  - OBJ: ~20-30 KB
  - STL: ~100-150 KB
  - PNG: ~200-500 KB (depends on resolution)

### Coordinate System
- **Origin**: Bottom-left corner of package
- **Units**: Millimeters (mm)
- **Orientation**: 
  - X-axis: Package length
  - Y-axis: Package width  
  - Z-axis: Package height (up)

### Color Encoding
Colors use hex RGB format:
- Package substrate: `#2C3E50` (dark blue-gray)
- Die substrate: `#1A1A1A` (dark silicon)
- Text/logo: `#FFFFFF` (white)
- Debug info: `#00FF00` (green)
- Functional areas: Custom colors (see table above)

## Customization

### Adding New Functional Areas

Edit `scripts/generate_3d_chip_model.py`:

```python
self.functional_areas = {
    'cpu_core': {'x': 0.1, 'y': 0.1, 'w': 0.4, 'h': 0.4, 'color': '#FF6B6B'},
    'new_block': {'x': 0.6, 'y': 0.6, 'w': 0.3, 'h': 0.3, 'color': '#FF00FF'},
    # ... existing areas
}
```

### Modifying Package Dimensions

```python
# Package dimensions (in mm)
self.package_length = 20.0  # Increase package size
self.package_width = 20.0
self.package_height = 1.5
```

### Custom Text and Logos

```python
def generate_text_engraving(self):
    text = "CUSTOM CHIP NAME"  # Change engraved text
    # ... rest of function
```

## Troubleshooting

### Common Issues

1. **Missing Dependencies**: Install requirements with `pip install -r scripts/requirements_3d.txt`
2. **Synthesis Failures**: Workflow creates placeholder data if synthesis fails
3. **Large File Sizes**: Reduce model complexity or use compression
4. **Visualization Issues**: Check matplotlib installation and display settings

### Debug Information

Enable verbose output:
```bash
python scripts/generate_3d_chip_model.py --verbose
```

Check synthesis logs:
```bash
cat examples/mhx_simple_system/syn/build/yosys/synthesis.log
```

## Future Enhancements

Planned improvements:
- **Advanced mesh operations** using Trimesh library
- **Thermal simulation overlays** based on power analysis
- **Interactive 3D viewer** using WebGL
- **Automated texture mapping** for more realistic appearance
- **Multi-die packages** for complex systems
- **Pin-out visualization** with ball grid array details

## License

Copyright 2025 MHX Neural.  
Licensed under the Apache License, Version 2.0.

## Support

For issues or questions about 3D model generation:
1. Check this documentation
2. Review workflow logs in GitHub Actions
3. Open an issue in the repository with:
   - Synthesis logs
   - Generated model files
   - Error messages
   - Target board information