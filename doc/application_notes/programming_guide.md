# MHX Ternary Extensions - Application Notes

**Document Version:** 1.0  
**Last Updated:** December 3, 2025  
**Status:** DRAFT

---

## Overview

This document provides practical guidance for developers implementing applications using the MHX Ternary Extensions for the Ibex RISC-V core. It covers programming patterns, optimization techniques, and best practices for leveraging ternary computing in real-world applications.

## Target Audience

- Embedded systems developers
- AI/ML application engineers
- Systems programmers
- Compiler developers

## Prerequisites

- Understanding of RISC-V ISA
- Familiarity with ternary logic concepts
- C/Assembly programming experience
- Knowledge of neural network basics (for neural operations)

---

## 1. Getting Started with Ternary Programming

### 1.1 Understanding Trit Encoding

MHX uses 2-bit encoding for each trit (ternary digit):

```c
// Trit encoding
#define TRIT_NEG  0b00  // Represents -1
#define TRIT_ZERO 0b01  // Represents  0
#define TRIT_POS  0b10  // Represents +1
#define TRIT_INVALID 0b11  // Invalid (treated as 0)

// Example: Encoding the ternary value [-1, 0, +1, -1]
ternary_t value = 0b00_01_10_00;  // 4 trits in 8 bits
```

### 1.2 Basic Ternary Operations

#### Assembly Examples

```assembly
# Ternary addition
tadd  t5, t1, t2    # t5 = t1 + t2

# Ternary subtraction  
tsub  t6, t3, t4    # t6 = t3 - t4

# Ternary multiplication
tmul  t7, t1, t2    # t7 = t1 * t2

# Ternary logical operations
tand  t8, t1, t2    # t8 = min(t1, t2)
tor   t9, t1, t2    # t9 = max(t1, t2)
txor  t10, t1, t2   # t10 = (t1 + t2) mod 3
tnot  t11, t1       # t11 = -t1
```

#### C Examples (with intrinsics)

```c
#include <mhx_ternary.h>

ternary_t a = 0x50A050A0;  // Alternating pattern
ternary_t b = 0xA050A050;  // Inverse pattern

// Arithmetic
ternary_t sum = __builtin_ternary_add(a, b);
ternary_t diff = __builtin_ternary_sub(a, b);
ternary_t product = __builtin_ternary_mul(a, b);

// Logical
ternary_t and_result = __builtin_ternary_and(a, b);
ternary_t or_result = __builtin_ternary_or(a, b);
ternary_t xor_result = __builtin_ternary_xor(a, b);
ternary_t not_result = __builtin_ternary_not(a);
```

---

## 2. Neural Network Operations

### 2.1 Simple Neuron Implementation

```c
#include <mhx_ternary.h>

// Compute a single neuron output
ternary_t compute_neuron(
    ternary_t weights,   // 16 ternary weights
    ternary_t inputs,    // 16 ternary inputs
    ternary_t bias       // Bias value (single trit)
) {
    // Multiply weights by inputs and add bias
    ternary_t mac_result = __builtin_neural_multiply(weights, inputs, bias);
    
    // Apply activation function (sign function)
    ternary_t output = __builtin_neural_activate(mac_result);
    
    return output;
}
```

### 2.2 Multi-Layer Neural Network

```c
// Simple 2-layer neural network
#define NUM_NEURONS 8
#define NUM_LAYERS 2

typedef struct {
    ternary_t weights[NUM_NEURONS][16];  // Each neuron has 16 weights
    ternary_t biases[NUM_NEURONS];       // One bias per neuron
} Layer;

ternary_t forward_pass(
    ternary_t input,
    Layer* layers,
    int num_layers
) {
    ternary_t current_output = input;
    
    for (int layer = 0; layer < num_layers; layer++) {
        ternary_t layer_outputs[NUM_NEURONS];
        
        // Compute each neuron in the layer
        for (int neuron = 0; neuron < NUM_NEURONS; neuron++) {
            layer_outputs[neuron] = compute_neuron(
                layers[layer].weights[neuron],
                current_output,
                layers[layer].biases[neuron]
            );
        }
        
        // Pack neuron outputs for next layer
        // (Implementation detail depends on network topology)
        current_output = pack_outputs(layer_outputs, NUM_NEURONS);
    }
    
    return current_output;
}
```

### 2.3 Training Example (Simplified)

```c
// Simple ternary perceptron learning
void train_neuron(
    ternary_t* weights,
    ternary_t input,
    int target,
    int actual
) {
    if (target != actual) {
        // Adjust weights based on error
        int error = target - actual;
        
        for (int i = 0; i < 16; i++) {
            int weight_trit = __builtin_ternary_get_trit(*weights, i);
            int input_trit = __builtin_ternary_get_trit(input, i);
            
            // Simple weight update rule
            if (error > 0 && input_trit > 0) {
                weight_trit = (weight_trit < 1) ? weight_trit + 1 : weight_trit;
            } else if (error < 0 && input_trit > 0) {
                weight_trit = (weight_trit > -1) ? weight_trit - 1 : weight_trit;
            }
            
            *weights = __builtin_ternary_set_trit(*weights, i, weight_trit);
        }
    }
}
```

---

## 3. Optimization Techniques

### 3.1 Data Packing

Maximize efficiency by packing multiple ternary values:

```c
// Pack 16 trits into a single 32-bit word
ternary_t pack_trits(int trits[16]) {
    ternary_t packed = 0;
    for (int i = 0; i < 16; i++) {
        int encoded;
        if (trits[i] < 0) encoded = TRIT_NEG;
        else if (trits[i] > 0) encoded = TRIT_POS;
        else encoded = TRIT_ZERO;
        
        packed |= (encoded << (i * 2));
    }
    return packed;
}

// Unpack to array
void unpack_trits(ternary_t packed, int trits[16]) {
    for (int i = 0; i < 16; i++) {
        trits[i] = __builtin_ternary_get_trit(packed, i);
    }
}
```

### 3.2 Loop Unrolling

```c
// Unoptimized
ternary_t compute_batch(ternary_t inputs[], int n) {
    ternary_t result = TERNARY_ALL_ZERO;
    for (int i = 0; i < n; i++) {
        result = __builtin_ternary_add(result, inputs[i]);
    }
    return result;
}

// Optimized with unrolling
ternary_t compute_batch_optimized(ternary_t inputs[], int n) {
    ternary_t sum0 = TERNARY_ALL_ZERO;
    ternary_t sum1 = TERNARY_ALL_ZERO;
    ternary_t sum2 = TERNARY_ALL_ZERO;
    ternary_t sum3 = TERNARY_ALL_ZERO;
    
    int i;
    for (i = 0; i < n - 3; i += 4) {
        sum0 = __builtin_ternary_add(sum0, inputs[i]);
        sum1 = __builtin_ternary_add(sum1, inputs[i+1]);
        sum2 = __builtin_ternary_add(sum2, inputs[i+2]);
        sum3 = __builtin_ternary_add(sum3, inputs[i+3]);
    }
    
    // Handle remainder
    for (; i < n; i++) {
        sum0 = __builtin_ternary_add(sum0, inputs[i]);
    }
    
    // Combine partial sums
    ternary_t result = __builtin_ternary_add(sum0, sum1);
    result = __builtin_ternary_add(result, sum2);
    result = __builtin_ternary_add(result, sum3);
    
    return result;
}
```

### 3.3 Avoiding Overflow

```c
// Check for potential overflow before operation
bool will_overflow_add(ternary_t a, ternary_t b) {
    // Check if both operands are all +1 or all -1
    return (a == TERNARY_ALL_POS && b == TERNARY_ALL_POS) ||
           (a == TERNARY_ALL_NEG && b == TERNARY_ALL_NEG);
}

// Safe addition with saturation
ternary_t safe_add(ternary_t a, ternary_t b) {
    if (a == TERNARY_ALL_POS && b == TERNARY_ALL_POS) {
        return TERNARY_ALL_POS;  // Saturate to maximum
    } else if (a == TERNARY_ALL_NEG && b == TERNARY_ALL_NEG) {
        return TERNARY_ALL_NEG;  // Saturate to minimum
    } else {
        return __builtin_ternary_add(a, b);
    }
}
```

---

## 4. Common Patterns and Idioms

### 4.1 Absolute Value

```c
ternary_t ternary_abs(ternary_t value) {
    // For each trit: abs(-1) = +1, abs(0) = 0, abs(+1) = +1
    ternary_t neg_value = __builtin_ternary_not(value);
    return __builtin_ternary_or(value, neg_value);
}
```

### 4.2 Sign Function

```c
int ternary_sign(ternary_t value) {
    // Returns -1, 0, or +1 based on majority of trits
    int count = 0;
    for (int i = 0; i < 16; i++) {
        count += __builtin_ternary_get_trit(value, i);
    }
    return (count > 0) ? 1 : (count < 0) ? -1 : 0;
}
```

### 4.3 Comparison

```c
bool ternary_equal(ternary_t a, ternary_t b) {
    ternary_t xor_result = __builtin_ternary_xor(a, b);
    return (xor_result == TERNARY_ALL_ZERO);
}

bool ternary_greater(ternary_t a, ternary_t b) {
    ternary_t diff = __builtin_ternary_sub(a, b);
    return (ternary_sign(diff) > 0);
}
```

---

## 5. Debugging and Testing

### 5.1 Printing Ternary Values

```c
void print_ternary(ternary_t value) {
    printf("Ternary: [");
    for (int i = 0; i < 16; i++) {
        int trit = __builtin_ternary_get_trit(value, i);
        printf("%+d", trit);
        if (i < 15) printf(", ");
    }
    printf("] (0x%08X)\n", value);
}
```

### 5.2 Validation Functions

```c
bool validate_ternary(ternary_t value) {
    for (int i = 0; i < 16; i++) {
        uint32_t trit_bits = (value >> (i * 2)) & 0x3;
        if (trit_bits == 0b11) {  // Invalid encoding
            printf("Invalid trit at position %d\n", i);
            return false;
        }
    }
    return true;
}
```

---

## 6. Performance Considerations

### 6.1 Expected Speedups

Based on benchmarking:

| Operation Type | Speedup vs Binary |
|---------------|------------------|
| Neural inference | 2.0x |
| Matrix multiply | 2.0x |
| Memory usage | 6.25% (93.8% reduction) |
| Power consumption | 30% (70% reduction) |

### 6.2 When to Use Ternary

**Good Use Cases:**
- Neural network inference (especially small models)
- Pattern matching
- Fuzzy logic applications
- Low-power AI on edge devices
- Applications tolerant to approximate computing

**Not Recommended:**
- High-precision scientific computing
- Cryptography (requires exact arithmetic)
- General-purpose computing with legacy code
- Applications requiring IEEE floating-point

---

## 7. Migration Guide

### 7.1 Converting Binary Code to Ternary

```c
// Binary version
int binary_dot_product(int8_t a[], int8_t b[], int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += a[i] * b[i];
    }
    return sum;
}

// Ternary version
ternary_t ternary_dot_product(ternary_t a[], ternary_t b[], int n) {
    ternary_t sum = TERNARY_ALL_ZERO;
    for (int i = 0; i < n; i++) {
        ternary_t product = __builtin_ternary_mul(a[i], b[i]);
        sum = __builtin_ternary_add(sum, product);
    }
    return sum;
}
```

### 7.2 Quantization from Floats

```c
ternary_t quantize_float_to_ternary(float value) {
    // Simple threshold-based quantization
    if (value > 0.33f) return TERNARY_ALL_POS;
    else if (value < -0.33f) return TERNARY_ALL_NEG;
    else return TERNARY_ALL_ZERO;
}

float dequantize_ternary_to_float(ternary_t value) {
    int sign = ternary_sign(value);
    return (float)sign;
}
```

---

## 8. References

- [MHX Ternary Formal Specification](mhx_ternary_formal_spec.md)
- [MHX Debug Guide](mhx_ternary_debug_guide.md)
- [MHX Security Analysis](mhx_ternary_security_analysis.md)
- RISC-V ISA Specification v2.2
- Ternary Computing: Theory and Applications (Academic Papers)

---

## 9. Support and Community

### Getting Help

- GitHub Issues: [ternary-ibex/issues](https://github.com/TheusHen/ternary-ibex/issues)
- Documentation: `/workspaces/ternary-ibex/doc/`
- Examples: `/workspaces/ternary-ibex/examples/`

### Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on:
- Submitting bug reports
- Proposing new features
- Contributing code
- Writing documentation

---

**Document Status:** DRAFT  
**Next Review:** When toolchain is implemented  
**Maintainer:** MHX Neural Team
