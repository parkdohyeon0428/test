`timescale 1ns / 1ps

module top_stopwatch(
    input clk,
    input reset,
    input btn_run,
    input btn_claer,
    output [3:0] fnd_comm,
    output [7:0] fnd_font
);
    wire w_run, w_clear;
    wire [6:0] msec, sec, min, hour;
    

    stopwatch_cu U_Stopwatch (
    .clk(clk),
    .reset(reset),
    .i_btn_run(btn_run),
    .i_btn_clear(btn_claer),
    .o_run(w_run),
    .o_clear(w_clear)
    );
    fnd_controller U_Fnd_Ctrl (
    .clk(clk),
    .reset(reset),
    .msec(msec),
    .sec(sec),
    .min(min),
    .hour(hour),
    .fnd_font(fnd_font),
    .fnd_comm(fnd_comm)
    );
    stopwatch_dp U_StopWatch_dp(
    .clk(clk),
    .reset(reset),
    .run(w_run),
    .clear(w_clear),
    .msec(msec),
    .sec(sec), //나머지 1비트는 그라운드드
    .min(min),
    .hour(hour)
);

endmodule
