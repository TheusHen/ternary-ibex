// MHX Ternary UVM Package
// Contains all UVM components and utilities for ternary extension verification

package mhx_ternary_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  // Import ternary-specific types from ibex_pkg
  import ibex_pkg::*;
  
  // Ternary operation types
  typedef enum logic [2:0] {
    TERNARY_ADD  = 3'b000,
    TERNARY_SUB  = 3'b001, 
    TERNARY_MUL  = 3'b010,
    TERNARY_AND  = 3'b011,
    TERNARY_OR   = 3'b100,
    TERNARY_XOR  = 3'b101,
    TERNARY_NOT  = 3'b110
  } ternary_op_e;
  
  typedef enum logic [1:0] {
    NEURAL_MULTIPLY   = 2'b00,
    NEURAL_ACCUMULATE = 2'b01,
    NEURAL_ACTIVATE   = 2'b10,
    NEURAL_LEARN      = 2'b11
  } neural_op_e;

  // Include all UVM components
  `include "mhx_ternary_transaction.sv"
  `include "mhx_ternary_config.sv"
  `include "mhx_ternary_sequencer.sv"
  `include "mhx_ternary_driver.sv"
  `include "mhx_ternary_monitor.sv"
  `include "mhx_ternary_agent.sv"
  `include "mhx_ternary_scoreboard.sv"
  `include "mhx_ternary_coverage.sv"
  `include "mhx_ternary_env.sv"
  `include "mhx_ternary_sequences.sv"
  `include "mhx_ternary_tests.sv"

endpackage : mhx_ternary_pkg