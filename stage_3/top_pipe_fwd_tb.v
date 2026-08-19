// Testbench for Stage 3 pipelined RV32I core WITH forwarding.
//
// Unlike Stage 2, this test program deliberately places dependent
// instructions back-to-back — no filler spacing needed, because the
// forwarding unit resolves the RAW hazards directly.
//
//   00: addi x1, x0, 5        x1 = 5
//   04: add  x2, x1, x1       x2 = 10   <- EX/MEM forward (x1 produced
//                                          immediately prior)
//   08: add  x3, x1, x2       x3 = 15   <- x1: MEM/WB forward (2 back)
//                                          x2: EX/MEM forward (1 back)
//   0C: add  x4, x1, x3       x4 = 20   <- x3: EX/MEM forward
//                                          x1: now 3 back, plain reg read
//   10: sw   x4, 0(x0)        mem[0]=20 <- store value needs EX/MEM
//                                          forward too (x4 produced
//                                          immediately prior)
//   14: lw   x5, 0(x0)        x5 = 20
//   18: addi x6, x0, 1        filler (keeps distance from the lw above,
//                                     since load-use hazards are NOT
//                                     yet handled -- that's Stage 4)
//   1C: add  x7, x5, x6       x7 = 21
`timescale 1ns/1ps
 
module top_pipe_fwd_tb;
 
    reg clk;
    reg rst;
    integer errors;
 
    top_pipe_fwd dut (
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
 
        // Last instruction fetched at cycle 7, WB completes at cycle 11.
        // Generous margin included.
        repeat (16) @(posedge clk);
 
        check(1, dut.u_rf.regs[1], 32'd5,  "x1 (addi x1,x0,5)");
        check(2, dut.u_rf.regs[2], 32'd10, "x2 (add x2,x1,x1 -- EX/MEM forward)");
        check(3, dut.u_rf.regs[3], 32'd15, "x3 (add x3,x1,x2 -- MEM/WB + EX/MEM forward)");
        check(4, dut.u_rf.regs[4], 32'd20, "x4 (add x4,x1,x3 -- EX/MEM forward)");
        check(5, dut.u_rf.regs[5], 32'd20, "x5 (lw x5,0(x0))");
        check(6, dut.u_rf.regs[6], 32'd1,  "x6 (addi x6,x0,1)");
        check(7, dut.u_rf.regs[7], 32'd21, "x7 (add x7,x5,x6)");
        check(8, dut.u_dmem.mem[0], 32'd20, "mem[0] (sw x4,0(x0) -- forwarded store value)");
 
        if (errors == 0)
            $display("\n*** ALL TESTS PASSED (Stage 3: forwarding) ***\n");
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