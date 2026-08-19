# RISC-V Pipelined Core

Pipelined RISC-V (RV32I) Core

This project implements a RISC-V processor core from the ground up in Verilog, built incrementally in stages to isolate and verify each piece of the design before adding complexity on top of it — rather than attempting a full pipelined implementation in one pass.

The core targets the RV32I base integer instruction set and is being developed in six stages: a single-cycle datapath first, to validate correct instruction execution end-to-end; a naive 5-stage pipeline with no hazard handling, to verify that pipeline registers correctly move instructions through IF/ID/EX/MEM/WB without corrupting state; a forwarding unit to resolve data hazards without stalling; a hazard detection unit to handle load-use hazards that forwarding alone can't fix; control hazard handling for branches and jumps; and finally verification against hand-written and standard RISC-V test programs.

Each stage is independently testable. Every module — register file, ALU, immediate generator, control unit, data memory, and the pipeline registers themselves — is a small, self-contained Verilog file with a single clear responsibility, simulated and verified with Icarus Verilog before moving to the next stage.

Currently implemented:
- **Stage 1**: Single-cycle core supporting add, sub, addi, lw, sw, and beq
- **Stage 2**: 5-stage pipelined datapath, verified against a hazard-free instruction sequence
