/* Copyright lowRISC contributors. */
/* Copyright 2025 MHX Neural. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/* Minimal C runtime startup for MHX test programs */

.section .text.start
.global _start

_start:
    /* Set up stack pointer */
    la sp, _stack_top
    
    /* Zero BSS section */
    la t0, _bss_start
    la t1, _bss_end
bss_clear:
    beq t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j bss_clear
bss_done:

    /* Call main function */
    jal ra, main
    
    /* Infinite loop if main returns */
loop:
    j loop

.section .text
.global _exit
_exit:
    j loop

/* Default trap handler */
.global trap_handler
trap_handler:
    j loop