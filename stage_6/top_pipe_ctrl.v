// 5-stage pipelined RV32I core — Stage 5
// Adds control hazard handling on top of Stage 4's forwarding + stalling:
//   - Branch decision (beq/bne) resolved in EX, reusing the already-
//     forwarded ALU operands from Stage 3 — so branch operands that
//     were just produced by nearby instructions are handled correctly.
//   - Branch target computed in EX (pc_EX + imm_ext_EX).
//   - On a taken branch: redirect PC, and FLUSH the two instructions
//     that were speculatively fetched down the wrong path (currently
//     sitting in IF/ID and about to be decoded from ID/EX) by turning
//     them into bubbles.
//
// Scope: beq and bne only (matches this project's incremental scope —
// blt/bge/bltu/bgeu and jal/jalr are natural follow-on extensions using
// the same flush mechanism, just a different taken-condition and, for
// jumps, an unconditional target).
module top_pipe_ctrl (
    input wire clk,
    input wire rst
);
 
    // =========================================================
    // Hazard/flush signals (declared early, used to gate several stages)
    // =========================================================
    wire stall;
    wire branch_taken;   // computed in EX stage below
    wire flush = branch_taken;
 
    // =========================================================
    // IF stage
    // =========================================================
    wire [31:0] pc, pc_plus4, pc_next;
    wire [31:0] instr_IF;
    wire [31:0] branch_target_EX;   // computed in EX stage below
 
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
    // Priority: taken branch redirects PC; else a load-use stall freezes
    // it; else normal sequential fetch.
    assign pc_next = flush ? branch_target_EX :
                      stall ? pc              :
                              pc_plus4;
 
    // =========================================================
    // IF/ID
    // =========================================================
    wire [31:0] pc_ID, pc_plus4_ID, instr_ID;
 
    if_id_reg u_if_id (
        .clk(clk), .rst(rst), .stall(stall), .flush(flush),
        .pc_in(pc), .pc_plus4_in(pc_plus4), .instr_in(instr_IF),
        .pc_out(pc_ID), .pc_plus4_out(pc_plus4_ID), .instr_out(instr_ID)
    );
 
    // =========================================================
    // ID stage
    // =========================================================
    wire [6:0] opcode_ID    = instr_ID[6:0];
    wire [4:0] rd_ID        = instr_ID[11:7];
    wire [2:0] funct3_ID    = instr_ID[14:12];
    wire [4:0] rs1_ID       = instr_ID[19:15];
    wire [4:0] rs2_ID       = instr_ID[24:20];
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
    wire [31:0] wb_data_WB;
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
 
    // ---- Load-use hazard detection (Stage 4, unchanged) ----
    wire        mem_to_reg_EX;
    wire [4:0]  rd_EX;
 
    hazard_detect_unit u_hazard (
        .idex_mem_to_reg(mem_to_reg_EX), .idex_rd_addr(rd_EX),
        .ifid_rs1_addr(rs1_ID), .ifid_rs2_addr(rs2_ID),
        .stall(stall)
    );
 
    // ---- Bubble insertion into ID/EX on EITHER a stall or a flush ----
    wire squash = stall || flush;
    wire reg_write_ID_eff  = squash ? 1'b0 : reg_write_ID;
    wire mem_write_ID_eff  = squash ? 1'b0 : mem_write_ID;
    wire mem_to_reg_ID_eff = squash ? 1'b0 : mem_to_reg_ID;
    wire branch_ID_eff     = squash ? 1'b0 : branch_ID;
 
    // =========================================================
    // ID/EX
    // =========================================================
    wire [31:0] pc_EX, rs1_data_EX, rs2_data_EX, imm_ext_EX;
    wire [4:0]  rs1_addr_EX, rs2_addr_EX;
    wire [2:0]  funct3_EX;
    wire        reg_write_EX, alu_src_EX, mem_write_EX, branch_EX;
    wire [3:0]  alu_ctrl_EX;
 
    id_ex_reg u_id_ex (
        .clk(clk), .rst(rst),
        .pc_in(pc_ID),
        .rs1_data_in(rs1_data_ID), .rs2_data_in(rs2_data_ID), .imm_ext_in(imm_ext_ID),
        .rs1_addr_in(rs1_ID), .rs2_addr_in(rs2_ID), .rd_addr_in(rd_ID),
        .funct3_in(funct3_ID),
        .reg_write_in(reg_write_ID_eff), .alu_src_in(alu_src_ID),
        .mem_write_in(mem_write_ID_eff), .mem_to_reg_in(mem_to_reg_ID_eff),
        .branch_in(branch_ID_eff),
        .alu_ctrl_in(alu_ctrl_ID),
        .pc_out(pc_EX),
        .rs1_data_out(rs1_data_EX), .rs2_data_out(rs2_data_EX), .imm_ext_out(imm_ext_EX),
        .rs1_addr_out(rs1_addr_EX), .rs2_addr_out(rs2_addr_EX), .rd_addr_out(rd_EX),
        .funct3_out(funct3_EX),
        .reg_write_out(reg_write_EX), .alu_src_out(alu_src_EX),
        .mem_write_out(mem_write_EX), .mem_to_reg_out(mem_to_reg_EX),
        .branch_out(branch_EX),
        .alu_ctrl_out(alu_ctrl_EX)
    );
 
    // =========================================================
    // EX stage — forwarding (Stage 3) + branch resolution (Stage 5, new)
    // =========================================================
    wire [31:0] alu_result_MEM;
    wire [4:0]  rd_MEM;
    wire        reg_write_MEM;
 
    wire [1:0] forward_a, forward_b;
 
    forward_unit u_fwd (
        .idex_rs1_addr(rs1_addr_EX), .idex_rs2_addr(rs2_addr_EX),
        .exmem_rd_addr(rd_MEM),      .exmem_reg_write(reg_write_MEM),
        .memwb_rd_addr(rd_WB),       .memwb_reg_write(reg_write_WB),
        .forward_a(forward_a), .forward_b(forward_b)
    );
 
    wire [31:0] alu_a_fwd = (forward_a == 2'b10) ? alu_result_MEM :
                            (forward_a == 2'b01) ? wb_data_WB     :
                                                    rs1_data_EX;
 
    wire [31:0] alu_b_fwd = (forward_b == 2'b10) ? alu_result_MEM :
                            (forward_b == 2'b01) ? wb_data_WB     :
                                                    rs2_data_EX;
 
    wire [31:0] alu_b_final = alu_src_EX ? imm_ext_EX : alu_b_fwd;
 
    wire [31:0] alu_result_EX;
    wire        alu_zero_EX;
 
    alu u_alu (
        .a(alu_a_fwd), .b(alu_b_final), .alu_ctrl(alu_ctrl_EX),
        .result(alu_result_EX), .zero(alu_zero_EX)
    );
 
    // Branch decision: beq taken when equal (zero=1), bne taken when
    // not equal (zero=0). alu_ctrl is SUB for every branch (set by
    // control_unit), so alu_zero_EX already tells us equality;
    // funct3 just picks how to interpret it.
    wire beq_taken = (funct3_EX == 3'b000) && alu_zero_EX;
    wire bne_taken = (funct3_EX == 3'b001) && !alu_zero_EX;
    assign branch_taken = branch_EX && (beq_taken || bne_taken);
 
    assign branch_target_EX = pc_EX + imm_ext_EX;
 
    // =========================================================
    // EX/MEM
    // =========================================================
    wire [31:0] write_data_MEM;
    wire        mem_write_MEM, mem_to_reg_MEM;
 
    ex_mem_reg u_ex_mem (
        .clk(clk), .rst(rst),
        .alu_result_in(alu_result_EX), .write_data_in(alu_b_fwd), .rd_addr_in(rd_EX),
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