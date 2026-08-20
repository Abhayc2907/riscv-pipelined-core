// ID/EX Pipeline Register — Stage 5 version
// Adds pc_in/pc_out (to compute the branch target in EX: pc + imm) and
// funct3_in/funct3_out (to distinguish beq from bne when deciding
// whether a branch is taken) on top of Stage 3/4's fields.
module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
 
    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_ext_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [4:0]  rd_addr_in,
    input  wire [2:0]  funct3_in,
 
    input  wire        reg_write_in,
    input  wire        alu_src_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        branch_in,
    input  wire [3:0]  alu_ctrl_in,
 
    output reg  [31:0] pc_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] imm_ext_out,
    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out,
    output reg  [4:0]  rd_addr_out,
    output reg  [2:0]  funct3_out,
 
    output reg          reg_write_out,
    output reg          alu_src_out,
    output reg          mem_write_out,
    output reg          mem_to_reg_out,
    output reg          branch_out,
    output reg  [3:0]  alu_ctrl_out
);
 
    always @(posedge clk) begin
        if (rst) begin
            pc_out         <= 32'b0;
            rs1_data_out   <= 32'b0;
            rs2_data_out   <= 32'b0;
            imm_ext_out    <= 32'b0;
            rs1_addr_out   <= 5'b0;
            rs2_addr_out   <= 5'b0;
            rd_addr_out    <= 5'b0;
            funct3_out     <= 3'b0;
            reg_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_out     <= 1'b0;
            alu_ctrl_out   <= 4'b0;
        end else begin
            pc_out         <= pc_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            imm_ext_out    <= imm_ext_in;
            rs1_addr_out   <= rs1_addr_in;
            rs2_addr_out   <= rs2_addr_in;
            rd_addr_out    <= rd_addr_in;
            funct3_out     <= funct3_in;
            reg_write_out  <= reg_write_in;
            alu_src_out    <= alu_src_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_out     <= branch_in;
            alu_ctrl_out   <= alu_ctrl_in;
        end
    end
 
endmodule