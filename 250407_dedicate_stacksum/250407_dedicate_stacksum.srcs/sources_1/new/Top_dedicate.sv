`timescale 1ns / 1ps

module Top_dedicate (
    input  logic       clk,
    input  logic       reset,
    output logic [7:0] outPort
);
    logic       SumSrcMuxSel;
    logic       iSelMuxSel;
    logic       SumEn;
    logic       iEn;
    logic       adderSrcMuxSel;
    logic       outBuf;
    logic       iLe10;

    Data_Path U_DataPath(
    .*);

    Control_Unit U_Control_Unit(
    .*);
endmodule
