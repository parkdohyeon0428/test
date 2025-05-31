`timescale 1ns / 1ps


module QVGA_memory_controller(
    // VGA Controller side
    input logic clk,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic DE,
    // frame buffer side
    output logic rclk,
    output logic d_en,
    output logic [16:0] rAddr,
    input logic [15:0] rData,
    // export side
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port

    );


    assign rAddr = (x_pixel < 320 && y_pixel < 240) ? ((y_pixel << 8) + (y_pixel << 6) + x_pixel) : 17'b0;

    logic display_en;
    assign d_en = display_en;
    assign rclk = clk;

    assign display_en = (x_pixel < 320 && y_pixel < 240);

    assign {red_port, green_port, blue_port} = display_en ? 
        {rData[15:12], rData[10:7], rData[4:1]} : 12'b0;




endmodule
