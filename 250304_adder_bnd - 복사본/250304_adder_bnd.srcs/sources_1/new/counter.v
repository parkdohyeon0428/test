`timescale 1ns / 1ps

module counter(
    input clk,
    input reset,
    output count
    );


    
    fnd_controller U_fnd_controller(
        .clk(clk),
        .reset(reset),
        .bcd({w_c, w_s}),      // 9bit
        .seg(seg),
        .seg_comm(seg_comm)
    );


endmodule
