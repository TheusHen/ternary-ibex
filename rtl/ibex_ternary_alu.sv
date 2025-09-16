// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Ternary Arithmetic Logic Unit for MHX Neural T1
 *
 * Performs arithmetic and logical operations on ternary data.
 * Each trit is encoded using 2 bits:
 * - 2'b00 = -1 (negative)
 * - 2'b01 = 0  (zero)
 * - 2'b10 = +1 (positive)
 * - 2'b11 = invalid
 */

`include "prim_assert.sv"

module ibex_ternary_alu import ibex_pkg::*; (
  input  logic [31:0]       operand_a_i,  // 16 trits * 2 bits
  input  logic [31:0]       operand_b_i,  // 16 trits * 2 bits
  input  ternary_op_e       operator_i,

  output logic [31:0]       result_o,
  output logic              ready_o
);

  // Ternary arithmetic functions
  function automatic logic [1:0] trit_add(logic [1:0] a, logic [1:0] b);
    case ({a, b})
      4'b0000: return TRIT_POS;   // (-1) + (-1) = -2 → clamp to +1 (overflow)
      4'b0001: return TRIT_NEG;   // (-1) + 0 = -1
      4'b0010: return TRIT_ZERO;  // (-1) + 1 = 0
      4'b0100: return TRIT_NEG;   // 0 + (-1) = -1
      4'b0101: return TRIT_ZERO;  // 0 + 0 = 0
      4'b0110: return TRIT_POS;   // 0 + 1 = 1
      4'b1000: return TRIT_ZERO;  // 1 + (-1) = 0
      4'b1001: return TRIT_POS;   // 1 + 0 = 1
      4'b1010: return TRIT_NEG;   // 1 + 1 = 2 → clamp to -1 (overflow)
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_sub(logic [1:0] a, logic [1:0] b);
    case ({a, b})
      4'b0000: return TRIT_ZERO;  // (-1) - (-1) = 0
      4'b0001: return TRIT_NEG;   // (-1) - 0 = -1
      4'b0010: return TRIT_POS;   // (-1) - 1 = -2 → clamp to +1
      4'b0100: return TRIT_POS;   // 0 - (-1) = 1
      4'b0101: return TRIT_ZERO;  // 0 - 0 = 0
      4'b0110: return TRIT_NEG;   // 0 - 1 = -1
      4'b1000: return TRIT_NEG;   // 1 - (-1) = 2 → clamp to -1
      4'b1001: return TRIT_POS;   // 1 - 0 = 1
      4'b1010: return TRIT_ZERO;  // 1 - 1 = 0
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_mul(logic [1:0] a, logic [1:0] b);
    case ({a, b})
      4'b0000: return TRIT_POS;   // (-1) * (-1) = 1
      4'b0001: return TRIT_ZERO;  // (-1) * 0 = 0
      4'b0010: return TRIT_NEG;   // (-1) * 1 = -1
      4'b0100: return TRIT_ZERO;  // 0 * (-1) = 0
      4'b0101: return TRIT_ZERO;  // 0 * 0 = 0
      4'b0110: return TRIT_ZERO;  // 0 * 1 = 0
      4'b1000: return TRIT_NEG;   // 1 * (-1) = -1
      4'b1001: return TRIT_ZERO;  // 1 * 0 = 0
      4'b1010: return TRIT_POS;   // 1 * 1 = 1
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_and(logic [1:0] a, logic [1:0] b);
    // Ternary AND: min(a, b)
    case ({a, b})
      4'b0000: return TRIT_NEG;   // min(-1, -1) = -1
      4'b0001: return TRIT_NEG;   // min(-1, 0) = -1
      4'b0010: return TRIT_NEG;   // min(-1, 1) = -1
      4'b0100: return TRIT_NEG;   // min(0, -1) = -1
      4'b0101: return TRIT_ZERO;  // min(0, 0) = 0
      4'b0110: return TRIT_ZERO;  // min(0, 1) = 0
      4'b1000: return TRIT_NEG;   // min(1, -1) = -1
      4'b1001: return TRIT_ZERO;  // min(1, 0) = 0
      4'b1010: return TRIT_POS;   // min(1, 1) = 1
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_or(logic [1:0] a, logic [1:0] b);
    // Ternary OR: max(a, b)
    case ({a, b})
      4'b0000: return TRIT_NEG;   // max(-1, -1) = -1
      4'b0001: return TRIT_ZERO;  // max(-1, 0) = 0
      4'b0010: return TRIT_POS;   // max(-1, 1) = 1
      4'b0100: return TRIT_ZERO;  // max(0, -1) = 0
      4'b0101: return TRIT_ZERO;  // max(0, 0) = 0
      4'b0110: return TRIT_POS;   // max(0, 1) = 1
      4'b1000: return TRIT_POS;   // max(1, -1) = 1
      4'b1001: return TRIT_POS;   // max(1, 0) = 1
      4'b1010: return TRIT_POS;   // max(1, 1) = 1
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_xor(logic [1:0] a, logic [1:0] b);
    // Ternary XOR: (a + b) mod 3, mapped to {-1, 0, 1}
    case ({a, b})
      4'b0000: return TRIT_POS;   // (-1) ⊕ (-1) = 1
      4'b0001: return TRIT_NEG;   // (-1) ⊕ 0 = -1
      4'b0010: return TRIT_ZERO;  // (-1) ⊕ 1 = 0
      4'b0100: return TRIT_NEG;   // 0 ⊕ (-1) = -1
      4'b0101: return TRIT_ZERO;  // 0 ⊕ 0 = 0
      4'b0110: return TRIT_POS;   // 0 ⊕ 1 = 1
      4'b1000: return TRIT_ZERO;  // 1 ⊕ (-1) = 0
      4'b1001: return TRIT_POS;   // 1 ⊕ 0 = 1
      4'b1010: return TRIT_NEG;   // 1 ⊕ 1 = -1
      default: return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  function automatic logic [1:0] trit_not(logic [1:0] a);
    // Ternary NOT: negate
    case (a)
      TRIT_NEG:  return TRIT_POS;   // -(-1) = 1
      TRIT_ZERO: return TRIT_ZERO;  // -0 = 0
      TRIT_POS:  return TRIT_NEG;   // -1 = -1
      default:   return TRIT_ZERO;  // Invalid → 0
    endcase
  endfunction

  // Main ALU logic
  always_comb begin
    result_o = 32'h0;
    ready_o = 1'b1;

    case (operator_i)
      TERNARY_ADD: begin
        for (int i = 0; i < 16; i++) begin
          result_o[i*2 +: 2] = trit_add(operand_a_i[i*2 +: 2], operand_b_i[i*2 +: 2]);
        end
      end

      TERNARY_SUB: begin
        for (int i = 0; i < 16; i++) begin
          result_o[i*2 +: 2] = trit_sub(operand_a_i[i*2 +: 2], operand_b_i[i*2 +: 2]);
        end
      end

      TERNARY_MUL: begin
        for (int i = 0; i < 16; i++) begin
          result_o[i*2 +: 2] = trit_mul(operand_a_i[i*2 +: 2], operand_b_i[i*2 +: 2]);
        end
      end

      TERNARY_AND: begin
        for (int i = 0; i < 16; i++) begin
          result_o[i*2 +: 2] = trit_and(operand_a_i[i*2 +: 2], operand_b_i[i*2 +: 2]);
        end
      end

      TERNARY_OR: begin
        for (int i = 0; i < 16; i++) begin
          result_o[i*2 +: 2] = trit_or(operand_a_i[i*2 +: 2], operand_b_i[i*2 +: 2]);
        end
      end

      TERNARY_XOR: begin
        for (int i = 0; i < 16; i++) begin
          result_o[i*2 +: 2] = trit_xor(operand_a_i[i*2 +: 2], operand_b_i[i*2 +: 2]);
        end
      end

      TERNARY_NOT: begin
        for (int i = 0; i < 16; i++) begin
          result_o[i*2 +: 2] = trit_not(operand_a_i[i*2 +: 2]);
        end
      end

      default: result_o = 32'h55555555; // All zeros in ternary
    endcase
  end

endmodule
