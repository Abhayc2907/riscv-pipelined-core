// Data memory
// Word-addressed for Stage 1 (only lw/sw). Byte/halfword access (lb/lh/etc.)
// can be added later by muxing on funct3.
module data_mem #(
    parameter MEM_WORDS = 256
) (
    input  wire        clk,
    input  wire         we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
 
    reg [31:0] mem [0:MEM_WORDS-1];
 
    integer i;
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'b0;
    end
 
    assign rdata = mem[addr[31:2]];
 
    always @(posedge clk) begin
        if (we)
            mem[addr[31:2]] <= wdata;
    end
 
endmodule