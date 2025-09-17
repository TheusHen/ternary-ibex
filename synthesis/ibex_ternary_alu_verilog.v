// Verilog-compatible Ternary ALU for Synthesis
// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Ternary operation encodings
`define TERNARY_ADD  3'b000
`define TERNARY_SUB  3'b001
`define TERNARY_MUL  3'b010
`define TERNARY_AND  3'b011
`define TERNARY_OR   3'b100
`define TERNARY_XOR  3'b101
`define TERNARY_NOT  3'b110

module ibex_ternary_alu_verilog (
  input  [31:0] operand_a_i,    // First operand (16 trits)
  input  [31:0] operand_b_i,    // Second operand (16 trits)
  input  [2:0]  operation_i,    // Operation selector

  output [31:0] result_o,       // Result (16 trits)
  output        valid_o         // Operation valid
);

  reg [31:0] result_reg;
  reg valid_reg;
  
  // Wire declarations for intermediate calculations
  wire [1:0] trit_a [15:0];
  wire [1:0] trit_b [15:0];
  reg [1:0] trit_result [15:0];
  
  integer i;
  
  // Extract individual trits
  generate
    genvar j;
    for (j = 0; j < 16; j = j + 1) begin : trit_extract
      assign trit_a[j] = operand_a_i[j*2 +: 2];
      assign trit_b[j] = operand_b_i[j*2 +: 2];
    end
  endgenerate

  // Main ALU logic
  always @(*) begin
    valid_reg = 1'b1;
    
    // Initialize result
    for (i = 0; i < 16; i = i + 1) begin
      trit_result[i] = 2'b01; // Default to 0
    end
    
    case (operation_i)
      `TERNARY_ADD: begin
        for (i = 0; i < 16; i = i + 1) begin
          case ({trit_a[i], trit_b[i]})
            4'b0000: trit_result[i] = 2'b00; // -1 + -1 = -1 (saturated)
            4'b0001: trit_result[i] = 2'b00; // -1 + 0  = -1
            4'b0010: trit_result[i] = 2'b01; // -1 + 1  = 0
            4'b0100: trit_result[i] = 2'b00; // 0  + -1 = -1
            4'b0101: trit_result[i] = 2'b01; // 0  + 0  = 0
            4'b0110: trit_result[i] = 2'b10; // 0  + 1  = 1
            4'b1000: trit_result[i] = 2'b01; // 1  + -1 = 0
            4'b1001: trit_result[i] = 2'b10; // 1  + 0  = 1
            4'b1010: trit_result[i] = 2'b10; // 1  + 1  = 1 (saturated)
            default: trit_result[i] = 2'b01; // Invalid -> 0
          endcase
        end
      end
      
      `TERNARY_SUB: begin
        for (i = 0; i < 16; i = i + 1) begin
          case ({trit_a[i], trit_b[i]})
            4'b0000: trit_result[i] = 2'b01; // -1 - -1 = 0
            4'b0001: trit_result[i] = 2'b00; // -1 - 0  = -1
            4'b0010: trit_result[i] = 2'b00; // -1 - 1  = -1 (saturated)
            4'b0100: trit_result[i] = 2'b10; // 0  - -1 = 1
            4'b0101: trit_result[i] = 2'b01; // 0  - 0  = 0
            4'b0110: trit_result[i] = 2'b00; // 0  - 1  = -1
            4'b1000: trit_result[i] = 2'b10; // 1  - -1 = 1 (saturated)
            4'b1001: trit_result[i] = 2'b10; // 1  - 0  = 1
            4'b1010: trit_result[i] = 2'b01; // 1  - 1  = 0
            default: trit_result[i] = 2'b01; // Invalid -> 0
          endcase
        end
      end
      
      `TERNARY_MUL: begin
        for (i = 0; i < 16; i = i + 1) begin
          case ({trit_a[i], trit_b[i]})
            4'b0000: trit_result[i] = 2'b10; // -1 * -1 = 1
            4'b0001: trit_result[i] = 2'b01; // -1 * 0  = 0
            4'b0010: trit_result[i] = 2'b00; // -1 * 1  = -1
            4'b0100: trit_result[i] = 2'b01; // 0  * -1 = 0
            4'b0101: trit_result[i] = 2'b01; // 0  * 0  = 0
            4'b0110: trit_result[i] = 2'b01; // 0  * 1  = 0
            4'b1000: trit_result[i] = 2'b00; // 1  * -1 = -1
            4'b1001: trit_result[i] = 2'b01; // 1  * 0  = 0
            4'b1010: trit_result[i] = 2'b10; // 1  * 1  = 1
            default: trit_result[i] = 2'b01; // Invalid -> 0
          endcase
        end
      end
      
      `TERNARY_AND: begin
        for (i = 0; i < 16; i = i + 1) begin
          if (trit_a[i] == 2'b00 || trit_b[i] == 2'b00) 
            trit_result[i] = 2'b00; // Any -1 gives -1
          else if (trit_a[i] == 2'b10 && trit_b[i] == 2'b10) 
            trit_result[i] = 2'b10; // 1 AND 1 = 1
          else 
            trit_result[i] = 2'b01; // Otherwise 0
        end
      end
      
      `TERNARY_OR: begin
        for (i = 0; i < 16; i = i + 1) begin
          if (trit_a[i] == 2'b10 || trit_b[i] == 2'b10) 
            trit_result[i] = 2'b10; // Any 1 gives 1
          else if (trit_a[i] == 2'b00 && trit_b[i] == 2'b00) 
            trit_result[i] = 2'b00; // -1 OR -1 = -1
          else 
            trit_result[i] = 2'b01; // Otherwise 0
        end
      end
      
      `TERNARY_XOR: begin
        for (i = 0; i < 16; i = i + 1) begin
          case ({trit_a[i], trit_b[i]})
            4'b0000: trit_result[i] = 2'b01; // -1 XOR -1 = 0
            4'b0001: trit_result[i] = 2'b00; // -1 XOR 0  = -1
            4'b0010: trit_result[i] = 2'b10; // -1 XOR 1  = 1
            4'b0100: trit_result[i] = 2'b00; // 0  XOR -1 = -1
            4'b0101: trit_result[i] = 2'b01; // 0  XOR 0  = 0
            4'b0110: trit_result[i] = 2'b10; // 0  XOR 1  = 1
            4'b1000: trit_result[i] = 2'b10; // 1  XOR -1 = 1
            4'b1001: trit_result[i] = 2'b10; // 1  XOR 0  = 1
            4'b1010: trit_result[i] = 2'b01; // 1  XOR 1  = 0
            default: trit_result[i] = 2'b01; // Invalid -> 0
          endcase
        end
      end
      
      `TERNARY_NOT: begin
        for (i = 0; i < 16; i = i + 1) begin
          case (trit_a[i])
            2'b00: trit_result[i] = 2'b10; // NOT -1 = 1
            2'b01: trit_result[i] = 2'b01; // NOT 0  = 0
            2'b10: trit_result[i] = 2'b00; // NOT 1  = -1
            default: trit_result[i] = 2'b01; // Invalid -> 0
          endcase
        end
      end
      
      default: begin
        valid_reg = 1'b0;
        for (i = 0; i < 16; i = i + 1) begin
          trit_result[i] = 2'b01; // All zeros
        end
      end
    endcase
    
    // Pack result
    result_reg = 32'h0;
    for (i = 0; i < 16; i = i + 1) begin
      result_reg[i*2 +: 2] = trit_result[i];
    end
  end

  assign result_o = result_reg;
  assign valid_o = valid_reg;

endmodule