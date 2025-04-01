`timescale 1ns / 1ps

module MAIN_Top (
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
        .btn_run_hour(btn_run_hour),
        .btn_clear_start(btn_clear_start),
        .btn_sec(btn_sec),
        .btn_min(btn_min),
        .command(w_command),
        .data(w_data),
        .sw_mode(sw),
        .fnd_comm(fnd_comm),
        .fnd_font(fnd_font),
        .led(led)
    );
endmodule

