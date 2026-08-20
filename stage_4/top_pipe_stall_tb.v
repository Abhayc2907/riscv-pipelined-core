// Testbench for Stage 4 pipelined RV32I core WITH forwarding AND
// load-use hazard stalling.
//
// This test program deliberately places two loads with ZERO gap before
// a dependent instruction — exactly the case forwarding alone (Stage 3)
// cannot handle, and exactly the case Stage 3's test program had to
// avoid with filler instructions.
//
//   00: addi x2, x0, 7        x2 = 7
//   04: sw   x2, 0(x0)        mem[0] = 7
//   08: lw   x1, 0(x0)        x1 = 7
//   0C: add  x3, x1, x1       ZERO GAP load-use hazard (x1 as rs1+rs2)
//                              -> pipeline must stall 1 cycle here
//                              x3 = 14
//   10: addi x4, x0, 5        x4 = 5
//   14: add  x5, x3, x4       x5 = 19  (x3 forwarded normally, no stall
//                              needed here -- x3 wasn't from a load)
//   18: lw   x6, 0(x0)        x6 = 7
//   1C: add  x7, x4, x6       ZERO GAP load-use hazard (x6 as rs2)
//                              x7 = 12
`timescale 1ns/1ps
 
module top_pipe_stall_tb;
 
    reg clk;
    reg rst;
    integer errors;
 
    top_pipe_stall dut (
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
 
        // Extra margin beyond Stage 3's cycle count -- each of the two
        // load-use hazards costs 1 extra stall cycle.
        repeat (24) @(posedge clk);
 
        check(1, dut.u_rf.regs[1], 32'd7,  "x1 (lw x1,0(x0))");
        check(2, dut.u_rf.regs[2], 32'd7,  "x2 (addi x2,x0,7)");
        check(3, dut.u_rf.regs[3], 32'd14, "x3 (add x3,x1,x1 -- load-use hazard, stalled)");
        check(4, dut.u_rf.regs[4], 32'd5,  "x4 (addi x4,x0,5)");
        check(5, dut.u_rf.regs[5], 32'd19, "x5 (add x5,x3,x4)");
        check(6, dut.u_rf.regs[6], 32'd7,  "x6 (lw x6,0(x0))");
        check(7, dut.u_rf.regs[7], 32'd12, "x7 (add x7,x4,x6 -- load-use hazard, stalled)");
 
        if (errors == 0)
            $display("\n*** ALL TESTS PASSED (Stage 4: load-use hazard stalling) ***\n");
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