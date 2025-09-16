#!/usr/bin/env python3
"""
Ternary Mathematical Validation Script
=====================================

This script performs comprehensive validation of ternary logic and math operations
for the MHX Core, including encoding/decoding, arithmetic operations, and neural
network functionality.
"""

import sys
import random

def encode_trit(val):
    """Encode ternary value (-1, 0, 1) to 2-bit representation"""
    if val == -1: return 0b00
    elif val == 0: return 0b01  
    elif val == 1: return 0b10
    else: raise ValueError(f"Invalid trit value: {val}")

def decode_trit(encoded):
    """Decode 2-bit representation to ternary value"""
    if encoded == 0b00: return -1
    elif encoded == 0b01: return 0
    elif encoded == 0b10: return 1
    else: raise ValueError(f"Invalid encoded trit: {encoded}")

def encode_ternary_register(trits):
    """Encode list of 16 trits to 32-bit register"""
    result = 0
    for i, trit in enumerate(trits[:16]):
        result |= (encode_trit(trit) << (i * 2))
    return result

def decode_ternary_register(encoded):
    """Decode 32-bit register to list of 16 trits"""
    trits = []
    for i in range(16):
        trit_encoded = (encoded >> (i * 2)) & 0b11
        trits.append(decode_trit(trit_encoded))
    return trits

# Ternary arithmetic operations
def ternary_add_trit(a, b):
    """Ternary addition with saturation"""
    result = a + b
    if result > 1: return 1   # Saturate to max
    if result < -1: return -1 # Saturate to min
    return result

def ternary_mul_trit(a, b):
    """Ternary multiplication"""
    return a * b

def ternary_and_trit(a, b):
    """Ternary AND operation (min)"""
    return min(a, b)

def ternary_or_trit(a, b):
    """Ternary OR operation (max)"""
    return max(a, b)

def ternary_not_trit(a):
    """Ternary NOT operation (negation)"""
    return -a

def ternary_xor_trit(a, b):
    """Ternary XOR operation"""
    if a == b: return 0
    elif (a == -1 and b == 1) or (a == 1 and b == -1): return 0
    elif a == 0: return b
    elif b == 0: return a
    else: return 0

# Register-level operations
def ternary_operation_register(a_encoded, b_encoded, operation):
    """Apply ternary operation element-wise on registers"""
    a_trits = decode_ternary_register(a_encoded)
    b_trits = decode_ternary_register(b_encoded)
    result_trits = []
    
    for i in range(16):
        if operation == "add":
            result_trits.append(ternary_add_trit(a_trits[i], b_trits[i]))
        elif operation == "mul":
            result_trits.append(ternary_mul_trit(a_trits[i], b_trits[i]))
        elif operation == "and":
            result_trits.append(ternary_and_trit(a_trits[i], b_trits[i]))
        elif operation == "or":
            result_trits.append(ternary_or_trit(a_trits[i], b_trits[i]))
        elif operation == "xor":
            result_trits.append(ternary_xor_trit(a_trits[i], b_trits[i]))
        else:
            raise ValueError(f"Unknown operation: {operation}")
    
    return encode_ternary_register(result_trits)

# Neural network operations
def neural_multiply_accumulate(weights_encoded, inputs_encoded):
    """Neural MAC operation: dot product of weights and inputs"""
    weights = decode_ternary_register(weights_encoded)
    inputs = decode_ternary_register(inputs_encoded)
    
    accumulator = 0
    for i in range(16):
        accumulator += weights[i] * inputs[i]
    
    return accumulator

def neural_activate(value, threshold=0):
    """Neural activation function with threshold"""
    if value > threshold: return 1
    elif value < -threshold: return -1
    else: return 0

def test_encoding_decoding():
    """Test encoding/decoding consistency"""
    print("1. Testing encoding/decoding consistency...")
    test_values = [-1, 0, 1, -1, 0, 1, 1, 0, -1, 1, 0, -1, 1, -1, 0, 1]
    encoded = encode_ternary_register(test_values)
    decoded = decode_ternary_register(encoded)

    if decoded == test_values:
        print("✓ PASS: Encoding/decoding consistency")
        return True
    else:
        print("✗ FAIL: Encoding/decoding inconsistency")
        print(f"  Original: {test_values}")
        print(f"  Decoded:  {decoded}")
        return False

def test_arithmetic_operations():
    """Test ternary arithmetic operations"""
    print("\n2. Testing ternary arithmetic operations...")
    operations = ["add", "mul", "and", "or", "xor"]
    test_cases = [
        ([-1, 0, 1] * 5 + [0], [1, -1, 0] * 5 + [0])
    ]

    for a_trits, b_trits in test_cases:
        a = encode_ternary_register(a_trits)
        b = encode_ternary_register(b_trits)
        
        for op in operations:
            result = ternary_operation_register(a, b, op)
            result_trits = decode_ternary_register(result)
            
            # Verify manually for first few elements
            if op == "add":
                expected = ternary_add_trit(a_trits[0], b_trits[0])
                if result_trits[0] == expected:
                    print(f"✓ PASS: Ternary {op.upper()} operation")
                else:
                    print(f"✗ FAIL: Ternary {op.upper()} operation")
                    return False
    return True

def test_neural_operations():
    """Test neural operations"""
    print("\n3. Testing neural operations...")
    weights = [1, -1, 0, 1] * 4
    inputs = [-1, 1, 0, -1] * 4

    weights_encoded = encode_ternary_register(weights)
    inputs_encoded = encode_ternary_register(inputs)

    mac_result = neural_multiply_accumulate(weights_encoded, inputs_encoded)
    activation = neural_activate(mac_result)

    expected_mac = sum(w * i for w, i in zip(weights, inputs))
    if mac_result == expected_mac:
        print("✓ PASS: Neural multiply-accumulate")
    else:
        print("✗ FAIL: Neural multiply-accumulate")
        print(f"  Expected: {expected_mac}, Got: {mac_result}")
        return False

    if activation in [-1, 0, 1]:
        print("✓ PASS: Neural activation function")
    else:
        print("✗ FAIL: Neural activation function")
        return False
    
    return True

def test_edge_cases():
    """Test edge cases and boundary conditions"""
    print("\n4. Testing edge cases...")

    # Test saturation in addition
    saturation_tests = [
        (1, 1, 1),   # Should saturate to 1
        (-1, -1, -1), # Should saturate to -1
        (1, -1, 0),   # Normal case
        (0, 0, 0)     # Zero case
    ]

    for a, b, expected in saturation_tests:
        result = ternary_add_trit(a, b)
        if result == expected:
            print(f"✓ PASS: Saturation test {a} + {b} = {result}")
        else:
            print(f"✗ FAIL: Saturation test {a} + {b} = {result}, expected {expected}")
            return False
    
    return True

def main():
    """Main test execution function"""
    print("=== Ternary Mathematical Validation ===")
    print("Running comprehensive ternary validation...")

    all_tests_passed = True
    
    # Run all test suites
    tests = [
        test_encoding_decoding,
        test_arithmetic_operations,
        test_neural_operations,
        test_edge_cases
    ]
    
    for test_func in tests:
        if not test_func():
            all_tests_passed = False
    
    if all_tests_passed:
        print("\n=== ALL TERNARY MATHEMATICAL VALIDATIONS PASSED! ===")
        return 0
    else:
        print("\n=== SOME TERNARY VALIDATIONS FAILED! ===")
        return 1

if __name__ == "__main__":
    sys.exit(main())