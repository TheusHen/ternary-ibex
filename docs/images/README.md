# MHX Ternary Core Floorplan

This directory contains the architectural floorplan visualization for the MHX Ternary RISC-V Core.

## Files

- `mhx_floorplan.png` - High-resolution floorplan (16x12 inches @ 300 DPI)
- `mhx_floorplan_thumb.png` - Thumbnail version for quick preview (800x800px)

## Automatic Generation

The floorplan is automatically generated and updated by the GitHub Actions workflow:
`.github/workflows/floorplan-generation.yml`

### Triggers
- Push to `main` or `develop` branches
- Pull requests
- Manual workflow dispatch

## Embedding in Documentation

Use this URL format to embed the floorplan in markdown files:

```markdown
![MHX Ternary Core Floorplan](https://raw.githubusercontent.com/TheusHen/ternary-ibex/main/docs/images/mhx_floorplan.png)
```

This ensures the image is always up-to-date from the repository.

## Floorplan Components

### Core Pipeline (Blue)
- **IF Stage**: Instruction Fetch
- **ID Stage**: Instruction Decode  
- **EX Stage**: Execute
- **Controller**: Pipeline control logic

### Ternary ALU (Green)
- **Trit ADD/SUB**: Addition and subtraction with overflow handling
- **Trit MUL**: Ternary multiplication
- **Trit Logic**: AND, OR, XOR, NOT operations

### Neural Unit (Yellow)
- **MAC Array**: Multiply-accumulate for neural networks
- **Activation**: Hardware activation functions

### Register File (Red)
- **Binary RF (x0-x31)**: Standard RISC-V registers
- **Ternary RF (t0-t15)**: Ternary-specific registers
- **Port Mux**: Read/write port multiplexing

### Memory Interface (Purple)
- **LSU**: Load-Store Unit
- **Addr Gen**: Address generation logic

### Control & Debug (Cyan)
- **CSR**: Control and Status Registers
- **Debug Unit**: RISC-V debug module

### I-Cache (Orange)
- **Tag Array**: Cache tag storage
- **Data Array**: Cache data storage
- **Cache Ctrl**: Cache controller

### Clock & Power (Gray)
- **Clock Gate**: Clock gating for power savings
- **Power Mgmt**: Power management unit
- **Reset Ctrl**: Reset control logic

## Specifications

| Property | Value |
|----------|-------|
| Technology | 130nm / Sky130 |
| Estimated Area | ~35 kGE |
| Target Clock | Up to 50 MHz |
| Power Consumption | < 5 mW @ 1.8V |
| Ternary Registers | 16 × 16 trits |
| Binary Registers | 32 × 32 bits |
| Neural Accelerator | 3× speedup |

## Regenerating Manually

To regenerate the floorplan locally:

```bash
mkdir -p build/floorplan
python3 << 'EOF'
# See .github/workflows/floorplan-generation.yml for the full script
# or trigger the workflow manually on GitHub
EOF
```

## Architecture Details

The floorplan shows the physical organization and interconnections of the MHX Ternary Core components. Key architectural features:

1. **Unified Pipeline**: Ternary and binary operations share the same pipeline stages
2. **Dual Register File**: Separate register files for binary and ternary data
3. **Dedicated Accelerators**: Ternary ALU and Neural Unit for specialized operations
4. **Standard Interfaces**: Compatible with standard RISC-V memory and debug interfaces

## Color Legend

- 🔵 **Blue**: Core pipeline and control logic
- 🟢 **Green**: Ternary arithmetic unit
- 🟡 **Yellow**: Neural processing unit
- 🔴 **Red**: Register file system
- 🟣 **Purple**: Memory interface
- 🔵 **Cyan**: Control and debug
- 🟠 **Orange**: Instruction cache
- ⚫ **Gray**: Infrastructure (clock/power)

## Related Documentation

- [MHX Core Overview](../../MHX_README.md)
- [Architecture Details](../../doc/03_reference/ternary_architecture.md)
- [Implementation Guide](../../doc/04_developer/implementation.md)

---

**Last Updated**: Automatically via CI/CD  
**Version**: 1.0.0  
**License**: Apache 2.0
