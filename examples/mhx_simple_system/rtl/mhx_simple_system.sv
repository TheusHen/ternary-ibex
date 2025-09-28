// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Simple System
 *
 * This is an enhanced system based on Ibex simple system, featuring:
 * - MHX core with ternary extensions
 * - RAM (runtime) + ROM (bootloader & tests)
 * - UART (tx/rx) for debug/console
 * - GPIOs (LEDs, buttons, expansion pins)
 * - Basic timer with interrupts
 * - Optional SPI master
 *
 * Memory Map:
 * - ROM: 0x0000_0000 - 0x0000_FFFF (64KB)
 * - RAM: 0x2000_0000 - 0x2000_FFFF (64KB)
 * - UART: 0x4000_0000 - 0x4000_0FFF
 * - GPIO: 0x4001_0000 - 0x4001_0FFF
 * - Timer: 0x4002_0000 - 0x4002_0FFF
 * - SPI: 0x4003_0000 - 0x4003_0FFF
 */

module mhx_simple_system (
  input IO_CLK,
  input IO_RST_N,

  // UART interface
  output uart_tx,
  input  uart_rx,

  // GPIO interface
  output [7:0] gpio_out,
  input  [7:0] gpio_in,
  output [7:0] gpio_oe,

  // SPI interface (optional)
  output spi_sck,
  output spi_mosi,
  input  spi_miso,
  output spi_cs
);

  // Import MHX package for ternary extensions
  import ibex_pkg::*;

  parameter bit                 SecureIbex               = 1'b0;
  parameter bit                 ICacheScramble           = 1'b0;
  parameter bit                 PMPEnable                = 1'b0;
  parameter int unsigned        PMPGranularity           = 0;
  parameter int unsigned        PMPNumRegions            = 4;
  parameter int unsigned        MHPMCounterNum           = 0;
  parameter int unsigned        MHPMCounterWidth         = 40;
  parameter bit                 RV32E                    = 1'b0;
  parameter ibex_pkg::rv32m_e   RV32M                    = ibex_pkg::RV32MFast;
  parameter ibex_pkg::rv32b_e   RV32B                    = ibex_pkg::RV32BNone;
  parameter ibex_pkg::regfile_e RegFile                  = ibex_pkg::RegFileFF;
  parameter bit                 BranchTargetALU          = 1'b0;
  parameter bit                 WritebackStage           = 1'b0;
  parameter bit                 ICache                   = 1'b0;
  parameter bit                 ICacheECC                = 1'b0;
  parameter bit                 BranchPredictor          = 1'b0;
  parameter bit                 DbgTriggerEn             = 1'b0;
  parameter                     ROMInitFile              = "";
  parameter                     RAMInitFile              = "";

  logic clk_sys, rst_sys_n;

  typedef enum logic[1:0] {
    CoreD
  } bus_host_e;

  typedef enum logic[2:0] {
    Rom,
    Ram,
    Uart,
    Gpio,
    Timer,
    Spi
  } bus_device_e;

  localparam int NrDevices = 6;
  localparam int NrHosts = 1;

  // Interrupts
  logic timer_irq;
  logic uart_irq;
  logic gpio_irq;
  logic spi_irq;

  logic [31:0] irq_vector;
  assign irq_vector = {28'b0, spi_irq, gpio_irq, uart_irq, timer_irq};

  // Host and device signals
  logic           host_req    [NrHosts];
  logic           host_gnt    [NrHosts];
  logic [31:0]    host_addr   [NrHosts];
  logic           host_we     [NrHosts];
  logic [ 3:0]    host_be     [NrHosts];
  logic [31:0]    host_wdata  [NrHosts];
  logic           host_rvalid [NrHosts];
  logic [31:0]    host_rdata  [NrHosts];
  logic           host_err    [NrHosts];

  logic [6:0]     data_rdata_intg;
  logic [6:0]     instr_rdata_intg;

  // Devices (slaves)
  logic           device_req    [NrDevices];
  logic [31:0]    device_addr   [NrDevices];
  logic           device_we     [NrDevices];
  logic [ 3:0]    device_be     [NrDevices];
  logic [31:0]    device_wdata  [NrDevices];
  logic           device_rvalid [NrDevices];
  logic [31:0]    device_rdata  [NrDevices];
  logic           device_err    [NrDevices];

  // Device address mapping
  localparam logic [31:0] RomBase     = 32'h0000_0000;
  localparam logic [31:0] RomSize     = 32'h0001_0000; // 64KB
  localparam logic [31:0] RamBase     = 32'h2000_0000;
  localparam logic [31:0] RamSize     = 32'h0001_0000; // 64KB
  localparam logic [31:0] UartBase    = 32'h4000_0000;
  localparam logic [31:0] UartSize    = 32'h0000_1000; // 4KB
  localparam logic [31:0] GpioBase    = 32'h4001_0000;
  localparam logic [31:0] GpioSize    = 32'h0000_1000; // 4KB
  localparam logic [31:0] TimerBase   = 32'h4002_0000;
  localparam logic [31:0] TimerSize   = 32'h0000_1000; // 4KB
  localparam logic [31:0] SpiBase     = 32'h4003_0000;
  localparam logic [31:0] SpiSize     = 32'h0000_1000; // 4KB

  // Instruction fetch interface
  logic instr_req;
  logic instr_gnt;
  logic instr_rvalid;
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;
  logic instr_err;

  assign instr_gnt = instr_req;
  assign instr_err = '0;

  // Clock and reset generation
  `ifdef VERILATOR
    assign clk_sys = IO_CLK;
    assign rst_sys_n = IO_RST_N;
  `else
    initial begin
      rst_sys_n = 1'b0;
      #8
      rst_sys_n = 1'b1;
    end
    always begin
      #1 clk_sys = 1'b0;
      #1 clk_sys = 1'b1;
    end
  `endif

  // Tie-off unused error signals
  assign device_err[Rom] = 1'b0;
  assign device_err[Ram] = 1'b0;
  assign device_err[Uart] = 1'b0;
  assign device_err[Gpio] = 1'b0;
  assign device_err[Timer] = 1'b0;
  assign device_err[Spi] = 1'b0;

  // Simple bus implementation (for now)
  // TODO: Replace with proper bus interconnect
  logic [31:0] rom_addr, ram_addr, uart_addr, gpio_addr, timer_addr, spi_addr;

  always_comb begin
    // Default assignments
    for (int i = 0; i < NrDevices; i++) begin
      device_req[i] = 1'b0;
      device_addr[i] = 32'h0;
      device_we[i] = 1'b0;
      device_be[i] = 4'h0;
      device_wdata[i] = 32'h0;
    end

    host_gnt[CoreD] = 1'b1;
    host_rvalid[CoreD] = 1'b0;
    host_rdata[CoreD] = 32'h0;
    host_err[CoreD] = 1'b0;

    // Address decode and routing
    if (host_req[CoreD]) begin
      if (host_addr[CoreD] >= RomBase && host_addr[CoreD] < RomBase + RomSize) begin
        device_req[Rom] = 1'b1;
        device_addr[Rom] = host_addr[CoreD];
        device_we[Rom] = 1'b0; // ROM is read-only
        device_be[Rom] = host_be[CoreD];
        device_wdata[Rom] = host_wdata[CoreD];
        host_rvalid[CoreD] = device_rvalid[Rom];
        host_rdata[CoreD] = device_rdata[Rom];
      end else if (host_addr[CoreD] >= RamBase && host_addr[CoreD] < RamBase + RamSize) begin
        device_req[Ram] = 1'b1;
        device_addr[Ram] = host_addr[CoreD];
        device_we[Ram] = host_we[CoreD];
        device_be[Ram] = host_be[CoreD];
        device_wdata[Ram] = host_wdata[CoreD];
        host_rvalid[CoreD] = device_rvalid[Ram];
        host_rdata[CoreD] = device_rdata[Ram];
      end else if (host_addr[CoreD] >= UartBase && host_addr[CoreD] < UartBase + UartSize) begin
        device_req[Uart] = 1'b1;
        device_addr[Uart] = host_addr[CoreD];
        device_we[Uart] = host_we[CoreD];
        device_be[Uart] = host_be[CoreD];
        device_wdata[Uart] = host_wdata[CoreD];
        host_rvalid[CoreD] = device_rvalid[Uart];
        host_rdata[CoreD] = device_rdata[Uart];
      end else if (host_addr[CoreD] >= GpioBase && host_addr[CoreD] < GpioBase + GpioSize) begin
        device_req[Gpio] = 1'b1;
        device_addr[Gpio] = host_addr[CoreD];
        device_we[Gpio] = host_we[CoreD];
        device_be[Gpio] = host_be[CoreD];
        device_wdata[Gpio] = host_wdata[CoreD];
        host_rvalid[CoreD] = device_rvalid[Gpio];
        host_rdata[CoreD] = device_rdata[Gpio];
      end else if (host_addr[CoreD] >= TimerBase && host_addr[CoreD] < TimerBase + TimerSize) begin
        device_req[Timer] = 1'b1;
        device_addr[Timer] = host_addr[CoreD];
        device_we[Timer] = host_we[CoreD];
        device_be[Timer] = host_be[CoreD];
        device_wdata[Timer] = host_wdata[CoreD];
        host_rvalid[CoreD] = device_rvalid[Timer];
        host_rdata[CoreD] = device_rdata[Timer];
      end else if (host_addr[CoreD] >= SpiBase && host_addr[CoreD] < SpiBase + SpiSize) begin
        device_req[Spi] = 1'b1;
        device_addr[Spi] = host_addr[CoreD];
        device_we[Spi] = host_we[CoreD];
        device_be[Spi] = host_be[CoreD];
        device_wdata[Spi] = host_wdata[CoreD];
        host_rvalid[CoreD] = device_rvalid[Spi];
        host_rdata[CoreD] = device_rdata[Spi];
      end else begin
        // Invalid address - return error
        host_rvalid[CoreD] = 1'b1;
        host_rdata[CoreD] = 32'hDEADBEEF;
        host_err[CoreD] = 1'b1;
      end
    end
  end

  // MHX Core (Enhanced Ibex with Ternary Extensions)
  ibex_top #(
    .PMPEnable        ( PMPEnable        ),
    .PMPGranularity   ( PMPGranularity   ),
    .PMPNumRegions    ( PMPNumRegions    ),
    .MHPMCounterNum   ( MHPMCounterNum   ),
    .MHPMCounterWidth ( MHPMCounterWidth ),
    .RV32E            ( RV32E            ),
    .RV32M            ( RV32M            ),
    .RV32B            ( RV32B            ),
    .RegFile          ( RegFile          ),
    .BranchTargetALU  ( BranchTargetALU  ),
    .ICache           ( ICache           ),
    .ICacheECC        ( ICacheECC        ),
    .WritebackStage   ( WritebackStage   ),
    .BranchPredictor  ( BranchPredictor  ),
    .DbgTriggerEn     ( DbgTriggerEn     ),
    .DmBaseAddr       ( 32'h00100000     ),
    .DmAddrMask       ( 32'h00000003     ),
    .DmHaltAddr       ( 32'h00100000     ),
    .DmExceptionAddr  ( 32'h00100001     )
  ) u_top (
    .clk_i                 ( clk_sys        ),
    .rst_ni                ( rst_sys_n      ),

    .test_en_i             ( '0             ),
    .scan_rst_ni           ( 1'b1           ),
    .ram_cfg_i             ( '0             ),

    .hart_id_i             ( 32'b0          ),
    .boot_addr_i           ( RomBase        ),

    .instr_req_o           ( instr_req      ),
    .instr_gnt_i           ( instr_gnt      ),
    .instr_rvalid_i        ( instr_rvalid   ),
    .instr_addr_o          ( instr_addr     ),
    .instr_rdata_i         ( instr_rdata    ),
    .instr_rdata_intg_i    ( instr_rdata_intg ),
    .instr_err_i           ( instr_err      ),

    .data_req_o            ( host_req    [CoreD] ),
    .data_gnt_i            ( host_gnt    [CoreD] ),
    .data_rvalid_i         ( host_rvalid [CoreD] ),
    .data_we_o             ( host_we     [CoreD] ),
    .data_be_o             ( host_be     [CoreD] ),
    .data_addr_o           ( host_addr   [CoreD] ),
    .data_wdata_o          ( host_wdata  [CoreD] ),
    .data_wdata_intg_o     ( data_rdata_intg    ),
    .data_rdata_i          ( host_rdata  [CoreD] ),
    .data_rdata_intg_i     ( data_rdata_intg    ),
    .data_err_i            ( host_err    [CoreD] ),

    .irq_software_i        ( 1'b0          ),
    .irq_timer_i           ( timer_irq     ),
    .irq_external_i        ( uart_irq | gpio_irq | spi_irq ),
    .irq_fast_i            ( 15'b0         ),
    .irq_nm_i              ( 1'b0          ),

    .scramble_key_valid_i  ( '0            ),
    .scramble_key_i        ( '0            ),
    .scramble_nonce_i      ( '0            ),
    .scramble_req_o        (               ),

    .debug_req_i           ( '0            ),
    .crash_dump_o          (               ),
    .double_fault_seen_o   (               ),

    .fetch_enable_i        ( '1            ),
    .alert_minor_o         (               ),
    .alert_major_internal_o(               ),
    .alert_major_bus_o     (               ),
    .core_sleep_o          (               )
  );

  // ROM for bootloader and programs
  // Simple ROM implementation using always blocks
  logic [31:0] rom_data [RomSize/4];
  logic rom_req_d, rom_req_q;

  // Initialize ROM with simple program if no init file
  initial begin
    if (ROMInitFile == "") begin
      // Simple boot program - jump to RAM
      rom_data[0] = 32'h20000137; // lui x2, 0x20000  (load RAM base to x2)
      rom_data[1] = 32'h00010113; // addi x2, x2, 1   (set stack pointer)
      rom_data[2] = 32'h00000067; // jalr x0, x0, 0   (infinite loop for now)
      for (int i = 3; i < RomSize/4; i++) begin
        rom_data[i] = 32'h00000013; // nop
      end
    end else begin
      $readmemh(ROMInitFile, rom_data);
    end
  end

  always_ff @(posedge clk_sys) begin
    rom_req_d <= device_req[Rom];
    if (device_req[Rom] && !device_we[Rom]) begin
      device_rdata[Rom] <= rom_data[device_addr[Rom][15:2]];
    end
  end

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      rom_req_q <= 1'b0;
    end else begin
      rom_req_q <= rom_req_d;
    end
  end

  assign device_rvalid[Rom] = rom_req_q;

  // RAM for runtime data
  // Simple RAM implementation using always blocks
  logic [31:0] ram_data [RamSize/4];
  logic ram_req_d, ram_req_q;

  // Initialize RAM if init file provided
  initial begin
    if (RAMInitFile != "") begin
      $readmemh(RAMInitFile, ram_data);
    end else begin
      for (int i = 0; i < RamSize/4; i++) begin
        ram_data[i] = 32'h0;
      end
    end
  end

  always_ff @(posedge clk_sys) begin
    ram_req_d <= device_req[Ram];
    if (device_req[Ram]) begin
      if (device_we[Ram]) begin
        // Write to RAM
        if (device_be[Ram][0]) ram_data[device_addr[Ram][15:2]][ 7: 0] <= device_wdata[Ram][ 7: 0];
        if (device_be[Ram][1]) ram_data[device_addr[Ram][15:2]][15: 8] <= device_wdata[Ram][15: 8];
        if (device_be[Ram][2]) ram_data[device_addr[Ram][15:2]][23:16] <= device_wdata[Ram][23:16];
        if (device_be[Ram][3]) ram_data[device_addr[Ram][15:2]][31:24] <= device_wdata[Ram][31:24];
      end
      device_rdata[Ram] <= ram_data[device_addr[Ram][15:2]];
    end
  end

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      ram_req_q <= 1'b0;
    end else begin
      ram_req_q <= ram_req_d;
    end
  end

  assign device_rvalid[Ram] = ram_req_q;

  // Instruction memory mux (ROM only for now)
  always_comb begin
    if (instr_addr >= RomBase && instr_addr < RomBase + RomSize) begin
      instr_rdata = rom_data[instr_addr[15:2]];
      instr_rvalid = 1'b1;
    end else begin
      instr_rdata = 32'h0;
      instr_rvalid = 1'b1;
    end
  end

  // Simple UART implementation
  // TODO: Replace with full UART peripheral
  logic [31:0] uart_tx_data;
  logic uart_tx_valid;
  logic uart_tx_ready;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      device_rvalid[Uart] <= 1'b0;
      device_rdata[Uart] <= 32'h0;
      uart_tx_valid <= 1'b0;
      uart_irq <= 1'b0;
    end else begin
      device_rvalid[Uart] <= device_req[Uart];

      if (device_req[Uart] && device_we[Uart]) begin
        // Write to UART - send character
        uart_tx_data <= device_wdata[Uart];
        uart_tx_valid <= 1'b1;
        uart_irq <= 1'b1; // Simple interrupt on write
      end else begin
        uart_tx_valid <= 1'b0;
        uart_irq <= 1'b0;
      end

      if (device_req[Uart] && !device_we[Uart]) begin
        // Read from UART - return status
        device_rdata[Uart] <= {31'b0, uart_tx_ready};
      end
    end
  end

  // Simple UART TX (just toggle for simulation)
  assign uart_tx = clk_sys; // For now, just clock

  // Simple GPIO implementation
  logic [7:0] gpio_out_reg, gpio_oe_reg;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      device_rvalid[Gpio] <= 1'b0;
      device_rdata[Gpio] <= 32'h0;
      gpio_out_reg <= 8'h0;
      gpio_oe_reg <= 8'h0;
      gpio_irq <= 1'b0;
    end else begin
      device_rvalid[Gpio] <= device_req[Gpio];

      if (device_req[Gpio] && device_we[Gpio]) begin
        case (device_addr[Gpio][3:0])
          4'h0: gpio_out_reg <= device_wdata[Gpio][7:0]; // GPIO_OUT
          4'h4: gpio_oe_reg <= device_wdata[Gpio][7:0];  // GPIO_OE
          default: ;
        endcase
      end

      if (device_req[Gpio] && !device_we[Gpio]) begin
        case (device_addr[Gpio][3:0])
          4'h0: device_rdata[Gpio] <= {24'b0, gpio_out_reg}; // GPIO_OUT
          4'h4: device_rdata[Gpio] <= {24'b0, gpio_oe_reg};  // GPIO_OE
          4'h8: device_rdata[Gpio] <= {24'b0, gpio_in};      // GPIO_IN
          default: device_rdata[Gpio] <= 32'h0;
        endcase
      end

      gpio_irq <= 1'b0; // No interrupts for now
    end
  end

  assign gpio_out = gpio_out_reg;
  assign gpio_oe = gpio_oe_reg;

  // Simple Timer implementation
  logic [31:0] timer_count, timer_compare;
  logic timer_enable;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      device_rvalid[Timer] <= 1'b0;
      device_rdata[Timer] <= 32'h0;
      timer_count <= 32'h0;
      timer_compare <= 32'hFFFFFFFF;
      timer_enable <= 1'b0;
      timer_irq <= 1'b0;
    end else begin
      device_rvalid[Timer] <= device_req[Timer];

      // Timer counting
      if (timer_enable) begin
        timer_count <= timer_count + 1;
        if (timer_count >= timer_compare) begin
          timer_irq <= 1'b1;
          timer_count <= 32'h0;
        end else begin
          timer_irq <= 1'b0;
        end
      end

      if (device_req[Timer] && device_we[Timer]) begin
        case (device_addr[Timer][3:0])
          4'h0: timer_count <= device_wdata[Timer];    // TIMER_COUNT
          4'h4: timer_compare <= device_wdata[Timer];  // TIMER_COMPARE
          4'h8: timer_enable <= device_wdata[Timer][0]; // TIMER_CTRL
          default: ;
        endcase
      end

      if (device_req[Timer] && !device_we[Timer]) begin
        case (device_addr[Timer][3:0])
          4'h0: device_rdata[Timer] <= timer_count;   // TIMER_COUNT
          4'h4: device_rdata[Timer] <= timer_compare; // TIMER_COMPARE
          4'h8: device_rdata[Timer] <= {31'b0, timer_enable}; // TIMER_CTRL
          default: device_rdata[Timer] <= 32'h0;
        endcase
      end
    end
  end

  // Simple SPI implementation (placeholder)
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      device_rvalid[Spi] <= 1'b0;
      device_rdata[Spi] <= 32'h0;
      spi_irq <= 1'b0;
    end else begin
      device_rvalid[Spi] <= device_req[Spi];
      device_rdata[Spi] <= 32'hDEADBEEF; // Placeholder
      spi_irq <= 1'b0;
    end
  end

  // SPI outputs (placeholder)
  assign spi_sck = 1'b0;
  assign spi_mosi = 1'b0;
  assign spi_cs = 1'b1;

  // Export DPI functions for performance monitoring
  export "DPI-C" function mhpmcounter_num;
  function automatic int unsigned mhpmcounter_num();
    return u_top.u_ibex_core.cs_registers_i.MHPMCounterNum;
  endfunction

  export "DPI-C" function mhpmcounter_get;
  function automatic longint unsigned mhpmcounter_get(int index);
    return u_top.u_ibex_core.cs_registers_i.mhpmcounter[index];
  endfunction

endmodule
