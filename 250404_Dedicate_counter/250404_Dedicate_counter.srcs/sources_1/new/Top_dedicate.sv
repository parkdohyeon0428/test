`timescale 1ns / 1ps

module Top_dedicate(
    input clk,
    input reset,
    output OutPort
);

    logic AsrcSel, en, alt10, outbuf;

    control_unit U_CU(
        .clk(clk),
        .reset(reset),
        .AsrcSel(AsrcSel),
        .en(en),
        .alt10(alt10),
        .outbuf(outbuf)
    );
    Data_path U_DP(
        .clk(clk),
        .reset(reset),
        .AsrcSel(AsrcSel),
        .en(en),
        .alt10(alt10),
        .outbuf(outbuf),
        .outPort(OutPort)
    );
endmodule
