// Forwarding Unit
// Compares the source registers of the instruction currently in EX
// against the destination registers of the instructions currently in
// MEM (EX/MEM reg) and WB (MEM/WB reg). If either later-stage instruction
// is about to write a register this EX-stage instruction needs, select
// that fresher value instead of the (stale) value read from the
// register file back in ID.
//
// Priority: EX/MEM (the more recently produced result) wins over
// MEM/WB if both would otherwise match the same register — handled
// simply by checking the EX/MEM condition first.
//
// Encoding: 2'b00 = no forward, use ID/EX value
//           2'b10 = forward from EX/MEM (the "EX hazard")
//           2'b01 = forward from MEM/WB (the "MEM hazard")
module forward_unit (
    input  wire [4:0] idex_rs1_addr,
    input  wire [4:0] idex_rs2_addr,
 
    input  wire [4:0] exmem_rd_addr,
    input  wire        exmem_reg_write,
 
    input  wire [4:0] memwb_rd_addr,
    input  wire        memwb_reg_write,
 
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);
 
    always @(*) begin
        // ---- Forward A (rs1) ----
        if (exmem_reg_write && (exmem_rd_addr != 5'd0) &&
            (exmem_rd_addr == idex_rs1_addr))
            forward_a = 2'b10;
        else if (memwb_reg_write && (memwb_rd_addr != 5'd0) &&
                 (memwb_rd_addr == idex_rs1_addr))
            forward_a = 2'b01;
        else
            forward_a = 2'b00;
 
        // ---- Forward B (rs2) ----
        if (exmem_reg_write && (exmem_rd_addr != 5'd0) &&
            (exmem_rd_addr == idex_rs2_addr))
            forward_b = 2'b10;
        else if (memwb_reg_write && (memwb_rd_addr != 5'd0) &&
                 (memwb_rd_addr == idex_rs2_addr))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end
 
endmodule