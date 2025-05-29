`timescale 1ns / 1ps


module ImageVGA (
    input  logic       clk,
    input  logic       reset,
    input  logic       [3:0] sw,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    logic DE;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic [3:0] w_red, w_green, w_blue;
    logic [3:0] w_gred, w_ggreen, w_gblue;
    
    logic [11:0] w_rgb;

    VGA_Controller U_VGA_Ctrl (.*);
    ImageRom U_im(
        .sw(sw[2:0]),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .I_red_port(w_red),
        .I_green_port(w_green),
        .I_blue_port(w_blue)
    );
    grayscale U_gray(
        .red_port(w_red),
        .green_port(w_green),
        .blue_port(w_blue),
        .gray_red_port(w_gred), 
        .gray_green_port(w_ggreen),
        .gray_blue_port(w_gblue)
    );
    mux6X1 U_mux(
        .sel(sw[3]),
        .R_red_port(w_red), 
        .R_green_port(w_green),
        .R_blue_port(w_blue),
        .G_red_port(w_gred), 
        .G_green_port(w_ggreen),
        .G_blue_port(w_gblue),
        .y1(red_port),
        .y2(green_port),
        .y3(blue_port)
    );
endmodule
