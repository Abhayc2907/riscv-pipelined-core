// Testbench for Stage 5 pipelined RV32I core: forwarding + load-use
// stalling + branch resolution/flushing.
//
//   00: addi x1, x0, 5      x1 = 5
//   04: addi x2, x0, 5      x2 = 5
//   08: beq  x1,x2,+12      TAKEN (5==5) -> jumps to 0x14
//   0C: addi x9, x0,111     SQUASHED -- must never execute (x9 stays 0)
//   10: addi x10,x0,222     SQUASHED -- must never execute (x10 stays 0)
//   14: addi x3, x0, 7      x3 = 7   (branch landed here correctly)
//   18: bne  x1,x2,+12      NOT taken (5==5, bne needs !=) -> falls through
//   1C: addi x4, x0, 44     x4 = 44  (executes normally, branch not taken)
//   20: addi x5, x0, 55     x5 = 55
//   24: bne  x4,x5,+12      TAKEN (44!=55) -> jumps to 0x30
//   28: addi x11,x0,333     SQUASHED -- must never execute (x11 stays 0)
//   2C: addi x12,x0,444     SQUASHED -- must never execute (x12 stays 0)
//   30: addi x6, x0, 99     x6 = 99  (branch landed here correctly)
//
// The squashed-register checks (x9,x10,x11,x12 == 0) are the real proof
// that flushing works -- if the flush logic were broken, these poison
// values (111,222,333,444) would incorrectly show up.
`timescale 1ns/1ps
 
module top_pipe_ctrl_tb;
 
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
 
        // Generous margin: 13 words in memory, 2 taken branches each
        // costing a 2-cycle flush penalty, plus normal pipeline latency.
        repeat (40) @(posedge clk);
 
        check(1,  dut.u_rf.regs[1],  32'd5,   "x1 (addi x1,x0,5)");
        check(2,  dut.u_rf.regs[2],  32'd5,   "x2 (addi x2,x0,5)");
        check(3,  dut.u_rf.regs[3],  32'd7,   "x3 (addi x3,x0,7 -- beq branch target)");
        check(4,  dut.u_rf.regs[4],  32'd44,  "x4 (addi x4,x0,44 -- bne not taken, normal fallthrough)");
        check(5,  dut.u_rf.regs[5],  32'd55,  "x5 (addi x5,x0,55)");
        check(6,  dut.u_rf.regs[6],  32'd99,  "x6 (addi x6,x0,99 -- bne branch target)");
        check(7,  dut.u_rf.regs[9],  32'd0,   "x9 (SQUASHED -- must never have executed)");
        check(8,  dut.u_rf.regs[10], 32'd0,   "x10 (SQUASHED -- must never have executed)");
        check(9,  dut.u_rf.regs[11], 32'd0,   "x11 (SQUASHED -- must never have executed)");
        check(10, dut.u_rf.regs[12], 32'd0,   "x12 (SQUASHED -- must never have executed)");
 
        if (errors == 0)
            $display("\n*** ALL TESTS PASSED (Stage 5: branch/control hazard handling) ***\n");
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
                $display("FAIL [%0d] %0s: expected %0d, got %0d",
                          id, name, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS [%0d] %0s = %0d", id, name, actual);
            end
        end
    endtask
 
endmodule