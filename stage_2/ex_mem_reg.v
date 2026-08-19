// EX/MEM Pipeline Register
// Latches execute-stage outputs for the memory stage.
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,
 
    input  wire [31:0] alu_result_in,
    input  wire [31:0] write_data_in,   // rs2 value, for stores
    input  wire [4:0]  rd_addr_in,
 
    input  wire        reg_write_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
 
    output reg  [31:0] alu_result_out,
    output reg  [31:0] write_data_out,
    output reg  [4:0]  rd_addr_out,
 
    output reg          reg_write_out,
    output reg          mem_write_out,
    output reg          mem_to_reg_out
);
 
    always @(posedge clk) begin
        if (rst) begin
            alu_result_out <= 32'b0;
            write_data_out <= 32'b0;
            rd_addr_out    <= 5'b0;
            reg_write_out  <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end else begin
            alu_result_out <= alu_result_in;
            write_data_out <= write_data_in;
            rd_addr_out    <= rd_addr_in;
            reg_write_out  <= reg_write_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end
 
endmodule