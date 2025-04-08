`timescale 1ns / 1ps

module RV32I_core(
    input logic clk,
    input logic reset,
    input logic [31:0] instrCode,
    output logic [31:0] instrMemAddr
);

    logic       regFilewe;
    logic [3:0] aluControl;

    ControlUnit U_control(
        .instrCode(instrCode),
        .regFileWe(regFilewe),
        .aluControl(aluControl)
    );

    DataPath U_dp(
        .clk(clk),
        .reset(reset),
        .instrCode(instrCode),
        .instrMemAddr(instrMemAddr),
        .regFileWe(regFilewe),
        .aluControl(aluControl)
    );

endmodule

