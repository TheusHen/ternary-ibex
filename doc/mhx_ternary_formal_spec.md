# MHX™ Ternary Extension - Formal Specification

**Version:** 1.0
**Date:** September 29, 2025
**Authors:** MHX™ Neural Team

## 1. Overview

This document provides the formal specification for the MHX™ Ternary Extension to the Ibex RISC-V core, covering all ternary arithmetic operations, neural processing units, and edge case behaviors.

## 2. Ternary Number System

### 2.1 Basic Definitions

The MHX™ ternary system uses balanced ternary notation with three possible values per digit (trit):

- **TRIT_NEG** (`2'b00`): Represents -1
- **TRIT_ZERO** (`2'b01`): Represents 0
- **TRIT_POS** (`2'b10`): Represents +1
- **INVALID** (`2'b11`): Reserved/invalid encoding

### 2.2 Data Representation

```
Ternary Word Format (32 bits):
[31:30][29:28]...[3:2][1:0]
  T15    T14  ...  T1   T0

Each Trit: 2 bits encoding {-1, 0, +1}
Total Trits per Word: 16
Value Range: -3^15/2 to +3^15/2 (approximately ±7.2M)
```

### 2.3 Encoding Validation

**Property TRT-001:** All valid trits must use encodings `00`, `01`, or `10`
```systemverilog
assert property (trit inside {2'b00, 2'b01, 2'b10});
```

**Property TRT-002:** Invalid encoding `11` should be treated as zero
```systemverilog
assert property (trit == 2'b11 |-> processed_trit == TRIT_ZERO);
```

## 3. Ternary Arithmetic Operations

### 3.1 Addition (TERNARY_ADD)

**Mathematical Definition:**
```
result[i] = (operand_a[i] + operand_b[i]) mod 3
overflow[i] = |operand_a[i] + operand_b[i]| > 1
```

**Truth Table:**
| A | B | Result | Overflow |
|---|---|--------|----------|
| -1| -1|   +1   |    1     |
| -1|  0|   -1   |    0     |
| -1| +1|    0   |    0     |
|  0| -1|   -1   |    0     |
|  0|  0|    0   |    0     |
|  0| +1|   +1   |    0     |
| +1| -1|    0   |    0     |
| +1|  0|   +1   |    0     |
| +1| +1|   -1   |    1     |

**Formal Properties:**
```systemverilog
// Commutativity: a + b = b + a
property ADD_COMMUTATIVE;
  @(posedge clk) trit_add(a, b) == trit_add(b, a);
endproperty

// Identity: a + 0 = a
property ADD_IDENTITY;
  @(posedge clk) trit_add(a, TRIT_ZERO) == a;
endproperty

// Overflow occurs only for (-1,-1) and (+1,+1)
property ADD_OVERFLOW;
  @(posedge clk) overflow == ((a == TRIT_NEG && b == TRIT_NEG) ||
                              (a == TRIT_POS && b == TRIT_POS));
endproperty
```

### 3.2 Subtraction (TERNARY_SUB)

**Mathematical Definition:**
```
result[i] = (operand_a[i] - operand_b[i]) mod 3
overflow[i] = |operand_a[i] - operand_b[i]| > 1
```

**Truth Table:**
| A | B | Result | Overflow |
|---|---|--------|----------|
| -1| -1|    0   |    0     |
| -1|  0|   -1   |    0     |
| -1| +1|   +1   |    1     |
|  0| -1|   +1   |    0     |
|  0|  0|    0   |    0     |
|  0| +1|   -1   |    0     |
| +1| -1|   -1   |    1     |
| +1|  0|   +1   |    0     |
| +1| +1|    0   |    0     |

**Formal Properties:**
```systemverilog
// Anti-commutativity: a - b = -(b - a)
property SUB_ANTICOMMUTATIVE;
  @(posedge clk) trit_sub(a, b) == trit_not(trit_sub(b, a));
endproperty

// Identity: a - 0 = a
property SUB_IDENTITY;
  @(posedge clk) trit_sub(a, TRIT_ZERO) == a;
endproperty

// Self-subtraction: a - a = 0
property SUB_SELF;
  @(posedge clk) trit_sub(a, a) == TRIT_ZERO;
endproperty
```

### 3.3 Multiplication (TERNARY_MUL)

**Mathematical Definition:**
```
result[i] = operand_a[i] × operand_b[i]
```

**Truth Table:**
| A | B | Result |
|---|---|--------|
| -1| -1|   +1   |
| -1|  0|    0   |
| -1| +1|   -1   |
|  0| -1|    0   |
|  0|  0|    0   |
|  0| +1|    0   |
| +1| -1|   -1   |
| +1|  0|    0   |
| +1| +1|   +1   |

**Formal Properties:**
```systemverilog
// Commutativity: a × b = b × a
property MUL_COMMUTATIVE;
  @(posedge clk) trit_mul(a, b) == trit_mul(b, a);
endproperty

// Identity: a × 1 = a
property MUL_IDENTITY;
  @(posedge clk) trit_mul(a, TRIT_POS) == a;
endproperty

// Zero property: a × 0 = 0
property MUL_ZERO;
  @(posedge clk) trit_mul(a, TRIT_ZERO) == TRIT_ZERO;
endproperty

// Sign properties: (-1) × a = -a
property MUL_NEGATION;
  @(posedge clk) trit_mul(TRIT_NEG, a) == trit_not(a);
endproperty
```

### 3.4 Logical Operations

#### 3.4.1 Ternary AND (TERNARY_AND)
**Definition:** `result[i] = min(operand_a[i], operand_b[i])`

#### 3.4.2 Ternary OR (TERNARY_OR)
**Definition:** `result[i] = max(operand_a[i], operand_b[i])`

#### 3.4.3 Ternary XOR (TERNARY_XOR)
**Definition:** `result[i] = (operand_a[i] + operand_b[i]) mod 3`

#### 3.4.4 Ternary NOT (TERNARY_NOT)
**Definition:** `result[i] = -operand_a[i]`

## 4. Neural Processing Unit Specification

### 4.1 Neural Operations

#### 4.1.1 NEURAL_MULTIPLY
**Function:** Ternary multiply-accumulate operation
```
accumulator = Σ(weights[i] × inputs[i]) + bias
result = accumulator (as signed 8-bit value)
```

**Formal Properties:**
```systemverilog
// Accumulator bounds: -17 ≤ accumulator ≤ +17
property NEURAL_ACCUMULATOR_BOUNDS;
  @(posedge clk) accumulator >= -16 && accumulator <= 16;
endproperty

// Linearity in weights
property NEURAL_WEIGHT_LINEARITY;
  @(posedge clk) neural_mul(2*w, i, b) == 2*neural_mul(w, i, b);
endproperty
```

#### 4.1.2 NEURAL_ACTIVATE
**Function:** Ternary activation function
```
if (accumulator > 1)       result = +1
else if (accumulator < -1) result = -1
else                       result = 0
```

#### 4.1.3 NEURAL_LEARN
**Function:** Reserved for future work; current implementations may pass through weights.
```
result = weights (pass-through)
```

### 4.2 Neural Unit Constraints

**Constraint NUR-001:** All neural operations must complete in one cycle
**Constraint NUR-002:** Accumulator bounds are guaranteed by design (sum of 16 trits)
**Constraint NUR-003:** Invalid trit inputs are treated as zero

## 5. Edge Cases and Error Handling

### 5.1 Invalid Trit Handling

**Rule IVT-001:** Any trit with encoding `2'b11` is treated as `TRIT_ZERO`
**Rule IVT-002:** All functions must return valid trit encodings
**Rule IVT-003:** Invalid operands do not cause exceptions, only warning flags

### 5.2 Overflow Behavior

**Rule OVF-001:** Arithmetic overflow wraps with modular arithmetic
**Rule OVF-002:** Overflow flags are set but do not cause exceptions
**Rule OVF-003:** Neural accumulator overflow saturates to ±17

### 5.3 Reset and Initialization

**Rule RST-001:** All ternary registers initialize to zero (`32'h55555555`)
**Rule RST-002:** Control signals initialize to safe defaults
**Rule RST-003:** Reset is synchronous and active-low

## 6. Instruction Encoding

### 6.1 Ternary Instructions

**Format:** R-type with custom opcode
```
31    25 24  20 19  15 14   12 11    7 6     0
 funct7   rs2    rs1   funct3   rd   opcode
                              ternary  0x0B
```

**Encodings:**
- `funct3 = 3'b000`: TERNARY_ADD
- `funct3 = 3'b001`: TERNARY_SUB
- `funct3 = 3'b010`: TERNARY_MUL
- `funct3 = 3'b011`: TERNARY_AND
- `funct3 = 3'b100`: TERNARY_OR
- `funct3 = 3'b101`: TERNARY_XOR
- `funct3 = 3'b110`: TERNARY_NOT

### 6.2 Neural Instructions

**Format:** R-type with custom opcode
```
31    25 24  20 19  15 14   12 11    7 6     0
 funct7   rs2    rs1   funct3   rd   opcode
                               mhx    0x0B
```

**Encodings:**
- `funct3 = 3'b000`: NEURAL_MULTIPLY
- `funct3 = 3'b001`: NEURAL_ACCUMULATE
- `funct3 = 3'b010`: NEURAL_ACTIVATE
- `funct3 = 3'b011`: NEURAL_LEARN

## 7. Performance Characteristics

### 7.1 Timing Requirements

**Requirement TMG-001:** All ternary operations complete in 1 cycle
**Requirement TMG-002:** Neural operations complete in 1 cycle
**Requirement TMG-003:** Register file access has 0 cycle read latency

### 7.2 Area and Power

**Target APW-001:** Ternary extensions add ~5 kGE (~10-17% area overhead)
**Target APW-002:** Neural unit power scales with utilization
**Target APW-003:** Ternary registers use standard flip-flops

## 8. Verification Requirements

### 8.1 Formal Verification

**Requirement FV-001:** All arithmetic properties must be formally proven
**Requirement FV-002:** Overflow behavior must be formally verified
**Requirement FV-003:** Neural unit bounds must be formally proven

### 8.2 Simulation Coverage

**Requirement SIM-001:** 100% statement coverage for all ternary modules
**Requirement SIM-002:** 100% branch coverage for all decision points
**Requirement SIM-003:** Corner cases must be explicitly tested

## 9. Security Considerations

### 9.1 Side-Channel Analysis

**Concern SEC-001:** Ternary operations may have timing variations
**Mitigation:** Use constant-time implementations where security-critical

**Concern SEC-002:** Power consumption may leak ternary values
**Mitigation:** Implement power analysis countermeasures if needed

### 9.2 Fault Injection

**Concern SEC-003:** Neural weights may be corrupted by fault injection
**Mitigation:** Implement error detection codes for critical applications

## 10. Compliance and Standards

This specification complies with:
- RISC-V ISA Extension Guidelines
- IEEE 754-2019 (where applicable)
- lowRISC coding standards
- Apache 2.0 license requirements

---

**Document Status:** APPROVED
**Review Date:** September 29, 2025
**Next Review:** December 29, 2025