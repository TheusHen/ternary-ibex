#!/bin/bash
# FPGA build script for MHX Neural T1 Simple System

set -e

BOARD=${1:-arty_a7}
PROJECT_ROOT="$(dirname "$(readlink -f "$0")")/../../../"

echo "Building MHX Neural T1 Simple System for $BOARD"
echo "Project root: $PROJECT_ROOT"

case $BOARD in
    arty_a7)
        cd "$PROJECT_ROOT/syn/fpga/arty_a7"
        vivado -mode batch -source build_arty_a7.tcl
        ;;
    basys3)
        cd "$PROJECT_ROOT/syn/fpga/basys3" 
        vivado -mode batch -source build_basys3.tcl
        ;;
    *)
        echo "Error: Unsupported board '$BOARD'"
        echo "Supported boards: arty_a7, basys3"
        exit 1
        ;;
esac

echo "FPGA build completed for $BOARD"