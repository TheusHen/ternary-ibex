# MHX Ternary RISC-V API Documentation

## Table of Contents

1. [Overview](#overview)
2. [C/C++ API](#cc-api)
3. [Python API](#python-api)
4. [Assembly Interface](#assembly-interface)
5. [Neural Network Library](#neural-network-library)
6. [Performance Profiling](#performance-profiling)
7. [Error Handling](#error-handling)
8. [Examples](#examples)

---

## Overview

The MHX Ternary RISC-V API provides high-level programming interfaces for ternary arithmetic, neural processing, and performance optimization. The API is designed to be intuitive for developers familiar with standard arithmetic while providing access to advanced ternary features.

### API Layers

```
┌─────────────────────────────────────┐
│        Application Layer            │
├─────────────────────────────────────┤
│     High-Level APIs (Python/C++)   │
├─────────────────────────────────────┤
│         C Runtime Library          │
├─────────────────────────────────────┤
│      Assembly Interface             │
├─────────────────────────────────────┤
│     Hardware Instructions          │
└─────────────────────────────────────┘
```

### Key Features

- **Native Ternary Types**: Built-in support for ternary arithmetic
- **Neural Acceleration**: Hardware-accelerated neural network operations
- **Performance Profiling**: Built-in timing and energy measurement
- **Memory Management**: Optimized memory allocation for ternary data
- **Error Handling**: Comprehensive exception and error reporting

---

## C/C++ API

### Core Types

#### Ternary Data Types

```c
#include <ternary.h>

// Basic ternary type
typedef enum {
    TERNARY_NEG = -1,    // False/Low state
    TERNARY_ZERO = 0,    // Neutral/Unknown state  
    TERNARY_POS = 1      // True/High state
} ternary_t;

// Ternary word (32 trits packed in 64 bits)
typedef struct {
    uint64_t data;       // Packed ternary data
    uint8_t width;       // Number of valid trits
} ternary_word_t;

// Ternary vector
typedef struct {
    ternary_word_t *data;
    size_t length;
    size_t capacity;
} ternary_vector_t;

// Ternary matrix
typedef struct {
    ternary_word_t *data;
    size_t rows;
    size_t cols;
    size_t stride;
} ternary_matrix_t;
```

#### Neural Network Types

```c
// Neural layer configuration
typedef struct {
    size_t input_size;
    size_t output_size;
    ternary_t *weights;
    ternary_t *biases;
    activation_func_t activation;
} neural_layer_t;

// Activation functions
typedef enum {
    ACTIVATION_SIGN = 0,     // Ternary sign function
    ACTIVATION_RELU = 1,     // ReLU activation
    ACTIVATION_TANH = 2,     // Hyperbolic tangent
    ACTIVATION_STEP = 3      // Step function
} activation_func_t;

// Neural network
typedef struct {
    neural_layer_t *layers;
    size_t num_layers;
    size_t input_size;
    size_t output_size;
} neural_network_t;
```

### Basic Ternary Operations

#### Arithmetic Functions

```c
// Basic arithmetic operations
ternary_t ternary_add(ternary_t a, ternary_t b);
ternary_t ternary_sub(ternary_t a, ternary_t b);
ternary_t ternary_mul(ternary_t a, ternary_t b);
ternary_t ternary_div(ternary_t a, ternary_t b);

// Example usage
ternary_t a = TERNARY_POS;
ternary_t b = TERNARY_NEG;
ternary_t result = ternary_add(a, b);  // Result: TERNARY_ZERO
```

#### Logic Functions

```c
// Logic operations
ternary_t ternary_and(ternary_t a, ternary_t b);
ternary_t ternary_or(ternary_t a, ternary_t b);
ternary_t ternary_xor(ternary_t a, ternary_t b);
ternary_t ternary_not(ternary_t a);

// Comparison
int ternary_compare(ternary_t a, ternary_t b);
ternary_t ternary_min(ternary_t a, ternary_t b);
ternary_t ternary_max(ternary_t a, ternary_t b);

// Example usage
ternary_t a = TERNARY_POS;
ternary_t b = TERNARY_ZERO;
ternary_t and_result = ternary_and(a, b);  // Result: TERNARY_ZERO
ternary_t or_result = ternary_or(a, b);    // Result: TERNARY_POS
```

### Ternary Word Operations

#### Creation and Conversion

```c
// Create ternary word from array
ternary_word_t ternary_word_from_array(const ternary_t *trits, size_t length);

// Convert ternary word to array
void ternary_word_to_array(const ternary_word_t *word, ternary_t *trits, size_t max_length);

// Convert from/to binary
ternary_word_t binary_to_ternary(int32_t value);
int32_t ternary_to_binary(const ternary_word_t *word);

// Example usage
ternary_t trits[] = {TERNARY_POS, TERNARY_ZERO, TERNARY_NEG, TERNARY_POS};
ternary_word_t word = ternary_word_from_array(trits, 4);

int32_t binary_val = 42;
ternary_word_t ternary_val = binary_to_ternary(binary_val);
```

#### Word Arithmetic

```c
// Word-level operations
ternary_word_t ternary_word_add(const ternary_word_t *a, const ternary_word_t *b);
ternary_word_t ternary_word_sub(const ternary_word_t *a, const ternary_word_t *b);
ternary_word_t ternary_word_mul(const ternary_word_t *a, const ternary_word_t *b);

// Bitwise operations
ternary_word_t ternary_word_and(const ternary_word_t *a, const ternary_word_t *b);
ternary_word_t ternary_word_or(const ternary_word_t *a, const ternary_word_t *b);
ternary_word_t ternary_word_xor(const ternary_word_t *a, const ternary_word_t *b);
ternary_word_t ternary_word_not(const ternary_word_t *a);

// Example usage
ternary_word_t a = ternary_word_from_array(trits_a, 8);
ternary_word_t b = ternary_word_from_array(trits_b, 8);
ternary_word_t sum = ternary_word_add(&a, &b);
```

### Vector and Matrix Operations

#### Vector Operations

```c
// Vector creation and management
ternary_vector_t* ternary_vector_create(size_t length);
void ternary_vector_destroy(ternary_vector_t *vector);
void ternary_vector_resize(ternary_vector_t *vector, size_t new_length);

// Vector arithmetic
ternary_vector_t* ternary_vector_add(const ternary_vector_t *a, const ternary_vector_t *b);
ternary_vector_t* ternary_vector_sub(const ternary_vector_t *a, const ternary_vector_t *b);
ternary_t ternary_vector_dot(const ternary_vector_t *a, const ternary_vector_t *b);

// Element access
ternary_t ternary_vector_get(const ternary_vector_t *vector, size_t index);
void ternary_vector_set(ternary_vector_t *vector, size_t index, ternary_t value);

// Example usage
ternary_vector_t *vec_a = ternary_vector_create(10);
ternary_vector_t *vec_b = ternary_vector_create(10);

// Set some values
ternary_vector_set(vec_a, 0, TERNARY_POS);
ternary_vector_set(vec_b, 0, TERNARY_NEG);

// Compute dot product
ternary_t dot_product = ternary_vector_dot(vec_a, vec_b);

// Clean up
ternary_vector_destroy(vec_a);
ternary_vector_destroy(vec_b);
```

#### Matrix Operations

```c
// Matrix creation and management
ternary_matrix_t* ternary_matrix_create(size_t rows, size_t cols);
void ternary_matrix_destroy(ternary_matrix_t *matrix);

// Matrix arithmetic
ternary_matrix_t* ternary_matrix_add(const ternary_matrix_t *a, const ternary_matrix_t *b);
ternary_matrix_t* ternary_matrix_mul(const ternary_matrix_t *a, const ternary_matrix_t *b);
ternary_vector_t* ternary_matrix_vector_mul(const ternary_matrix_t *matrix, const ternary_vector_t *vector);

// Element access
ternary_t ternary_matrix_get(const ternary_matrix_t *matrix, size_t row, size_t col);
void ternary_matrix_set(ternary_matrix_t *matrix, size_t row, size_t col, ternary_t value);

// Example usage
ternary_matrix_t *weights = ternary_matrix_create(10, 8);
ternary_vector_t *input = ternary_vector_create(8);
ternary_vector_t *output = ternary_matrix_vector_mul(weights, input);
```

### Neural Network API

#### Layer Operations

```c
// Create neural layer
neural_layer_t* neural_layer_create(size_t input_size, size_t output_size, activation_func_t activation);
void neural_layer_destroy(neural_layer_t *layer);

// Forward pass
ternary_vector_t* neural_layer_forward(const neural_layer_t *layer, const ternary_vector_t *input);

// Set weights and biases
void neural_layer_set_weights(neural_layer_t *layer, const ternary_matrix_t *weights);
void neural_layer_set_biases(neural_layer_t *layer, const ternary_vector_t *biases);

// Example usage
neural_layer_t *layer = neural_layer_create(784, 128, ACTIVATION_SIGN);

// Set random ternary weights
ternary_matrix_t *weights = ternary_matrix_create(128, 784);
// ... initialize weights ...
neural_layer_set_weights(layer, weights);

// Forward pass
ternary_vector_t *input = /* load input data */;
ternary_vector_t *output = neural_layer_forward(layer, input);
```

#### Network Operations

```c
// Create neural network
neural_network_t* neural_network_create(size_t input_size, size_t output_size);
void neural_network_destroy(neural_network_t *network);

// Add layers
void neural_network_add_layer(neural_network_t *network, neural_layer_t *layer);

// Forward pass through entire network
ternary_vector_t* neural_network_forward(const neural_network_t *network, const ternary_vector_t *input);

// Load/save network
int neural_network_load(neural_network_t *network, const char *filename);
int neural_network_save(const neural_network_t *network, const char *filename);

// Example usage
neural_network_t *network = neural_network_create(784, 10);

// Add layers
neural_layer_t *layer1 = neural_layer_create(784, 128, ACTIVATION_SIGN);
neural_layer_t *layer2 = neural_layer_create(128, 64, ACTIVATION_SIGN);
neural_layer_t *layer3 = neural_layer_create(64, 10, ACTIVATION_SIGN);

neural_network_add_layer(network, layer1);
neural_network_add_layer(network, layer2);
neural_network_add_layer(network, layer3);

// Inference
ternary_vector_t *input = /* load input image */;
ternary_vector_t *prediction = neural_network_forward(network, input);
```

### Performance and Profiling

#### Performance Counters

```c
// Performance measurement
typedef struct {
    uint64_t cycles;
    uint64_t instructions;
    uint64_t ternary_ops;
    uint64_t neural_ops;
    double energy_uj;
} performance_stats_t;

// Start/stop performance measurement
void performance_start_measurement(void);
performance_stats_t performance_stop_measurement(void);

// Get current statistics
performance_stats_t performance_get_stats(void);
void performance_reset_stats(void);

// Example usage
performance_start_measurement();

// ... perform ternary operations ...

performance_stats_t stats = performance_stop_measurement();
printf("Cycles: %lu, Ternary ops: %lu, Energy: %.2f uJ\\n", 
       stats.cycles, stats.ternary_ops, stats.energy_uj);
```

#### Memory Management

```c
// Ternary-optimized memory allocation
void* ternary_malloc(size_t size);
void* ternary_calloc(size_t num, size_t size);
void* ternary_realloc(void *ptr, size_t size);
void ternary_free(void *ptr);

// Memory alignment for performance
void* ternary_aligned_alloc(size_t alignment, size_t size);

// Memory statistics
typedef struct {
    size_t total_allocated;
    size_t total_freed;
    size_t current_usage;
    size_t peak_usage;
} memory_stats_t;

memory_stats_t ternary_memory_stats(void);
```

---

## Python API

### Installation

```bash
pip install mhx-ternary-riscv
```

### Basic Usage

```python
import ternary_riscv as tr
import numpy as np

# Create ternary values
a = tr.Ternary(1)   # +1
b = tr.Ternary(-1)  # -1
c = tr.Ternary(0)   # 0

# Basic operations
result = a + b      # Ternary addition
result = a & b      # Ternary AND
result = ~a         # Ternary NOT
```

### Ternary Class

```python
class Ternary:
    """Ternary number class supporting -1, 0, +1 values"""
    
    def __init__(self, value):
        """Initialize ternary value from int, float, or string"""
        
    def __add__(self, other):
        """Ternary addition"""
        
    def __sub__(self, other):
        """Ternary subtraction"""
        
    def __mul__(self, other):
        """Ternary multiplication"""
        
    def __and__(self, other):
        """Ternary AND (conjunction)"""
        
    def __or__(self, other):
        """Ternary OR (disjunction)"""
        
    def __xor__(self, other):
        """Ternary XOR"""
        
    def __invert__(self):
        """Ternary NOT (negation)"""
        
    def __str__(self):
        """String representation"""
        
    def __repr__(self):
        """Detailed representation"""

# Example usage
t1 = tr.Ternary(1)
t2 = tr.Ternary(-1)
t3 = t1 + t2        # Ternary(0)
t4 = t1 & t2        # Ternary(-1)
t5 = ~t1            # Ternary(-1)
```

### TernaryArray Class

```python
class TernaryArray:
    """NumPy-like array for ternary data"""
    
    def __init__(self, data, shape=None):
        """Create ternary array from list or numpy array"""
        
    def __getitem__(self, key):
        """Element access"""
        
    def __setitem__(self, key, value):
        """Element assignment"""
        
    def dot(self, other):
        """Dot product with hardware acceleration"""
        
    def reshape(self, new_shape):
        """Reshape array"""
        
    def sum(self, axis=None):
        """Sum along axis"""
        
    @property
    def shape(self):
        """Array shape"""
        
    @property
    def size(self):
        """Total number of elements"""

# Example usage
data = [[1, -1, 0], [0, 1, -1]]
arr = tr.TernaryArray(data)
print(arr.shape)      # (2, 3)

# Arithmetic operations
arr2 = tr.TernaryArray([[1, 1, 1], [-1, -1, -1]])
result = arr + arr2

# Dot product (hardware accelerated)
vec1 = tr.TernaryArray([1, -1, 0, 1])
vec2 = tr.TernaryArray([-1, 1, 0, -1])
dot_result = vec1.dot(vec2)
```

### Neural Network Module

```python
class TernaryNeuralNetwork:
    """Ternary neural network with hardware acceleration"""
    
    def __init__(self, input_size, hidden_sizes, output_size):
        """Initialize network architecture"""
        
    def add_layer(self, size, activation='sign'):
        """Add a layer to the network"""
        
    def forward(self, input_data):
        """Forward pass through network"""
        
    def predict(self, input_data):
        """Make predictions"""
        
    def save(self, filename):
        """Save network to file"""
        
    def load(self, filename):
        """Load network from file"""
        
    def summary(self):
        """Print network summary"""

# Example usage
network = tr.TernaryNeuralNetwork(input_size=784, 
                                  hidden_sizes=[128, 64], 
                                  output_size=10)

# Forward pass
input_data = tr.TernaryArray(np.random.choice([-1, 0, 1], size=784))
output = network.forward(input_data)

# Training (if supported)
network.train(train_data, train_labels, epochs=10)
```

### Performance Profiling

```python
class PerformanceProfiler:
    """Hardware performance profiling"""
    
    def __enter__(self):
        """Start profiling context"""
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Stop profiling and return stats"""
        
    def get_stats(self):
        """Get current performance statistics"""

# Example usage
with tr.PerformanceProfiler() as profiler:
    # Perform ternary operations
    result = large_ternary_array.dot(weights)
    
stats = profiler.get_stats()
print(f"Cycles: {stats.cycles}")
print(f"Ternary operations: {stats.ternary_ops}")
print(f"Energy: {stats.energy_uj} µJ")
```

---

## Assembly Interface

### Direct Assembly Programming

#### Function Calling Convention

```assembly
# Ternary function calling convention
# Arguments in t1-t8 (ternary registers)
# Return value in t1
# Caller-saved: t1-t15
# Callee-saved: t16-t31

.text
.global ternary_add_func
ternary_add_func:
    # Input: t1 = a, t2 = b
    # Output: t1 = a + b
    
    tadd t1, t1, t2     # Perform ternary addition
    ret                 # Return with result in t1

.global ternary_dot_product
ternary_dot_product:
    # Input: t1 = vector a address
    #        t2 = vector b address
    #        t3 = vector length
    # Output: t1 = dot product result
    
    mv t4, t0           # Initialize accumulator
    mv t5, t0           # Initialize index
    
dot_loop:
    ltw t6, 0(t1)       # Load a[i]
    ltw t7, 0(t2)       # Load b[i]
    tmul t8, t6, t7     # Multiply elements
    tadd t4, t4, t8     # Accumulate
    
    addi t1, t1, 4      # Next element of a
    addi t2, t2, 4      # Next element of b
    addi t5, t5, 1      # Increment index
    blt t5, t3, dot_loop # Continue if index < length
    
    mv t1, t4           # Return result
    ret
```

#### Inline Assembly in C

```c
// Inline assembly for performance-critical code
static inline ternary_t fast_ternary_add(ternary_t a, ternary_t b) {
    ternary_t result;
    __asm__ volatile (
        "tadd %0, %1, %2"
        : "=r" (result)
        : "r" (a), "r" (b)
    );
    return result;
}

static inline ternary_t ternary_dot_product_asm(const ternary_t *a, const ternary_t *b, size_t len) {
    ternary_t result;
    __asm__ volatile (
        "mv t4, zero\n\t"           // Initialize accumulator
        "mv t5, zero\n\t"           // Initialize index
        "1:\n\t"                    // Loop label
        "ltw t6, 0(%1)\n\t"         // Load a[i]
        "ltw t7, 0(%2)\n\t"         // Load b[i]
        "tmul t8, t6, t7\n\t"       // Multiply
        "tadd t4, t4, t8\n\t"       // Accumulate
        "addi %1, %1, 4\n\t"        // Next a
        "addi %2, %2, 4\n\t"        // Next b
        "addi t5, t5, 1\n\t"        // Increment index
        "blt t5, %3, 1b\n\t"        // Loop if index < len
        "mv %0, t4"                 // Return result
        : "=r" (result), "+r" (a), "+r" (b)
        : "r" (len)
        : "t4", "t5", "t6", "t7", "t8"
    );
    return result;
}
```

---

## Neural Network Library

### High-Level Neural Network API

```c
#include <ternary_neural.h>

// Network creation and management
neural_network_t* create_mlp(size_t *layer_sizes, size_t num_layers);
neural_network_t* create_cnn(cnn_config_t *config);
void destroy_network(neural_network_t *network);

// Training and inference
void train_network(neural_network_t *network, dataset_t *train_data, training_config_t *config);
ternary_vector_t* predict(neural_network_t *network, ternary_vector_t *input);
float evaluate_accuracy(neural_network_t *network, dataset_t *test_data);

// Model serialization
int save_network(neural_network_t *network, const char *filename);
neural_network_t* load_network(const char *filename);

// Example usage
size_t layer_sizes[] = {784, 128, 64, 10};
neural_network_t *network = create_mlp(layer_sizes, 4);

// Load dataset
dataset_t *train_data = load_dataset("mnist_train.dat");
dataset_t *test_data = load_dataset("mnist_test.dat");

// Training configuration
training_config_t config = {
    .epochs = 50,
    .batch_size = 32,
    .learning_rate = 0.01,
    .optimizer = OPTIMIZER_SGD
};

// Train the network
train_network(network, train_data, &config);

// Evaluate accuracy
float accuracy = evaluate_accuracy(network, test_data);
printf("Test accuracy: %.2f%%\n", accuracy * 100);

// Save trained model
save_network(network, "trained_model.tnw");
```

### Specialized Neural Operations

```c
// Convolution operations
ternary_matrix_t* ternary_conv2d(const ternary_matrix_t *input, const ternary_matrix_t *kernel, conv_params_t *params);
ternary_matrix_t* ternary_maxpool2d(const ternary_matrix_t *input, pool_params_t *params);

// Batch operations
void ternary_batch_norm(ternary_matrix_t *input, const ternary_vector_t *mean, const ternary_vector_t *var);
void ternary_dropout(ternary_matrix_t *input, float dropout_rate);

// Activation functions
void apply_activation(ternary_vector_t *input, activation_func_t func);
ternary_vector_t* softmax(const ternary_vector_t *input);

// Loss functions
float cross_entropy_loss(const ternary_vector_t *predictions, const ternary_vector_t *labels);
float mean_squared_error(const ternary_vector_t *predictions, const ternary_vector_t *labels);
```

---

## Performance Profiling

### Hardware Performance Counters

```c
// Performance measurement API
typedef struct {
    uint64_t timestamp_start;
    uint64_t timestamp_end;
    uint64_t cycle_count;
    uint64_t instruction_count;
    uint64_t ternary_operation_count;
    uint64_t neural_operation_count;
    double energy_microjoules;
    double frequency_mhz;
} perf_measurement_t;

// Start performance measurement
void perf_start(perf_measurement_t *measurement);

// Stop performance measurement
void perf_stop(perf_measurement_t *measurement);

// Get instantaneous performance stats
void perf_get_current_stats(perf_measurement_t *stats);

// Reset all performance counters
void perf_reset_counters(void);

// Example usage
perf_measurement_t perf;
perf_start(&perf);

// Perform operations to measure
ternary_vector_t *result = ternary_vector_dot(vec_a, vec_b);

perf_stop(&perf);

printf("Performance Results:\n");
printf("  Cycles: %lu\n", perf.cycle_count);
printf("  Instructions: %lu\n", perf.instruction_count);
printf("  Ternary operations: %lu\n", perf.ternary_operation_count);
printf("  Energy: %.2f µJ\n", perf.energy_microjoules);
printf("  Frequency: %.1f MHz\n", perf.frequency_mhz);
printf("  IPC: %.2f\n", (double)perf.instruction_count / perf.cycle_count);
```

### Energy Profiling

```c
// Energy measurement API
typedef struct {
    double core_energy_uj;
    double memory_energy_uj;
    double io_energy_uj;
    double total_energy_uj;
    double average_power_mw;
} energy_measurement_t;

// Energy profiling
void energy_start_measurement(void);
energy_measurement_t energy_stop_measurement(void);

// Per-operation energy estimation
double estimate_operation_energy(operation_type_t op_type, size_t data_size);

// Example usage
energy_start_measurement();

// Neural network inference
ternary_vector_t *output = neural_network_forward(network, input);

energy_measurement_t energy = energy_stop_measurement();
printf("Total energy: %.2f µJ\n", energy.total_energy_uj);
printf("Average power: %.2f mW\n", energy.average_power_mw);
```

---

## Error Handling

### Error Codes and Exceptions

```c
// Error codes
typedef enum {
    TERNARY_SUCCESS = 0,
    TERNARY_ERROR_INVALID_VALUE = 1,
    TERNARY_ERROR_NULL_POINTER = 2,
    TERNARY_ERROR_OUT_OF_MEMORY = 3,
    TERNARY_ERROR_DIMENSION_MISMATCH = 4,
    TERNARY_ERROR_DIVISION_BY_ZERO = 5,
    TERNARY_ERROR_OVERFLOW = 6,
    TERNARY_ERROR_UNDERFLOW = 7,
    TERNARY_ERROR_HARDWARE_FAULT = 8,
    TERNARY_ERROR_INVALID_OPERATION = 9
} ternary_error_t;

// Error handling functions
const char* ternary_error_string(ternary_error_t error);
void ternary_set_error_handler(void (*handler)(ternary_error_t, const char*));
ternary_error_t ternary_get_last_error(void);
void ternary_clear_error(void);

// Exception-safe operations
ternary_error_t ternary_vector_add_safe(const ternary_vector_t *a, const ternary_vector_t *b, ternary_vector_t **result);
ternary_error_t ternary_matrix_mul_safe(const ternary_matrix_t *a, const ternary_matrix_t *b, ternary_matrix_t **result);

// Example error handling
void my_error_handler(ternary_error_t error, const char* message) {
    fprintf(stderr, "Ternary error %d: %s\n", error, message);
    exit(1);
}

int main() {
    ternary_set_error_handler(my_error_handler);
    
    ternary_vector_t *result;
    ternary_error_t error = ternary_vector_add_safe(vec_a, vec_b, &result);
    
    if (error != TERNARY_SUCCESS) {
        printf("Error: %s\n", ternary_error_string(error));
        return 1;
    }
    
    return 0;
}
```

### Debug and Logging

```c
// Debug and logging API
typedef enum {
    LOG_LEVEL_ERROR = 0,
    LOG_LEVEL_WARNING = 1,
    LOG_LEVEL_INFO = 2,
    LOG_LEVEL_DEBUG = 3,
    LOG_LEVEL_TRACE = 4
} log_level_t;

// Logging functions
void ternary_log(log_level_t level, const char* format, ...);
void ternary_set_log_level(log_level_t level);
void ternary_set_log_file(const char* filename);

// Debug utilities
void ternary_dump_vector(const ternary_vector_t *vector, const char* name);
void ternary_dump_matrix(const ternary_matrix_t *matrix, const char* name);
void ternary_dump_performance_stats(void);

// Conditional compilation for debug builds
#ifdef TERNARY_DEBUG
    #define TERNARY_LOG_DEBUG(fmt, ...) ternary_log(LOG_LEVEL_DEBUG, fmt, ##__VA_ARGS__)
    #define TERNARY_ASSERT(condition) do { if (!(condition)) { ternary_log(LOG_LEVEL_ERROR, "Assertion failed: %s", #condition); abort(); } } while(0)
#else
    #define TERNARY_LOG_DEBUG(fmt, ...)
    #define TERNARY_ASSERT(condition)
#endif

// Example usage
ternary_set_log_level(LOG_LEVEL_DEBUG);
ternary_set_log_file("ternary_debug.log");

TERNARY_LOG_DEBUG("Starting ternary computation with %zu elements", vector_size);
TERNARY_ASSERT(vector != NULL);

ternary_dump_vector(input_vector, "input");
ternary_vector_t *result = ternary_vector_compute(input_vector);
ternary_dump_vector(result, "result");
```

---

## Examples

### Complete Neural Network Example

```c
#include <ternary.h>
#include <ternary_neural.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    // Initialize ternary system
    ternary_init();
    
    // Create a simple 3-layer network for MNIST-like classification
    size_t layer_sizes[] = {784, 128, 64, 10};
    neural_network_t *network = create_mlp(layer_sizes, 4);
    
    if (!network) {
        fprintf(stderr, "Failed to create neural network\n");
        return 1;
    }
    
    // Load training data (simplified)
    printf("Loading training data...\n");
    dataset_t *train_data = load_dataset("mnist_ternary_train.dat");
    dataset_t *test_data = load_dataset("mnist_ternary_test.dat");
    
    if (!train_data || !test_data) {
        fprintf(stderr, "Failed to load datasets\n");
        return 1;
    }
    
    // Configure training
    training_config_t config = {
        .epochs = 20,
        .batch_size = 64,
        .learning_rate = 0.01,
        .optimizer = OPTIMIZER_ADAM,
        .use_hardware_acceleration = true
    };
    
    // Start performance monitoring
    perf_measurement_t perf;
    perf_start(&perf);
    
    // Train the network
    printf("Training network...\n");
    train_network(network, train_data, &config);
    
    // Stop performance monitoring
    perf_stop(&perf);
    
    // Evaluate on test set
    printf("Evaluating on test set...\n");
    float accuracy = evaluate_accuracy(network, test_data);
    
    // Print results
    printf("\\nTraining completed!\\n");
    printf("Test accuracy: %.2f%%\\n", accuracy * 100);
    printf("Training time: %.2f seconds\\n", (perf.timestamp_end - perf.timestamp_start) / 1e9);
    printf("Energy consumption: %.2f mJ\\n", perf.energy_microjoules / 1000);
    printf("Ternary operations: %lu\\n", perf.ternary_operation_count);
    
    // Save trained model
    save_network(network, "mnist_ternary_model.tnw");
    printf("Model saved to mnist_ternary_model.tnw\\n");
    
    // Cleanup
    destroy_network(network);
    free_dataset(train_data);
    free_dataset(test_data);
    ternary_cleanup();
    
    return 0;
}
```

### Performance Benchmarking Example

```c
#include <ternary.h>
#include <time.h>

void benchmark_operations() {
    const size_t sizes[] = {100, 1000, 10000, 100000};
    const size_t num_sizes = sizeof(sizes) / sizeof(sizes[0]);
    
    printf("Ternary Operation Benchmarks\\n");
    printf("============================\\n");
    
    for (size_t i = 0; i < num_sizes; i++) {
        size_t size = sizes[i];
        
        // Create test vectors
        ternary_vector_t *vec_a = ternary_vector_create(size);
        ternary_vector_t *vec_b = ternary_vector_create(size);
        
        // Initialize with random ternary values
        for (size_t j = 0; j < size; j++) {
            ternary_t val_a = (ternary_t)(rand() % 3 - 1);  // -1, 0, or 1
            ternary_t val_b = (ternary_t)(rand() % 3 - 1);
            ternary_vector_set(vec_a, j, val_a);
            ternary_vector_set(vec_b, j, val_b);
        }
        
        // Benchmark dot product
        perf_measurement_t perf;
        perf_start(&perf);
        
        ternary_t dot_result = ternary_vector_dot(vec_a, vec_b);
        
        perf_stop(&perf);
        
        // Calculate performance metrics
        double throughput = (double)size / (perf.cycle_count / perf.frequency_mhz / 1e6);
        double energy_per_op = perf.energy_microjoules / size;
        
        printf("Size: %6zu | Cycles: %8lu | Throughput: %8.2f ops/sec | Energy: %.3f µJ/op\\n",
               size, perf.cycle_count, throughput, energy_per_op);
        
        // Cleanup
        ternary_vector_destroy(vec_a);
        ternary_vector_destroy(vec_b);
    }
}

int main() {
    ternary_init();
    benchmark_operations();
    ternary_cleanup();
    return 0;
}
```

---

**Document Information**
- **Version**: 1.0
- **Date**: September 2025  
- **Author**: MHX Neural Research Team
- **Status**: Complete
- **Related**: MHX Ternary RISC-V Technical Documentation

---

*This API documentation provides comprehensive programming interfaces for the MHX Ternary RISC-V processor. For hardware-level details, see the Technical Documentation and Instruction Set Reference.*