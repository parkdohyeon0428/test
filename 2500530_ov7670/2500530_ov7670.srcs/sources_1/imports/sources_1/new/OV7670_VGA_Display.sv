`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // ov7670 signals
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    // export signals
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    // 내부 신호
    logic        we;
    logic [16:0] wAddr;
    logic [15:0] wData;

    logic [16:0] rAddr;
    logic [15:0] rData;

    logic        DE;
    logic [9:0]  x_pixel;
    logic [9:0]  y_pixel;

    logic w_rclk,rclk;
    logic oe;

    // --------------------------
    // Clock Generator for Camera
    // --------------------------
    pixel_clk_gen u_OV7670_clk_gen(
        .clk(clk),
        .reset(reset),
        .pclk(ov7670_xclk)
    );

    // --------------------------
    // VGA Signal Generator
    // --------------------------
    VGA_Controller u_VGA_Controller(
        .clk(clk),
        .reset(reset),
        .rclk(w_rclk),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    // --------------------------
    // Camera Memory Write Logic
    // --------------------------
    OV7670_memory_controller u_OV7670_memory_controller (
        .pclk(ov7670_pclk),
        .reset(reset),
        .href(ov7670_href),
        .v_sync(ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    // --------------------------
    // Frame Buffer
    // --------------------------
    Frame_Buffer u_Frame_Buffer (
        .wclk(ov7670_pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(rclk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    // --------------------------
    // Memory Read + RGB Split
    // --------------------------
    QVGA_memory_controller u_QVGA_memory_controller (
        .clk(w_rclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .rclk(rclk),
        .d_en(oe),
        .rAddr(rAddr),
        .rData(rData),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
    );

endmodule
