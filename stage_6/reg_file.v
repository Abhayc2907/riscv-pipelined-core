// 32x32 Register File
// x0 always reads as zero and cannot be written.
// Two combinational read ports (rs1, rs2), one clocked write port (rd).
module reg_file (
    input  wire        clk,
    input  wire         we,        // write enable
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
 
    reg [31:0] regs [1:31];   // x1..x31 (x0 has no storage — hardwired)
 
    // Simulation-only initialization. Real silicon powers up with
    // undefined register contents — software is responsible for
    // initializing any register it depends on before reading it.
    // This exists purely so testbenches can see clean 0s for
    // registers a test program never touches, instead of X's.
    integer k;
    initial begin
        for (k = 1; k <= 31; k = k + 1)
            regs[k] = 32'b0;
    end
 
    // Read ports: x0 forced to 0. If a write is happening THIS cycle to
    // the same register being read, forward the incoming write data
    // directly ("write-first" behavior) instead of the stale stored
    // value — otherwise a producer and consumer exactly 3 instructions
    // apart would read one cycle too early, since by the time the
    // consumer reaches EX, the producer has already left the EX/MEM and
    // MEM/WB pipeline registers and can no longer be forwarded from there.
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 :
                       (we && rd_addr == rs1_addr) ? rd_data : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 :
                       (we && rd_addr == rs2_addr) ? rd_data : regs[rs2_addr];
 
    // Write port: writes to x0 are discarded.
    always @(posedge clk) begin
        if (we && rd_addr != 5'd0)
            regs[rd_addr] <= rd_data;
    end
 
endmodule