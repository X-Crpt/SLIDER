# SLIDER — SLH-DSA Lightweight Instruction and Dedicated Engine for RISC-V

SLIDER collects the hardware, software, and integration work for a
SLH-DSA (FIPS 205 / SPHINCS+) hardware accelerator built as a
CV-X-IF coprocessor for the [CVA6](https://github.com/openhwgroup/cva6)
RISC-V core. It is a clean, reorganized extraction of a long-running
CVA6 fork, split so that upstream CVA6, our RTL, and our software tests
are each easy to find and review independently.

## Relationship to CVA6

This repository is built on top of CVA6, an open-source 6-stage,
single-issue, in-order 64-bit RISC-V application-class core originally
developed at ETH Zurich and now maintained by the
[OpenHW Group](https://github.com/openhwgroup/cva6). The `cva6/` folder
here is a snapshot of our fork
([edge-group-polito/cva6](https://github.com/edge-group-polito/cva6),
branch `HASH`, commit `2c8f1532c`), which is itself a fork of
[vlsi-lab/cva6](https://github.com/vlsi-lab/cva6). CVA6's own
`README.md`, `ACKNOWLEDGEMENTS.md`, `CITATION.cff`, `CODEOWNERS`, and
license files are preserved as-is under `cva6/` — see that folder for
CVA6's full documentation, contributor list, and citation entry
(`cva6/CITATION.cff`, Zaruba & Benini, 10.1109/TVLSI.2019.2926114).

We did not fork CVA6 again for this project; instead this repo carries a
fresh, single-commit copy of the fork's working tree (no rewritten commit
history) with our own coprocessor and test code physically separated out,
so it is unambiguous which parts are CVA6 and which parts are ours.

## Repository layout

```
SLIDER/
├── cva6/    CVA6 core, unmodified except for the filelist/config wiring
│            needed to point at rtl/ and sw/ (see cva6/README.md)
├── rtl/     Our hardware contributions, as standalone IP outside the
│            CVA6 tree:
│              spx-unit/   the SLH-DSA/SPHINCS+ + Keccak CV-X-IF
│                          coprocessor (formerly `hash_ip`, renamed to
│                          match the "SPX unit" naming used in the paper)
│              keccak_ip/  the earlier, narrower Keccak-only CV-X-IF
│                          coprocessor, kept for backwards compatibility
│                          (CVA6Cfg.CoproType = COPRO_KECCAK)
└── sw/      Our software tests, split by scope:
               pqc-complete/  full SLH-DSA keygen/sign/verify flows
                              (original/ = pure-C reference,
                               optimized/ = spx-unit-accelerated)
               simple/        focused unit tests for individual
                              spx-unit operations (Keccak absorb/permute,
                              THASH, PRF, WOTS+ chain lengths, ...)
```

`rtl/` is meant to make our contribution self-evident: everything in
there is coprocessor RTL that does not exist in upstream CVA6. `sw/` is
meant to make it easy to compare an unaccelerated software baseline
against the hardware-accelerated path for the same algorithm.

## Hardware: the SPX unit

`rtl/spx-unit/` is a 64-bit native CV-X-IF coprocessor (custom opcode
`0x5B`, 20 instructions) combining a Keccak-f[1600] permutation core, a
unified SLH-DSA THASH1/THASH2/PRF pipeline, and a WOTS+ chain-lengths
accelerator, wired into CVA6 through `corev_apu/src/ariane.sv`
(`CVA6Cfg.CoproType == COPRO_SPX_UNIT`). See `rtl/spx-unit/README.md` for
the full instruction set, microarchitecture, and timing tables.

## Building and running tests

### 1. Python environment

Follow CVA6's own process (`cva6/README.md`, "Python Environment"): create
and activate the conda environment from the provided lock file, run from
`cva6/`:

```bash
conda env create -f environment_lock.yml
conda activate cva6
```

### 2. RISC-V toolchain, Verilator, Spike

Simulation needs three tools that this repo does not vendor or assume a
path for: a RISC-V GCC toolchain, Verilator, and Spike. Build them
following CVA6's own guide (`cva6/README.md`, "RISC-V Toolchain and
Verilator Setup"; full detail in `cva6/util/toolchain-builder/README.md`):

```bash
# RISC-V GCC (from cva6/util/toolchain-builder/)
bash get-toolchain.sh gcc-13.1.0-baremetal
bash build-toolchain.sh gcc-13.1.0-baremetal /path/to/install/riscv-toolchain

# Verilator and Spike: see cva6/util/toolchain-builder/README.md and the
# upstream Verilator (https://verilator.org/guide/latest/install.html) /
# riscv-isa-sim (https://github.com/riscv-software-src/riscv-isa-sim)
# install instructions.
```

### 3. Point the repo at your toolchain

`cva6/verif/sim/setup-env.sh` is the file every test sources to find its
tools. It does not hardcode a path — set these three yourself, either by
exporting them in your shell before running a test, or by editing the
three commented-out lines near the top of that file:

```bash
export RISCV="/path/to/your/riscv-toolchain"
export VERILATOR_INSTALL_DIR="/path/to/your/verilator"
export SPIKE_INSTALL_DIR="/path/to/your/spike"
```

If any of these is unset or doesn't exist, sourcing the file prints a
clear error naming which one and stops (it won't silently use the wrong
toolchain or close your shell if you `source` it directly).

### 4. Run the tests

Test entry points live under `sw/`:

```bash
# Interactive picker for the focused unit tests
bash sw/simple/run_tests.sh

# Interactive picker for full SLH-DSA keygen/sign/verify variants
bash sw/pqc-complete/run_spx.sh

# Non-interactive batch run of all SLH-DSA variants
bash sw/pqc-complete/run_spx_batch.sh --mode all all
```

See `sw/README.md` for the full test catalogue and environment
variables.

## 📄 License

CVA6 and the code under `cva6/` are licensed under the Solderpad
Hardware License 0.51 (`LICENSE`), with vendored third-party components
under `LICENSE.Berkeley` (BSD 3-Clause) and `LICENSE.SiFive`
(Apache 2.0) — see those files for exact scope. Our own contributions
under `rtl/` and `sw/` are licensed Apache-2.0 WITH SHL-2.1, matching
the SPDX headers already present in the source (e.g.
`rtl/spx-unit/hw/spx_unit.sv`), Copyright 2025 PoliTO — EDGE Group,
VLSI Lab.

## 👥 Authors

- **Behnam Farnaghinejad** - behnam.farnaghinejad@polito.it

- **Valeria Piscopo** - valeria.piscopo@polito.it

- **Alessandra Dolmeta** - alessandra.dolmeta@polito.it

