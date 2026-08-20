// IF/ID Pipeline Register — Stage 4 version
// Adds a `stall` input: when asserted, the register holds its current
// output instead of latching new fetch-stage values. This freezes the
// instruction currently in ID (and everything upstream, since PC is
// frozen too) for one cycle while a load-use hazard resolves.
module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,       // hold current output, don't latch
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
        end else if (stall) begin
            // hold — intentionally do nothing, outputs keep their value
        end else begin
            pc_out       <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            instr_out    <= instr_in;
        end
    end
 
endmodule