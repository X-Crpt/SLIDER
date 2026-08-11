# CVA6 project root
if [ -n "$BASH_VERSION" ]; then
  SCRIPT_PATH="$BASH_SOURCE[0]"
elif [ -n "$ZSH_VERSION" ]; then
  SCRIPT_PATH="${(%):-%N}"
else
  echo "Error: Non recognized shell."
  return
fi
export ROOT_PROJECT=$(readlink -f $(dirname "${SCRIPT_PATH}")/../..)

export RTL_PATH="$ROOT_PROJECT/"
export TB_PATH="$ROOT_PROJECT/verif/tb/core"
export TESTS_PATH="$ROOT_PROJECT/verif/tests"

# RISCV-DV & COREV-DV
export RISCV_DV_ROOT="$ROOT_PROJECT/verif/sim/dv"
export CVA6_DV_ROOT="$ROOT_PROJECT/verif/env/corev-dv"


# Set RISCV toolchain-related variables.
# Priority: a RISCV already exported by the caller (and actually present
# on disk) > the VLSI-Lab server toolchain (if present) > a toolchain
# built locally under ~/tools (the layout produced by
# cva6/util/toolchain-builder). Checking "present on disk", not just
# "non-empty", matters because this script is meant to be sourced: a
# stale/wrong RISCV exported by an earlier `source` of this same script
# (e.g. before a toolchain was installed, or on a different machine)
# would otherwise stick around in your shell forever and never get
# re-detected. Export your own RISCV (and the VERILATOR_INSTALL_DIR/
# SPIKE_* vars below) before sourcing this script to point anywhere else.
if [ -z "$RISCV" ] || [ ! -d "$RISCV/bin" ]; then
  if [ -d "/software/riscv/riscv64-cva6" ]; then
    export RISCV="/software/riscv/riscv64-cva6"                       ##@VLSI-Lab Server
  elif [ -d "$HOME/tools/riscv64" ]; then
    export RISCV="$HOME/tools/riscv64"
  fi
fi
if [ -z "$RISCV" ]; then
  echo "Error: RISCV variable undefined (no toolchain found; export RISCV yourself)."
  return
fi
#export RISCV="/home/alessandra.dolmeta/cva6/old/cva6/util/riscv_toolchain"
export LIBRARY_PATH="$RISCV/lib"
export LD_LIBRARY_PATH="$RISCV/lib:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$RISCV/include"
export CPLUS_INCLUDE_PATH="$RISCV/include"

# Auto-detect RISC-V tool name prefix if not explicitly given.
if [ -z "$CV_SW_PREFIX" ]; then
    export CV_SW_PREFIX="$(ls -1 $RISCV/bin/riscv* | head -n 1 | rev | cut -d '/' -f 1 | cut -d '-' -f 2- | rev)-"
fi
# Default to auto-detected CC name if not explicitly given.
if [ -z "$RISCV_CC" ]; then
    export RISCV_CC="$RISCV/bin/${CV_SW_PREFIX}gcc"
fi
# Default to auto-detected OBJCOPY name if not explicitly given.
if [ -z "$RISCV_OBJCOPY" ]; then
    export RISCV_OBJCOPY="$RISCV/bin/${CV_SW_PREFIX}objcopy"
fi

# Set verilator and spike related variables
#if [ -z "$VERILATOR_INSTALL_DIR" ]; then
#    export VERILATOR_INSTALL_DIR="$ROOT_PROJECT"/tools/verilator
#fi
#if [ -z "$SPIKE_SRC_DIR" -o "$SPIKE_INSTALL_DIR" = "__local__" ]; then
#  export SPIKE_SRC_DIR="$ROOT_PROJECT"/verif/core-v-verif/vendor/riscv/riscv-isa-sim
#fi
#if [ -z "$SPIKE_INSTALL_DIR" -o "$SPIKE_INSTALL_DIR" = "__local__" ]; then
#    export SPIKE_INSTALL_DIR="$ROOT_PROJECT"/tools/spike
#fi
#export SPIKE_PATH="$SPIKE_INSTALL_DIR"/bin

# Set verilator and spike related variables
# export VERILATOR_INSTALL_DIR="$ROOT_PROJECT"/tools/verilator-v5.008
# export SPIKE_SRC_DIR="$ROOT_PROJECT"/verif/core-v-verif/vendor/riscv/riscv-isa-sim
# export SPIKE_INSTALL_DIR="$ROOT_PROJECT"/tools/spike
# export SPIKE_PATH="$SPIKE_INSTALL_DIR"/bin

if [ -z "$VERILATOR_INSTALL_DIR" ] || [ ! -d "$VERILATOR_INSTALL_DIR/bin" ]; then
  if [ -d "/software/cva6/verilator-v5.008" ]; then
    export VERILATOR_INSTALL_DIR="/software/cva6/verilator-v5.008"    ##@VLSI-Lab Server
  elif [ -d "$HOME/tools/verilator-v5.008" ]; then
    export VERILATOR_INSTALL_DIR="$HOME/tools/verilator-v5.008"
  fi
fi
if [ -z "$SPIKE_SRC_DIR" ]; then
  export SPIKE_SRC_DIR="/software/cva6/riscv-isa-sim"                 ##@VLSI-Lab Server
fi
if [ -z "$SPIKE_INSTALL_DIR" ] || [ ! -d "$SPIKE_INSTALL_DIR" ]; then
  if [ -d "/software/spike/spike" ]; then
    export SPIKE_INSTALL_DIR="/software/spike/spike"                  ##@VLSI-Lab Server
  elif [ -d "$HOME/tools/spike" ]; then
    export SPIKE_INSTALL_DIR="$HOME/tools/spike"
  fi
fi
export SPIKE_PATH="$SPIKE_INSTALL_DIR/bin"

# Update the PATH to add all the tools
export PATH="$VERILATOR_INSTALL_DIR/bin:$RISCV/bin:$PATH"
