`timescale 1ns / 1ps

module top_stopwatch (
    input clk,
    input reset,
    input btn_run_hour,
    input btn_clear_start,
    input btn_sec,
    input btn_min,
    input [7:0] command,
    input data,
    input [1:0] sw_mode,
    output [3:0] fnd_comm,
    output [7:0] fnd_font,
    output [3:0] led
);
    wire w_run, w_clear, w_hour, w_min, w_sec, w_start, run, clear;
    wire w_com_run, w_com_clear, w_com_hour, w_com_min, w_com_sec, W_com_start;
    wire [6:0] msec, sec, min, hour;
    wire [6:0] w_watch_msec, w_stop_msec;
    wire [5:0] w_watch_sec, w_stop_sec;
    wire [5:0] w_watch_min, w_stop_min;
    wire [4:0] w_watch_hour, w_stop_hour;


    // 1bit wire는 선언안해도 자동 1bit 로 연결됨

    btn_debounce U_Btn_Run_DB (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_run_hour & sw_mode[1] == 0),
        .o_btn(w_run)
    );
    btn_debounce U_Btn_Clear_DB (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_clear_start & sw_mode[1] == 0),
        .o_btn(w_clear)
    );
    btn_debounce U_Btn_Hour_DB (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_run_hour & sw_mode[1] == 1),
        .o_btn(w_hour)
    );
    btn_debounce U_Btn_Start_DB (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_clear_start & sw_mode[1] == 1),
        .o_btn(w_start)
    );
    btn_debounce U_Btn_Min_DB (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_min),
        .o_btn(w_min)
    );
    btn_debounce U_Btn_Sec_DB (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_sec),
        .o_btn(w_sec)
    );
    uart_cu U_Uart_Cu(
        .clk(clk),
        .reset(reset),
        .data(data),
        .command(command),
        .com_run(w_com_run),
        .com_clear(w_com_clear),
        .com_sec(w_com_sec),
        .com_min(w_com_min),
        .com_hour(w_com_hour),
        .com_start(W_com_start)
    );
    stopwatch_cu U_Stopwatch (
        .clk(clk),
        .reset(reset),
        .i_btn_run(w_run | w_com_run),
        .i_btn_clear(w_clear | w_com_clear),
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
    stopwatch_dp U_StopWatch_dp (
        .clk  (clk),
        .reset(reset),
        .run  (run),
        .clear(clear),
        .msec (w_stop_msec),
        .sec  (w_stop_sec),
        .min  (w_stop_min),
        .hour (w_stop_hour)
    );
    clock_dp U_clock_dp (
        .clk(clk),
        .reset(reset),
        .i_btn_sec(w_sec | w_com_sec),
        .i_btn_min(w_min | w_com_min),
        .i_btn_hour(w_hour | w_com_hour),
        .i_start(w_start | W_com_start),
        .sw(sw_mode),
        .msec(w_watch_msec),
        .sec(w_watch_sec),
        .min(w_watch_min),
        .hour(w_watch_hour)
    );
    top_stopwatch_encoder U_Stopwatch_encoder (
        .clk(clk),
        .reset(reset),
        .watch_msec(w_watch_msec),
        .stopwatch_msec(w_stop_msec),
        .watch_sec(w_watch_sec),
        .stopwatch_sec(w_stop_sec),
        .watch_min(w_watch_min),
        .stopwatch_min(w_stop_min),
        .watch_hour(w_watch_hour),
        .stopwatch_hour(w_stop_hour),
        .sw_mode(sw_mode),
        .o_watch_msec(msec),
        .o_watch_sec(sec),
        .o_watch_min(min),
        .o_watch_hour(hour)
    );
    stopwatch_led U_led (
        .sw_mode(sw_mode),
        .led(led)
    );

endmodule

module stopwatch_led (
    input [1:0] sw_mode,
    output reg [3:0] led
);
    always @(sw_mode) begin
        case (sw_mode)
            2'b00:   led = 4'b0001;
            2'b01:   led = 4'b0010;
            2'b10:   led = 4'b0100;
            2'b11:   led = 4'b1000;
            default: led = 4'b0001;
        endcase
    end
endmodule

module top_stopwatch_encoder (
    input clk,
    reset,
    input [6:0] watch_msec,
    stopwatch_msec,
    input [5:0] watch_sec,
    stopwatch_sec,
    input [5:0] watch_min,
    stopwatch_min,
    input [4:0] watch_hour,
    stopwatch_hour,
    input [1:0] sw_mode,
    output reg [6:0] o_watch_msec,
    output reg [5:0] o_watch_sec,
    output reg [5:0] o_watch_min,
    output reg [4:0] o_watch_hour
);
    always @(*) begin
        if (sw_mode[1] == 1'b1) begin
            o_watch_msec = watch_msec;
            o_watch_sec  = watch_sec;
            o_watch_min  = watch_min;
            o_watch_hour = watch_hour;
        end else begin
            o_watch_msec = stopwatch_msec;
            o_watch_sec  = stopwatch_sec;
            o_watch_min  = stopwatch_min;
            o_watch_hour = stopwatch_hour;
        end
    end

endmodule



