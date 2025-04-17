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
