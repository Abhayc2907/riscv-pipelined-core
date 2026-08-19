// IF/ID Pipeline Register
// Latches fetch-stage outputs so decode stage reads a stable, one-cycle-old
// instruction while fetch moves on to the next PC.
module if_id_reg (
    input  wire        clk,
    input  wire        rst,
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
        end else begin
            pc_out       <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            instr_out    <= instr_in;
        end
    end

endmodule
