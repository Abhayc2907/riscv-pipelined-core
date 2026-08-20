// Testbench for Stage 6: comprehensive verification of every instruction
// control_unit.v has claimed to support since Stage 1, run through the
// FULL Stage 5 pipeline (forwarding + load-use stalling + branch
// resolution/flushing all active simultaneously) -- not isolated
// single-feature tests like Stages 2-5 used, but a realistic,
// densely-packed instruction stream the way a compiler would emit it.
//
// See program.hex / the assembler script for the full instruction list
// and comments. Summary of what's being proven:
//   - All 10 R-type ALU ops:  add, sub, and, or, xor, sll, srl, sra,
//                              slt, sltu
//   - All 9 I-type ALU ops:   addi, andi, ori, xori, slli, srli, srai,
//                              slti, sltiu
//   - lw / sw
//   - beq / bne, both taken and not-taken, integrated with everything
//     else (re-confirms flush logic still works amid a broader mix)
`timescale 1ns/1ps
 
module top_pipe_ctrl_verify_tb;
 
    reg clk;
    reg rst;
    integer errors;
 
    top_pipe_ctrl dut (
        .clk(clk),
        .rst(rst)
    );
 
    initial clk = 0;
    always #5 clk = ~clk;
 
    initial begin
        errors = 0;
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
 
        // 30 instructions, 1 taken branch (2-cycle flush penalty),
        // generous margin included.
        repeat (50) @(posedge clk);
 
        // --- setup ---
        check(1,  dut.u_rf.regs[1],  32'd12,        "x1 (addi x1,x0,12)");
        check(2,  dut.u_rf.regs[2],  32'd10,        "x2 (addi x2,x0,10)");
        check(3,  dut.u_rf.regs[12], 32'hFFFFFFF8,  "x12 (addi x12,x0,-8)");
        check(4,  dut.u_rf.regs[9],  32'd1,         "x9 (addi x9,x0,1)");
        check(5,  dut.u_rf.regs[30], 32'd2,         "x30 (addi x30,x0,2)");
 
        // --- R-type ALU ---
        check(6,  dut.u_rf.regs[3],  32'd22,        "x3 (add x3,x1,x2)");
        check(7,  dut.u_rf.regs[4],  32'd2,         "x4 (sub x4,x1,x2)");
        check(8,  dut.u_rf.regs[5],  32'd8,         "x5 (and x5,x1,x2)");
        check(9,  dut.u_rf.regs[6],  32'd14,        "x6 (or x6,x1,x2)");
        check(10, dut.u_rf.regs[7],  32'd6,         "x7 (xor x7,x1,x2)");
        check(11, dut.u_rf.regs[10], 32'd48,        "x10 (sll x10,x1,x30)");
        check(12, dut.u_rf.regs[11], 32'd3,         "x11 (srl x11,x1,x30)");
        check(13, dut.u_rf.regs[13], 32'h7FFFFFFC,  "x13 (srl x13,x12,x9 -- logical)");
        check(14, dut.u_rf.regs[14], 32'hFFFFFFFC,  "x14 (sra x14,x12,x9 -- arithmetic, -4)");
        check(15, dut.u_rf.regs[15], 32'd1,         "x15 (slt x15,x12,x9 -- signed)");
        check(16, dut.u_rf.regs[16], 32'd0,         "x16 (sltu x16,x12,x9 -- unsigned)");
 
        // --- I-type ALU ---
        check(17, dut.u_rf.regs[17], 32'd17,        "x17 (addi x17,x1,5)");
        check(18, dut.u_rf.regs[18], 32'd8,         "x18 (andi x18,x1,10)");
        check(19, dut.u_rf.regs[19], 32'd14,        "x19 (ori x19,x1,10)");
        check(20, dut.u_rf.regs[20], 32'd6,         "x20 (xori x20,x1,10)");
        check(21, dut.u_rf.regs[21], 32'd48,        "x21 (slli x21,x1,2)");
        check(22, dut.u_rf.regs[22], 32'h7FFFFFFC,  "x22 (srli x22,x12,1)");
        check(23, dut.u_rf.regs[23], 32'hFFFFFFFC,  "x23 (srai x23,x12,1 -- arithmetic, -4)");
        check(24, dut.u_rf.regs[24], 32'd1,         "x24 (slti x24,x12,1)");
        check(25, dut.u_rf.regs[25], 32'd0,         "x25 (sltiu x25,x12,1)");
 
        // --- lw/sw ---
        check(26, dut.u_dmem.mem[0], 32'd17,        "mem[0] (sw x17,0(x0))");
        check(27, dut.u_rf.regs[26], 32'd17,        "x26 (lw x26,0(x0))");
 
        // --- beq/bne integration ---
        check(28, dut.u_rf.regs[27], 32'd0,         "x27 (SQUASHED -- must never have executed)");
        check(29, dut.u_rf.regs[28], 32'd28,        "x28 (bne taken -> branch target)");
        check(30, dut.u_rf.regs[29], 32'd29,        "x29 (beq not taken -> normal fallthrough)");
 
        if (errors == 0)
            $display("\n*** ALL TESTS PASSED (Stage 6: comprehensive verification) ***\n");
        else
            $display("\n*** %0d TEST(S) FAILED ***\n", errors);
 
        $finish;
    end
 
    task check;
        input integer id;
        input [31:0] actual;
        input [31:0] expected;
        input [200*8-1:0] name;
        begin
            if (actual !== expected) begin
                $display("FAIL [%0d] %0s: expected %0d (0x%0h), got %0d (0x%0h)",
                          id, name, expected, expected, actual, actual);
                errors = errors + 1;
            end else begin
                $display("PASS [%0d] %0s = %0d", id, name, actual);
            end
        end
    endtask
 
endmodule