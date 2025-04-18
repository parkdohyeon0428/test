`timescale 1ns / 1ps

module peripheral (
    input  logic clk,
    input  logic reset,
    input  logic we,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic start,
    output logic ready
);
    
endmodule

module Master (
    //신호
    input  logic clk,
    input  logic reset,
    input  logic we,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic start,
    output logic ready,
    //master - slave
    output logic [31:0] PAddr,
    output logic PWrite,
    output logic PSel,
    output logic Penable,
    output logic [31:0] PWData,
    input logic [31:0] PRData,
    input logic PReady
);
    
endmodule

module slave (
    input logic [31:0] PAddr,
    input logic PWrite,
    input logic PSel,
    input logic Penable,
    input logic [31:0] PWData,
    output logic [31:0] PRData,
    output logic PReady
);
    
endmodule