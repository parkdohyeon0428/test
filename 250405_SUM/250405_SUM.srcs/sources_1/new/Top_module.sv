`timescale 1ns / 1ps

module Top_SUM(
    input logic clk,
    input logic reset,
    output logic [7:0] OutPort
);

    logic AsrcSel, en, alt11, outbuf;

    control_unit U_CU(
        .clk(clk),
        .reset(reset),
        .AsrcSel(AsrcSel),
        .en(en),
        .alt11(alt11),
        .outbuf(outbuf)
    );
    Data_path U_DP(
        .clk(clk),
        .reset(reset),
        .AsrcSel(AsrcSel),
        .AEn(en),
        .Alt11(alt11),
        .outBuf(outbuf),
        .OutPort(OutPort)
    );
endmodule
