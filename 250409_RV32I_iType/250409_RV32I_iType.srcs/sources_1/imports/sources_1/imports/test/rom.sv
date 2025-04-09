`timescale 1ns / 1ps

module rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom[0:15];

    initial begin
        //rom[x]=32'b   imm12      _rs1  _f3 _ rd  _opcode  // i-Type
        rom[0] = 32'b000000001000_00010_000_00011_0010011; // imm[x1] rs1[x2] rd [x3]
        rom[1] = 32'b000000001000_00010_010_00011_0010011; // imm[x1] rs1[x2] rd [x3]
        rom[2] = 32'b000000001000_00010_011_00011_0010011; // imm[x1] rs1[x2] rd [x3]
        rom[3] = 32'b000000001000_00010_100_00011_0010011; // imm[x1] rs1[x2] rd [x3]
        rom[4] = 32'b000000001000_00010_110_00011_0010011; // imm[x1] rs1[x2] rd [x3]
        rom[5] = 32'b000000001000_00010_111_00011_0010011; // imm[x1] rs1[x2] rd [x3]
        rom[6] = 32'b0000000_01000_00010_001_00011_0010011; // imm[x1] rs1[x2] rd [x3]
        rom[7] = 32'b0000000_01000_00010_101_00011_0010011; // imm[x1] rs1[x2] rd [x3]
        rom[8] = 32'b0100000_01000_00010_101_00011_0010011; // imm[x1] rs1[x2] rd [x3]
    end
    assign data = rom[addr[31:2]];
endmodule
