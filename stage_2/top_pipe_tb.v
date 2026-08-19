// Testbench for Stage 2 pipelined RV32I core (no hazards, no forwarding)
//
// Test program (see program.hex) — every producer/consumer pair is
// separated by at least 3 independent filler instructions, since this
// naive pipeline has NO forwarding: a consumer's ID-stage register read
// must land strictly after the producer's WB-stage write, which needs
// a fetch-index gap of >= 4 (IF=N -> WB=N+4; ID=N+1 must exceed that).
//   00: addi x1,  x0, 5       x1 = 5
//   04: addi x2,  x0, 10      x2 = 10
//   08: addi x3,  x0, 15      x3 = 15
//   0C: addi x20, x0, 1       filler (creates the required gap)
//   10: sw   x1, 0(x0)        mem[0] = 5   (gap=4 from x1 -- safe)
//   14: addi x4,  x0, 20      x4 = 20
//   18: addi x21, x0, 2       filler
//   1C: addi x22, x0, 3       filler
//   20: addi x23, x0, 4       filler (creates the required gap)
//   24: lw   x5, 0(x0)        x5 = 5       (gap=4 from sw -- safe)
//   28: addi x6,  x0, 30      x6 = 30
//   2C: addi x7,  x0, 35      x7 = 35
//
// Pipeline latency: an instruction fetched at cycle N reaches WB at
// cycle N+4 (IF=N, ID=N+1, EX=N+2, MEM=N+3, WB=N+4). The last
// instruction here is fetched at cycle 11, so it writes back at cycle 15.
`timescale 1ns/1ps
 
module top_pipe_tb;
 
    reg clk;
    reg rst;
    integer errors;
 
    top_pipe dut (
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
 
        // Need enough cycles for the last instruction (fetched cycle 11)
        // to clear WB (cycle 15), plus margin.
        repeat (20) @(posedge clk);
 
        check(1, dut.u_rf.regs[1],  32'd5,  "x1 (addi x1,x0,5)");
        check(2, dut.u_rf.regs[2],  32'd10, "x2 (addi x2,x0,10)");
        check(3, dut.u_rf.regs[3],  32'd15, "x3 (addi x3,x0,15)");
        check(4, dut.u_rf.regs[4],  32'd20, "x4 (addi x4,x0,20)");
        check(5, dut.u_rf.regs[5],  32'd5,  "x5 (lw x5,0(x0) -- pipelined load)");
        check(6, dut.u_rf.regs[6],  32'd30, "x6 (addi x6,x0,30)");
        check(7, dut.u_rf.regs[7],  32'd35, "x7 (addi x7,x0,35)");
        check(8, dut.u_dmem.mem[0], 32'd5,  "mem[0] (sw x1,0(x0) -- pipelined store)");
 
        if (errors == 0)
            $display("\n*** ALL TESTS PASSED (Stage 2: naive pipeline) ***\n");
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