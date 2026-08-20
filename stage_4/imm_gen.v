// Immediate Generator
// Reassembles the scattered immediate bits for each instruction format
// into one sign-extended 32-bit value. Selected by imm_src (from control_unit).
//
// imm_src encoding:
//   000 = I-type   (addi, lw, jalr)
//   001 = S-type   (sw)
//   010 = B-type   (beq, bne, ...)
//   011 = U-type   (lui, auipc)      -- included for future stages
//   100 = J-type   (jal)             -- included for future stages
module imm_gen (
    input  wire [31:0] instr,
    input  wire [2:0]  imm_src,
    output reg  [31:0] imm_ext
);
 
    always @(*) begin
        case (imm_src)
            // I-type: imm[11:0] = instr[31:20], sign-extended
            3'b000: imm_ext = {{20{instr[31]}}, instr[31:20]};
 
            // S-type: imm[11:5]=instr[31:25], imm[4:0]=instr[11:7]
            3'b001: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
 
            // B-type: imm[12|10:5|4:1|11], bit0 implicitly 0
            3'b010: imm_ext = {{19{instr[31]}}, instr[31], instr[7],
                                instr[30:25], instr[11:8], 1'b0};
 
            // U-type: imm[31:12] placed directly, lower 12 bits zeroed
            3'b011: imm_ext = {instr[31:12], 12'b0};
 
            // J-type: imm[20|10:1|11|19:12], bit0 implicitly 0
            3'b100: imm_ext = {{11{instr[31]}}, instr[31], instr[19:12],
                                instr[20], instr[30:21], 1'b0};
 
            default: imm_ext = 32'b0;
        endcase
    end
 
endmodule