/* Copyright lowRISC contributors.
 * Copyright 2025 MHX Neural.
 * Licensed under the Apache License, Version 2.0, see LICENSE for details.
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * MHX Simple System Linker Script
 *
 * This linker script defines the memory layout for programs running
 * on the MHX Simple System. It supports both ROM-based and RAM-based
 * programs.
 *
 * Memory Map:
 * - ROM: 0x0000_0000 - 0x0000_FFFF (64KB) - Boot code and constants
 * - RAM: 0x2000_0000 - 0x2000_FFFF (64KB) - Runtime data and stack
 */

/* Entry point */
ENTRY(_start)

/* Memory regions */
MEMORY
{
    /* ROM region - for bootloader and read-only code/data */
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    
    /* RAM region - for runtime data, heap, and stack */
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
}

/* Stack configuration */
PROVIDE(__stack_size = 4K);
PROVIDE(__heap_size = 8K);

/* Stack top (grows downward from end of RAM) */
PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));
PROVIDE(__stack_bottom = __stack_top - __stack_size);

/* Heap (grows upward from end of BSS) */
PROVIDE(__heap_start = __bss_end);
PROVIDE(__heap_end = __heap_start + __heap_size);

/* Global pointer for small data optimization */
PROVIDE(__global_pointer$ = __sdata_start + 0x800);

SECTIONS
{
    /* ================================================================
     * ROM Sections (Read-Only)
     * ================================================================ */
    
    /* Boot vector and startup code */
    .boot : ALIGN(4)
    {
        KEEP(*(.boot))
        . = ALIGN(4);
    } > ROM
    
    /* Main text section - executable code */
    .text : ALIGN(4)
    {
        *(.text.boot)
        *(.text.init)
        *(.text)
        *(.text.*)
        . = ALIGN(4);
    } > ROM
    
    /* Exception and interrupt vectors */
    .vectors : ALIGN(4)
    {
        KEEP(*(.vectors))
        . = ALIGN(4);
    } > ROM
    
    /* Read-only data */
    .rodata : ALIGN(4)
    {
        *(.rodata)
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)
        . = ALIGN(4);
    } > ROM
    
    /* Constructor/destructor tables */
    .init_array : ALIGN(4)
    {
        PROVIDE(__init_array_start = .);
        KEEP(*(.init_array))
        KEEP(*(.ctors))
        PROVIDE(__init_array_end = .);
        . = ALIGN(4);
    } > ROM
    
    .fini_array : ALIGN(4)
    {
        PROVIDE(__fini_array_start = .);
        KEEP(*(.fini_array))
        KEEP(*(.dtors))
        PROVIDE(__fini_array_end = .);
        . = ALIGN(4);
    } > ROM
    
    /* End of ROM content */
    PROVIDE(__rom_end = .);
    
    /* ================================================================
     * RAM Sections (Read-Write)
     * ================================================================ */
    
    /* Initialized data section (copied from ROM at startup) */
    .data : ALIGN(4)
    {
        PROVIDE(__data_start = .);
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
        . = ALIGN(4);
        PROVIDE(__data_end = .);
    } > RAM AT > ROM
    
    /* Data load address in ROM */
    PROVIDE(__data_load_start = LOADADDR(.data));
    PROVIDE(__data_load_end = __data_load_start + SIZEOF(.data));
    
    /* Uninitialized data section (zeroed at startup) */
    .bss : ALIGN(4)
    {
        PROVIDE(__bss_start = .);
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        . = ALIGN(4);
        PROVIDE(__bss_end = .);
    } > RAM
    
    /* Thread-local storage (if used) */
    .tdata : ALIGN(4)
    {
        PROVIDE(__tdata_start = .);
        *(.tdata)
        *(.tdata.*)
        PROVIDE(__tdata_end = .);
    } > RAM AT > ROM
    
    .tbss : ALIGN(4)
    {
        PROVIDE(__tbss_start = .);
        *(.tbss)
        *(.tbss.*)
        PROVIDE(__tbss_end = .);
    } > RAM
    
    /* ================================================================
     * Special Sections
     * ================================================================ */
    
    /* Heap section (optional) */
    .heap : ALIGN(4)
    {
        . = . + __heap_size;
    } > RAM
    
    /* Stack section (grows downward) */
    .stack : ALIGN(4)
    {
        . = . + __stack_size;
    } > RAM
    
    /* ================================================================
     * Debug Sections (not loaded)
     * ================================================================ */
    
    /* DWARF debug information */
    .debug_abbrev   0 : { *(.debug_abbrev) }
    .debug_aranges  0 : { *(.debug_aranges) }
    .debug_frame    0 : { *(.debug_frame) }
    .debug_info     0 : { *(.debug_info) }
    .debug_line     0 : { *(.debug_line) }
    .debug_loc      0 : { *(.debug_loc) }
    .debug_macinfo  0 : { *(.debug_macinfo) }
    .debug_pubnames 0 : { *(.debug_pubnames) }
    .debug_pubtypes 0 : { *(.debug_pubtypes) }
    .debug_ranges   0 : { *(.debug_ranges) }
    .debug_str      0 : { *(.debug_str) }
    
    /* RISC-V specific debug sections */
    .riscv.attributes 0 : { *(.riscv.attributes) }
    
    /* ================================================================
     * Discarded Sections
     * ================================================================ */
    
    /DISCARD/ :
    {
        *(.note.GNU-stack)
        *(.gnu_debuglink)
        *(.gnu.lto_*)
    }
}

/* ====================================================================
 * Symbol Definitions and Assertions
 * ==================================================================== */

/* Useful symbols for startup code */
PROVIDE(__text_start = ADDR(.text));
PROVIDE(__text_end = ADDR(.text) + SIZEOF(.text));
PROVIDE(__rodata_start = ADDR(.rodata));
PROVIDE(__rodata_end = ADDR(.rodata) + SIZEOF(.rodata));

/* RAM usage symbols */
PROVIDE(__ram_start = ORIGIN(RAM));
PROVIDE(__ram_end = ORIGIN(RAM) + LENGTH(RAM));
PROVIDE(__ram_size = LENGTH(RAM));

/* ROM usage symbols */
PROVIDE(__rom_start = ORIGIN(ROM));
PROVIDE(__rom_size = LENGTH(ROM));

/* Program size information */
PROVIDE(__program_size = __rom_end - __rom_start);
PROVIDE(__data_size = SIZEOF(.data));
PROVIDE(__bss_size = SIZEOF(.bss));

/* Memory usage assertions */
ASSERT(__rom_end <= (ORIGIN(ROM) + LENGTH(ROM)), "ROM overflow! Program too large for ROM.")
ASSERT(__bss_end <= __heap_start, "RAM overflow! BSS section too large.")
ASSERT(__heap_end <= __stack_bottom, "RAM overflow! Heap and stack collision.")

/* Alignment assertions */
ASSERT((__data_start % 4) == 0, "Data section not word-aligned")
ASSERT((__bss_start % 4) == 0, "BSS section not word-aligned")
ASSERT((__stack_top % 4) == 0, "Stack not word-aligned")

/* Size assertions */
ASSERT(__stack_size >= 1024, "Stack too small (minimum 1KB required)")
ASSERT(__heap_size >= 1024, "Heap too small (minimum 1KB required)")

/* ====================================================================
 * Memory Layout Summary (for reference)
 * ====================================================================
 *
 * ROM Layout (0x0000_0000 - 0x0000_FFFF):
 * +------------------+ 0x0000_0000
 * | .boot            | Boot vector
 * | .text            | Executable code
 * | .vectors         | Exception vectors
 * | .rodata          | Read-only data
 * | .init_array      | Constructors
 * | .fini_array      | Destructors
 * +------------------+ __rom_end
 * | Unused ROM       |
 * +------------------+ 0x0000_FFFF
 *
 * RAM Layout (0x2000_0000 - 0x2000_FFFF):
 * +------------------+ 0x2000_0000
 * | .data            | Initialized data
 * | .bss             | Uninitialized data
 * +------------------+ __bss_end / __heap_start
 * | Heap (grows up)  | Dynamic allocation
 * +------------------+ __heap_end
 * | Unused RAM       |
 * +------------------+ __stack_bottom
 * | Stack (grows dn) | Function calls
 * +------------------+ 0x2000_FFFF (__stack_top)
 *
 * ==================================================================== */