// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

#include "simple_system_common.h"

// RISC-V R-type encoder.
#define ENCODE_R(funct7, rs2, rs1, funct3, rd, opcode) \
  ((uint32_t)((((uint32_t)(funct7)&0x7f) << 25) |      \
              (((uint32_t)(rs2)&0x1f) << 20) |         \
              (((uint32_t)(rs1)&0x1f) << 15) |         \
              (((uint32_t)(funct3)&0x7) << 12) |       \
              (((uint32_t)(rd)&0x1f) << 7) | ((uint32_t)(opcode)&0x7f)))

// MHX™ custom opcodes (see rtl/ibex_pkg.sv)
#define OPCODE_TERNARY 0x0B
#define OPCODE_NEURAL 0x2B

// funct3 encodings (see rtl/ibex_decoder.sv)
#define FUNCT3_TADD 0x0
#define FUNCT3_NEURON 0x0

// Fixed instruction encodings using ternary registers T1, T2, T3.
// Note: These occupy the standard rs1/rs2/rd fields but are interpreted by MHX™
// as ternary register indices.
#define INS_TADD_T3_T1_T2 ENCODE_R(0x00, 2, 1, FUNCT3_TADD, 3, OPCODE_TERNARY)
#define INS_NEURON_T3_T1_T2 \
  ENCODE_R(0x00, 2, 1, FUNCT3_NEURON, 3, OPCODE_NEURAL)

static void puthex64(uint64_t v) {
  puthex((uint32_t)(v >> 32));
  puthex((uint32_t)(v & 0xffffffffu));
}

static inline int trit_to_int(uint32_t trit2b) {
  // 00=-1, 01=0, 10=+1, 11=invalid (treat as 0 for safety)
  if (trit2b == 0x0)
    return -1;
  if (trit2b == 0x1)
    return 0;
  if (trit2b == 0x2)
    return 1;
  return 0;
}

static uint32_t baseline_neuron_once(uint32_t w, uint32_t in) {
  // Computes a 16-trit dot product (conceptually) using packed 2-bit trits.
  int acc = 0;
  for (int i = 0; i < 16; i++) {
    uint32_t w2 = (w >> (2 * i)) & 0x3;
    uint32_t i2 = (in >> (2 * i)) & 0x3;
    acc += trit_to_int(w2) * trit_to_int(i2);
  }
  // Return a small signature so the compiler can't elide the loop.
  return (uint32_t)(acc & 0xff);
}

static uint32_t baseline_tadd_once(uint32_t a, uint32_t b) {
  // A small, deterministic baseline workload (not semantically identical to MHX™
  // TADD, but provides a stable integer-op reference).
  uint32_t x = a;
  uint32_t y = b;
  for (int i = 0; i < 16; i++) {
    x ^= (y << (i & 7));
    y += (x >> (i & 7));
  }
  return x ^ y;
}

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  // Use enough iterations to dominate fixed overhead.
  const uint32_t iters = 2000;

  volatile uint32_t sink32 = 0;

  pcount_enable(0);
  pcount_reset();
  pcount_enable(1);

  // --- Neural benchmark ---
  uint32_t weights = 0xAAAA5555u;
  uint32_t inputs = 0x5AA55AA5u;

  uint64_t t0 = get_mcycle();
  for (uint32_t i = 0; i < iters; i++) {
    sink32 ^= baseline_neuron_once(weights ^ i, inputs + i);
  }
  uint64_t t1 = get_mcycle();
  uint64_t neural_baseline_cycles = t1 - t0;

  t0 = get_mcycle();
  for (uint32_t i = 0; i < iters; i++) {
    asm volatile(".word %0" : : "i"(INS_NEURON_T3_T1_T2) : "memory");
  }
  t1 = get_mcycle();
  uint64_t neural_mhx_cycles = t1 - t0;

  // --- Matrix-ish benchmark (reference vs MHX™ TADD) ---
  t0 = get_mcycle();
  for (uint32_t i = 0; i < iters; i++) {
    sink32 ^= baseline_tadd_once(0x12345678u + i, 0x9ABCDEF0u ^ i);
  }
  t1 = get_mcycle();
  uint64_t matrix_baseline_cycles = t1 - t0;

  t0 = get_mcycle();
  for (uint32_t i = 0; i < iters; i++) {
    asm volatile(".word %0" : : "i"(INS_TADD_T3_T1_T2) : "memory");
  }
  t1 = get_mcycle();
  uint64_t matrix_mhx_cycles = t1 - t0;

  // Emit parseable results.
  puts("MHX_CYCLE_BENCH neural_baseline_cycles=0x");
  puthex64(neural_baseline_cycles);
  puts(" neural_mhx_cycles=0x");
  puthex64(neural_mhx_cycles);
  puts("\n");

  puts("MHX_CYCLE_BENCH matrix_baseline_cycles=0x");
  puthex64(matrix_baseline_cycles);
  puts(" matrix_mhx_cycles=0x");
  puthex64(matrix_mhx_cycles);
  puts("\n");

  // Keep sink live.
  puts("MHX_CYCLE_BENCH sink=0x");
  puthex(sink32);
  puts("\n");

  sim_halt();
  return 0;
}
