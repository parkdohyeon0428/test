`timescale 1ns / 1ps


module QQVGA_memory_controller (
    // VGA Controller side
    input logic clk,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic DE,
    // frame buffer side
    output logic rclk,
    output logic d_en,
    output logic [16:0] rAddr,
    output logic [16:0] rAddr2,
    input [3:0] hamming
);



    logic [9:0] x_mod = ((x_pixel % 320));
    logic [9:0] y_mod = ((y_pixel % 240));

    assign rAddr = y_mod * 320 + x_mod;
    assign rAddr2 = (239 - y_mod) * 320 + x_mod;

    assign d_en = (x_pixel < 640 && y_pixel < 480) ?  1'b1 : 1'b0;


    assign rclk = clk;




endmodule


