# MHX Ternary Integration Guide

**Document Version:** 1.0  
**Last Updated:** December 3, 2025  
**Status:** DRAFT

---

## Overview

This document provides comprehensive guidance for integrating the MHX Ternary Ibex core into System-on-Chip (SoC) designs. It covers hardware integration, software setup, verification, and validation procedures.

## Target Audience

- SoC architects
- ASIC/FPGA design engineers
- System integration engineers
- Verification engineers

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Hardware Integration](#2-hardware-integration)
3. [Memory Subsystem](#3-memory-subsystem)
4. [Interrupt Handling](#4-interrupt-handling)
5. [Debug Interface](#5-debug-interface)
6. [FPGA Implementation](#6-fpga-implementation)
7. [ASIC Implementation](#7-asic-implementation)
8. [Verification Strategy](#8-verification-strategy)
9. [Reference Designs](#9-reference-designs)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Architecture Overview

### 1.1 MHX Ternary Ibex Top-Level

```
┌─────────────────────────────────────────────────────┐
│ ibex_top (with MHX Ternary Extensions)              │
│                                                      │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ IF Stage │→│ ID/EX Stage  │→│ WB Stage     │  │
│  └──────────┘  └──────────────┘  └──────────────┘  │
│                       ↓                ↓            │
│              ┌────────────────┐  ┌──────────────┐  │
│              │ Ternary ALU    │  │ Ternary      │  │
│              │ (7 operations) │  │ Register File│  │
│              └────────────────┘  │ (32 × 16trit)│  │
│                       ↓          └──────────────┘  │
│              ┌────────────────┐                    │
│              │ Neural Unit    │                    │
│              │ (4 operations) │                    │
│              └────────────────┘                    │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ Interfaces:                                  │  │
│  │ - Instruction Bus (32-bit)                   │  │
│  │ - Data Bus (32-bit)                          │  │
│  │ - Interrupts (IRQ)                           │  │
│  │ - Debug (JTAG/DMI)                           │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### 1.2 Key Parameters

```systemverilog
module ibex_top #(
    parameter bit          PMPEnable        = 1'b0,
    parameter int unsigned PMPGranularity   = 0,
    parameter int unsigned PMPNumRegions    = 4,
    parameter int unsigned MHPMCounterNum   = 0,
    parameter int unsigned MHPMCounterWidth = 40,
    parameter bit          RV32E            = 1'b0,
    parameter bit          RV32M            = ibex_pkg::RV32MFast,
    parameter bit          RV32B            = ibex_pkg::RV32BNone,
    parameter bit          BranchTargetALU  = 1'b0,
    parameter bit          WritebackStage   = 1'b0,
    parameter bit          ICache           = 1'b0,
    parameter bit          ICacheECC        = 1'b0,
    parameter bit          DbgTriggerEn     = 1'b0,
    parameter int unsigned DbgHwBreakNum    = 1,
    parameter bit          SecureIbex       = 1'b0,
    // MHX Ternary Extensions (always enabled)
    parameter bit          TernaryExt       = 1'b1,
    parameter bit          NeuralExt        = 1'b1
) (
    // Clock and Reset
    input  logic        clk_i,
    input  logic        rst_ni,
    
    // Instruction memory interface
    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    input  logic        instr_rvalid_i,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,
    input  logic        instr_err_i,
    
    // Data memory interface
    output logic        data_req_o,
    input  logic        data_gnt_i,
    input  logic        data_rvalid_i,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,
    input  logic        data_err_i,
    
    // Interrupt inputs
    input  logic        irq_software_i,
    input  logic        irq_timer_i,
    input  logic        irq_external_i,
    input  logic [14:0] irq_fast_i,
    input  logic        irq_nm_i,
    
    // Debug interface
    input  logic        debug_req_i,
    output logic        alert_minor_o,
    output logic        alert_major_o,
    
    // CPU control
    input  logic        fetch_enable_i,
    output logic        core_sleep_o
);
```

---

## 2. Hardware Integration

### 2.1 Basic Integration

Minimal integration for simulation/FPGA:

```systemverilog
module mhx_soc (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [15:0] gpio_in,
    output logic [15:0] gpio_out
);

    // Instruction bus signals
    logic        instr_req;
    logic        instr_gnt;
    logic        instr_rvalid;
    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;
    logic        instr_err;
    
    // Data bus signals
    logic        data_req;
    logic        data_gnt;
    logic        data_rvalid;
    logic        data_we;
    logic [3:0]  data_be;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
    logic        data_err;
    
    // Interrupts
    logic        irq_software;
    logic        irq_timer;
    logic        irq_external;
    logic [14:0] irq_fast;
    
    // Ibex core instantiation
    ibex_top #(
        .PMPEnable       (1'b1),
        .PMPGranularity  (0),
        .PMPNumRegions   (4),
        .RV32M           (ibex_pkg::RV32MFast),
        .WritebackStage  (1'b1),
        .TernaryExt      (1'b1),
        .NeuralExt       (1'b1)
    ) u_core (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),
        
        .instr_req_o     (instr_req),
        .instr_gnt_i     (instr_gnt),
        .instr_rvalid_i  (instr_rvalid),
        .instr_addr_o    (instr_addr),
        .instr_rdata_i   (instr_rdata),
        .instr_err_i     (instr_err),
        
        .data_req_o      (data_req),
        .data_gnt_i      (data_gnt),
        .data_rvalid_i   (data_rvalid),
        .data_we_o       (data_we),
        .data_be_o       (data_be),
        .data_addr_o     (data_addr),
        .data_wdata_o    (data_wdata),
        .data_rdata_i    (data_rdata),
        .data_err_i      (data_err),
        
        .irq_software_i  (irq_software),
        .irq_timer_i     (irq_timer),
        .irq_external_i  (irq_external),
        .irq_fast_i      (irq_fast),
        .irq_nm_i        (1'b0),
        
        .debug_req_i     (1'b0),
        .alert_minor_o   (),
        .alert_major_o   (),
        
        .fetch_enable_i  (1'b1),
        .core_sleep_o    ()
    );
    
    // Memory subsystem
    mhx_memory_subsystem u_mem (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),
        
        // Instruction interface
        .instr_req_i     (instr_req),
        .instr_gnt_o     (instr_gnt),
        .instr_rvalid_o  (instr_rvalid),
        .instr_addr_i    (instr_addr),
        .instr_rdata_o   (instr_rdata),
        .instr_err_o     (instr_err),
        
        // Data interface
        .data_req_i      (data_req),
        .data_gnt_o      (data_gnt),
        .data_rvalid_o   (data_rvalid),
        .data_we_i       (data_we),
        .data_be_i       (data_be),
        .data_addr_i     (data_addr),
        .data_wdata_i    (data_wdata),
        .data_rdata_o    (data_rdata),
        .data_err_o      (data_err)
    );
    
    // Peripheral subsystem
    mhx_peripherals u_peripherals (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),
        .gpio_in         (gpio_in),
        .gpio_out        (gpio_out),
        .irq_timer_o     (irq_timer),
        .irq_external_o  (irq_external)
    );
    
    assign irq_software = 1'b0;
    assign irq_fast = 15'b0;

endmodule
```

### 2.2 Memory Map Example

```
┌─────────────────────────────────────────────┐
│ 0x0000_0000 - 0x0000_FFFF │ Boot ROM (64KB) │
├─────────────────────────────────────────────┤
│ 0x0001_0000 - 0x0001_FFFF │ SRAM (64KB)     │
├─────────────────────────────────────────────┤
│ 0x0002_0000 - 0x0FFF_FFFF │ Reserved        │
├─────────────────────────────────────────────┤
│ 0x1000_0000 - 0x1000_0FFF │ GPIO            │
├─────────────────────────────────────────────┤
│ 0x1000_1000 - 0x1000_1FFF │ UART            │
├─────────────────────────────────────────────┤
│ 0x1000_2000 - 0x1000_2FFF │ Timer           │
├─────────────────────────────────────────────┤
│ 0x1000_3000 - 0x1FFF_FFFF │ Reserved        │
├─────────────────────────────────────────────┤
│ 0x2000_0000 - 0x3FFF_FFFF │ External Memory │
└─────────────────────────────────────────────┘
```

---

## 3. Memory Subsystem

### 3.1 Simple SRAM Controller

```systemverilog
module mhx_sram_controller #(
    parameter int unsigned ADDR_WIDTH = 16,  // 64KB
    parameter int unsigned DATA_WIDTH = 32
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    
    // CPU interface
    input  logic                    req_i,
    output logic                    gnt_o,
    output logic                    rvalid_o,
    input  logic                    we_i,
    input  logic [3:0]              be_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    output logic [DATA_WIDTH-1:0]   rdata_o,
    output logic                    err_o
);

    // SRAM array
    logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH];
    
    // State
    logic                  rvalid_q;
    logic [DATA_WIDTH-1:0] rdata_q;
    
    // Always grant immediately (single cycle latency)
    assign gnt_o = req_i;
    assign err_o = 1'b0;
    
    // Read/Write logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rvalid_q <= 1'b0;
            rdata_q  <= '0;
        end else begin
            rvalid_q <= req_i && !we_i;
            
            if (req_i) begin
                if (we_i) begin
                    // Write
                    if (be_i[0]) mem[addr_i][ 7: 0] <= wdata_i[ 7: 0];
                    if (be_i[1]) mem[addr_i][15: 8] <= wdata_i[15: 8];
                    if (be_i[2]) mem[addr_i][23:16] <= wdata_i[23:16];
                    if (be_i[3]) mem[addr_i][31:24] <= wdata_i[31:24];
                end else begin
                    // Read
                    rdata_q <= mem[addr_i];
                end
            end
        end
    end
    
    assign rvalid_o = rvalid_q;
    assign rdata_o  = rdata_q;

endmodule
```

### 3.2 Bus Arbiter

```systemverilog
module mhx_bus_arbiter (
    input  logic        clk_i,
    input  logic        rst_ni,
    
    // Master interfaces (instruction + data)
    input  logic        instr_req_i,
    output logic        instr_gnt_o,
    input  logic [31:0] instr_addr_i,
    
    input  logic        data_req_i,
    output logic        data_gnt_o,
    input  logic        data_we_i,
    input  logic [3:0]  data_be_i,
    input  logic [31:0] data_addr_i,
    input  logic [31:0] data_wdata_i,
    
    // Slave interface (to memory/peripherals)
    output logic        mem_req_o,
    input  logic        mem_gnt_i,
    output logic        mem_we_o,
    output logic [3:0]  mem_be_o,
    output logic [31:0] mem_addr_o,
    output logic [31:0] mem_wdata_o
);

    typedef enum logic {
        INSTR_PRIORITY,
        DATA_PRIORITY
    } arb_state_e;
    
    arb_state_e state_q, state_d;
    
    // Priority arbiter: data has priority to avoid stalls
    always_comb begin
        state_d = state_q;
        
        instr_gnt_o = 1'b0;
        data_gnt_o  = 1'b0;
        mem_req_o   = 1'b0;
        mem_we_o    = 1'b0;
        mem_be_o    = 4'b0;
        mem_addr_o  = '0;
        mem_wdata_o = '0;
        
        if (data_req_i) begin
            // Data request
            mem_req_o   = 1'b1;
            mem_we_o    = data_we_i;
            mem_be_o    = data_be_i;
            mem_addr_o  = data_addr_i;
            mem_wdata_o = data_wdata_i;
            data_gnt_o  = mem_gnt_i;
            state_d     = DATA_PRIORITY;
        end else if (instr_req_i) begin
            // Instruction request
            mem_req_o   = 1'b1;
            mem_we_o    = 1'b0;
            mem_be_o    = 4'b1111;
            mem_addr_o  = instr_addr_i;
            instr_gnt_o = mem_gnt_i;
            state_d     = INSTR_PRIORITY;
        end
    end
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= INSTR_PRIORITY;
        end else begin
            state_q <= state_d;
        end
    end

endmodule
```

---

## 4. Interrupt Handling

### 4.1 Interrupt Controller

```systemverilog
module mhx_interrupt_controller (
    input  logic        clk_i,
    input  logic        rst_ni,
    
    // External interrupt sources
    input  logic [31:0] irq_sources_i,
    
    // CPU interrupt outputs
    output logic        irq_software_o,
    output logic        irq_timer_o,
    output logic        irq_external_o,
    output logic [14:0] irq_fast_o,
    
    // Configuration registers
    input  logic [31:0] irq_enable_i,
    input  logic [31:0] irq_priority_i
);

    logic [31:0] irq_pending;
    
    // Latch interrupt sources
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            irq_pending <= '0;
        end else begin
            irq_pending <= (irq_sources_i & irq_enable_i) | irq_pending;
        end
    end
    
    // Map to RISC-V interrupt lines
    assign irq_software_o = irq_pending[0];
    assign irq_timer_o    = irq_pending[1];
    assign irq_external_o = |irq_pending[31:16];
    assign irq_fast_o     = irq_pending[16:2];

endmodule
```

---

## 5. Debug Interface

### 5.1 JTAG Integration

```systemverilog
module mhx_debug_interface (
    input  logic        clk_i,
    input  logic        rst_ni,
    
    // JTAG signals
    input  logic        tck_i,
    input  logic        tms_i,
    input  logic        tdi_i,
    output logic        tdo_o,
    input  logic        trst_ni,
    
    // Debug request to CPU
    output logic        debug_req_o
);

    // JTAG TAP controller
    dm::dtm_t dtm;
    
    // Debug Module (DM)
    logic [40:0] dmi_req;
    logic [33:0] dmi_resp;
    
    dmi_jtag #(
        .IdcodeValue (32'h4D485801)  // MHX-01
    ) u_dmi_jtag (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .testmode_i     (1'b0),
        
        .tck_i          (tck_i),
        .tms_i          (tms_i),
        .trst_ni        (trst_ni),
        .td_i           (tdi_i),
        .td_o           (tdo_o),
        
        .dmi_req_o      (dmi_req),
        .dmi_resp_i     (dmi_resp)
    );
    
    dm_top u_dm_top (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .testmode_i     (1'b0),
        .ndmreset_o     (),
        .dmactive_o     (),
        .debug_req_o    (debug_req_o),
        .unavailable_i  (1'b0),
        .dmi_req_i      (dmi_req),
        .dmi_resp_o     (dmi_resp)
    );

endmodule
```

---

## 6. FPGA Implementation

### 6.1 Xilinx Vivado Flow

See `syn/synthesize_fpga.sh` for automated synthesis.

**Manual steps:**

```tcl
# Create project
create_project mhx_ibex ./vivado_project -part xc7a100tcsg324-1

# Add RTL files
add_files [glob ../rtl/*.sv]
add_files [glob ../rtl/*.v]

# Add constraints
add_files -fileset constrs_1 ./constraints/mhx_timing.xdc
add_files -fileset constrs_1 ./constraints/mhx_pinout.xdc

# Set top module
set_property top mhx_soc [current_fileset]

# Synthesis
synth_design -top mhx_soc -part xc7a100tcsg324-1

# Implementation
opt_design
place_design
route_design

# Generate bitstream
write_bitstream -force ./mhx_ibex.bit
```

### 6.2 Intel Quartus Flow

```tcl
# Create project
project_new mhx_ibex -overwrite

# Set device
set_global_assignment -name DEVICE EP4CE115F29C7

# Add RTL files
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/ibex_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/ibex_top.sv
# ... (add all files)

# Set top entity
set_global_assignment -name TOP_LEVEL_ENTITY mhx_soc

# Compile
execute_flow -compile
```

---

## 7. ASIC Implementation

### 7.1 Synthesis Constraints

**Timing constraints (SDC format):**

```sdc
# Clock definition (100 MHz)
create_clock -name clk_i -period 10.0 [get_ports clk_i]

# Input delays (2ns setup, 1ns hold)
set_input_delay -clock clk_i -max 2.0 [all_inputs]
set_input_delay -clock clk_i -min 1.0 [all_inputs]

# Output delays (3ns setup, 1ns hold)
set_output_delay -clock clk_i -max 3.0 [all_outputs]
set_output_delay -clock clk_i -min 1.0 [all_outputs]

# False paths for asynchronous reset
set_false_path -from [get_ports rst_ni]

# Multicycle paths for ternary operations (2 cycles)
set_multicycle_path -setup 2 -through [get_pins */ternary_alu/*]
set_multicycle_path -hold 1 -through [get_pins */ternary_alu/*]
```

### 7.2 Power Intent (UPF)

```upf
# Power domains
create_power_domain PD_TOP
create_power_domain PD_CORE -elements {u_core}

# Supply sets
create_supply_set SS_TOP -function {power VDD} -function {ground VSS}
create_supply_set SS_CORE -function {power VDD_CORE} -function {ground VSS}

# Associate supply sets with domains
associate_supply_set SS_TOP -handle PD_TOP
associate_supply_set SS_CORE -handle PD_CORE

# Power states
add_power_state PD_TOP -state {ON -supply_expr {power == FULL_ON}}
add_power_state PD_CORE -state {ON -supply_expr {power == FULL_ON}}
add_power_state PD_CORE -state {OFF -supply_expr {power == OFF}}

# Level shifters (if needed for multi-voltage)
set_level_shifter LS_CORE -domain PD_CORE -applies_to outputs
```

---

## 8. Verification Strategy

### 8.1 Simulation Checklist

- [ ] Run basic instruction tests
- [ ] Run UVM regression suite
- [ ] Run ternary-specific directed tests
- [ ] Run fault injection tests
- [ ] Check coverage > 90%
- [ ] Run formal verification
- [ ] Verify interrupt handling
- [ ] Verify debug interface
- [ ] Power analysis

### 8.2 FPGA Validation

- [ ] Synthesize design
- [ ] Meet timing constraints
- [ ] Program FPGA
- [ ] Run on-board tests
- [ ] Validate peripherals
- [ ] Measure power consumption
- [ ] Stress test (temperature, voltage)

### 8.3 Sign-off Criteria

**Functional:**
- ✅ 100% of directed tests pass
- ✅ 95%+ functional coverage
- ✅ 0 lint errors/warnings
- ✅ Formal verification complete

**Timing:**
- ✅ No setup/hold violations
- ✅ Meets target frequency (100 MHz+)

**Power:**
- ✅ Power consumption < target
- ✅ No hot spots
- ✅ EM/IR drop analysis clean

---

## 9. Reference Designs

### 9.1 Minimal SoC

Location: `examples/mhx_simple_system/`

Features:
- Ibex core with MHX extensions
- 64KB SRAM
- UART
- GPIO
- Timer

### 9.2 Demo Application

Location: `examples/mhx_demo.s`

Demonstrates:
- Ternary arithmetic
- Neural network inference
- Peripheral access

---

## 10. Troubleshooting

### 10.1 Common Issues

**Issue:** Core not fetching instructions
- Check reset is properly de-asserted
- Verify `fetch_enable_i` is high
- Check instruction memory returns valid data
- Verify boot address is correct

**Issue:** Data access hangs
- Check data bus arbiter
- Verify memory controller grants requests
- Check for address decode errors
- Verify rvalid signal timing

**Issue:** Interrupts not working
- Check interrupt controller configuration
- Verify interrupt enable bits
- Check interrupt priority
- Verify MIE/MSTATUS CSR settings

**Issue:** Ternary operations produce wrong results
- Verify trit encoding (2 bits per trit)
- Check for invalid trits (0b11)
- Validate test vectors
- Check for overflow conditions

### 10.2 Debug Techniques

**Waveform analysis:**
```bash
# Run simulation with waveform dump
make -C dv run TEST=mhx_ternary_test WAVES=1

# View waveforms
gtkwave dv/waves.vcd
```

**Print debug info:**
```systemverilog
// In testbench
initial begin
    $monitor("Time=%0t PC=%h Instr=%h", $time, u_core.pc, u_core.instr);
end
```

**Assertions:**
```systemverilog
// Add runtime checks
assert property (@(posedge clk) req |-> ##[1:3] gnt)
    else $error("Grant not received within 3 cycles");
```

---

## Appendix A: Signal Descriptions

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk_i` | Input | 1 | System clock |
| `rst_ni` | Input | 1 | Active-low reset |
| `instr_req_o` | Output | 1 | Instruction request |
| `instr_gnt_i` | Input | 1 | Instruction grant |
| `instr_rvalid_i` | Input | 1 | Instruction data valid |
| `instr_addr_o` | Output | 32 | Instruction address |
| `instr_rdata_i` | Input | 32 | Instruction data |
| `data_req_o` | Output | 1 | Data request |
| `data_gnt_i` | Input | 1 | Data grant |
| `data_rvalid_i` | Input | 1 | Data response valid |
| `data_we_o` | Output | 1 | Data write enable |
| `data_be_o` | Output | 4 | Data byte enables |
| `data_addr_o` | Output | 32 | Data address |
| `data_wdata_o` | Output | 32 | Data write data |
| `data_rdata_i` | Input | 32 | Data read data |

---

## Appendix B: Register Map

See [Control and Status Registers](../03_reference/cs_registers.rst) for complete CSR documentation.

---

## Appendix C: Performance Specifications

| Metric | Value |
|--------|-------|
| Maximum frequency (ASIC) | 200-300 MHz |
| Maximum frequency (FPGA) | 100-150 MHz |
| Area (gates) | ~50K |
| Power (dynamic @ 100 MHz) | ~10 mW |
| Instruction throughput | 0.8-1.0 IPC |
| Ternary ops throughput | 1.0 IPC |
| Neural ops throughput | 1.0 IPC |

---

**Document Status:** DRAFT  
**Next Review:** After first tape-out  
**Maintainer:** MHX Neural Team
