// Standalone Ternary ALU for Synthesis
// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Ternary Arithmetic Logic Unit for MHX Neural T1 (Synthesis Version)
 *
 * Performs arithmetic and logical operations on ternary data.
 * Each trit is encoded using 2 bits:
 * - 2'b00 = -1 (negative)
 * - 2'b01 = 0  (zero)
 * - 2'b10 = +1 (positive)
 * - 2'b11 = invalid
 */

typedef enum logic [2:0] {
  TERNARY_ADD = 3'b000,
  TERNARY_SUB = 3'b001,
  TERNARY_MUL = 3'b010,
  TERNARY_AND = 3'b011,
  TERNARY_OR  = 3'b100,
  TERNARY_XOR = 3'b101,
  TERNARY_NOT = 3'b110
} ternary_op_e;

module ibex_ternary_alu_synth (
  input  logic [31:0]       operand_a_i,  // 16 trits * 2 bits
  input  logic [31:0]       operand_b_i,  // 16 trits * 2 bits
  input  ternary_op_e       operator_i,

  output logic [31:0]       result_o,
  output logic              ready_o
);

  // Individual trit operations
  function automatic logic [1:0] ternary_add_trit(input logic [1:0] a, input logic [1:0] b);
    case ({a, b})
      4'b0000: ternary_add_trit = 2'b00; // -1 + -1 = -1 (saturated)
      4'b0001: ternary_add_trit = 2'b00; // -1 + 0  = -1
      4'b0010: ternary_add_trit = 2'b01; // -1 + 1  = 0
      4'b0100: ternary_add_trit = 2'b00; // 0  + -1 = -1
      4'b0101: ternary_add_trit = 2'b01; // 0  + 0  = 0
      4'b0110: ternary_add_trit = 2'b10; // 0  + 1  = 1
      4'b1000: ternary_add_trit = 2'b01; // 1  + -1 = 0
      4'b1001: ternary_add_trit = 2'b10; // 1  + 0  = 1
      4'b1010: ternary_add_trit = 2'b10; // 1  + 1  = 1 (saturated)
      default: ternary_add_trit = 2'b01; // Invalid -> 0
    endcase
  endfunction

  function automatic logic [1:0] ternary_sub_trit(input logic [1:0] a, input logic [1:0] b);
    case ({a, b})
      4'b0000: ternary_sub_trit = 2'b01; // -1 - -1 = 0
      4'b0001: ternary_sub_trit = 2'b00; // -1 - 0  = -1
      4'b0010: ternary_sub_trit = 2'b00; // -1 - 1  = -1 (saturated)
      4'b0100: ternary_sub_trit = 2'b10; // 0  - -1 = 1
      4'b0101: ternary_sub_trit = 2'b01; // 0  - 0  = 0
      4'b0110: ternary_sub_trit = 2'b00; // 0  - 1  = -1
      4'b1000: ternary_sub_trit = 2'b10; // 1  - -1 = 1 (saturated)
      4'b1001: ternary_sub_trit = 2'b10; // 1  - 0  = 1
      4'b1010: ternary_sub_trit = 2'b01; // 1  - 1  = 0
      default: ternary_sub_trit = 2'b01; // Invalid -> 0
    endcase
  endfunction

  function automatic logic [1:0] ternary_mul_trit(input logic [1:0] a, input logic [1:0] b);
    case ({a, b})
      4'b0000: ternary_mul_trit = 2'b10; // -1 * -1 = 1
      4'b0001: ternary_mul_trit = 2'b01; // -1 * 0  = 0
      4'b0010: ternary_mul_trit = 2'b00; // -1 * 1  = -1
      4'b0100: ternary_mul_trit = 2'b01; // 0  * -1 = 0
      4'b0101: ternary_mul_trit = 2'b01; // 0  * 0  = 0
      4'b0110: ternary_mul_trit = 2'b01; // 0  * 1  = 0
      4'b1000: ternary_mul_trit = 2'b00; // 1  * -1 = -1
      4'b1001: ternary_mul_trit = 2'b01; // 1  * 0  = 0
      4'b1010: ternary_mul_trit = 2'b10; // 1  * 1  = 1
      default: ternary_mul_trit = 2'b01; // Invalid -> 0
    endcase
  endfunction

  function automatic logic [1:0] ternary_and_trit(input logic [1:0] a, input logic [1:0] b);
    // Min operation
    if (a == 2'b00 || b == 2'b00) return 2'b00; // -1
    if (a == 2'b01 || b == 2'b01) return 2'b01; // 0
    return 2'b10; // 1
  endfunction

  function automatic logic [1:0] ternary_or_trit(input logic [1:0] a, input logic [1:0] b);
    // Max operation
    if (a == 2'b10 || b == 2'b10) return 2'b10; // 1
    if (a == 2'b01 || b == 2'b01) return 2'b01; // 0
    return 2'b00; // -1
  endfunction

  function automatic logic [1:0] ternary_xor_trit(input logic [1:0] a, input logic [1:0] b);
    case ({a, b})
      4'b0000: return 2'b01; // -1 XOR -1 = 0
      4'b0001: return 2'b00; // -1 XOR 0  = -1
      4'b0010: return 2'b10; // -1 XOR 1  = 1
      4'b0100: return 2'b00; // 0  XOR -1 = -1
      4'b0101: return 2'b01; // 0  XOR 0  = 0
      4'b0110: return 2'b10; // 0  XOR 1  = 1
      4'b1000: return 2'b10; // 1  XOR -1 = 1
      4'b1001: return 2'b10; // 1  XOR 0  = 1
      4'b1010: return 2'b01; // 1  XOR 1  = 0
      default: return 2'b01; // Invalid -> 0
    endcase
  endfunction

  function automatic logic [1:0] ternary_not_trit(input logic [1:0] a);
    case (a)
      2'b00: return 2'b10; // NOT -1 = 1
      2'b01: return 2'b01; // NOT 0  = 0
      2'b10: return 2'b00; // NOT 1  = -1
      default: return 2'b01; // Invalid -> 0
    endcase
  endfunction

  // ALU operation logic
  always_comb begin
    result_o = 32'h0;
    ready_o = 1'b1;

    for (int i = 0; i < 16; i++) begin
      logic [1:0] trit_a = operand_a_i[i*2 +: 2];
      logic [1:0] trit_b = operand_b_i[i*2 +: 2];
      logic [1:0] trit_result;

      case (operator_i)
        TERNARY_ADD: trit_result = ternary_add_trit(trit_a, trit_b);
        TERNARY_SUB: trit_result = ternary_sub_trit(trit_a, trit_b);
        TERNARY_MUL: trit_result = ternary_mul_trit(trit_a, trit_b);
        TERNARY_AND: trit_result = ternary_and_trit(trit_a, trit_b);
        TERNARY_OR:  trit_result = ternary_or_trit(trit_a, trit_b);
        TERNARY_XOR: trit_result = ternary_xor_trit(trit_a, trit_b);
        TERNARY_NOT: trit_result = ternary_not_trit(trit_a);
        default:     trit_result = 2'b01; // Default to 0
      endcase

      result_o[i*2 +: 2] = trit_result;
    end
  end

endmodule