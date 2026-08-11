# SLIDER software tests

This directory contains the software tests for the custom hash coprocessor
on CVA6 (custom opcode `0x5B`). All tests run inside the CVA6 Verilator
simulation (`veri-testharness`) and compare a software reference against
the hardware accelerator, printing cycle counts and a speedup ratio.

Tests are split into two categories:

- **`simple/`** — focused unit tests for individual coprocessor operations
  (Keccak absorb/permute, SLH-DSA THASH/PRF, WOTS+ chain lengths, ...).
- **`pqc-complete/`** — full SLH-DSA (SPHINCS+) keygen/sign/verify flows,
  each available in an `original/` (pure-C reference) and `optimized/`
  (hardware-accelerated) variant.

`inc/` holds infrastructure shared by both categories.

---

## Quick start

All commands below are run **from the SLIDER repo root** (the directory
containing `cva6/`, `rtl/`, and `sw/`).

```bash
# Interactive menu — picks one unit test and runs it
bash sw/simple/run_tests.sh

# Interactive menu — picks one SPHINCS+ full-flow variant
bash sw/pqc-complete/run_spx.sh

# Batch — run all SPHINCS+ variants for keygen + sign + verify
bash sw/pqc-complete/run_spx_batch.sh --mode original all
bash sw/pqc-complete/run_spx_batch.sh --mode optimized all
bash sw/pqc-complete/run_spx_batch.sh --mode all all      # 36 simulations total
```

---

## Top-level scripts

| Script | What it does |
|---|---|
| `simple/run_tests.sh` | Interactive numbered menu of all unit tests. Pick a number → runs that test's `run.sh`. |
| `pqc-complete/run_spx.sh` | Interactive menu of SPHINCS+ variants (original and optimized). Pick one → runs it. |
| `pqc-complete/run_spx_batch.sh` | Non-interactive batch driver for SPHINCS+. Accepts `--mode`, `--variants`, phases (`keygen sign verify all`). Saves `.log.iss` files and a `summary.tsv` under `results/spx_batch_<timestamp>/`. |
| `run_tests_cw305.sh` | Picker across both `simple/` and `pqc-complete/`, using **CW305 build flags** (`rv64imac`, `-Os`) for SPHINCS+ tests (for FPGA side-channel measurements). Non-SPHINCS tests fall back to their default flags. |
| `pqc-complete/run_spx_cw305.sh` | Same as `run_spx.sh` but with CW305 build flags. Thin wrapper around `run_spx_batch_cw305.sh`. |
| `pqc-complete/run_spx_batch_cw305.sh` | Same as `run_spx_batch.sh` but with CW305 build flags. |

### Simulation vs CW305 flags

| Flag | Standard (`run_tests.sh` / `run_spx.sh`) | CW305 (`*_cw305.sh`) |
|---|---|---|
| Architecture | `rv64imafdc` (with FP) | `rv64imac` (no FP) |
| Optimization | `-O2` | `-Os` (size optimized) |
| Runtime | `crt.S` / `test.ld` | `cw305_crt.S` / `cw305_linker.ld` |
| Purpose | RTL simulation | Side-channel on CW305 FPGA |

---

## Unit tests (`simple/`, accessible via `run_tests.sh`)

Each of these lives in its own subdirectory and has a `run.sh` that can also
be called directly. Where the software reference and hardware-accelerated
paths live in separate source files, those files are split into
`original/` and `optimized/` subfolders; `main.c` and `run.sh` stay at the
test root and build both into the same comparison binary. A few tests
(`hello-world`, `trigger`, `keccak-abs`, `keccak-permute`) have no such
split — the hardware path is inline in `main.c` or the test isn't a SW/HW
comparison at all — and stay flat.

### `hello-world`

**What it does:** Basic sanity check. Prints a hello message over simulated UART and exits.
**Use it to:** Verify the simulation environment is set up correctly before running heavier tests.

```bash
bash sw/simple/hello-world/run.sh
```

---

### `keccak-permute`

**What it does:** Runs **one Keccak-f[1600] permutation** in both software and hardware on the same deterministic input, then compares all 25 output lanes. Uses the dual-lane `SPX_UNIT_LOAD2` instruction to halve load cycles (13 vs 25 cycles).

**Pass condition:** All 25 lanes match. Prints `RESULT: PASS` and a SW/HW speedup ratio.

```bash
bash sw/simple/keccak-permute/run.sh
```

---

### `keccak-abs`

**What it does:** Full Keccak absorption suite — runs SW (FIPS-202) and HW accelerated versions of:
- SHA3-256 single block (`"abc"`)
- SHA3-512 single block (`"abc"`)
- SHA3-256 multi-block (200-byte input)
- SHAKE128 XOF (consistency check)
- SHAKE256 XOF (consistency check)
- SHAKE128 multi-squeeze (500-byte output)

**Pass condition:** All outputs match expected values and each other.

```bash
bash sw/simple/keccak-abs/run.sh
```

---

### `keccak-abs-sha3-256-single-block`

**What it does:** Focused SHA3-256 test on the single-block input `"abc"`. Runs SW FIPS-202 (`original/`) and HW `sha3_256_hw()` (`optimized/`), checks against the known answer `3a985da7...`.

```bash
bash sw/simple/keccak-abs-sha3-256-single-block/run.sh
```

---

### `keccak-abs-sha3-256-multi-block`

**What it does:** SHA3-256 on a 200-byte input (which spans multiple Keccak rate-blocks). Compares SW (`original/`) vs HW (`optimized/`) output.

```bash
bash sw/simple/keccak-abs-sha3-256-multi-block/run.sh
```

---

### `keccak-abs-shake256`

**What it does:** SHAKE256 on a 100-byte input, 64-byte output. Runs SW (`original/`) and HW (`optimized/`) and compares.

```bash
bash sw/simple/keccak-abs-shake256/run.sh
```

---

### `keccak-abs-multi-squeeze`

**What it does:** SHAKE128 with a large **500-byte output**, requiring multiple squeeze permutations. Compares SW (`original/`) vs HW (`optimized/`) byte-for-byte and measures the speedup.

```bash
bash sw/simple/keccak-abs-multi-squeeze/run.sh
```

---

### `thash`

**What it does:** Tests the SPHINCS+ **`thash1`** (1-input tweakable hash) via the hash coprocessor, across all 6 SPHINCS+ parameter sets: `128f-robust`, `128f-simple`, `192f-robust`, `192f-simple`, `256f-robust`, `256f-simple`. Runs 2 test cases per variant, comparing SW (`original/`) vs HW (`optimized/`).

```bash
bash sw/simple/thash/run.sh
```

---

### `thash2`

**What it does:** Same as `thash` but for **`thash2`** (2-input tweakable hash, used in Merkle tree compression). Doubles the input width (2×n bytes).

```bash
bash sw/simple/thash2/run.sh
```

---

### `thash-wots`

**What it does:** Two sub-tests per SPHINCS+ variant:
1. A single `thash1` call (same as `thash`).
2. A **WOTS+ chain** of 15 sequential `thash1` calls (simulating a WOTS+ hash chain step).

Useful for measuring the cumulative speedup of iterated HW hashing.

```bash
bash sw/simple/thash-wots/run.sh
```

---

### `prf-addr`

**What it does:** Tests **`PRF_addr`** — the SPHINCS+ pseudorandom function that derives secret key material from `(SK.seed, PK.seed, ADRS)`. Runs SW (`original/`) vs HW (`optimized/`) for all 6 parameter sets.

```bash
bash sw/simple/prf-addr/run.sh
```

---

### `chain-lengths`

**What it does:** Tests the **WOTS+ `chain_lengths`** algorithm, which converts a WOTS+ message hash into a vector of nibbles (chain step counts). Includes 3 parameter-set variants (128f/192f/256f), each with pre-computed test vectors. Compares SW (`original/chain_lengths_sw`) vs HW (`optimized/chain_lengths_hw_128f/192f/256f`).

```bash
bash sw/simple/chain-lengths/run.sh
```

---

### `trigger`

**What it does:** Tests the **AXI-mapped trigger IP** peripheral at `0x41000000`. Reads the STATUS register, pulses the trigger output 3 times (START/STOP), and reads back GPIO_O.

**Purpose:** Used for side-channel power measurements — the trigger signal tells the oscilloscope when a cryptographic operation starts/stops. This test verifies the peripheral responds correctly in simulation before using it on the CW305 FPGA.

```bash
bash sw/simple/trigger/run.sh
```

---

## SPHINCS+ / SLH-DSA full-flow tests (`pqc-complete/`)

These are complete SLH-DSA (NIST PQC standard, formerly SPHINCS+) key generation, signing, and verification flows, driven by `run_spx.sh` / `run_spx_batch.sh`.

### Directory layout

```
pqc-complete/
├── original/DS/SLH-DSA/
│   ├── SPHINCS-128f-robust/    # n=16, SHAKE-based, robust tweak
│   ├── SPHINCS-128f-simple/    # n=16, SHAKE-based, simple tweak
│   ├── SPHINCS-192f-robust/    # n=24
│   ├── SPHINCS-192f-simple/    # n=24
│   ├── SPHINCS-256f-robust/    # n=32
│   └── SPHINCS-256f-simple/    # n=32
└── optimized/DS/SLH-DSA/
    └── ... (same 6 variants)
```

### Original vs Optimized

| | Original | Optimized |
|---|---|---|
| Keccak implementation | Pure C (FIPS-202) | Uses the hash coprocessor (`keccak_coproc.S`) |
| Extra source file | — | `keccak_coproc.S` compiled in |
| Purpose | Software reference | Measures HW speedup on a full PQC signature |

### Phases

Each variant can be tested in three phases, controlled by compile-time defines:

| Phase | Define | What runs |
|---|---|---|
| `keygen` | `-DTEST_KEY=1` | Key pair generation |
| `sign` | `-DTEST_SIGN=1` | Message signing |
| `verify` | `-DTEST_SIGN_OPEN=1` | Signature verification |

### Running a single SPHINCS+ variant interactively

```bash
# Standard simulation flags
bash sw/pqc-complete/run_spx.sh

# CW305 FPGA flags
bash sw/pqc-complete/run_spx_cw305.sh
```

### Running all variants in batch

```bash
# All 18 original (reference) simulations (6 variants × 3 phases)
bash sw/pqc-complete/run_spx_batch.sh --mode original keygen sign verify

# All 6 optimized variants, keygen only
bash sw/pqc-complete/run_spx_batch.sh --mode optimized keygen

# Everything (36 simulations)
bash sw/pqc-complete/run_spx_batch.sh --mode all all

# Custom subset of variants
bash sw/pqc-complete/run_spx_batch.sh --mode optimized --variants "SPHINCS-128f-robust SPHINCS-256f-simple" all

# Save results to a specific directory
bash sw/pqc-complete/run_spx_batch.sh --mode original --results-dir /tmp/my_results keygen sign verify
```

Results are saved as `<mode>-<variant>-<phase>.log.iss` plus a `summary.tsv` with mode/variant/phase/status/duration columns, under `sw/results/spx_batch_<timestamp>/` (shared with the unit-test batch output).

There is also a plain `Makefile` (`make -C sw/pqc-complete`) and standalone
`generate_{bin,elf,hex}[_cw305].sh` scripts that build the same variants
into `.bin`/`.elf`/`.hex` artifacts without running ISS/simulation — see
`sw/pqc-complete/generate_hex.sh --help` for the shared option set.

---

## Shared infrastructure (`inc/`)

| Path | Purpose |
|---|---|
| `inc/spx_unit.h` | Hardware coprocessor intrinsics: `spx_unit_init()`, `spx_unit_load()`, `spx_unit_load2()`, `spx_unit_kperm()`, `spx_unit_store()` |
| `inc/spx_unit_coproc.S` | Assembly wrapper for the hash coprocessor |
| `inc/uart.h` / `inc/uart.c` | UART driver used in simulation |
| `inc/compat.h` | Portability helpers |
| `simple/sphincs_ref_impl.h` | Inline SPHINCS+ reference implementation used by `thash`, `thash2`, `thash-wots`, `prf-addr` |
| `simple/api.h` | Kyber-512 API declarations (legacy, not used by current tests) |
| `results/` | Output directory for batch simulation logs (shared by `simple/` and `pqc-complete/`) |

---

## Environment variables

| Variable | Default | Effect |
|---|---|---|
| `SPX_TEST_TIMEOUT` | `100000000000` | RTL watchdog timeout (simulation cycles) |
| `SPX_ISS_TIMEOUT` | `1000000` | `cva6.py` wall-clock timeout (seconds) |
| `DV_SIMULATORS` | `veri-testharness` | Which simulator to use |
| `DV_OPTS` | _(empty)_ | Extra options passed to `cva6.py` |
