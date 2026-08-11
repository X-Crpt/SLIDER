# spx-unit results

This collects every measured result for the **spx-unit** (the `\haship`
CV-X-IF coprocessor, `rtl/spx-unit/`) accelerating SLH-DSA/SPHINCS+ on
CVA6. Physical design, algorithm-level, energy, and FPGA-comparison numbers
are reproduced from `jetcas_slider.tex` (already-measured, not re-run here).
The kernel-level breakdown at the bottom is new: it was obtained by running
the actual unit tests in `sw/simple/` on the cycle-accurate Verilator RTL
simulation of the integrated CVA6 + spx-unit system, so it also serves as a
functional check that the hardware path is working correctly (every test
below reports `PASS`, i.e. HW output == SW reference output, in addition to
the cycle/instruction counts).

Implementation target: Xilinx Artix-7 XC7A100T (ChipWhisperer CW305),
Vivado 2019.2. Static timing closes up to 128 MHz for spx-unit; power/energy
measurements were taken at 12 MHz (JTAG-bandwidth-limited acquisition
setup), see the Energy section for why that operating point does not
represent nominal throughput.

---

## 1. Algorithm-level performance

Software baseline (`Base (SHA)`, pure-C, no acceleration) vs. spx-unit,
across all six SLH-DSA-SHAKE parameter sets and all three operations
(K = Keygen, S = Sign, V = Verify). kCC/kI are thousands of cycles /
instructions.

| Par | Op | Base kCC | Base kI | spx-unit kCC | spx-unit kI | Spd | Instr. Red. |
|---|---|---:|---:|---:|---:|---:|---:|
| 128fs | K | 41,490 | 35,183 | 2,677 | 1,635 | 15.50x | 95.35% |
| 128fs | S | 966,360 | 823,343 | 64,522 | 38,688 | 14.98x | 95.30% |
| 128fs | V | 57,617 | 49,147 | 3,904 | 2,354 | 14.76x | 95.21% |
| 128fr | K | 80,552 | 68,681 | 2,918 | 1,705 | 27.61x | 97.52% |
| 128fr | S | 1,866,566 | 1,592,597 | 69,826 | 40,235 | 26.73x | 97.47% |
| 128fr | V | 120,091 | 102,602 | 4,366 | 2,541 | 27.50x | 97.52% |
| 192fs | K | 61,055 | 51,405 | 4,660 | 3,057 | 13.10x | 94.05% |
| 192fs | S | 1,594,248 | 1,346,993 | 126,827 | 80,984 | 12.57x | 93.99% |
| 192fs | V | 86,886 | 73,376 | 6,910 | 4,401 | 12.57x | 94.00% |
| 192fr | K | 118,227 | 100,564 | 5,037 | 3,188 | 23.47x | 96.83% |
| 192fr | S | 3,044,459 | 2,578,710 | 135,823 | 83,901 | 22.41x | 96.75% |
| 192fr | V | 171,492 | 144,944 | 7,655 | 4,737 | 22.40x | 96.73% |
| 256fs | K | 161,597 | 136,355 | 15,475 | 9,622 | 10.44x | 92.94% |
| 256fs | S | 3,305,886 | 2,779,607 | 313,918 | 198,249 | 10.53x | 92.87% |
| 256fs | V | 87,693 | 73,789 | 8,502 | 5,132 | 10.31x | 93.04% |
| 256fr | K | 428,280 | 370,725 | 16,167 | 10,065 | 26.49x | 97.28% |
| 256fr | S | 8,368,608 | 7,195,093 | 329,644 | 205,835 | 25.39x | 97.14% |
| 256fr | V | 235,096 | 202,790 | 9,193 | 5,725 | 25.57x | 97.18% |

**Takeaway:** spx-unit cuts executed instructions by 92.9%–97.5% and
delivers 10.3x–27.6x cycle speedup over the pure-C baseline across all six
parameter sets. Robust variants benefit more (22.4x–27.6x) than simple
variants (10.3x–15.5x), since the `sphincs-unit` FSM retains the
intermediate bitmask on-chip for the extra Keccak-f pass robust THASH
requires, instead of round-tripping it through software.

---

## 2. Area / resource utilization

| Resource | spx-unit |
|---|---:|
| LUT | 13,047 |
| FF | 7,436 |
| DSP | 0 |
| BRAM | 0 |

(For reference, the area-optimized `ALU*` scalar crypto-extension backend
uses 2,944 LUT / 399 FF / 0 DSP / 0 BRAM — spx-unit trades a larger
footprint, from the two 1600-bit state structures and the Keccak-f
datapath, for full local retention of SLH-DSA hash-processing state.)

---

## 3. Energy (SPHINCS+ 128f-robust, measured at 12 MHz)

FPGA-core-supply-rail energy-to-solution; reductions are relative to the
`Base (SHA)` software baseline. See caveats below the table — this is a
system-level (FPGA core rail), not isolated-accelerator, measurement.

| Metric | Keygen | Sign | Verify |
|---|---:|---:|---:|
| Base (SHA) power [mW] | 2.899 | 3.006 | 3.000 |
| Base (SHA) energy [mJ] | 20.164 | 483.893 | 31.027 |
| spx-unit power [mW] | 2.905 | 2.761 | 2.825 |
| spx-unit energy [mJ] | 0.712 | 15.532 | 1.003 |
| **Energy reduction** | **96.47%** | **96.79%** | **96.77%** |

Caveats (see `jetcas_slider.tex` §Energy Efficiency Analysis for full
detail): measured at the FPGA core-rail boundary (includes static/board
power, not the accelerator in isolation), at a 12 MHz operating point
chosen for the JTAG acquisition setup, not spx-unit's actual 128 MHz
closure frequency. Because measured power is roughly constant across
baseline and accelerated runs, the reported energy reduction mainly
reflects the reduction in execution time, not a claim about isolated
accelerator dynamic energy.

---

## 4. Comparison with literature (SPHINCS+ 256fs, Artix-7)

| Ref. | Resources (LUT/FF/DSP/BRAM) | eSlices | f_max [MHz] | Keygen [ms] | Sign [ms] | Verify [ms] |
|---|---|---:|---:|---:|---:|---:|
| Deshpande et al. 2025 (SPHINCSLET, SHAKE) | 10,416 / 7,672 / 0 / 8 | 3,628 | 150 | -- | 62 | 3 |
| Deshpande et al. 2025 (SPHINCSLET, SHA-2) | 15,513 / 15,206 / 0 / 12 | 5,414 | 100 | -- | 173 | 14 |
| Amiet et al. 2020 | 51,009 / 74,539 / 1 / 22.5 | 15,632 | 250 | -- | 3 | -- |
| Lopez-Valdivieso & Cumplido 2024 (SHAKE) | 5,611 / 2,652 / 0 / 16 | 3,451 | 100 | 341 | 6,932 | 189 |
| Lopez-Valdivieso & Cumplido 2024 (Haraka) | 7,226 / 3,164 / 0 / 16 | 3,855 | 100 | 803 | 11,811 | 30 |
| Saarinen 2024 (SHAKE) | 8,605 / 3,745 / 0 / 32 | 6,247 | 100 | -- | 237 | 9 |
| Saarinen 2024 (SHA-2) | 8,965 / 6,823 / 0 / 32 | 6,337 | 100 | -- | 502 | 14 |
| **spx-unit (this work)** | **13,047 / 7,436 / 0 / 0** | **3,261** | **128** | **121** | **2,452** | **66** |

eSlices = max(LUT/4 + 128·BRAM, FF/8). spx-unit resource figures are the
incremental accelerator only (host CVA6 core excluded), same convention as
the other rows. Literature entries pursuing maximum throughput through
dedicated local memory/parallelism (Deshpande et al., Amiet et al., Saarinen)
reach lower latency at a larger dedicated footprint; spx-unit occupies an
intermediate point (3,261 eSlices, comparable to the smallest dedicated
designs above) while retaining the CV-X-IF software-integration model.

---

## 5. Kernel-level execution breakdown (SPHINCS+ 128f-robust signing)

**New in this pass.** Rather than only the algorithm-level totals above,
this isolates the five hardware kernels spx-unit exposes and measures each
one directly, SW reference vs. spx-unit, on the same cycle-accurate RTL
simulation — both to report per-kernel numbers and to confirm the hardware
path is functionally correct (every row below passed HW-vs-SW output
comparison in its unit test).

| Kernel | Calls/Sign | SW Cycles/Instr | spx-unit Cycles/Instr | Speedup | Instr. Reduction |
|---|---:|---:|---:|---:|---:|
| Keccak-*f* (`KPERM`) | 203,566 | 5,056 / 4,600 | 264 / 139 | 19.15x | 96.98% |
| PRF_addr (`PRFADDR_128`) | 8,305 | 6,396 / 5,306 | 482 / 255 | 13.27x | 95.19% |
| THASH1 (`THASH1_128`) | 94,512 | 12,184 / 10,594 | 508 / 255 | 23.98x | 97.59% |
| THASH2 (`THASH2_128`) | 2,233 | 12,283 / 10,719 | 529 / 267 | 23.22x | 97.51% |
| WOTS+ chain length (`WOTS_128`) | 22 | 795 / 420 | 367 / 164 | 2.17x | 60.95% |

**Test source (`sw/simple/`):** `keccak-permute` (KPERM), `prf-addr`
(PRFADDR_128), `thash` (THASH1_128), `thash2` (THASH2_128),
`chain-lengths` (WOTS_128). Each test's `run.sh` builds both the SW
reference path and the spx-unit-accelerated path into one RISC-V binary,
runs it on the full CVA6 + spx-unit Verilator model, and compares outputs;
SW/HW cycle counts come from `mcycle`, instruction counts from `minstret`
(both CSRs newly instrumented in this pass — previously only `mcycle` was
read). Numbers above are the 128f-robust (`n=16`, `simple_mode=0`) case;
each test also exercises 128f-simple/192f/256f, see the full per-variant
output in `sw/simple/*/run.sh` logs.

**Calls/Sign methodology:** these are *not* simulated on the RTL model —
one full SLH-DSA-SHAKE-128f-robust sign takes on the order of 10⁷–10⁸
simulated cycles, impractical to run in this environment. Instead, the
reference C implementation (`sw/pqc-complete/original/DS/SLH-DSA/SPHINCS-128f-robust/`)
was instrumented with call counters on `thash()` (split by 1- vs 2-block
calls), `prf_addr()`, `chain_lengths()`, and the underlying
`KeccakF1600_StatePermute()`, compiled natively (x86, functional only, not
cycle-accurate), and run once against the NIST KAT vector bundled in that
test (keygen + sign). `KPERM`'s count is the *total* permutations executed
by the SW reference during signing — it includes permutations that, in the
accelerated path, happen internally inside `PRFADDR_128`/`THASH1_128`/
`THASH2_128` (each of those triggers 1–2 Keccak-f passes per the
`sphincs-unit` FSM) as well as the generic multi-block tweakable hashes
(WOTS+ and FORS public-key compression) that fall outside the five
dedicated kernels listed here. The other four rows count discrete
top-level calls to that specific primitive, one-to-one with the
corresponding custom instruction.

Sanity check: multiplying each kernel's spx-unit cycle cost by its
Calls/Sign and summing accounts for ≈53.2M of the 69.8M total spx-unit
sign cycles reported in §1 (128fr) — the remainder is the generic
multi-block THASH calls (WOTS+/FORS public-key compression, len=35/k=33
blocks, not covered by the two dedicated 1-/2-block kernels) plus
top-level SW orchestration, both outside the five kernels profiled here.
