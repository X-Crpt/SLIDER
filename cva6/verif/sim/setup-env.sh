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


# ---------------------------------------------------------------------------
# Toolchain paths: RISCV, VERILATOR_INSTALL_DIR, SPIKE_INSTALL_DIR.
#
# This repo does not assume a specific machine. Set these three yourself
# before sourcing this script -- either export them in your shell, or edit
# the three lines below (uncomment and fill in your real paths):
#
#   export RISCV="/path/to/your/riscv-toolchain"
#   export VERILATOR_INSTALL_DIR="/path/to/your/verilator"
#   export SPIKE_INSTALL_DIR="/path/to/your/spike"
#
# See sw/README.md ("Building and running tests") for where to get each
# of these (CVA6's own toolchain-builder / conda environment / Verilator
# and Spike install instructions).
# ---------------------------------------------------------------------------

# export RISCV="/path/to/your/riscv-toolchain"
# export VERILATOR_INSTALL_DIR="/path/to/your/verilator"
# export SPIKE_INSTALL_DIR="/path/to/your/spike"

# Validate before use: catches both "never set" and "set but stale/wrong"
# (this script is meant to be sourced, so a bad value from an earlier
# `source` would otherwise silently stick around in your shell).
if [ -z "$RISCV" ] || [ ! -d "$RISCV/bin" ]; then
  echo "Error: RISCV is not set to a valid toolchain directory."
  echo "       export RISCV=/path/to/your/riscv-toolchain (see sw/README.md)"
  return
fi
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

if [ -z "$VERILATOR_INSTALL_DIR" ] || [ ! -d "$VERILATOR_INSTALL_DIR/bin" ]; then
  echo "Error: VERILATOR_INSTALL_DIR is not set to a valid Verilator install."
  echo "       export VERILATOR_INSTALL_DIR=/path/to/your/verilator (see sw/README.md)"
  return
fi
if [ -z "$SPIKE_INSTALL_DIR" ] || [ ! -d "$SPIKE_INSTALL_DIR" ]; then
  echo "Error: SPIKE_INSTALL_DIR is not set to a valid Spike install."
  echo "       export SPIKE_INSTALL_DIR=/path/to/your/spike (see sw/README.md)"
  return
fi
export SPIKE_PATH="$SPIKE_INSTALL_DIR/bin"

# Update the PATH to add all the tools
export PATH="$VERILATOR_INSTALL_DIR/bin:$RISCV/bin:$PATH"
