`timescale 1ns / 1ps

module VGA_RGB_Switch (
    // input  logic [3:0] sw_red,
    // input  logic [3:0] sw_green,
    // input  logic [3:0] sw_blue,
    input  logic       DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    // assign red_port = DE ? sw_red : 4'b0;
    // assign green_port = DE ? sw_green : 4'b0;
    // assign blue_port = DE ? sw_blue : 4'b0;

    always_comb begin
        if ((x_pixel < 92) && (y_pixel < 320)) begin
            red_port = 15;
            green_port = 15;
            blue_port = 15;
        end else if ((x_pixel > 91) && (x_pixel < 183) && (y_pixel < 320)) begin
            red_port = 15;
            green_port = 15;
            blue_port = 0;
        end else if ((x_pixel > 182) && (x_pixel < 274) && (y_pixel < 320)) begin
            red_port = 0;
            green_port = 15;
            blue_port = 15;
        end else if ((x_pixel > 273) && (x_pixel < 366) && (y_pixel < 320)) begin
            red_port = 0;
            green_port = 15;
            blue_port = 0;
        end else if ((x_pixel > 365) && (x_pixel < 457) && (y_pixel < 320)) begin
            red_port = 15;
            green_port = 0;
            blue_port = 15;
        end else if ((x_pixel > 456) && (x_pixel < 549) && (y_pixel < 320)) begin
            red_port = 15;
            green_port = 0;
            blue_port = 0;
        end else if ((x_pixel > 548) && (x_pixel < 640) && (y_pixel < 320)) begin
            red_port = 0;
            green_port = 0;
            blue_port = 15;
        end else if ((x_pixel < 91) && (y_pixel > 319) && (y_pixel <361)) begin
            red_port = 0;
            green_port = 0;
            blue_port = 15;
        end else if ((x_pixel > 91) && (x_pixel < 183) && (y_pixel > 319) && (y_pixel <361)) begin
            red_port = 0;
            green_port = 0;
            blue_port = 0;
        end else if ((x_pixel > 182) && (x_pixel < 274) && (y_pixel > 319) && (y_pixel <361)) begin
            red_port = 15;
            green_port = 0;
            blue_port = 15;
        end else if ((x_pixel > 273) && (x_pixel < 366) && (y_pixel > 319) && (y_pixel <361)) begin
            red_port = 0;
            green_port = 0;
            blue_port = 0;
        end else if ((x_pixel > 365) && (x_pixel < 457) && (y_pixel > 319) && (y_pixel <361)) begin
            red_port = 0;
            green_port = 15;
            blue_port = 15;
        end else if ((x_pixel > 456) && (x_pixel < 549) && (y_pixel > 319) && (y_pixel <361)) begin
            red_port = 0;
            green_port = 0;
            blue_port = 0;
        end else if ((x_pixel > 548) && (x_pixel < 640) && (y_pixel > 319) && (y_pixel <361)) begin
            red_port = 15;
            green_port = 15;
            blue_port = 15;
        end else if ((x_pixel < 106) && (y_pixel < 360) && (y_pixel < 480)) begin
            red_port = 0;
            green_port = 0;
            blue_port = 7;
        end else if ((x_pixel > 105) && (x_pixel < 213) && (y_pixel > 360) && (y_pixel < 480)) begin
            red_port = 15;
            green_port = 15;
            blue_port = 15;
        end else if ((x_pixel > 212) && (x_pixel < 319) && (y_pixel > 360) && (y_pixel < 480)) begin
            red_port = 8;
            green_port = 0;
            blue_port = 8;
        end else if ((x_pixel < 318) && (x_pixel < 640) && (y_pixel > 360) && (y_pixel < 480)) begin
            red_port = 0;
            green_port = 0;
            blue_port = 0;
        end 
    end

endmodule
