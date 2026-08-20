# RISC-V Pipelined Core

Pipelined RISC-V (RV32I) Core

This project implements a RISC-V processor core from the ground up in Verilog, built incrementally in stages to isolate and verify each piece of the design before adding complexity on top of it — rather than attempting a full pipelined implementation in one pass.

The core targets the RV32I base integer instruction set and was developed in six stages: a single-cycle datapath first, to validate correct instruction execution end-to-end; a naive 5-stage pipeline with no hazard handling, to verify that pipeline registers correctly move instructions through IF/ID/EX/MEM/WB without corrupting state; a forwarding unit to resolve data hazards without stalling; a hazard detection unit to handle load-use hazards that forwarding alone can't fix; control hazard handling for branches; and finally comprehensive verification against a broad, densely-packed instruction stream.

Each stage is independently testable and lives in its own folder. Every module — register file, ALU, immediate generator, control unit, data memory, and the pipeline registers themselves — is a small, self-contained Verilog file with a single clear responsibility, simulated and verified with Icarus Verilog before moving to the next stage. Testbenches use self-checking assertions (expected vs. actual register/memory values) rather than manual waveform inspection, so regressions are caught automatically as the design grows in complexity.

## Progress

- **Stage 1 — Single-cycle core**: Supports `add`, `sub`, `addi`, `lw`, `sw`, `beq`, with a full RV32I-compliant immediate generator (I/S/B-type) and control unit driven by opcode/funct3/funct7 decoding.
- **Stage 2 — Naive 5-stage pipeline**: IF/ID/EX/MEM/WB pipeline registers inserted, no hazard handling. Verified against a hazard-free instruction sequence to confirm correct pipeline timing.
- **Stage 3 — Forwarding**: EX/MEM → EX and MEM/WB → EX bypass paths added, resolving RAW data hazards without stalling. Also required a "write-first" register file (same-cycle write/read bypass) to correctly handle producer/consumer pairs exactly 3 instructions apart.
- **Stage 4 — Load-use hazard detection**: Hazard detection unit + 1-cycle pipeline stall for the one case forwarding can't resolve — a load immediately followed by a dependent instruction.
- **Stage 5 — Control hazards**: `beq`/`bne` resolved in the EX stage (reusing Stage 3's forwarding for branch operands), with a 2-cycle flush of speculatively-fetched instructions on a taken branch.
- **Stage 6 — Comprehensive verification**: Every R-type and I-type ALU operation `control_unit.v` has supported since Stage 1 — but never actually been run — verified through the full pipeline (forwarding + stalling + branch flush all active simultaneously), including logical-vs-arithmetic shift and signed-vs-unsigned comparison edge cases.

## Known gaps (honest scope)

This core implements a functional, hazard-correct subset of RV32I — not the full ISA. Explicitly **not yet implemented**:
- `blt`, `bge`, `bltu`, `bgeu` — control unit decodes them, but EX-stage branch decision logic only handles `beq`/`bne`
- `jal`, `jalr` — not wired up
- `lb`, `lh`, `lbu`, `lhu`, `sb`, `sh` — data memory is word-only; only `lw`/`sw` are supported
- CSR instructions, `ecall`/`ebreak`, `fence` — stubbed as no-ops via the control unit's default case
- Exceptions/interrupts, branch prediction beyond static not-taken, M-extension (mul/div)

These are natural extensions using the same mechanisms already built (the flush logic that handles `beq`/`bne` reuses directly for `blt`/`bge`/`jal`/`jalr`; byte/halfword memory access just needs `funct3`-based width selection added to `data_mem.v`).

## Build & run

Each stage lives in its own folder (`stage_1` through `stage_6`). From inside a stage's folder:

```bash
iverilog -o sim.out <testbench>.v <top-level>.v <other .v files...>
vvp sim.out
```

See each stage folder for its exact file list and compile command.

## Requirements

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`)
