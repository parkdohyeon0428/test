`timescale 1ns / 1ps

module top_stopwatch(
    input clk,
    input reset,
    input btn_run,
    input btn_clear,
    input sw_mode,
    output [3:0] fnd_comm,
    output [7:0] fnd_font
);
    wire w_run, w_clear, run, clear;
    wire [6:0] msec, sec, min, hour;
    // 1bit wire는 선언안해도 자동 1bit 로 연결됨
    
    btn_debounce U_Btn_Run_DB(
    .clk(clk),
    .reset(reset),
    .i_btn(btn_run),
    .o_btn(w_run)
    );
    btn_debounce U_Btn_Clear_DB(
    .clk(clk),
    .reset(reset),
    .i_btn(btn_clear),
    .o_btn(w_clear)
    );
    stopwatch_cu U_Stopwatch (
    .clk(clk),
    .reset(reset),
    .i_btn_run(w_run),
    .i_btn_clear(w_clear),
    .o_run(run),
    .o_clear(clear)
    );
    fnd_controller U_Fnd_Ctrl (
    .clk(clk),
    .reset(reset),
    .sw_mode(sw_mode),
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
    .run(run),
    .clear(clear),
    .msec(msec),
    .sec(sec), //나머지 1비트는 그라운드드
    .min(min),
    .hour(hour)
);

endmodule
