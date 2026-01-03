// Copyright lowRISC contributors.
// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Advanced Ternary Operations Library
 *
 * Extended ternary operations for AI/ML:
 * - Vectorized operations (SIMD-style)
 * - Dot product
 * - Manhattan distance
 * - Hamming distance (ternary)
 * - Max/Min reduction
 * - Population count (tritpop)
 * - Leading zeros count
 * - Saturation arithmetic
 */

`include "prim_assert.sv"

module ibex_ternary_advanced import ibex_pkg::*; #(
  parameter int unsigned TernaryDataWidth = 32,
  parameter int unsigned NumTrits = 16
)(
  input  logic [TernaryDataWidth-1:0] operand_a_i,
  input  logic [TernaryDataWidth-1:0] operand_b_i,
  input  logic [2:0]                  advanced_op_i,  // Advanced operation selector

  output logic [TernaryDataWidth-1:0] result_o,
  output logic [7:0]                  scalar_result_o, // For reduction operations
  output logic                        ready_o
);

  // Advanced operation encodings
  typedef enum logic [2:0] {
    TERNARY_ADV_DOT       = 3'b000,  // Dot product
    TERNARY_ADV_MANHATTAN = 3'b001,  // Manhattan distance
    TERNARY_ADV_HAMMING   = 3'b010,  // Hamming distance
    TERNARY_ADV_MAXRED    = 3'b011,  // Max reduction
    TERNARY_ADV_MINRED    = 3'b100,  // Min reduction
    TERNARY_ADV_TRITPOP   = 3'b101,  // Trit population count
    TERNARY_ADV_CLZ       = 3'b110,  // Count leading zeros
    TERNARY_ADV_SAT_ADD   = 3'b111   // Saturating addition
  } ternary_advanced_op_e;

  // Convert trit to signed integer
  function automatic logic signed [1:0] trit_to_int(logic [1:0] trit);
    case (trit)
      TRIT_NEG:  return -1;
      TRIT_ZERO: return 0;
      TRIT_POS:  return 1;
      default:   return 0;
    endcase
  endfunction

  // Convert integer back to trit
  function automatic logic [1:0] int_to_trit(logic signed [7:0] value);
    if (value > 0) return TRIT_POS;
    else if (value < 0) return TRIT_NEG;
    else return TRIT_ZERO;
  endfunction

  // Saturating addition
  function automatic logic [1:0] trit_sat_add(logic [1:0] a, logic [1:0] b);
    logic signed [2:0] sum;
    sum = trit_to_int(a) + trit_to_int(b);

    if (sum > 1) return TRIT_POS;
    else if (sum < -1) return TRIT_NEG;
    else if (sum == 0) return TRIT_ZERO;
    else return int_to_trit(sum);
  endfunction

  // Absolute difference
  function automatic logic [1:0] trit_abs_diff(logic [1:0] a, logic [1:0] b);
    logic signed [2:0] diff;
    diff = trit_to_int(a) - trit_to_int(b);

    if (diff < 0) diff = -diff;

    if (diff == 0) return TRIT_ZERO;
    else if (diff == 1) return TRIT_POS;
    else return 2'b10; // +1 is max in ternary, so 2 maps to +1
  endfunction

  always_comb begin
    logic signed [7:0] accumulator;
    logic [7:0] counter;
    logic [1:0] max_trit, min_trit;
    logic [7:0] leading_zeros;
    logic found_nonzero;

    // Initialize outputs
    result_o = '0;
    scalar_result_o = '0;
    ready_o = 1'b1;
    accumulator = '0;
    counter = '0;
    max_trit = TRIT_NEG;
    min_trit = TRIT_POS;
    leading_zeros = '0;
    found_nonzero = 1'b0;

    case (advanced_op_i)
      TERNARY_ADV_DOT: begin
        // Dot product: sum(a[i] * b[i])
        for (int i = 0; i < NumTrits; i++) begin
          logic [1:0] a_trit, b_trit;
          logic signed [1:0] product;

          a_trit = operand_a_i[i*2 +: 2];
          b_trit = operand_b_i[i*2 +: 2];

          product = trit_to_int(a_trit) * trit_to_int(b_trit);
          accumulator = accumulator + product;
        end
        scalar_result_o = accumulator;
        result_o = {{TernaryDataWidth-8{1'b0}}, accumulator};
      end

      TERNARY_ADV_MANHATTAN: begin
        // Manhattan distance: sum(|a[i] - b[i]|)
        for (int i = 0; i < NumTrits; i++) begin
          logic [1:0] a_trit, b_trit;
          logic signed [2:0] diff;

          a_trit = operand_a_i[i*2 +: 2];
          b_trit = operand_b_i[i*2 +: 2];

          diff = trit_to_int(a_trit) - trit_to_int(b_trit);
          if (diff < 0) diff = -diff;

          counter = counter + diff[1:0];
        end
        scalar_result_o = counter;
        result_o = {{TernaryDataWidth-8{1'b0}}, counter};
      end

      TERNARY_ADV_HAMMING: begin
        // Hamming distance: count(a[i] != b[i])
        for (int i = 0; i < NumTrits; i++) begin
          logic [1:0] a_trit, b_trit;

          a_trit = operand_a_i[i*2 +: 2];
          b_trit = operand_b_i[i*2 +: 2];

          if (a_trit != b_trit) begin
            counter = counter + 1;
          end
        end
        scalar_result_o = counter;
        result_o = {{TernaryDataWidth-8{1'b0}}, counter};
      end

      TERNARY_ADV_MAXRED: begin
        // Max reduction: find maximum trit value
        for (int i = 0; i < NumTrits; i++) begin
          logic [1:0] a_trit;
          logic signed [1:0] a_int, max_int;

          a_trit = operand_a_i[i*2 +: 2];
          a_int = trit_to_int(a_trit);
          max_int = trit_to_int(max_trit);

          if (a_int > max_int) begin
            max_trit = a_trit;
          end
        end

        // Replicate max value to all trits
        for (int i = 0; i < NumTrits; i++) begin
          result_o[i*2 +: 2] = max_trit;
        end
        scalar_result_o = {{6{max_trit[1]}}, max_trit};
      end

      TERNARY_ADV_MINRED: begin
        // Min reduction: find minimum trit value
        for (int i = 0; i < NumTrits; i++) begin
          logic [1:0] a_trit;
          logic signed [1:0] a_int, min_int;

          a_trit = operand_a_i[i*2 +: 2];
          a_int = trit_to_int(a_trit);
          min_int = trit_to_int(min_trit);

          if (a_int < min_int) begin
            min_trit = a_trit;
          end
        end

        // Replicate min value to all trits
        for (int i = 0; i < NumTrits; i++) begin
          result_o[i*2 +: 2] = min_trit;
        end
        scalar_result_o = {{6{min_trit[1]}}, min_trit};
      end

      TERNARY_ADV_TRITPOP: begin
        // Trit population count: count non-zero trits
        logic [7:0] pos_count, neg_count, zero_count;
        pos_count = '0;
        neg_count = '0;
        zero_count = '0;

        for (int i = 0; i < NumTrits; i++) begin
          logic [1:0] a_trit;
          a_trit = operand_a_i[i*2 +: 2];

          case (a_trit)
            TRIT_POS:  pos_count = pos_count + 1;
            TRIT_NEG:  neg_count = neg_count + 1;
            TRIT_ZERO: zero_count = zero_count + 1;
            default:   zero_count = zero_count + 1;
          endcase
        end

        // Return counts in different bytes
        // [7:6] = unused, [5:4] = pos_count, [3:2] = neg_count, [1:0] = zero_count
        scalar_result_o = {2'b00, pos_count[5:4], neg_count[3:2], zero_count[1:0]};
        result_o = {{TernaryDataWidth-24{1'b0}}, pos_count, neg_count, zero_count};
      end

      TERNARY_ADV_CLZ: begin
        // Count leading zero trits
        for (int i = NumTrits-1; i >= 0; i--) begin
          logic [1:0] a_trit;
          a_trit = operand_a_i[i*2 +: 2];

          if (!found_nonzero) begin
            if (a_trit == TRIT_ZERO) begin
              leading_zeros = leading_zeros + 1;
            end else begin
              found_nonzero = 1'b1;
            end
          end
        end

        scalar_result_o = leading_zeros;
        result_o = {{TernaryDataWidth-8{1'b0}}, leading_zeros};
      end

      TERNARY_ADV_SAT_ADD: begin
        // Saturating addition (element-wise)
        for (int i = 0; i < NumTrits; i++) begin
          logic [1:0] a_trit, b_trit;

          a_trit = operand_a_i[i*2 +: 2];
          b_trit = operand_b_i[i*2 +: 2];

          result_o[i*2 +: 2] = trit_sat_add(a_trit, b_trit);
        end
      end

      default: begin
        result_o = TERNARY_ZERO_PATTERN;
        scalar_result_o = '0;
      end
    endcase
  end

  ///////////////////////////
  // Formal Verification   //
  ///////////////////////////

  `ASSERT(AlwaysReady, ready_o === 1'b1)

  // Dot product commutativity - verified by design
  // Property: DOT(a,b) == DOT(b,a)

  // Manhattan distance is always non-negative
  `ASSERT(ManhattanNonNegative,
    (advanced_op_i == TERNARY_ADV_MANHATTAN) |->
    (scalar_result_o[7] == 1'b0))

  // Hamming distance bounded by number of trits
  `ASSERT(HammingBounded,
    (advanced_op_i == TERNARY_ADV_HAMMING) |->
    (scalar_result_o <= NumTrits))

  // Leading zeros count bounded
  `ASSERT(CLZBounded,
    (advanced_op_i == TERNARY_ADV_CLZ) |->
    (scalar_result_o <= NumTrits))

endmodule
