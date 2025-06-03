// `timescale 1ns / 1ps

// module ImageRom (
//     input  logic [2:0] sw,
//     input  logic [9:0] x_pixel,
//     input  logic [9:0] y_pixel,
//     input  logic       DE,
//     output logic [3:0] I_red_port,
//     output logic [3:0] I_green_port,
//     output logic [3:0] I_blue_port
// );

//     logic [16:0] image_addr;
//     logic [15:0] image_data;    //RGB => 16'b rrrrr_gggggg_bbbbb red = 5bit, green = 6bit, blue = 5bit

//     assign image_addr = 320 * y_pixel + x_pixel;
//     // assign {I_red_port, green_port, blue_port} = 
//     // DE ? {image_data[15:12], image_data[10:7], image_data[4:1]} : 12'b0;

//     always_comb begin
//         {I_red_port, I_green_port, I_blue_port} = 12'b0;
//         if ((x_pixel < 320) && (y_pixel < 240)) begin
//             if (sw[2:0] == 3'b111) begin
//                 {I_red_port, I_green_port, I_blue_port} = {
//                     image_data[15:12], image_data[10:7], image_data[4:1]
//                 };
//             end else if (sw[2:0] == 3'b100) begin
//                 {I_red_port, I_green_port, I_blue_port} = {
//                     image_data[15:12], 4'b0, 4'b0
//                 };
//             end else if (sw[2:0] == 3'b010) begin
//                 {I_red_port, I_green_port, I_blue_port} = {
//                     4'b0, image_data[10:7], 4'b0
//                 };
//             end else if (sw[2:0] == 3'b001) begin
//                 {I_red_port, I_green_port, I_blue_port} = {
//                     4'b0, 4'b0, image_data[4:1]
//                 };
//             end else if (sw[2:0] == 3'b000) begin
//                 {I_red_port, I_green_port, I_blue_port} = {4'b0, 4'b0, 4'b0};
//             end
//         end
//     end


//     image_rom1 U_ROM (
//         .addr(image_addr),
//         .data(image_data)
//     );

// endmodule

// module image_rom1 (
//     //640x480의 Data
//     input  logic [16:0] addr,
//     output logic [15:0] data
// );
//     localparam SCALE = 320 * 240;
//     logic [15:0] rom[0:SCALE - 1];

//     initial begin
//         $readmemh("lenna.mem", rom);
//     end

//     assign data = rom[addr];
// endmodule

// module grayscale (
//     input  logic [3:0] red_port,
//     input  logic [3:0] green_port,
//     input  logic [3:0] blue_port,
//     output logic [3:0] gray_red_port, 
//     output logic [3:0] gray_green_port,
//     output logic [3:0] gray_blue_port
// );
    
//     logic [11:0] weighted_sum;

//     assign weighted_sum = (red_port   * 8'd77)  // 0.299 * 256 = 77
//                        + (green_port * 8'd150) //  0.587 * 256 = 150
//                        + (blue_port  * 8'd29); //  0.114 * 256 = 29

//     assign gray_red_port   = weighted_sum[11:8];
//     assign gray_green_port = weighted_sum[11:8];
//     assign gray_blue_port  = weighted_sum[11:8];

// endmodule

// module mux6X1 (
//     input  logic       sel,
//     input  logic [3:0] R_red_port, 
//     input  logic [3:0] R_green_port,
//     input  logic [3:0] R_blue_port,
//     input  logic [3:0] G_red_port, 
//     input  logic [3:0] G_green_port,
//     input  logic [3:0] G_blue_port,
//     output logic [3:0] y1,
//     output logic [3:0] y2,
//     output logic [3:0] y3
// );

//     assign y1 = (sel == 1'b0) ? R_red_port   : G_red_port;
//     assign y2 = (sel == 1'b0) ? R_green_port : G_green_port;
//     assign y3 = (sel == 1'b0) ? R_blue_port  : G_blue_port;

// endmodule

`timescale 1ns / 1ps

module ImageRom (
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       DE,
    input  logic [2:0] sw,
    output logic [11:0] RGB_port
    // output logic [3:0] green_port,
    // output logic [3:0] blue_port
);
    logic [16:0] image_addr;
    logic [15:0] image_data;  // RGB565 => 16'brrrrr_gggggg_bbbbb
    logic [3:0] red_port, green_port, blue_port;
    assign RGB_port = {red_port, green_port, blue_port};
    assign image_addr = 320 * y_pixel + x_pixel;
    // assign {red_port, green_port, blue_port} = 
    // DE ? {image_data[15:12], image_data[10:7], image_data[4:1]} : 12'b0;

    always_comb begin
        red_port   = 4'b0;
        green_port = 4'b0;
        blue_port  = 4'b0;
        case (sw)
            3'b000: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = image_data[15:12];
                    green_port = image_data[10:7];
                    blue_port  = image_data[4:1];
                end
            end
            3'b001: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = image_data[15:12];
                    green_port = 4'b0;
                    blue_port  = 4'b0;
                end
            end
            3'b010: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = 4'b0;
                    green_port = image_data[10:7];
                    blue_port  = 4'b0;
                end
            end
            3'b100: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = 4'b0;
                    green_port = 4'b0;
                    blue_port  = image_data[4:1];
                end
            end
            3'b100: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = 4'b0;
                    green_port = 4'b0;
                    blue_port  = image_data[4:1];
                end
            end
            3'b011: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = image_data[15:12];
                    green_port = image_data[10:7];
                    blue_port  = 4'b0;
                end
            end
            3'b101: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = image_data[15:12];
                    green_port = 4'b0;
                    blue_port  = image_data[4:1];
                end
            end
            3'b110: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = 4'b0;
                    green_port = image_data[10:7];
                    blue_port  = image_data[4:1];
                end
            end
            3'b111: begin
                if (DE && x_pixel < 321 && y_pixel < 241) begin
                    red_port   = 4'b0;
                    green_port = 4'b0;
                    blue_port  = 4'b0;
                end
            end
        endcase
    end


    image_rom U_ROM (
        .addr(image_addr),
        .data(image_data)
    );

endmodule

module image_rom (
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] rom[0:320*240-1];

    initial begin
        $readmemh("loopy.mem", rom);
    end

    assign data = rom[addr];
endmodule

module GrayScale (
    input logic [11:0] RGB_port,
    output logic [3:0] G_port
);
    logic [15:0] GG_port; //오버플로우 생길수 있기에 비트 늘림 

    assign GG_port = {RGB_port[11:8] * 77 + RGB_port[7:4] * 150 + RGB_port[3:0] * 29};
    assign G_port = GG_port[11:8];
endmodule

module MUX (
    input logic sw,
    input logic [11:0] RGB_port,
    input logic [3:0] G_port,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port 
);
    always_comb begin
        red_port = RGB_port[11:8];
        green_port = RGB_port[7:4];
        blue_port = RGB_port[3:0];
        case (sw)
            1'b0: begin
                red_port = RGB_port[11:8];
                green_port = RGB_port[7:4];
                blue_port = RGB_port[3:0];
            end
            1'b1: begin
                red_port = G_port;
                green_port = G_port;
                blue_port = G_port;
            end
        endcase
    end
endmodule

