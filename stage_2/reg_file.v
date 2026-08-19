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
 
    // Read ports: x0 forced to 0, everything else reads storage.
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];
 
    // Write port: writes to x0 are discarded.
    always @(posedge clk) begin
        if (we && rd_addr != 5'd0)
            regs[rd_addr] <= rd_data;
    end
 
endmodule