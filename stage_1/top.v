
// Single-cycle RV32I core — Stage 1
// Supports: add, sub, addi, lw, sw, beq
// Everything happens within one clock cycle: fetch -> decode -> execute
// -> memory -> writeback, all as combinational logic between PC updates.
module top (
    input wire clk,
    input wire rst
);
 
    // ---------------- Fetch ----------------
    wire [31:0] pc, pc_next, pc_plus4, pc_branch;
    wire [31:0] instr;
 
    pc_reg u_pc (
        .clk(clk), .rst(rst),
        .pc_next(pc_next),
        .pc(pc)
    );
 
    instr_mem u_imem (
        .addr(pc),
        .instr(instr)
    );
 
    assign pc_plus4 = pc + 32'd4;
 
    // ---------------- Decode ----------------
    wire [6:0] opcode  = instr[6:0];
    wire [4:0] rd_addr = instr[11:7];
    wire [2:0] funct3  = instr[14:12];
    wire [4:0] rs1_addr = instr[19:15];
    wire [4:0] rs2_addr = instr[24:20];
    wire       funct7_b5 = instr[30];
 
    wire        reg_write, alu_src, mem_write, mem_to_reg, branch;
    wire [2:0]  imm_src;
    wire [3:0]  alu_ctrl;
 
    control_unit u_ctrl (
        .opcode(opcode), .funct3(funct3), .funct7_b5(funct7_b5),
        .reg_write(reg_write), .alu_src(alu_src), .mem_write(mem_write),
        .mem_to_reg(mem_to_reg), .branch(branch),
        .imm_src(imm_src), .alu_ctrl(alu_ctrl)
    );
 
    wire [31:0] rs1_data, rs2_data, wb_data;
 
    reg_file u_rf (
        .clk(clk), .we(reg_write),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .rd_addr(rd_addr),
        .rd_data(wb_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );
 
    wire [31:0] imm_ext;
    imm_gen u_immgen (
        .instr(instr), .imm_src(imm_src),
        .imm_ext(imm_ext)
    );
 
    // ---------------- Execute ----------------
    wire [31:0] alu_b   = alu_src ? imm_ext : rs2_data;
    wire [31:0] alu_result;
    wire        alu_zero;
 
    alu u_alu (
        .a(rs1_data), .b(alu_b), .alu_ctrl(alu_ctrl),
        .result(alu_result), .zero(alu_zero)
    );
 
    // Branch target = PC + immediate (B-type)
    assign pc_branch = pc + imm_ext;
 
    // beq: take branch when operands are equal (alu computed rs1-rs2, zero=equal)
    wire pc_src = branch & alu_zero;
    assign pc_next = pc_src ? pc_branch : pc_plus4;
 
    // ---------------- Memory ----------------
    wire [31:0] mem_rdata;
 
    data_mem u_dmem (
        .clk(clk), .we(mem_write),
        .addr(alu_result), .wdata(rs2_data),
        .rdata(mem_rdata)
    );
 
    // ---------------- Writeback ----------------
    assign wb_data = mem_to_reg ? mem_rdata : alu_result;
 
endmodule
 