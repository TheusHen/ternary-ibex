// MHX Ternary UVM Transaction
// Base transaction class for all ternary operations

class mhx_ternary_transaction extends uvm_sequence_item;
  `uvm_object_utils(mhx_ternary_transaction)

  // Instruction fields
  rand logic [31:0] instruction;
  rand logic [6:0]  opcode;
  rand logic [2:0]  funct3;
  rand logic [6:0]  funct7;
  rand logic [4:0]  rs1, rs2, rd;
  rand logic [31:0] pc;

  // Ternary operation type
  rand ternary_op_e ternary_operation;
  rand neural_op_e  neural_operation;
  rand logic        is_ternary;
  rand logic        is_neural;

  // Ternary register addresses
  rand logic [4:0] ternary_rs1;
  rand logic [4:0] ternary_rs2;
  rand logic [4:0] ternary_rd;

  // Operands and results
  rand logic [31:0] operand_a;
  rand logic [31:0] operand_b;
  rand logic [31:0] bias;
  logic [31:0]      result;
  logic             ready;
  logic             overflow;
  logic [15:0]      trit_overflow;
  logic             valid;

  // Timing information
  int unsigned      start_cycle;
  int unsigned      end_cycle;
  int unsigned      latency;

  // Error flags
  logic             error_detected;
  string            error_message;

  // Constraints
  constraint c_valid_ternary_addresses {
    ternary_rs1 < 32;  // Updated for 32 ternary registers (T0-T31)
    ternary_rs2 < 32;  // Updated for 32 ternary registers (T0-T31)
    ternary_rd  < 32;  // Updated for 32 ternary registers (T0-T31)
  }

  constraint c_valid_ternary_data {
    // Ensure operands contain valid trits only
    foreach (operand_a[i]) {
      if (i % 2 == 0) operand_a[i+1:i] inside {2'b00, 2'b01, 2'b10};
    }
    foreach (operand_b[i]) {
      if (i % 2 == 0) operand_b[i+1:i] inside {2'b00, 2'b01, 2'b10};
    }
    foreach (bias[i]) {
      if (i % 2 == 0) bias[i+1:i] inside {2'b00, 2'b01, 2'b10};
    }
  }

  constraint c_operation_type {
    // Only one operation type at a time
    is_ternary + is_neural <= 1;

    // Valid operation ranges
    if (is_ternary)
      ternary_operation inside {
        TERNARY_ADD, TERNARY_SUB, TERNARY_MUL,
        TERNARY_AND, TERNARY_OR,  TERNARY_XOR, TERNARY_NOT
      };
    if (is_neural)
      neural_operation inside {
        NEURAL_MULTIPLY, NEURAL_ACCUMULATE, NEURAL_ACTIVATE, NEURAL_LEARN
      };
  }

  constraint c_instruction_encoding {
    // RISC-V instruction format constraints
    if (is_ternary) {
      opcode == 7'b0001011; // OPCODE_TERNARY
      funct3 == ternary_operation;
      instruction[6:0]   == opcode;
      instruction[14:12] == funct3;
      instruction[19:16] == ternary_rs1;
      instruction[23:20] == ternary_rs2;
      instruction[11:8]  == ternary_rd;
    }
    if (is_neural) {
      opcode == 7'b0101011; // OPCODE_NEURAL
      funct3[1:0] == neural_operation;
      instruction[6:0]   == opcode;
      instruction[14:12] == funct3;
      instruction[19:16] == ternary_rs1;
      instruction[23:20] == ternary_rs2;
      instruction[11:8]  == ternary_rd;
    }
  }

  function new(string name = "mhx_ternary_transaction");
    super.new(name);
  endfunction

  // Convert transaction to string for printing
  virtual function string convert2string();
    string s;
    s = super.convert2string();
    s = {s, $sformatf("\n  Instruction: 0x%08h", instruction)};
    s = {s, $sformatf("\n  PC: 0x%08h", pc)};
    if (is_ternary) begin
      s = {s, $sformatf("\n  Ternary Op: %s", ternary_operation.name())};
      s = {s, $sformatf(
                  "\n  T%0d = T%0d %s T%0d",
                  ternary_rd, ternary_rs1, ternary_operation.name(), ternary_rs2)};
    end
    if (is_neural) begin
      s = {s, $sformatf("\n  Neural Op: %s", neural_operation.name())};
      s = {s, $sformatf(
                  "\n  T%0d = T%0d %s T%0d (bias=T%0d)",
                  ternary_rd, ternary_rs1, neural_operation.name(), ternary_rs2, ternary_rs1)};
    end
    s = {s, $sformatf("\n  Operand A: 0x%08h", operand_a)};
    s = {s, $sformatf("\n  Operand B: 0x%08h", operand_b)};
    s = {s, $sformatf("\n  Result: 0x%08h", result)};
    s = {s, $sformatf("\n  Ready: %b, Overflow: %b, Valid: %b", ready, overflow, valid)};
    if (error_detected) begin
      s = {s, $sformatf("\n  ERROR: %s", error_message)};
    end
    return s;
  endfunction

  // Copy function
  virtual function void do_copy(uvm_object rhs);
    mhx_ternary_transaction rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("COPY", "Cast failed in do_copy")
    end
    super.do_copy(rhs);
    instruction = rhs_.instruction;
    opcode = rhs_.opcode;
    funct3 = rhs_.funct3;
    funct7 = rhs_.funct7;
    rs1 = rhs_.rs1;
    rs2 = rhs_.rs2;
    rd = rhs_.rd;
    pc = rhs_.pc;
    ternary_operation = rhs_.ternary_operation;
    neural_operation = rhs_.neural_operation;
    is_ternary = rhs_.is_ternary;
    is_neural = rhs_.is_neural;
    ternary_rs1 = rhs_.ternary_rs1;
    ternary_rs2 = rhs_.ternary_rs2;
    ternary_rd = rhs_.ternary_rd;
    operand_a = rhs_.operand_a;
    operand_b = rhs_.operand_b;
    bias = rhs_.bias;
    result = rhs_.result;
    ready = rhs_.ready;
    overflow = rhs_.overflow;
    trit_overflow = rhs_.trit_overflow;
    valid = rhs_.valid;
  endfunction

  // Compare function
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    mhx_ternary_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            instruction == rhs_.instruction &&
            pc == rhs_.pc &&
            ternary_operation == rhs_.ternary_operation &&
            neural_operation == rhs_.neural_operation &&
            operand_a == rhs_.operand_a &&
            operand_b == rhs_.operand_b &&
            result == rhs_.result);
  endfunction

  // Utility functions for ternary data manipulation
  function logic [1:0] get_trit(logic [31:0] data, int index);
    return data[index*2 +: 2];
  endfunction

  function void set_trit(ref logic [31:0] data, int index, logic [1:0] trit);
    data[index*2 +: 2] = trit;
  endfunction

  function logic is_valid_ternary_word(logic [31:0] data);
    for (int i = 0; i < 16; i++) begin
      logic [1:0] trit = get_trit(data, i);
      if (!(trit inside {2'b00, 2'b01, 2'b10})) return 1'b0;
    end
    return 1'b1;
  endfunction

endclass : mhx_ternary_transaction
// MHX Ternary UVM Transaction
// Base transaction class for all ternary operations

class mhx_ternary_transaction extends uvm_sequence_item;
  `uvm_object_utils(mhx_ternary_transaction)
  
  // Instruction fields
  rand logic [31:0] instruction;
  rand logic [6:0]  opcode;
  rand logic [2:0]  funct3;
  rand logic [6:0]  funct7;
  rand logic [4:0]  rs1, rs2, rd;
  rand logic [31:0] pc;
  
  // Ternary operation type
  rand ternary_op_e ternary_operation;
  rand neural_op_e  neural_operation;
  rand logic        is_ternary;
  rand logic        is_neural;
  
  // Ternary register addresses
  rand logic [4:0] ternary_rs1;
  rand logic [4:0] ternary_rs2;
  rand logic [4:0] ternary_rd;
  
  // Operands and results
  rand logic [31:0] operand_a;
  rand logic [31:0] operand_b;
  rand logic [31:0] bias;
  logic [31:0]      result;
  logic             ready;
  logic             overflow;
  logic [15:0]      trit_overflow;
  logic             valid;
  
  // Timing information
  int unsigned      start_cycle;
  int unsigned      end_cycle;
  int unsigned      latency;
  
  // Error flags
  logic             error_detected;
  string            error_message;
  
  // Constraints
  constraint c_valid_ternary_addresses {
    ternary_rs1 < 32;  // Updated for 32 ternary registers (T0-T31)
    ternary_rs2 < 32;  // Updated for 32 ternary registers (T0-T31)
    ternary_rd  < 32;  // Updated for 32 ternary registers (T0-T31)
  }
  
  constraint c_valid_ternary_data {
    // Ensure operands contain valid trits only
    foreach (operand_a[i]) {
      if (i % 2 == 0) operand_a[i+1:i] inside {2'b00, 2'b01, 2'b10};
    }
    foreach (operand_b[i]) {
      if (i % 2 == 0) operand_b[i+1:i] inside {2'b00, 2'b01, 2'b10};
    }
    foreach (bias[i]) {
      if (i % 2 == 0) bias[i+1:i] inside {2'b00, 2'b01, 2'b10};
    }
  }
  
  constraint c_operation_type {
    // Only one operation type at a time
    is_ternary + is_neural <= 1;
    
    // Valid operation ranges
    if (is_ternary) ternary_operation inside {TERNARY_ADD, TERNARY_SUB, TERNARY_MUL, 
                                              TERNARY_AND, TERNARY_OR, TERNARY_XOR, TERNARY_NOT};
    if (is_neural)  neural_operation inside {NEURAL_MULTIPLY, NEURAL_ACCUMULATE, 
                                             NEURAL_ACTIVATE, NEURAL_LEARN};
  }
  
  constraint c_instruction_encoding {
    // RISC-V instruction format constraints
    if (is_ternary) {
      opcode == 7'b0001011; // OPCODE_TERNARY
      funct3 == ternary_operation;
      instruction[6:0]   == opcode;
      instruction[14:12] == funct3;
      instruction[19:16] == ternary_rs1;
      instruction[23:20] == ternary_rs2;
      instruction[11:8]  == ternary_rd;
    }
    if (is_neural) {
      opcode == 7'b0101011; // OPCODE_NEURAL
      funct3[1:0] == neural_operation;
      instruction[6:0]   == opcode;
      instruction[14:12] == funct3;
      instruction[19:16] == ternary_rs1;
      instruction[23:20] == ternary_rs2;
      instruction[11:8]  == ternary_rd;
    }
  }
  
  function new(string name = "mhx_ternary_transaction");
    super.new(name);
  endfunction
  
  // Convert transaction to string for printing
  virtual function string convert2string();
    string s;
    s = super.convert2string();
    s = {s, $sformatf("\n  Instruction: 0x%08h", instruction)};
    s = {s, $sformatf("\n  PC: 0x%08h", pc)};
    if (is_ternary) begin
      s = {s, $sformatf("\n  Ternary Op: %s", ternary_operation.name())};
      s = {s, $sformatf("\n  T%0d = T%0d %s T%0d", ternary_rd, ternary_rs1, 
                       ternary_operation.name(), ternary_rs2)};
    end
    if (is_neural) begin
      s = {s, $sformatf("\n  Neural Op: %s", neural_operation.name())};
      s = {s, $sformatf("\n  T%0d = T%0d %s T%0d (bias=T%0d)", ternary_rd, ternary_rs1,
                       neural_operation.name(), ternary_rs2, ternary_rs1)};
    end
    s = {s, $sformatf("\n  Operand A: 0x%08h", operand_a)};
    s = {s, $sformatf("\n  Operand B: 0x%08h", operand_b)};
    s = {s, $sformatf("\n  Result: 0x%08h", result)};
    s = {s, $sformatf("\n  Ready: %b, Overflow: %b, Valid: %b", ready, overflow, valid)};
    if (error_detected) begin
      s = {s, $sformatf("\n  ERROR: %s", error_message)};
    end
    return s;
  endfunction
  
  // Copy function
  virtual function void do_copy(uvm_object rhs);
    mhx_ternary_transaction rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("COPY", "Cast failed in do_copy")
    end
    super.do_copy(rhs);
    instruction = rhs_.instruction;
    opcode = rhs_.opcode;
    funct3 = rhs_.funct3;
    funct7 = rhs_.funct7;
    rs1 = rhs_.rs1;
    rs2 = rhs_.rs2;
    rd = rhs_.rd;
    pc = rhs_.pc;
    ternary_operation = rhs_.ternary_operation;
    neural_operation = rhs_.neural_operation;
    is_ternary = rhs_.is_ternary;
    is_neural = rhs_.is_neural;
    ternary_rs1 = rhs_.ternary_rs1;
    ternary_rs2 = rhs_.ternary_rs2;
    ternary_rd = rhs_.ternary_rd;
    operand_a = rhs_.operand_a;
    operand_b = rhs_.operand_b;
    bias = rhs_.bias;
    result = rhs_.result;
    ready = rhs_.ready;
    overflow = rhs_.overflow;
    trit_overflow = rhs_.trit_overflow;
    valid = rhs_.valid;
  endfunction
  
  // Compare function
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    mhx_ternary_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            instruction == rhs_.instruction &&
            pc == rhs_.pc &&
            ternary_operation == rhs_.ternary_operation &&
            neural_operation == rhs_.neural_operation &&
            operand_a == rhs_.operand_a &&
            operand_b == rhs_.operand_b &&
            result == rhs_.result);
  endfunction
  
  // Utility functions for ternary data manipulation
  function logic [1:0] get_trit(logic [31:0] data, int index);
    return data[index*2 +: 2];
  endfunction
  
  function void set_trit(ref logic [31:0] data, int index, logic [1:0] trit);
    data[index*2 +: 2] = trit;
  endfunction
  
  function logic is_valid_ternary_word(logic [31:0] data);
    for (int i = 0; i < 16; i++) begin
      logic [1:0] trit = get_trit(data, i);
      if (!(trit inside {2'b00, 2'b01, 2'b10})) return 1'b0;
    end
    return 1'b1;
  endfunction

endclass : mhx_ternary_transaction
