/* Copyright lowRISC contributors. */
/* Copyright 2025 MHX Neural. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/* Linker script for MHX test programs */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x100000, LENGTH = 1M
}

ENTRY(_start)

SECTIONS
{
    . = 0x100000;
    
    .text : {
        *(.text.start)
        *(.text*)
    } > RAM
    
    .rodata : {
        *(.rodata*)
    } > RAM
    
    .data : {
        *(.data*)
    } > RAM
    
    .bss : {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > RAM
    
    . = ALIGN(16);
    _stack_end = .;
    . = . + 0x1000;
    _stack_top = .;
}