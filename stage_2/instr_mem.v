module instr_mem #(
    parameter MEM_WORDS = 256
) (
    input  wire [31:0] addr,      // byte address, must be 4-byte aligned
    output wire [31:0] instr
);
 
    reg [31:0] mem [0:MEM_WORDS-1];
 
    // Load program at simulation start. Replace "program.hex" with your
    // assembled test program (one 32-bit hex word per line).
    initial begin
        $readmemh("program.hex", mem);
    end
 
    // Byte address -> word index. addr[31:2] selects the word.
    assign instr = mem[addr[31:2]];
 
endmodule