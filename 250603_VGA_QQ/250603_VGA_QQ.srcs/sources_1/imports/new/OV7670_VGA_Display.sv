`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // ov7670 signals  1
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk1,
    input  logic       ov7670_href1,
    input  logic       ov7670_v_sync1,
    input  logic [7:0] ov7670_data1,
    // ov7670 signals  2
    input  logic       ov7670_pclk2,
    input  logic       ov7670_href2,
    input  logic       ov7670_v_sync2,
    input  logic [7:0] ov7670_data2
    // export signals
    // output logic       h_sync,
    // output logic       v_sync,
    // output logic [3:0] red_port,
    // output logic [3:0] green_port,
    // output logic [3:0] blue_port
);
    logic we1, we2 ,oe; //w_rclk, DE, rclk, 
    logic [16:0] wAddr1, rAddr1;
    logic [15:0] wData1, rData1;
    logic [16:0] wAddr2, rAddr2;
    logic [15:0] wData2, rData2;
    //logic [9:0] x_pixel, y_pixel;

    // Pixel_clk_Gen u_OV7670_clk_Gen (
    //     .clk  (clk),
    //     .reset(reset),
    //     .pclk (ov7670_xclk)
    // );
    // VGA_Controller U_VGAController (
    //     .clk    (clk),
    //     .reset  (reset),
    //     .rclk   (w_rclk),
    //     .h_sync (h_sync),
    //     .v_sync (v_sync),
    //     .DE     (DE),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel)
    // );
    OV7670_MemController U_OV7670_Memcotroller1 (
        .pclk       (ov7670_pclk1),
        .reset      (reset),
        .href       (ov7670_href1),
        .v_sync     (ov7670_v_sync1),
        .ov7670_data(ov7670_data1),
        .we         (we1),
        .wAddr      (wAddr1),
        .wData      (wData1)
    );
    frame_buffer U_Frame_buffer1 (
        // write side
        .wclk (ov7670_pclk1),
        .we   (we1),
        .wAddr(wAddr1),
        .wData(wData1),
        // read side 
        .rclk (),
        .oe(oe),
        .rAddr(rAddr1),
        .rData(rData1)
    );
        OV7670_MemController U_OV7670_Memcotroller2 (
        .pclk       (ov7670_pclk2),
        .reset      (reset),
        .href       (ov7670_href2),
        .v_sync     (ov7670_v_sync2),
        .ov7670_data(ov7670_data2),
        .we         (we2),
        .wAddr      (wAddr2),
        .wData      (wData2)
    );
    frame_buffer U_Frame_buffer2 (
        // write side
        .wclk (ov7670_pclk2),
        .we   (we2),
        .wAddr(wAddr2),
        .wData(wData2),
        // read side 
        .rclk (),
        .oe(oe),
        .rAddr(rAddr2),
        .rData(rDataw)
    );
    // QVGA_memory_control U_QVGA_MemController (
    //     // VGA Controller side
    //     .clk       (w_rclk),
    //     .x_pixel   (x_pixel),
    //     .y_pixel   (y_pixel),
    //     .DE        (DE),
    //     // frame buffer side
    //     .rclk      (rclk),
    //     .d_en      (oe),
    //     .rAddr     (rAddr),
    //     .rData     (rData),
    //     .red_port  (red_port),
    //     .green_port(green_port),
    //     .blue_port (blue_port)
    // );
endmodule
