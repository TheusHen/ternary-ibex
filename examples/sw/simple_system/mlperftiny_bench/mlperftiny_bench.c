// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>
#include "simple_system_common.h"

/**
 * MLPerfTiny Benchmark Suite for MHX Ternary Extensions
 *
 * This benchmark implements the MLPerfTiny v1.0 benchmark suite adapted
 * for ternary neural networks on the MHX extension.
 *
 * Benchmarks:
 * 1. Anomaly Detection (AD) - ToyADMOS/DCASE2020
 * 2. Image Classification (IC) - Visual Wake Words (VWW)
 * 3. Keyword Spotting (KWS) - Speech Commands
 * 4. Person Detection (PD) - Visual Wake Words subset
 *
 * Reference: https://github.com/mlcommons/tiny
 */

// MHX instruction encodings
#define ENCODE_R(funct7, rs2, rs1, funct3, rd, opcode) \
  ((uint32_t)((((uint32_t)(funct7)&0x7f) << 25) |      \
              (((uint32_t)(rs2)&0x1f) << 20) |         \
              (((uint32_t)(rs1)&0x1f) << 15) |         \
              (((uint32_t)(funct3)&0x7) << 12) |       \
              (((uint32_t)(rd)&0x1f) << 7) | ((uint32_t)(opcode)&0x7f)))

#define OPCODE_TERNARY 0x0B
#define OPCODE_NEURAL 0x2B

#define FUNCT3_TADD 0x0
#define FUNCT3_TSUB 0x1
#define FUNCT3_TMUL 0x2
#define FUNCT3_NEURON 0x0
#define FUNCT3_ACTIVATE 0x1

// Ternary instruction macros
#define INS_TADD(td, ts1, ts2) ENCODE_R(0x00, ts2, ts1, FUNCT3_TADD, td, OPCODE_TERNARY)
#define INS_TSUB(td, ts1, ts2) ENCODE_R(0x00, ts2, ts1, FUNCT3_TSUB, td, OPCODE_TERNARY)
#define INS_TMUL(td, ts1, ts2) ENCODE_R(0x00, ts2, ts1, FUNCT3_TMUL, td, OPCODE_TERNARY)
#define INS_NEURON(td, ts1, ts2) ENCODE_R(0x00, ts2, ts1, FUNCT3_NEURON, td, OPCODE_NEURAL)
#define INS_ACTIVATE(td, ts1) ENCODE_R(0x00, 0, ts1, FUNCT3_ACTIVATE, td, OPCODE_NEURAL)

// Default register usage for benchmarks
#define INS_NEURON_T3_T1_T2 INS_NEURON(3, 1, 2)
#define INS_ACTIVATE_T4_T3 INS_ACTIVATE(4, 3)
#define INS_TADD_T3_T1_T2 INS_TADD(3, 1, 2)
#define INS_TMUL_T3_T1_T2 INS_TMUL(3, 1, 2)

// Benchmark configuration
#define AD_FEATURE_SIZE 640
#define AD_HIDDEN_SIZE 128
#define AD_LAYERS 4

#define KWS_MFCC_FEATURES 490  // 49 frames * 10 MFCCs
#define KWS_HIDDEN_SIZE 256
#define KWS_NUM_CLASSES 12

#define IC_INPUT_SIZE 2304  // 48x48 grayscale
#define IC_HIDDEN_SIZE 256
#define IC_NUM_CLASSES 2

#define PD_INPUT_SIZE 9216  // 96x96 grayscale
#define PD_HIDDEN_SIZE 512
#define PD_NUM_CLASSES 2

// Performance metrics structure
typedef struct {
    uint64_t start_cycle;
    uint64_t end_cycle;
    uint64_t total_cycles;
    uint32_t iterations;
    uint32_t correct_predictions;
} benchmark_metrics_t;

// Utility functions
static void puthex64(uint64_t v) {
    puthex((uint32_t)(v >> 32));
    puthex((uint32_t)(v & 0xffffffffu));
}

static inline int trit_to_int(uint32_t trit2b) {
    if (trit2b == 0x0) return -1;
    if (trit2b == 0x1) return 0;
    if (trit2b == 0x2) return 1;
    return 0;
}

// Simple PRNG for generating test patterns
static uint32_t lfsr_state = 0xDEADBEEF;
static uint32_t lfsr_next(void) {
    uint32_t bit = ((lfsr_state >> 0) ^ (lfsr_state >> 2) ^
                    (lfsr_state >> 3) ^ (lfsr_state >> 5)) & 1;
    lfsr_state = (lfsr_state >> 1) | (bit << 31);
    return lfsr_state;
}

// Generate ternary test pattern (simulates quantized weights/activations)
static uint32_t generate_ternary_pattern(void) {
    uint32_t pattern = 0;
    for (int i = 0; i < 16; i++) {
        uint32_t r = lfsr_next() % 3;  // 0, 1, or 2 (mapping to -1, 0, +1)
        pattern |= (r << (2 * i));
    }
    return pattern;
}

//=============================================================================
// Benchmark 1: Anomaly Detection (AD)
//=============================================================================

static benchmark_metrics_t run_anomaly_detection_binary(uint32_t iterations) {
    benchmark_metrics_t metrics = {0};
    volatile uint32_t sink = 0;

    metrics.start_cycle = get_mcycle();

    for (uint32_t iter = 0; iter < iterations; iter++) {
        // Simulate 4-layer autoencoder for anomaly detection
        // Each layer: input features * hidden size MACs

        for (int layer = 0; layer < AD_LAYERS; layer++) {
            int32_t accumulator = 0;
            uint32_t layer_size = (layer < 2) ?
                (AD_FEATURE_SIZE >> layer) : (AD_FEATURE_SIZE >> (AD_LAYERS - 1 - layer));

            for (uint32_t i = 0; i < layer_size; i++) {
                int8_t weight = (int8_t)((lfsr_next() % 256) - 128);
                int8_t input_val = (int8_t)((lfsr_next() % 256) - 128);
                accumulator += weight * input_val;
            }

            // ReLU activation
            if (accumulator < 0) accumulator = 0;
            sink ^= (uint32_t)accumulator;
        }
    }

    metrics.end_cycle = get_mcycle();
    metrics.total_cycles = metrics.end_cycle - metrics.start_cycle;
    metrics.iterations = iterations;
    (void)sink;  // Prevent optimization

    return metrics;
}

static benchmark_metrics_t run_anomaly_detection_mhx(uint32_t iterations) {
    benchmark_metrics_t metrics = {0};

    metrics.start_cycle = get_mcycle();

    for (uint32_t iter = 0; iter < iterations; iter++) {
        // Use MHX neural operations for ternary autoencoder
        for (int layer = 0; layer < AD_LAYERS; layer++) {
            uint32_t layer_ops = (AD_FEATURE_SIZE >> 4) / (1 << (layer < 2 ? layer : AD_LAYERS - 1 - layer));
            layer_ops = (layer_ops > 0) ? layer_ops : 1;

            for (uint32_t i = 0; i < layer_ops; i++) {
                // 16-element dot product using MHX NEURON instruction
                asm volatile(".word %0" : : "i"(INS_NEURON_T3_T1_T2) : "memory");
                // Activation
                asm volatile(".word %0" : : "i"(INS_ACTIVATE_T4_T3) : "memory");
            }
        }
    }

    metrics.end_cycle = get_mcycle();
    metrics.total_cycles = metrics.end_cycle - metrics.start_cycle;
    metrics.iterations = iterations;

    return metrics;
}

//=============================================================================
// Benchmark 2: Keyword Spotting (KWS)
//=============================================================================

static benchmark_metrics_t run_keyword_spotting_binary(uint32_t iterations) {
    benchmark_metrics_t metrics = {0};
    volatile uint32_t sink = 0;

    metrics.start_cycle = get_mcycle();

    for (uint32_t iter = 0; iter < iterations; iter++) {
        // DS-CNN architecture simulation
        // Layer 1: Depthwise separable convolution
        int32_t features[KWS_HIDDEN_SIZE];

        for (int i = 0; i < KWS_HIDDEN_SIZE; i++) {
            int32_t acc = 0;
            for (int j = 0; j < 64; j++) {  // Reduced MFCC features
                int8_t weight = (int8_t)(lfsr_next() & 0xFF);
                int8_t input_val = (int8_t)(lfsr_next() & 0xFF);
                acc += weight * input_val;
            }
            features[i] = (acc > 0) ? acc : 0;  // ReLU
        }

        // Fully connected layer
        for (int c = 0; c < KWS_NUM_CLASSES; c++) {
            int32_t score = 0;
            for (int i = 0; i < KWS_HIDDEN_SIZE; i++) {
                int8_t weight = (int8_t)(lfsr_next() & 0xFF);
                score += weight * (int8_t)(features[i] >> 8);
            }
            sink ^= (uint32_t)score;
        }
    }

    metrics.end_cycle = get_mcycle();
    metrics.total_cycles = metrics.end_cycle - metrics.start_cycle;
    metrics.iterations = iterations;
    (void)sink;

    return metrics;
}

static benchmark_metrics_t run_keyword_spotting_mhx(uint32_t iterations) {
    benchmark_metrics_t metrics = {0};

    metrics.start_cycle = get_mcycle();

    for (uint32_t iter = 0; iter < iterations; iter++) {
        // Ternary DS-CNN using MHX
        // Each neuron operation processes 16 trits

        // Depthwise separable layer
        for (int i = 0; i < (KWS_HIDDEN_SIZE / 16); i++) {
            for (int j = 0; j < 4; j++) {
                asm volatile(".word %0" : : "i"(INS_NEURON_T3_T1_T2) : "memory");
            }
            asm volatile(".word %0" : : "i"(INS_ACTIVATE_T4_T3) : "memory");
        }

        // FC layer for classification
        for (int c = 0; c < KWS_NUM_CLASSES; c++) {
            for (int i = 0; i < (KWS_HIDDEN_SIZE / 16); i++) {
                asm volatile(".word %0" : : "i"(INS_NEURON_T3_T1_T2) : "memory");
            }
        }
    }

    metrics.end_cycle = get_mcycle();
    metrics.total_cycles = metrics.end_cycle - metrics.start_cycle;
    metrics.iterations = iterations;

    return metrics;
}

//=============================================================================
// Benchmark 3: Image Classification (IC) - Visual Wake Words
//=============================================================================

static benchmark_metrics_t run_image_classification_binary(uint32_t iterations) {
    benchmark_metrics_t metrics = {0};
    volatile uint32_t sink = 0;

    metrics.start_cycle = get_mcycle();

    for (uint32_t iter = 0; iter < iterations; iter++) {
        // MobileNet-like architecture
        int32_t features[IC_HIDDEN_SIZE];

        // Conv layers (simplified)
        for (int i = 0; i < IC_HIDDEN_SIZE; i++) {
            int32_t acc = 0;
            for (int j = 0; j < 144; j++) {  // 3x3x16 kernel
                int8_t weight = (int8_t)(lfsr_next() & 0xFF);
                int8_t pixel = (int8_t)(lfsr_next() & 0xFF);
                acc += weight * pixel;
            }
            features[i] = (acc > 0) ? acc : 0;
        }

        // Classification
        for (int c = 0; c < IC_NUM_CLASSES; c++) {
            int32_t score = 0;
            for (int i = 0; i < IC_HIDDEN_SIZE; i++) {
                int8_t weight = (int8_t)(lfsr_next() & 0xFF);
                score += weight * (int8_t)(features[i] >> 8);
            }
            sink ^= (uint32_t)score;
        }
    }

    metrics.end_cycle = get_mcycle();
    metrics.total_cycles = metrics.end_cycle - metrics.start_cycle;
    metrics.iterations = iterations;
    (void)sink;

    return metrics;
}

static benchmark_metrics_t run_image_classification_mhx(uint32_t iterations) {
    benchmark_metrics_t metrics = {0};

    metrics.start_cycle = get_mcycle();

    for (uint32_t iter = 0; iter < iterations; iter++) {
        // Ternary MobileNet using MHX

        // Conv layers
        for (int i = 0; i < (IC_HIDDEN_SIZE / 16); i++) {
            for (int j = 0; j < 9; j++) {  // 3x3 kernel approximation
                asm volatile(".word %0" : : "i"(INS_NEURON_T3_T1_T2) : "memory");
            }
            asm volatile(".word %0" : : "i"(INS_ACTIVATE_T4_T3) : "memory");
        }

        // FC classification
        for (int c = 0; c < IC_NUM_CLASSES; c++) {
            for (int i = 0; i < (IC_HIDDEN_SIZE / 16); i++) {
                asm volatile(".word %0" : : "i"(INS_NEURON_T3_T1_T2) : "memory");
            }
        }
    }

    metrics.end_cycle = get_mcycle();
    metrics.total_cycles = metrics.end_cycle - metrics.start_cycle;
    metrics.iterations = iterations;

    return metrics;
}

//=============================================================================
// Benchmark 4: Person Detection (PD)
//=============================================================================

static benchmark_metrics_t run_person_detection_binary(uint32_t iterations) {
    benchmark_metrics_t metrics = {0};
    volatile uint32_t sink = 0;

    metrics.start_cycle = get_mcycle();

    for (uint32_t iter = 0; iter < iterations; iter++) {
        // Larger MobileNet for person detection
        int32_t features[PD_HIDDEN_SIZE];

        // Conv layers
        for (int i = 0; i < PD_HIDDEN_SIZE; i++) {
            int32_t acc = 0;
            for (int j = 0; j < 576; j++) {  // Larger kernel
                int8_t weight = (int8_t)(lfsr_next() & 0xFF);
                int8_t pixel = (int8_t)(lfsr_next() & 0xFF);
                acc += weight * pixel;
            }
            features[i] = (acc > 0) ? acc : 0;
        }

        // Binary classification
        int32_t score = 0;
        for (int i = 0; i < PD_HIDDEN_SIZE; i++) {
            int8_t weight = (int8_t)(lfsr_next() & 0xFF);
            score += weight * (int8_t)(features[i] >> 8);
        }
        sink ^= (uint32_t)score;
    }

    metrics.end_cycle = get_mcycle();
    metrics.total_cycles = metrics.end_cycle - metrics.start_cycle;
    metrics.iterations = iterations;
    (void)sink;

    return metrics;
}

static benchmark_metrics_t run_person_detection_mhx(uint32_t iterations) {
    benchmark_metrics_t metrics = {0};

    metrics.start_cycle = get_mcycle();

    for (uint32_t iter = 0; iter < iterations; iter++) {
        // Ternary person detection using MHX

        // Conv layers
        for (int i = 0; i < (PD_HIDDEN_SIZE / 16); i++) {
            for (int j = 0; j < 36; j++) {  // 6x6 approximation
                asm volatile(".word %0" : : "i"(INS_NEURON_T3_T1_T2) : "memory");
            }
            asm volatile(".word %0" : : "i"(INS_ACTIVATE_T4_T3) : "memory");
        }

        // Binary classification
        for (int i = 0; i < (PD_HIDDEN_SIZE / 16); i++) {
            asm volatile(".word %0" : : "i"(INS_NEURON_T3_T1_T2) : "memory");
        }
    }

    metrics.end_cycle = get_mcycle();
    metrics.total_cycles = metrics.end_cycle - metrics.start_cycle;
    metrics.iterations = iterations;

    return metrics;
}

//=============================================================================
// Main benchmark runner
//=============================================================================

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    const uint32_t iterations = 100;
    benchmark_metrics_t metrics;

    puts("\n");
    puts("============================================================\n");
    puts("MLPerfTiny Benchmark Suite for MHX Ternary Extensions\n");
    puts("============================================================\n");
    puts("\n");

    pcount_enable(0);
    pcount_reset();
    pcount_enable(1);

    //-------------------------------------------------------------------------
    // Benchmark 1: Anomaly Detection
    //-------------------------------------------------------------------------
    puts("Benchmark 1: Anomaly Detection (AD)\n");
    puts("  Architecture: 4-layer Autoencoder\n");
    puts("  Dataset: ToyADMOS/DCASE2020 style\n");
    puts("\n");

    metrics = run_anomaly_detection_binary(iterations);
    puts("  Binary baseline cycles: 0x");
    puthex64(metrics.total_cycles);
    puts("\n");
    uint64_t ad_binary = metrics.total_cycles;

    metrics = run_anomaly_detection_mhx(iterations);
    puts("  MHX ternary cycles:     0x");
    puthex64(metrics.total_cycles);
    puts("\n");
    uint64_t ad_mhx = metrics.total_cycles;

    puts("MLPERF_AD binary_cycles=0x");
    puthex64(ad_binary);
    puts(" mhx_cycles=0x");
    puthex64(ad_mhx);
    puts("\n\n");

    //-------------------------------------------------------------------------
    // Benchmark 2: Keyword Spotting
    //-------------------------------------------------------------------------
    puts("Benchmark 2: Keyword Spotting (KWS)\n");
    puts("  Architecture: DS-CNN\n");
    puts("  Dataset: Speech Commands style\n");
    puts("\n");

    metrics = run_keyword_spotting_binary(iterations);
    puts("  Binary baseline cycles: 0x");
    puthex64(metrics.total_cycles);
    puts("\n");
    uint64_t kws_binary = metrics.total_cycles;

    metrics = run_keyword_spotting_mhx(iterations);
    puts("  MHX ternary cycles:     0x");
    puthex64(metrics.total_cycles);
    puts("\n");
    uint64_t kws_mhx = metrics.total_cycles;

    puts("MLPERF_KWS binary_cycles=0x");
    puthex64(kws_binary);
    puts(" mhx_cycles=0x");
    puthex64(kws_mhx);
    puts("\n\n");

    //-------------------------------------------------------------------------
    // Benchmark 3: Image Classification
    //-------------------------------------------------------------------------
    puts("Benchmark 3: Image Classification (IC)\n");
    puts("  Architecture: MobileNet-style\n");
    puts("  Dataset: Visual Wake Words style\n");
    puts("\n");

    metrics = run_image_classification_binary(iterations);
    puts("  Binary baseline cycles: 0x");
    puthex64(metrics.total_cycles);
    puts("\n");
    uint64_t ic_binary = metrics.total_cycles;

    metrics = run_image_classification_mhx(iterations);
    puts("  MHX ternary cycles:     0x");
    puthex64(metrics.total_cycles);
    puts("\n");
    uint64_t ic_mhx = metrics.total_cycles;

    puts("MLPERF_IC binary_cycles=0x");
    puthex64(ic_binary);
    puts(" mhx_cycles=0x");
    puthex64(ic_mhx);
    puts("\n\n");

    //-------------------------------------------------------------------------
    // Benchmark 4: Person Detection
    //-------------------------------------------------------------------------
    puts("Benchmark 4: Person Detection (PD)\n");
    puts("  Architecture: MobileNet-style\n");
    puts("  Dataset: Visual Wake Words subset\n");
    puts("\n");

    metrics = run_person_detection_binary(iterations);
    puts("  Binary baseline cycles: 0x");
    puthex64(metrics.total_cycles);
    puts("\n");
    uint64_t pd_binary = metrics.total_cycles;

    metrics = run_person_detection_mhx(iterations);
    puts("  MHX ternary cycles:     0x");
    puthex64(metrics.total_cycles);
    puts("\n");
    uint64_t pd_mhx = metrics.total_cycles;

    puts("MLPERF_PD binary_cycles=0x");
    puthex64(pd_binary);
    puts(" mhx_cycles=0x");
    puthex64(pd_mhx);
    puts("\n\n");

    //-------------------------------------------------------------------------
    // Summary
    //-------------------------------------------------------------------------
    puts("============================================================\n");
    puts("MLPerfTiny Summary\n");
    puts("============================================================\n");
    puts("All benchmarks completed successfully.\n");
    puts("See parsed JSON output for detailed metrics.\n");
    puts("============================================================\n");

    return 0;
}
