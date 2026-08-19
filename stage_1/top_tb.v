// Testbench for Stage 1 single-cycle RV32I core
//
// Test program (see program.hex):
//   00: addi x1, x0, 5        x1 = 5
//   04: addi x2, x0, 10       x2 = 10
//   08: add  x3, x1, x2       x3 = 15
//   0C: sub  x4, x2, x1       x4 = 5
//   10: sw   x3, 0(x0)        mem[0] = 15
//   14: lw   x5, 0(x0)        x5 = 15
//   18: beq  x4, x1, +8       taken (5==5), skips next instruction
//   1C: addi x6, x0, 99       SKIPPED — x6 should stay 0
//   20: addi x7, x0, 42       x7 = 42
//   24: beq  x0, x0, 0        infinite self-loop (halts progress)
`timescale 1ns/1ps

module top_tb;

    reg clk;
    reg rst;
    integer errors;

    top dut (
        .clk(clk),
        .rst(rst)
    );

    // 10ns clock period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        errors = 0;
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Run long enough for all 9 real instructions to execute
        // (single-cycle core: 1 instruction per clock)
        repeat (12) @(posedge clk);

        // Check results via hierarchical reference into the register file
        check(1,  dut.u_rf.regs[1],  32'd5,  "x1 (addi x1,x0,5)");
        check(2,  dut.u_rf.regs[2],  32'd10, "x2 (addi x2,x0,10)");
        check(3,  dut.u_rf.regs[3],  32'd15, "x3 (add x3,x1,x2)");
        check(4,  dut.u_rf.regs[4],  32'd5,  "x4 (sub x4,x2,x1)");
        check(5,  dut.u_rf.regs[5],  32'd15, "x5 (lw x5,0(x0))");
        check(6,  dut.u_rf.regs[6],  32'd0,  "x6 (should be skipped by beq)");
        check(7,  dut.u_rf.regs[7],  32'd42, "x7 (addi x7,x0,42 -- branch target)");
        check(8,  dut.u_dmem.mem[0], 32'd15, "mem[0] (sw x3,0(x0))");

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***\n");
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
