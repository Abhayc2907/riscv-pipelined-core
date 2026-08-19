# RISC-V Pipelined Core

Pipelined RISC-V (RV32I) Core

This project implements a RISC-V processor core from the ground up in Verilog, built incrementally in stages to isolate and verify each piece of the design before adding complexity on top of it — rather than attempting a full pipelined implementation in one pass.

The core targets the RV32I base integer instruction set and is being developed in six stages: a single-cycle datapath first, to validate correct instruction execution end-to-end; a naive 5-stage pipeline with no hazard handling, to verify that pipeline registers correctly move instructions through IF/ID/EX/MEM/WB without corrupting state; a forwarding unit to resolve data hazards without stalling; a hazard detection unit to handle load-use hazards that forwarding alone can't fix; control hazard handling for branches and jumps; and finally verification against hand-written and standard RISC-V test programs.

Each stage is independently testable. Every module — register file, ALU, immediate generator, control unit, data memory, and the pipeline registers themselves — is a small, self-contained Verilog file with a single clear responsibility, simulated and verified with Icarus Verilog before moving to the next stage. Testbenches use self-checking assertions (expected vs. actual register/memory values) rather than manual waveform inspection, so regressions are caught automatically as the design grows in complexity.

## Progress

- **Stage 1 — Single-cycle core**: Supports `add`, `sub`, `addi`, `lw`, `sw`, `beq`, with a full RV32I-compliant immediate generator (I/S/B-type) and control unit driven by opcode/funct3/funct7 decoding.
- **Stage 2 — Naive 5-stage pipeline**: IF/ID/EX/MEM/WB pipeline registers inserted, no hazard handling. Verified against a hazard-free instruction sequence to confirm correct pipeline timing.
- **Stage 3 — Forwarding**: EX/MEM → EX and MEM/WB → EX bypass paths added, resolving RAW data hazards without stalling. Dependent instructions can now sit back-to-back. Also required a "write-first" register file (same-cycle write/read bypass) to correctly handle producer/consumer pairs exactly 3 instructions apart.
- **Stage 4 — Load-use hazard detection** *(in progress)*: forwarding alone can't resolve a load immediately followed by a dependent instruction, since the loaded value isn't ready until MEM completes. Requires a hazard detection unit and a 1-cycle pipeline stall.
- **Stage 5 — Control hazards** *(planned)*: branch/jump resolution and pipeline flush.
- **Stage 6 — Verification** *(planned)*: testing against standard RISC-V test suites.

## Build & run

Each stage lives in its own folder (`stage_1`, `stage_2`, `stage_3`, ...). From inside a stage's folder:

```bash
iverilog -o sim.out <testbench>.v <top-level>.v <other .v files...>
vvp sim.out
```

See each stage folder for its exact file list and compile command.

## Requirements

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`)
