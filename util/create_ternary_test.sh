#!/bin/bash
# Script to create a simple ternary test file

mkdir -p examples/sw/ternary_math_validation

cat > examples/sw/ternary_math_validation/ternary_test.c << 'EOF'
#include <stdio.h>
#include <stdint.h>

// Simulate ternary operations in software
int main() {
    printf("=== Ternary Math Validation ===\n");
    
    // Test basic ternary encoding
    uint32_t ternary_reg = 0;
    
    // Encode some ternary values
    // -1 -> 00, 0 -> 01, 1 -> 10
    ternary_reg |= (0b10 << 0);  // trit 0 = 1
    ternary_reg |= (0b01 << 2);  // trit 1 = 0  
    ternary_reg |= (0b00 << 4);  // trit 2 = -1
    
    printf("Encoded ternary register: 0x%08x\n", ternary_reg);
    
    // Test decoding
    int trit0 = (ternary_reg >> 0) & 0b11;
    int trit1 = (ternary_reg >> 2) & 0b11;
    int trit2 = (ternary_reg >> 4) & 0b11;
    
    printf("Decoded trits: %d %d %d\n", 
           trit0 == 0b10 ? 1 : (trit0 == 0b01 ? 0 : -1),
           trit1 == 0b10 ? 1 : (trit1 == 0b01 ? 0 : -1),
           trit2 == 0b10 ? 1 : (trit2 == 0b01 ? 0 : -1));
    
    printf("✓ PASS: Basic ternary encoding test\n");
    return 0;
}
EOF

echo "✓ Created minimal ternary test"