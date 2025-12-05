// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Ternary Debug Module
 *
 * JTAG debug interface for ternary registers and operations:
 * - Read/Write access to all 32 ternary registers
 * - Ternary ALU single-step execution
 * - Breakpoints on ternary register access
 * - Performance counter access
 * - Neural unit state inspection
 *
 * Integration with standard RISC-V debug module (dm_top).
 */

`include "prim_assert.sv"

module ibex_ternary_debug import ibex_pkg::*; #(
  parameter int unsigned NumBreakpoints = 4
) (
  input  logic                         clk_i,
  input  logic                         rst_ni,

  // Debug Module Interface (DMI)
  input  logic                         dmi_req_valid_i,
  output logic                         dmi_req_ready_o,
  input  logic [6:0]                   dmi_req_addr_i,
  input  logic [1:0]                   dmi_req_op_i,     // 0=NOP, 1=READ, 2=WRITE
  input  logic [31:0]                  dmi_req_data_i,
  output logic                         dmi_resp_valid_o,
  input  logic                         dmi_resp_ready_i,
  output logic [31:0]                  dmi_resp_data_o,
  output logic [1:0]                   dmi_resp_op_o,    // 0=SUCCESS, 2=FAILED, 3=BUSY

  // Ternary Register File Interface
  output logic [4:0]                   treg_raddr_o,
  input  logic [TERNARY_REG_WIDTH-1:0] treg_rdata_i,
  output logic [4:0]                   treg_waddr_o,
  output logic [TERNARY_REG_WIDTH-1:0] treg_wdata_o,
  output logic                         treg_we_o,

  // Ternary ALU Control (for single-step)
  output logic [TERNARY_REG_WIDTH-1:0] debug_operand_a_o,
  output logic [TERNARY_REG_WIDTH-1:0] debug_operand_b_o,
  output ternary_op_e                  debug_operator_o,
  output logic                         debug_alu_req_o,
  input  logic [TERNARY_REG_WIDTH-1:0] debug_alu_result_i,
  input  logic                         debug_alu_ready_i,

  // Performance Counters Interface
  output logic [11:0]                  perf_csr_addr_o,
  input  logic [31:0]                  perf_csr_rdata_i,
  input  logic                         perf_csr_valid_i,

  // Core control
  output logic                         halt_req_o,       // Request core halt
  output logic                         resume_req_o,     // Request core resume
  input  logic                         halted_i,         // Core is halted
  input  logic                         running_i,        // Core is running

  // Breakpoint interface
  output logic [NumBreakpoints-1:0]    bp_enabled_o,
  output logic [4:0]                   bp_treg_addr_o [NumBreakpoints],
  output logic                         bp_on_read_o  [NumBreakpoints],
  output logic                         bp_on_write_o [NumBreakpoints],
  input  logic                         bp_hit_i
);

  // DMI operation codes
  localparam logic [1:0] DMI_OP_NOP   = 2'b00;
  localparam logic [1:0] DMI_OP_READ  = 2'b01;
  localparam logic [1:0] DMI_OP_WRITE = 2'b10;

  // Response codes
  localparam logic [1:0] DMI_RESP_SUCCESS = 2'b00;
  localparam logic [1:0] DMI_RESP_FAILED  = 2'b10;
  localparam logic [1:0] DMI_RESP_BUSY    = 2'b11;

  // Debug register addresses (custom ternary extension)
  localparam logic [6:0] DBG_TERNARY_CTRL    = 7'h40;  // Ternary debug control
  localparam logic [6:0] DBG_TERNARY_STATUS  = 7'h41;  // Ternary debug status
  localparam logic [6:0] DBG_TREG_ADDR       = 7'h42;  // Ternary register address
  localparam logic [6:0] DBG_TREG_DATA       = 7'h43;  // Ternary register data
  localparam logic [6:0] DBG_ALU_OP          = 7'h44;  // ALU operation
  localparam logic [6:0] DBG_ALU_OP_A        = 7'h45;  // ALU operand A
  localparam logic [6:0] DBG_ALU_OP_B        = 7'h46;  // ALU operand B
  localparam logic [6:0] DBG_ALU_RESULT      = 7'h47;  // ALU result
  localparam logic [6:0] DBG_PERF_ADDR       = 7'h48;  // Performance counter address
  localparam logic [6:0] DBG_PERF_DATA       = 7'h49;  // Performance counter data
  localparam logic [6:0] DBG_BP_CTRL         = 7'h4A;  // Breakpoint control
  localparam logic [6:0] DBG_BP_ADDR         = 7'h4B;  // Breakpoint address

  // FSM states
  typedef enum logic [2:0] {
    DBG_IDLE,
    DBG_READ_TREG,
    DBG_WRITE_TREG,
    DBG_EXEC_ALU,
    DBG_WAIT_ALU,
    DBG_READ_PERF,
    DBG_RESPOND
  } dbg_state_e;

  dbg_state_e state_q, state_d;

  // Internal registers
  logic [4:0]  treg_addr_q;
  logic [TERNARY_REG_WIDTH-1:0] treg_data_q;
  logic [TERNARY_REG_WIDTH-1:0] alu_operand_a_q;
  logic [TERNARY_REG_WIDTH-1:0] alu_operand_b_q;
  ternary_op_e alu_operator_q;
  logic [TERNARY_REG_WIDTH-1:0] alu_result_q;
  logic [11:0] perf_addr_q;
  logic [31:0] perf_data_q;
  logic [31:0] response_data_q;
  logic [1:0]  response_op_q;

  // Breakpoint configuration
  logic [NumBreakpoints-1:0] bp_enabled_q;
  logic [4:0]                bp_addr_q [NumBreakpoints];
  logic                      bp_read_q [NumBreakpoints];
  logic                      bp_write_q [NumBreakpoints];
  logic [1:0]                bp_select_q;

  // State machine
  always_comb begin
    state_d = state_q;
    treg_raddr_o = treg_addr_q;
    treg_waddr_o = '0;
    treg_wdata_o = '0;
    treg_we_o = 1'b0;

    debug_operand_a_o = alu_operand_a_q;
    debug_operand_b_o = alu_operand_b_q;
    debug_operator_o = alu_operator_q;
    debug_alu_req_o = 1'b0;

    perf_csr_addr_o = perf_addr_q;

    dmi_req_ready_o = 1'b0;
    dmi_resp_valid_o = 1'b0;
    dmi_resp_data_o = response_data_q;
    dmi_resp_op_o = response_op_q;

    halt_req_o = 1'b0;
    resume_req_o = 1'b0;

    // Handle halt/resume control register writes
    if (dmi_req_valid_i && dmi_req_op_i == DMI_OP_WRITE &&
        dmi_req_addr_i == DBG_TERNARY_CTRL) begin
      halt_req_o = dmi_req_data_i[0];
      resume_req_o = dmi_req_data_i[1];
    end

    case (state_q)
      DBG_IDLE: begin
        dmi_req_ready_o = 1'b1;

        if (dmi_req_valid_i) begin
          case (dmi_req_op_i)
            DMI_OP_READ: begin
              case (dmi_req_addr_i)
                DBG_TREG_DATA: state_d = DBG_READ_TREG;
                DBG_ALU_RESULT: state_d = DBG_RESPOND;
                DBG_PERF_DATA: state_d = DBG_READ_PERF;
                default: state_d = DBG_RESPOND;
              endcase
            end

            DMI_OP_WRITE: begin
              case (dmi_req_addr_i)
                DBG_TREG_DATA: state_d = DBG_WRITE_TREG;
                DBG_ALU_OP: state_d = DBG_EXEC_ALU;
                default: state_d = DBG_RESPOND;
              endcase
            end

            default: state_d = DBG_RESPOND;
          endcase
        end
      end

      DBG_READ_TREG: begin
        treg_raddr_o = treg_addr_q;
        state_d = DBG_RESPOND;
      end

      DBG_WRITE_TREG: begin
        treg_waddr_o = treg_addr_q;
        treg_wdata_o = treg_data_q;
        treg_we_o = 1'b1;
        state_d = DBG_RESPOND;
      end

      DBG_EXEC_ALU: begin
        debug_alu_req_o = 1'b1;
        state_d = DBG_WAIT_ALU;
      end

      DBG_WAIT_ALU: begin
        if (debug_alu_ready_i) begin
          state_d = DBG_RESPOND;
        end
      end

      DBG_READ_PERF: begin
        if (perf_csr_valid_i) begin
          state_d = DBG_RESPOND;
        end
      end

      DBG_RESPOND: begin
        dmi_resp_valid_o = 1'b1;
        if (dmi_resp_ready_i) begin
          state_d = DBG_IDLE;
        end
      end

      default: state_d = DBG_IDLE;
    endcase
  end

  // Register updates
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= DBG_IDLE;
      treg_addr_q <= '0;
      treg_data_q <= '0;
      alu_operand_a_q <= '0;
      alu_operand_b_q <= '0;
      alu_operator_q <= TERNARY_ADD;
      alu_result_q <= '0;
      perf_addr_q <= '0;
      perf_data_q <= '0;
      response_data_q <= '0;
      response_op_q <= DMI_RESP_SUCCESS;
      bp_enabled_q <= '0;
      bp_select_q <= '0;
      for (int i = 0; i < NumBreakpoints; i++) begin
        bp_addr_q[i] <= '0;
        bp_read_q[i] <= 1'b0;
        bp_write_q[i] <= 1'b0;
      end
    end else begin
      state_q <= state_d;

      // Handle DMI writes
      if (dmi_req_valid_i && dmi_req_op_i == DMI_OP_WRITE) begin
        case (dmi_req_addr_i)
          DBG_TERNARY_CTRL: begin
            // Control register: bit 0 = halt, bit 1 = resume
            // Handled combinationally above
          end

          DBG_TREG_ADDR: begin
            treg_addr_q <= dmi_req_data_i[4:0];
          end

          DBG_TREG_DATA: begin
            treg_data_q <= dmi_req_data_i;
          end

          DBG_ALU_OP: begin
            alu_operator_q <= ternary_op_e'(dmi_req_data_i[2:0]);
          end

          DBG_ALU_OP_A: begin
            alu_operand_a_q <= dmi_req_data_i;
          end

          DBG_ALU_OP_B: begin
            alu_operand_b_q <= dmi_req_data_i;
          end

          DBG_PERF_ADDR: begin
            perf_addr_q <= dmi_req_data_i[11:0];
          end

          DBG_BP_CTRL: begin
            bp_select_q <= dmi_req_data_i[1:0];
            if (32'(dmi_req_data_i[1:0]) < NumBreakpoints) begin
              bp_enabled_q[dmi_req_data_i[1:0]] <= dmi_req_data_i[8];
              bp_read_q[dmi_req_data_i[1:0]] <= dmi_req_data_i[9];
              bp_write_q[dmi_req_data_i[1:0]] <= dmi_req_data_i[10];
            end
          end

          DBG_BP_ADDR: begin
            bp_addr_q[bp_select_q] <= dmi_req_data_i[4:0];
          end

          default: ;
        endcase
      end

      // Update response data based on state
      case (state_q)
        DBG_READ_TREG: begin
          response_data_q <= treg_rdata_i;
          response_op_q <= DMI_RESP_SUCCESS;
        end

        DBG_WAIT_ALU: begin
          if (debug_alu_ready_i) begin
            alu_result_q <= debug_alu_result_i;
            response_data_q <= debug_alu_result_i;
            response_op_q <= DMI_RESP_SUCCESS;
          end
        end

        DBG_READ_PERF: begin
          if (perf_csr_valid_i) begin
            perf_data_q <= perf_csr_rdata_i;
            response_data_q <= perf_csr_rdata_i;
            response_op_q <= DMI_RESP_SUCCESS;
          end
        end

        DBG_RESPOND: begin
          // Prepare response for various read requests
          if (dmi_req_addr_i == DBG_TERNARY_STATUS) begin
            response_data_q <= {30'b0, running_i, halted_i};
          end else if (dmi_req_addr_i == DBG_ALU_RESULT) begin
            response_data_q <= alu_result_q;
          end
        end

        default: ;
      endcase
    end
  end

  // Breakpoint outputs
  assign bp_enabled_o = bp_enabled_q;
  generate
    for (genvar i = 0; i < NumBreakpoints; i++) begin : gen_bp_outputs
      assign bp_treg_addr_o[i] = bp_addr_q[i];
      assign bp_on_read_o[i] = bp_read_q[i];
      assign bp_on_write_o[i] = bp_write_q[i];
    end
  endgenerate

  ///////////////////////////
  // Formal Verification   //
  ///////////////////////////

  // DMI handshake protocol
  `ASSERT(DmiReqReady, dmi_req_valid_i && dmi_req_ready_o |=> !dmi_req_ready_o, clk_i, !rst_ni)
  `ASSERT(DmiRespValid, dmi_resp_valid_o && dmi_resp_ready_i |=> !dmi_resp_valid_o, clk_i, !rst_ni)

  // Only one state active
  `ASSERT(ValidState, state_q inside {DBG_IDLE, DBG_READ_TREG, DBG_WRITE_TREG,
                                      DBG_EXEC_ALU, DBG_WAIT_ALU, DBG_READ_PERF,
                                      DBG_RESPOND}, clk_i, !rst_ni)

  // Treg write only in write state
  `ASSERT(TregWeOnlyInWrite, treg_we_o |-> (state_q == DBG_WRITE_TREG), clk_i, !rst_ni)

  // ALU request only in exec state
  `ASSERT(AluReqOnlyInExec, debug_alu_req_o |-> (state_q == DBG_EXEC_ALU), clk_i, !rst_ni)

endmodule
