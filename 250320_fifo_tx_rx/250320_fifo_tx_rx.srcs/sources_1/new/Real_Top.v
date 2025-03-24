`timescale 1ns / 1ps

module Real_Top (
    input clk,
    input reset,
    input rx,
    input [1:0] sw,
    input btn_run_hour,
    input btn_clear_start,
    input btn_sec,
    input btn_min,
    output tx,
    output [3:0] fnd_comm,
    output [7:0] fnd_font,
    output [3:0] led
);
    wire [7:0] w_command;
    wire w_data;

    assign com_run_hour = btn_run_hour | w_com_run;
    assign com_clear_start = btn_clear_start | w_com_clear;
    assign com_sec = btn_sec | w_com_sec;
    assign com_min = btn_min | w_com_min;
    
    Top_module U_Top_Module(
        .clk(clk),
        .reset(reset),
        .command(w_command),
        .data(w_data),
        .rx(rx),
        .tx(tx)
    );
    top_stopwatch U_Top_StopWatch (
        .clk(clk),
        .reset(reset),
        .btn_run_hour(com_run_hour),
        .btn_clear_start(com_clear_start),
        .btn_sec(com_sec),
        .btn_min(com_min),
        .sw_mode(sw),
        .fnd_comm(fnd_comm),
        .fnd_font(fnd_font),
        .led(led)
    );
    uart_cu U_Uart_Cu(
        .clk(clk),
        .reset(reset),
        .data(w_data),
        .command(w_command),
        .com_run_hour(w_com_run),
        .com_clear_start(w_com_clear),
        .com_sec(w_com_sec),
        .com_min(w_com_min)
    );
endmodule
