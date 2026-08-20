// IF/ID Pipeline Register — Stage 5 version
// Adds `flush` on top of Stage 4's `stall`. They serve different
// purposes: `stall` HOLDS the current output (freeze in place, for a
// load-use hazard). `flush` SQUASHES the output to a NOP (zero
// instruction) — used when a branch resolves as taken and the
// instruction currently in IF/ID was speculatively fetched down the
// wrong path, so it must never be allowed to execute.
// Priority: rst > flush > stall > normal latch.
module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,       // hold current output, don't latch
    input  wire        flush,       // squash output to NOP
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] instr_in,
 
    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] instr_out
);
 
    always @(posedge clk) begin
        if (rst) begin
            pc_out       <= 32'b0;
            pc_plus4_out <= 32'b0;
            instr_out    <= 32'b0;
        end else if (flush) begin
            pc_out       <= 32'b0;
            pc_plus4_out <= 32'b0;
            instr_out    <= 32'b0;   // NOP — decodes to all-default control signals
        end else if (stall) begin
            // hold — intentionally do nothing, outputs keep their value
        end else begin
            pc_out       <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            instr_out    <= instr_in;
        end
    end
 
endmodule