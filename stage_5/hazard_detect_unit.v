// Hazard Detection Unit
// Detects the ONE hazard forwarding cannot fix: a load immediately
// followed by an instruction that needs the loaded value. The loaded
// value isn't ready until the end of MEM — one cycle too late for the
// very next instruction's EX stage, no matter how it's forwarded.
//
// Looks at the instruction currently sitting in ID/EX (is it a load?
// mem_to_reg is a reliable "this is a load" signal in this design,
// since only loads assert it) and compares its destination register
// against the source registers of the instruction currently in ID
// (the one about to enter ID/EX this cycle).
//
// If they match, assert `stall`: freeze PC, freeze IF/ID, and the
// caller inserts a bubble (NOP) into ID/EX instead of the real
// instruction — buying one cycle so the load's result reaches EX/MEM
// and can be forwarded normally next cycle.
module hazard_detect_unit (
    input  wire        idex_mem_to_reg,   // ID/EX instruction is a load
    input  wire [4:0]  idex_rd_addr,
 
    input  wire [4:0]  ifid_rs1_addr,     // rs1/rs2 of instruction in ID
    input  wire [4:0]  ifid_rs2_addr,
 
    output wire         stall
);
 
    assign stall = idex_mem_to_reg &&
                   (idex_rd_addr != 5'd0) &&
                   ((idex_rd_addr == ifid_rs1_addr) ||
                    (idex_rd_addr == ifid_rs2_addr));
 
endmodule