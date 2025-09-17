# MHX Ternary RISC-V Instruction Set Reference

## Table of Contents

1. [Overview](#overview)
2. [Standard RISC-V Instructions](#standard-risc-v-instructions)
3. [Ternary Extension Instructions](#ternary-extension-instructions)
4. [Neural Processing Instructions](#neural-processing-instructions)
5. [Control and Status Registers](#control-and-status-registers)
6. [Instruction Encoding](#instruction-encoding)
7. [Assembly Syntax](#assembly-syntax)
8. [Programming Examples](#programming-examples)

---

## Overview

The MHX Ternary RISC-V processor implements the complete RV32I base instruction set plus custom ternary extensions. The ternary extensions use the RISC-V custom instruction space to provide native support for ternary arithmetic, logic operations, and neural processing.

### Instruction Categories

| Category | Count | Description |
|----------|-------|-------------|
| RV32I Base | 47 | Standard RISC-V integer instructions |
| Ternary Arithmetic | 8 | Ternary add, subtract, multiply, divide |
| Ternary Logic | 6 | Ternary and, or, xor, not, compare |
| Ternary Memory | 4 | Ternary load/store operations |
| Neural Processing | 5 | Dot product, convolution, activation |
| Control | 3 | Mode switching, configuration |

### Notation

- **Rd**: Destination register (x0-x31 for binary, t0-t31 for ternary)
- **Rs1, Rs2**: Source registers
- **imm**: Immediate value
- **[X]**: Optional field
- **{A|B}**: Choice between A or B

---

## Standard RISC-V Instructions

The processor implements the complete RV32I instruction set. All standard instructions operate normally on binary data.

### Integer Arithmetic

| Instruction | Format | Operation | Description |
|-------------|--------|-----------|-------------|
| ADD rd, rs1, rs2 | R-type | rd = rs1 + rs2 | Add |
| SUB rd, rs1, rs2 | R-type | rd = rs1 - rs2 | Subtract |
| SLT rd, rs1, rs2 | R-type | rd = (rs1 < rs2) ? 1 : 0 | Set less than |
| SLTU rd, rs1, rs2 | R-type | rd = (rs1 < rs2) ? 1 : 0 | Set less than unsigned |

### Integer Arithmetic with Immediates

| Instruction | Format | Operation | Description |
|-------------|--------|-----------|-------------|
| ADDI rd, rs1, imm | I-type | rd = rs1 + imm | Add immediate |
| SLTI rd, rs1, imm | I-type | rd = (rs1 < imm) ? 1 : 0 | Set less than immediate |
| SLTIU rd, rs1, imm | I-type | rd = (rs1 < imm) ? 1 : 0 | Set less than immediate unsigned |

### Logical Operations

| Instruction | Format | Operation | Description |
|-------------|--------|-----------|-------------|
| AND rd, rs1, rs2 | R-type | rd = rs1 & rs2 | Bitwise AND |
| OR rd, rs1, rs2 | R-type | rd = rs1 \| rs2 | Bitwise OR |
| XOR rd, rs1, rs2 | R-type | rd = rs1 ^ rs2 | Bitwise XOR |
| ANDI rd, rs1, imm | I-type | rd = rs1 & imm | AND immediate |
| ORI rd, rs1, imm | I-type | rd = rs1 \| imm | OR immediate |
| XORI rd, rs1, imm | I-type | rd = rs1 ^ imm | XOR immediate |

### Shift Operations

| Instruction | Format | Operation | Description |
|-------------|--------|-----------|-------------|
| SLL rd, rs1, rs2 | R-type | rd = rs1 << rs2[4:0] | Shift left logical |
| SRL rd, rs1, rs2 | R-type | rd = rs1 >> rs2[4:0] | Shift right logical |
| SRA rd, rs1, rs2 | R-type | rd = rs1 >>> rs2[4:0] | Shift right arithmetic |
| SLLI rd, rs1, imm | I-type | rd = rs1 << imm[4:0] | Shift left logical immediate |
| SRLI rd, rs1, imm | I-type | rd = rs1 >> imm[4:0] | Shift right logical immediate |
| SRAI rd, rs1, imm | I-type | rd = rs1 >>> imm[4:0] | Shift right arithmetic immediate |

### Memory Operations

| Instruction | Format | Operation | Description |
|-------------|--------|-----------|-------------|
| LB rd, offset(rs1) | I-type | rd = M[rs1 + offset][7:0] | Load byte |
| LH rd, offset(rs1) | I-type | rd = M[rs1 + offset][15:0] | Load halfword |
| LW rd, offset(rs1) | I-type | rd = M[rs1 + offset][31:0] | Load word |
| LBU rd, offset(rs1) | I-type | rd = M[rs1 + offset][7:0] | Load byte unsigned |
| LHU rd, offset(rs1) | I-type | rd = M[rs1 + offset][15:0] | Load halfword unsigned |
| SB rs2, offset(rs1) | S-type | M[rs1 + offset][7:0] = rs2 | Store byte |
| SH rs2, offset(rs1) | S-type | M[rs1 + offset][15:0] = rs2 | Store halfword |
| SW rs2, offset(rs1) | S-type | M[rs1 + offset][31:0] = rs2 | Store word |

### Control Transfer

| Instruction | Format | Operation | Description |
|-------------|--------|-----------|-------------|
| BEQ rs1, rs2, offset | B-type | if (rs1 == rs2) PC += offset | Branch if equal |
| BNE rs1, rs2, offset | B-type | if (rs1 != rs2) PC += offset | Branch if not equal |
| BLT rs1, rs2, offset | B-type | if (rs1 < rs2) PC += offset | Branch if less than |
| BGE rs1, rs2, offset | B-type | if (rs1 >= rs2) PC += offset | Branch if greater or equal |
| BLTU rs1, rs2, offset | B-type | if (rs1 < rs2) PC += offset | Branch if less than unsigned |
| BGEU rs1, rs2, offset | B-type | if (rs1 >= rs2) PC += offset | Branch if greater or equal unsigned |
| JAL rd, offset | J-type | rd = PC + 4; PC += offset | Jump and link |
| JALR rd, rs1, offset | I-type | rd = PC + 4; PC = rs1 + offset | Jump and link register |

### System Instructions

| Instruction | Format | Operation | Description |
|-------------|--------|-----------|-------------|
| ECALL | I-type | Trap to environment | Environment call |
| EBREAK | I-type | Trap to debugger | Environment break |
| FENCE | I-type | Memory fence | Fence instruction |

---

## Ternary Extension Instructions

The ternary extensions provide native support for ternary arithmetic and logic operations. All ternary instructions use the custom-0 opcode space (0001011).

### Ternary Arithmetic Instructions

#### TADD - Ternary Addition
```
TADD td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = ts1 + ts2 (ternary addition)
- **Encoding**: funct7=0000000, funct3=000
- **Description**: Performs ternary addition with carry propagation

**Example**:
```assembly
tadd t1, t2, t3    # t1 = t2 + t3 (ternary)
```

#### TSUB - Ternary Subtraction
```
TSUB td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = ts1 - ts2 (ternary subtraction)
- **Encoding**: funct7=0000001, funct3=000
- **Description**: Performs ternary subtraction with borrow propagation

#### TMUL - Ternary Multiplication
```
TMUL td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = ts1 * ts2 (ternary multiplication)
- **Encoding**: funct7=0000010, funct3=000
- **Description**: Performs ternary multiplication using shift-add algorithm

#### TDIV - Ternary Division
```
TDIV td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = ts1 / ts2 (ternary division)
- **Encoding**: funct7=0000011, funct3=000
- **Description**: Performs ternary division with remainder handling

#### TADDI - Ternary Add Immediate
```
TADDI td, ts1, imm
```
- **Format**: I-type (custom)
- **Operation**: td = ts1 + sign_extend(imm)
- **Encoding**: funct3=000
- **Description**: Adds 12-bit signed immediate to ternary register

### Ternary Logic Instructions

#### TAND - Ternary AND (Conjunction)
```
TAND td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = ts1 ∧ ts2 (ternary conjunction)
- **Encoding**: funct7=0001000, funct3=001
- **Description**: Performs ternary AND operation (minimum function)

**Truth Table**:
```
∧   | -1   0  +1
----|----------
-1  | -1  -1  -1
 0  | -1   0   0
+1  | -1   0  +1
```

#### TOR - Ternary OR (Disjunction)
```
TOR td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = ts1 ∨ ts2 (ternary disjunction)
- **Encoding**: funct7=0001001, funct3=001
- **Description**: Performs ternary OR operation (maximum function)

#### TXOR - Ternary XOR
```
TXOR td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = ts1 ⊕ ts2 (ternary exclusive or)
- **Encoding**: funct7=0001010, funct3=001
- **Description**: Performs ternary exclusive OR operation

#### TNOT - Ternary NOT (Negation)
```
TNOT td, ts1
```
- **Format**: R-type (custom)
- **Operation**: td = ¬ts1 (ternary negation)
- **Encoding**: funct7=0001011, funct3=001
- **Description**: Performs ternary negation (-ts1)

#### TCMP - Ternary Compare
```
TCMP td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = compare(ts1, ts2)
- **Encoding**: funct7=0001100, funct3=001
- **Description**: Compares two ternary values, returns -1, 0, or +1

#### TMIN - Ternary Minimum
```
TMIN td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = min(ts1, ts2)
- **Encoding**: funct7=0001101, funct3=001
- **Description**: Returns the minimum of two ternary values

### Ternary Memory Instructions

#### LTW - Load Ternary Word
```
LTW td, offset(rs1)
```
- **Format**: I-type (custom)
- **Operation**: td = M[rs1 + offset] (ternary load)
- **Encoding**: funct3=010
- **Description**: Loads a ternary word from memory

#### STW - Store Ternary Word
```
STW ts2, offset(rs1)
```
- **Format**: S-type (custom)
- **Operation**: M[rs1 + offset] = ts2 (ternary store)
- **Encoding**: funct3=010
- **Description**: Stores a ternary word to memory

#### MVB2T - Move Binary to Ternary
```
MVB2T td, rs1
```
- **Format**: R-type (custom)
- **Operation**: td = convert_binary_to_ternary(rs1)
- **Encoding**: funct7=0010000, funct3=011
- **Description**: Converts binary value to ternary representation

#### MVT2B - Move Ternary to Binary
```
MVT2B rd, ts1
```
- **Format**: R-type (custom)
- **Operation**: rd = convert_ternary_to_binary(ts1)
- **Encoding**: funct7=0010001, funct3=011
- **Description**: Converts ternary value to binary representation

---

## Neural Processing Instructions

Specialized instructions for accelerating neural network operations using ternary arithmetic.

### TDOT - Ternary Dot Product
```
TDOT td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = dot_product(ts1, ts2)
- **Encoding**: funct7=0100000, funct3=100
- **Description**: Computes dot product of two ternary vectors

**Example**:
```assembly
# Compute dot product of 8-element vectors
ltw t1, 0(x10)     # Load first vector
ltw t2, 0(x11)     # Load second vector
tdot t3, t1, t2    # Compute dot product
```

### TCONV - Ternary Convolution
```
TCONV td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = convolution(ts1, ts2)
- **Encoding**: funct7=0100001, funct3=100
- **Description**: Performs 1D convolution operation

### TACT - Ternary Activation Function
```
TACT td, ts1, imm
```
- **Format**: I-type (custom)
- **Operation**: td = activation(ts1, function_type)
- **Encoding**: funct3=100
- **Description**: Applies activation function specified by immediate

**Activation Functions**:
- **0**: Sign function (ternary sign)
- **1**: ReLU (rectified linear)
- **2**: Tanh (hyperbolic tangent)
- **3**: Step function

### TSUM - Ternary Vector Sum
```
TSUM td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = vector_sum(ts1, ts2)
- **Encoding**: funct7=0100010, funct3=100
- **Description**: Computes element-wise sum of two ternary vectors

### TMAC - Ternary Multiply-Accumulate
```
TMAC td, ts1, ts2
```
- **Format**: R-type (custom)
- **Operation**: td = td + (ts1 * ts2)
- **Encoding**: funct7=0100011, funct3=100
- **Description**: Multiply-accumulate operation for neural networks

---

## Control and Status Registers

### Ternary Mode Control Register (TMODE) - 0x7C0

| Bits | Name | Access | Description |
|------|------|--------|-------------|
| 0 | TEN | R/W | Ternary extensions enable |
| 1 | NEN | R/W | Neural unit enable |
| 2 | TAUTO | R/W | Automatic ternary conversion |
| 3 | TROUND | R/W | Ternary rounding mode |
| 7:4 | TPREC | R/W | Ternary precision setting |
| 31:8 | Reserved | R | Reserved, reads as zero |

### Ternary Status Register (TSTAT) - 0x7C1

| Bits | Name | Access | Description |
|------|------|--------|-------------|
| 0 | TOF | R/W1C | Ternary overflow flag |
| 1 | TUF | R/W1C | Ternary underflow flag |
| 2 | TIF | R/W1C | Ternary invalid operation flag |
| 3 | TZF | R/W1C | Ternary divide by zero flag |
| 7:4 | TCNT | R | Ternary operation count |
| 15:8 | NCNT | R | Neural operation count |
| 31:16 | Reserved | R | Reserved, reads as zero |

### Ternary Configuration Register (TCONF) - 0x7C2

| Bits | Name | Access | Description |
|------|------|--------|-------------|
| 3:0 | TWIDTH | R/W | Ternary word width |
| 7:4 | NWIDTH | R/W | Neural vector width |
| 11:8 | CACHESIZE | R/W | Neural cache size |
| 15:12 | PERFCNT | R/W | Performance counter enable |
| 31:16 | Reserved | R | Reserved, reads as zero |

---

## Instruction Encoding

### Standard RISC-V Formats

All ternary instructions follow RISC-V encoding conventions but use the custom-0 opcode space.

#### R-type (Register-Register)
```
31          25 24   20 19   15 14   12 11    7 6      0
┌─────────────┬───────┬───────┬───────┬───────┬────────┐
│    funct7   │  rs2  │  rs1  │funct3 │  rd   │ opcode │
└─────────────┴───────┴───────┴───────┴───────┴────────┘
```

#### I-type (Immediate)
```
31          20 19   15 14   12 11    7 6      0
┌─────────────┬───────┬───────┬───────┬────────┐
│    imm      │  rs1  │funct3 │  rd   │ opcode │
└─────────────┴───────┴───────┴───────┴────────┘
```

#### S-type (Store)
```
31    25 24   20 19   15 14   12 11    7 6      0
┌────────┬───────┬───────┬───────┬────────┬────────┐
│ imm[11:5] │  rs2  │  rs1  │funct3 │imm[4:0]│ opcode │
└────────┴───────┴───────┴───────┴────────┴────────┘
```

### Ternary Instruction Encoding Table

| Category | funct7 | funct3 | Instruction |
|----------|--------|--------|-------------|
| Arithmetic | 0000000 | 000 | TADD |
| Arithmetic | 0000001 | 000 | TSUB |
| Arithmetic | 0000010 | 000 | TMUL |
| Arithmetic | 0000011 | 000 | TDIV |
| Logic | 0001000 | 001 | TAND |
| Logic | 0001001 | 001 | TOR |
| Logic | 0001010 | 001 | TXOR |
| Logic | 0001011 | 001 | TNOT |
| Logic | 0001100 | 001 | TCMP |
| Logic | 0001101 | 001 | TMIN |
| Memory | - | 010 | LTW/STW |
| Convert | 0010000 | 011 | MVB2T |
| Convert | 0010001 | 011 | MVT2B |
| Neural | 0100000 | 100 | TDOT |
| Neural | 0100001 | 100 | TCONV |
| Neural | 0100010 | 100 | TSUM |
| Neural | 0100011 | 100 | TMAC |

---

## Assembly Syntax

### Register Naming

#### Binary Registers
- **x0-x31**: Standard RISC-V integer registers
- **x0** (zero): Always contains value 0
- **x1** (ra): Return address
- **x2** (sp): Stack pointer

#### Ternary Registers
- **t0-t31**: Ternary registers (32 trits each)
- **t0**: Always contains ternary zero (all trits = 0)
- **t1**: Temporary register
- **t2**: Temporary register

### Immediate Values

#### Ternary Immediate Syntax
```assembly
taddi t1, t2, #123    # Decimal immediate
taddi t1, t2, #0x7B   # Hexadecimal immediate
taddi t1, t2, #0b111  # Binary immediate
taddi t1, t2, #0t+-0  # Ternary immediate (+1, -1, 0)
```

#### Neural Function Codes
```assembly
tact t1, t2, #0       # Sign function
tact t1, t2, #1       # ReLU function
tact t1, t2, #2       # Tanh function
tact t1, t2, #3       # Step function
```

### Labels and Symbols

```assembly
.text
main:
    tadd t1, t2, t3     # Label for main function
    beq t1, t0, done    # Branch to done label
    
done:
    taddi t1, t0, #1    # Set result to +1
    ret                 # Return

.data
weights:
    .ternary 1, -1, 0, 1, -1    # Ternary data declaration
    
inputs:
    .ternary 0, 1, 1, -1, 0     # Input vector
```

---

## Programming Examples

### Basic Ternary Arithmetic

```assembly
# Ternary addition example
.text
main:
    # Load ternary values
    taddi t1, t0, #5      # t1 = +5 (ternary)
    taddi t2, t0, #-3     # t2 = -3 (ternary)
    
    # Perform addition
    tadd t3, t1, t2       # t3 = t1 + t2 = +2
    
    # Store result
    stw t3, result, x0    # Store to memory
    
    ret

.data
result: .word 0
```

### Neural Network Layer

```assembly
# Simple neural network layer computation
.text
neural_layer:
    # Input: x10 = input vector address
    #        x11 = weight matrix address  
    #        x12 = output vector address
    #        x13 = vector length
    
    mv x14, x0            # Initialize index
    
loop:
    # Load input and weight vectors
    ltw t1, 0(x10)        # Load input vector
    ltw t2, 0(x11)        # Load weight vector
    
    # Compute dot product
    tdot t3, t1, t2       # Dot product
    
    # Apply activation function (sign)
    tact t4, t3, #0       # Apply sign activation
    
    # Store result
    stw t4, 0(x12)        # Store output
    
    # Update pointers
    addi x10, x10, 4      # Next input
    addi x11, x11, 4      # Next weight
    addi x12, x12, 4      # Next output
    addi x14, x14, 1      # Increment index
    
    # Check loop condition
    blt x14, x13, loop    # Continue if index < length
    
    ret
```

### Ternary Convolution

```assembly
# 1D convolution with ternary data
.text
ternary_conv:
    # Input: x10 = input array
    #        x11 = kernel array
    #        x12 = output array
    #        x13 = input length
    #        x14 = kernel length
    
    mv x15, x0            # Output index
    
conv_loop:
    mv x16, x0            # Kernel index
    mv t5, t0             # Initialize accumulator
    
kernel_loop:
    # Calculate addresses
    add x17, x10, x15     # Input + output_index
    add x17, x17, x16     # + kernel_index
    add x18, x11, x16     # Kernel + kernel_index
    
    # Load values
    ltw t1, 0(x17)        # Load input
    ltw t2, 0(x18)        # Load kernel
    
    # Multiply and accumulate
    tmul t3, t1, t2       # Multiply
    tadd t5, t5, t3       # Accumulate
    
    # Next kernel element
    addi x16, x16, 4      # Next kernel index
    srli x19, x14, 2      # Kernel length in words
    blt x16, x19, kernel_loop
    
    # Store convolution result
    add x17, x12, x15     # Output address
    stw t5, 0(x17)        # Store result
    
    # Next output position
    addi x15, x15, 4      # Next output index
    sub x19, x13, x14     # Input - kernel + 1
    addi x19, x19, 4      # Convert to bytes
    blt x15, x19, conv_loop
    
    ret
```

### Ternary Matrix Multiplication

```assembly
# Ternary matrix multiplication: C = A * B
.text
ternary_matmul:
    # Input: x10 = matrix A address
    #        x11 = matrix B address
    #        x12 = matrix C address
    #        x13 = matrix dimension (N for NxN)
    
    mv x14, x0            # i = 0
    
i_loop:
    mv x15, x0            # j = 0
    
j_loop:
    mv x16, x0            # k = 0
    mv t5, t0             # sum = 0
    
k_loop:
    # Calculate A[i][k] address
    mul x17, x14, x13     # i * N
    add x17, x17, x16     # + k
    slli x17, x17, 2      # * 4 (word size)
    add x17, x10, x17     # + base address
    ltw t1, 0(x17)        # Load A[i][k]
    
    # Calculate B[k][j] address
    mul x17, x16, x13     # k * N
    add x17, x17, x15     # + j
    slli x17, x17, 2      # * 4 (word size)
    add x17, x11, x17     # + base address
    ltw t2, 0(x17)        # Load B[k][j]
    
    # Multiply and accumulate
    tmul t3, t1, t2       # A[i][k] * B[k][j]
    tadd t5, t5, t3       # sum += product
    
    # k++
    addi x16, x16, 1
    blt x16, x13, k_loop
    
    # Store C[i][j]
    mul x17, x14, x13     # i * N
    add x17, x17, x15     # + j
    slli x17, x17, 2      # * 4 (word size)
    add x17, x12, x17     # + base address
    stw t5, 0(x17)        # Store result
    
    # j++
    addi x15, x15, 1
    blt x15, x13, j_loop
    
    # i++
    addi x14, x14, 1
    blt x14, x13, i_loop
    
    ret
```

---

## Pseudo-Instructions

The assembler supports pseudo-instructions for common operations:

### Ternary Pseudo-Instructions

| Pseudo-Instruction | Expansion | Description |
|-------------------|-----------|-------------|
| `tli td, imm` | `taddi td, t0, imm` | Load ternary immediate |
| `tmv td, ts` | `tadd td, ts, t0` | Move ternary register |
| `tneg td, ts` | `tnot td, ts` | Negate ternary value |
| `tclr td` | `tadd td, t0, t0` | Clear ternary register |
| `tset td` | `taddi td, t0, #1` | Set to ternary +1 |

### Control Flow Pseudo-Instructions

| Pseudo-Instruction | Expansion | Description |
|-------------------|-----------|-------------|
| `teq ts1, ts2, label` | `tcmp t31, ts1, ts2; beq t31, t0, label` | Branch if ternary equal |
| `tne ts1, ts2, label` | `tcmp t31, ts1, ts2; bne t31, t0, label` | Branch if ternary not equal |
| `tlt ts1, ts2, label` | `tcmp t31, ts1, ts2; bltz t31, label` | Branch if ternary less than |
| `tgt ts1, ts2, label` | `tcmp t31, ts1, ts2; bgtz t31, label` | Branch if ternary greater than |

---

**Document Information**
- **Version**: 1.0  
- **Date**: September 2025
- **Author**: MHX Neural Research Team
- **Status**: Complete
- **Related**: MHX Ternary RISC-V Technical Documentation

---

*For the complete processor documentation, see the MHX Ternary RISC-V Technical Documentation.*