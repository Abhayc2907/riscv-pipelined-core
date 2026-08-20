// Control Unit
// Main decoder: opcode -> datapath control signals
// ALU decoder: {opcode, funct3, funct7[5]} -> alu_ctrl
//
// Stage 1 scope: R-type (add, sub), I-type OP-IMM (addi), LOAD (lw),
// STORE (sw), BRANCH (beq). Extend the case statements to add more.
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire        funct7_b5,   // instr[30] - distinguishes sub/srai etc.
 
    output reg         reg_write,
    output reg         alu_src,     // 0 = rs2, 1 = immediate
    output reg         mem_write,
    output reg         mem_to_reg,  // 0 = alu_result, 1 = mem_rdata
    output reg         branch,
    output reg  [2:0]  imm_src,
    output reg  [3:0]  alu_ctrl
);
 
    // Opcode major classes (inst[6:0], inst[1:0] always = 11 so omitted)
    localparam OP_R      = 7'b0110011; // add, sub, ...
    localparam OP_IMM    = 7'b0010011; // addi, ...
    localparam OP_LOAD   = 7'b0000011; // lw, ...
    localparam OP_STORE  = 7'b0100011; // sw, ...
    localparam OP_BRANCH = 7'b1100011; // beq, ...
 
    always @(*) begin
        // Safe defaults — every control signal driven every cycle
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        imm_src    = 3'b000;
        alu_ctrl   = 4'b0000;
 
        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;         // both operands from registers
                case (funct3)
                    3'b000: alu_ctrl = funct7_b5 ? 4'b0001 : 4'b0000; // sub : add
                    3'b111: alu_ctrl = 4'b0010;                        // and
                    3'b110: alu_ctrl = 4'b0011;                        // or
                    3'b100: alu_ctrl = 4'b0100;                        // xor
                    3'b001: alu_ctrl = 4'b0101;                        // sll
                    3'b101: alu_ctrl = funct7_b5 ? 4'b0111 : 4'b0110;  // sra : srl
                    3'b010: alu_ctrl = 4'b1000;                        // slt
                    3'b011: alu_ctrl = 4'b1001;                        // sltu
                    default: alu_ctrl = 4'b0000;
                endcase
            end
 
            OP_IMM: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;         // second operand is immediate
                imm_src   = 3'b000;       // I-type
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000;                        // addi
                    3'b111: alu_ctrl = 4'b0010;                        // andi
                    3'b110: alu_ctrl = 4'b0011;                        // ori
                    3'b100: alu_ctrl = 4'b0100;                        // xori
                    3'b001: alu_ctrl = 4'b0101;                        // slli
                    3'b101: alu_ctrl = funct7_b5 ? 4'b0111 : 4'b0110;  // srai : srli
                    3'b010: alu_ctrl = 4'b1000;                        // slti
                    3'b011: alu_ctrl = 4'b1001;                        // sltiu
                    default: alu_ctrl = 4'b0000;
                endcase
            end
 
            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;        // rs1 + imm = address
                imm_src    = 3'b000;      // I-type
                mem_to_reg = 1'b1;        // writeback comes from memory
                alu_ctrl   = 4'b0000;     // address = add
            end
 
            OP_STORE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;         // rs1 + imm = address
                imm_src   = 3'b001;       // S-type
                alu_ctrl  = 4'b0000;      // address = add
            end
 
            OP_BRANCH: begin
                branch   = 1'b1;
                alu_src  = 1'b0;          // compare rs1 vs rs2 directly
                imm_src  = 3'b010;        // B-type
                alu_ctrl = 4'b0001;       // subtract, check zero flag
                // Stage 1 only wires up beq (funct3 = 000).
                // bne/blt/bge/etc. need the branch-decision logic extended
                // in top.v beyond a plain zero-flag check.
            end
 
            default: ; // reserved/unimplemented opcode — all signals stay at safe defaults
        endcase
    end
 
endmodule