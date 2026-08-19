// Program Counter register
// Holds the address of the current instruction. Updated every clock edge.
module pc_reg (
    input  wire clk,
    input  wire rst,       // synchronous reset -> PC = 0
    input  wire [31:0] pc_next,
    output reg  [31:0] pc
);
 
    always @(posedge clk) begin
        if (rst)
            pc <= 32'h00000000;
        else
            pc <= pc_next;
    end
 
endmodule
 