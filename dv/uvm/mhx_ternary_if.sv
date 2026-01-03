// MHX™ Ternary UVM Interface
// Virtual interface for connecting testbench to DUT

interface mhx_ternary_if (
  input logic clk_i,
  input logic rst_ni
);

  // Core signals
  logic                   instr_valid_i;
  logic [31:0]           instr_rdata_i;
  logic [31:0]           pc_id;

  // Ternary-specific signals
  logic                   ternary_en_id;
  logic                   neural_en_id;
  ternary_op_e           ternary_op_id;
  neural_op_e            neural_op_id;

  // Register file interface
  logic [4:0]            ternary_raddr_a_id;
  logic [4:0]            ternary_raddr_b_id;
  logic [4:0]            ternary_waddr_id;
  logic [31:0]           ternary_rdata_a;
  logic [31:0]           ternary_rdata_b;
  logic [31:0]           ternary_wdata;
  logic                   ternary_we_wb;

  // ALU interface
  logic [31:0]           ternary_alu_operand_a;
  logic [31:0]           ternary_alu_operand_b;
  logic [31:0]           ternary_alu_result;
  logic                   ternary_alu_ready;
  logic                   ternary_alu_overflow;
  logic [15:0]           ternary_trit_overflow;

  // Neural unit interface
  logic [31:0]           neural_weights;
  logic [31:0]           neural_inputs;
  logic [31:0]           neural_bias;
  logic [31:0]           neural_result;
  logic                   neural_valid;

  // Debug signals
  logic [31:0]           debug_ternary_pc;
  logic [31:0]           debug_ternary_instr;
  logic                   debug_error_flag;

  // Clocking blocks for synchronous driving/sampling
  clocking driver_cb @(posedge clk_i);
    default input #1 output #1;
    output instr_valid_i;
    output instr_rdata_i;
    output pc_id;
    input  ternary_en_id;
    input  neural_en_id;
    input  ternary_op_id;
    input  neural_op_id;
  endclocking

  clocking monitor_cb @(posedge clk_i);
    default input #1;
    input instr_valid_i;
    input instr_rdata_i;
    input pc_id;
    input ternary_en_id;
    input neural_en_id;
    input ternary_op_id;
    input neural_op_id;
    input ternary_raddr_a_id;
    input ternary_raddr_b_id;
    input ternary_waddr_id;
    input ternary_rdata_a;
    input ternary_rdata_b;
    input ternary_wdata;
    input ternary_we_wb;
    input ternary_alu_result;
    input ternary_alu_ready;
    input ternary_alu_overflow;
    input neural_result;
    input neural_valid;
  endclocking

  // Modports
  modport driver (clocking driver_cb, input rst_ni);
  modport monitor (clocking monitor_cb, input rst_ni);

  // Helper functions for ternary validation
  function automatic logic is_valid_trit(logic [1:0] trit);
    return (trit inside {2'b00, 2'b01, 2'b10}); // Valid: NEG, ZERO, POS
  endfunction

  function automatic logic is_valid_ternary(logic [31:0] data);
    for (int i = 0; i < 16; i++) begin
      if (!is_valid_trit(data[i*2 +: 2])) return 1'b0;
    end
    return 1'b1;
  endfunction

  // Assertions for interface validation
  property valid_ternary_data;
    @(posedge clk_i) disable iff (!rst_ni)
    ternary_en_id |-> is_valid_ternary(ternary_alu_operand_a) &&
                     is_valid_ternary(ternary_alu_operand_b);
  endproperty

  property neural_data_consistency;
    @(posedge clk_i) disable iff (!rst_ni)
    neural_en_id |-> is_valid_ternary(neural_weights) &&
                    is_valid_ternary(neural_inputs);
  endproperty

  assert_valid_ternary_data: assert property(valid_ternary_data)
    else `uvm_error("INTF", "Invalid ternary data detected on interface");

  assert_neural_data_consistency: assert property(neural_data_consistency)
    else `uvm_error("INTF", "Invalid neural data detected on interface");

endinterface : mhx_ternary_if

