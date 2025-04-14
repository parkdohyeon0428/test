`timescale 1ns / 1ps

module ram (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    logic [31:0] mem[0:9];

    always_ff @(posedge clk) begin

        if (we) begin
            mem[addr[31:2]] <= wData;
            // case (addr)
            //     32'd4: mem[addr[31:2]] <= (wData & 32'h000000FF); // SB
            //     32'd8: mem[addr[31:2]] <= (wData & 32'h0000FFFF); // SH
            //     default: mem[addr[31:2]] <= wData;                // SW
            // endcase
        end
    end

    assign rData = mem[addr[31:2]];
endmodule