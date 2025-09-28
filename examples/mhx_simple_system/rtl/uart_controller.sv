// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Simple UART Controller for MHX Simple System
 *
 * Basic UART with fixed 115200 baud rate for debug output
 * Memory mapped interface at base address + offsets:
 * 0x00: UART_DATA  - Transmit/Receive data register
 * 0x04: UART_STATUS - Status register (bit 0: TX ready, bit 1: RX ready)
 * 0x08: UART_CTRL  - Control register (bit 0: TX enable, bit 1: RX enable, bit 2: IRQ enable)
 */

module uart_controller (
  input  logic        clk_i,
  input  logic        rst_ni,

  // Bus interface
  input  logic        req_i,
  input  logic        we_i,
  input  logic [3:0]  be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,
  output logic        rvalid_o,
  output logic [31:0] rdata_o,

  // UART pins
  output logic        uart_tx_o,
  input  logic        uart_rx_i,
  output logic        uart_irq_o
);

  // Register addresses
  localparam logic [31:0] UART_DATA_ADDR   = 32'h00;
  localparam logic [31:0] UART_STATUS_ADDR = 32'h04;
  localparam logic [31:0] UART_CTRL_ADDR   = 32'h08;

  // UART parameters for 115200 baud at 50MHz clock
  localparam int BAUD_RATE = 115200;
  localparam int CLK_FREQ = 50000000;
  localparam int BAUD_DIV = CLK_FREQ / BAUD_RATE;

  // Internal registers
  logic [7:0]  tx_data_reg;
  logic [7:0]  rx_data_reg;
  logic [2:0]  ctrl_reg;    // [2]=irq_en, [1]=rx_en, [0]=tx_en
  logic        tx_ready;
  logic        rx_ready;
  logic        tx_start;

  // UART transmitter
  logic [$clog2(BAUD_DIV)-1:0] tx_counter;
  logic [3:0] tx_bit_counter;
  logic [9:0] tx_shift_reg; // start + 8 data + stop
  
  typedef enum logic [1:0] {
    TX_IDLE,
    TX_START,
    TX_DATA,
    TX_STOP
  } tx_state_e;
  
  tx_state_e tx_state;

  // Address decoding
  logic [31:0] word_addr;
  assign word_addr = {addr_i[31:2], 2'b00};

  // Status signals
  assign tx_ready = (tx_state == TX_IDLE);
  assign rx_ready = 1'b0; // Simplified - no actual RX implementation
  assign uart_irq_o = ctrl_reg[2] && (tx_ready || rx_ready);

  // Read logic
  always_comb begin
    rdata_o = 32'h0;
    case (word_addr[7:0])
      UART_DATA_ADDR[7:0]:   rdata_o = {24'h0, rx_data_reg};
      UART_STATUS_ADDR[7:0]: rdata_o = {30'h0, rx_ready, tx_ready};
      UART_CTRL_ADDR[7:0]:   rdata_o = {29'h0, ctrl_reg};
      default:               rdata_o = 32'h0;
    endcase
  end

  // Write logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tx_data_reg <= 8'h0;
      rx_data_reg <= 8'h0;
      ctrl_reg    <= 3'b001; // TX enabled by default
      rvalid_o    <= 1'b0;
      tx_start    <= 1'b0;
    end else begin
      rvalid_o <= req_i;
      tx_start <= 1'b0;

      if (req_i && we_i) begin
        case (word_addr[7:0])
          UART_DATA_ADDR[7:0]: begin
            if (be_i[0] && tx_ready && ctrl_reg[0]) begin
              tx_data_reg <= wdata_i[7:0];
              tx_start    <= 1'b1;
            end
          end
          UART_CTRL_ADDR[7:0]: begin
            if (be_i[0]) ctrl_reg <= wdata_i[2:0];
          end
          default: begin
            // Read-only or invalid address
          end
        endcase
      end
    end
  end

  // UART transmitter state machine
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tx_state       <= TX_IDLE;
      tx_counter     <= '0;
      tx_bit_counter <= '0;
      tx_shift_reg   <= 10'h3FF; // All ones (idle state)
      uart_tx_o      <= 1'b1;
    end else begin
      case (tx_state)
        TX_IDLE: begin
          uart_tx_o <= 1'b1;
          if (tx_start) begin
            tx_shift_reg   <= {1'b1, tx_data_reg, 1'b0}; // stop + data + start
            tx_counter     <= '0;
            tx_bit_counter <= '0;
            tx_state       <= TX_START;
          end
        end
        
        TX_START, TX_DATA, TX_STOP: begin
          if (tx_counter == ($clog2(BAUD_DIV))'(BAUD_DIV - 1)) begin
            tx_counter <= '0;
            uart_tx_o  <= tx_shift_reg[0];
            tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
            
            if (tx_bit_counter == 9) begin
              tx_state <= TX_IDLE;
            end else begin
              tx_bit_counter <= tx_bit_counter + 1;
              tx_state <= TX_DATA;
            end
          end else begin
            tx_counter <= tx_counter + 1;
          end
        end
      endcase
    end
  end

  // Simplified RX (just store received data, no actual UART RX logic)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rx_data_reg <= 8'h0;
    end else begin
      // In a real implementation, this would include UART RX logic
      // For now, just echo back for testing
      if (tx_start) begin
        rx_data_reg <= tx_data_reg;
      end
    end
  end

endmodule
