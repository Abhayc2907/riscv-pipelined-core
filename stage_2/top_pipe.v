// 5-stage pipelined RV32I core — Stage 2
// Naive pipeline: NO forwarding, NO hazard detection/stalling, NO branch
// handling (PC always increments by 4 — branches deferred to Stage 5).
// Valid ONLY for independent instruction sequences at this stage — that's
// the point: verify the pipeline registers move instructions through
// correctly before hazard logic is added on top in Stages 3-5.
module top_pipe (
    input wire clk,
    input wire rst
);
 
    // =========================================================
    // IF stage
    // =========================================================
    wire [31:0] pc, pc_plus4, pc_next;
    wire [31:0] instr_IF;
 
    pc_reg u_pc (
        .clk(clk), .rst(rst),
        .pc_next(pc_next),
        .pc(pc)
    );
 
    instr_mem u_imem (
        .addr(pc),
        .instr(instr_IF)
    );
 
    assign pc_plus4 = pc + 32'd4;
    assign pc_next  = pc_plus4;   // no branching yet — Stage 5 adds the mux
 
    // =========================================================
    // IF/ID
    // =========================================================
    wire [31:0] pc_ID, pc_plus4_ID, instr_ID;
 
    if_id_reg u_if_id (
        .clk(clk), .rst(rst),
        .pc_in(pc), .pc_plus4_in(pc_plus4), .instr_in(instr_IF),
        .pc_out(pc_ID), .pc_plus4_out(pc_plus4_ID), .instr_out(instr_ID)
    );
 
    // =========================================================
    // ID stage
    // =========================================================
    wire [6:0] opcode_ID   = instr_ID[6:0];
    wire [4:0] rd_ID       = instr_ID[11:7];
    wire [2:0] funct3_ID   = instr_ID[14:12];
    wire [4:0] rs1_ID      = instr_ID[19:15];
    wire [4:0] rs2_ID      = instr_ID[24:20];
    wire       funct7_b5_ID = instr_ID[30];
 
    wire        reg_write_ID, alu_src_ID, mem_write_ID, mem_to_reg_ID, branch_ID;
    wire [2:0]  imm_src_ID;
    wire [3:0]  alu_ctrl_ID;
 
    control_unit u_ctrl (
        .opcode(opcode_ID), .funct3(funct3_ID), .funct7_b5(funct7_b5_ID),
        .reg_write(reg_write_ID), .alu_src(alu_src_ID), .mem_write(mem_write_ID),
        .mem_to_reg(mem_to_reg_ID), .branch(branch_ID),
        .imm_src(imm_src_ID), .alu_ctrl(alu_ctrl_ID)
    );
 
    wire [31:0] rs1_data_ID, rs2_data_ID;
    wire [31:0] wb_data_WB;         // driven from WB stage, defined below
    wire        reg_write_WB;
    wire [4:0]  rd_WB;
 
    reg_file u_rf (
        .clk(clk), .we(reg_write_WB),
        .rs1_addr(rs1_ID), .rs2_addr(rs2_ID), .rd_addr(rd_WB),
        .rd_data(wb_data_WB),
        .rs1_data(rs1_data_ID), .rs2_data(rs2_data_ID)
    );
 
    wire [31:0] imm_ext_ID;
    imm_gen u_immgen (
        .instr(instr_ID), .imm_src(imm_src_ID),
        .imm_ext(imm_ext_ID)
    );
 
    // =========================================================
    // ID/EX
    // =========================================================
    wire [31:0] rs1_data_EX, rs2_data_EX, imm_ext_EX;
    wire [4:0]  rs1_addr_EX, rs2_addr_EX, rd_EX;
    wire        reg_write_EX, alu_src_EX, mem_write_EX, mem_to_reg_EX;
    wire [3:0]  alu_ctrl_EX;
 
    id_ex_reg u_id_ex (
        .clk(clk), .rst(rst),
        .rs1_data_in(rs1_data_ID), .rs2_data_in(rs2_data_ID), .imm_ext_in(imm_ext_ID),
        .rs1_addr_in(rs1_ID), .rs2_addr_in(rs2_ID), .rd_addr_in(rd_ID),
        .reg_write_in(reg_write_ID), .alu_src_in(alu_src_ID),
        .mem_write_in(mem_write_ID), .mem_to_reg_in(mem_to_reg_ID),
        .alu_ctrl_in(alu_ctrl_ID),
        .rs1_data_out(rs1_data_EX), .rs2_data_out(rs2_data_EX), .imm_ext_out(imm_ext_EX),
        .rs1_addr_out(rs1_addr_EX), .rs2_addr_out(rs2_addr_EX), .rd_addr_out(rd_EX),
        .reg_write_out(reg_write_EX), .alu_src_out(alu_src_EX),
        .mem_write_out(mem_write_EX), .mem_to_reg_out(mem_to_reg_EX),
        .alu_ctrl_out(alu_ctrl_EX)
    );
 
    // =========================================================
    // EX stage
    // =========================================================
    wire [31:0] alu_b_EX = alu_src_EX ? imm_ext_EX : rs2_data_EX;
    wire [31:0] alu_result_EX;
    wire        alu_zero_EX;
 
    alu u_alu (
        .a(rs1_data_EX), .b(alu_b_EX), .alu_ctrl(alu_ctrl_EX),
        .result(alu_result_EX), .zero(alu_zero_EX)
    );
 
    // =========================================================
    // EX/MEM
    // =========================================================
    wire [31:0] alu_result_MEM, write_data_MEM;
    wire [4:0]  rd_MEM;
    wire        reg_write_MEM, mem_write_MEM, mem_to_reg_MEM;
 
    ex_mem_reg u_ex_mem (
        .clk(clk), .rst(rst),
        .alu_result_in(alu_result_EX), .write_data_in(rs2_data_EX), .rd_addr_in(rd_EX),
        .reg_write_in(reg_write_EX), .mem_write_in(mem_write_EX), .mem_to_reg_in(mem_to_reg_EX),
        .alu_result_out(alu_result_MEM), .write_data_out(write_data_MEM), .rd_addr_out(rd_MEM),
        .reg_write_out(reg_write_MEM), .mem_write_out(mem_write_MEM), .mem_to_reg_out(mem_to_reg_MEM)
    );
 
    // =========================================================
    // MEM stage
    // =========================================================
    wire [31:0] mem_rdata_MEM;
 
    data_mem u_dmem (
        .clk(clk), .we(mem_write_MEM),
        .addr(alu_result_MEM), .wdata(write_data_MEM),
        .rdata(mem_rdata_MEM)
    );
 
    // =========================================================
    // MEM/WB
    // =========================================================
    wire [31:0] mem_rdata_WB, alu_result_WB_pass;
    wire        mem_to_reg_WB;
 
    mem_wb_reg u_mem_wb (
        .clk(clk), .rst(rst),
        .mem_rdata_in(mem_rdata_MEM), .alu_result_in(alu_result_MEM), .rd_addr_in(rd_MEM),
        .reg_write_in(reg_write_MEM), .mem_to_reg_in(mem_to_reg_MEM),
        .mem_rdata_out(mem_rdata_WB), .alu_result_out(alu_result_WB_pass), .rd_addr_out(rd_WB),
        .reg_write_out(reg_write_WB), .mem_to_reg_out(mem_to_reg_WB)
    );
 
    // =========================================================
    // WB stage
    // =========================================================
    assign wb_data_WB = mem_to_reg_WB ? mem_rdata_WB : alu_result_WB_pass;
 
endmodule