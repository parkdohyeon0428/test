`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // ov7670 signals  1
    output logic       ov7670_xclk1,
    output logic       ov7670_xclk2,
    input  logic       ov7670_pclk1,
    input  logic       ov7670_href1,
    input  logic       ov7670_v_sync1,
    input  logic [7:0] ov7670_data1,
    // ov7670 signals  2
    input  logic       ov7670_pclk2,
    input  logic       ov7670_href2,
    input  logic       ov7670_v_sync2,
    input  logic [7:0] ov7670_data2,
    // export signals
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic       sda1,
    output logic       scl1,
    output logic       sda2,
    output logic       scl2,

    output logic led
);
    logic we1, we2, oe;  //w_rclk, DE, rclk, 
    logic [16:0] wAddr1, rAddr, rAddr2;
    logic [3:0] r_harming;
    logic [15:0] wData1, rData1;
    logic [16:0] wAddr2;
    logic [15:0] wData2, rData2;
    logic [9:0] x_pixel, y_pixel;


    logic [43:0] census_left, census_right;
    logic [15:0] hamming;
    logic [15:0] rgb;
    logic [15:0] ww_rgb;

    logic [7:0] gray_rData1, gray_rData2;

    logic [7:0] gray_wData1, gray_wData2;





    assign {red_port, green_port, blue_port} = {
        rgb[15:12], rgb[10:7], rgb[4:1]
    };


    top_SCCB u_top_SCCB (
        .clk  (clk),
        .reset(reset),
        .sda  (sda1),
        .scl  (scl1)
    );

    top_SCCB2 u_top_SCCB2 (
        .clk  (clk),
        .reset(reset),
        .sda  (sda2),
        .scl  (scl2)
    );




    pixel_clk_gen u_OV7670_clk_Gena (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk1)
    );

    pixel_clk_gen u_OV7670_clk_Genb (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk2)
    );



    VGA_Controller u_VGA_Controller (
        .clk    (clk),
        .reset  (reset),
        .rclk   (rclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE),
        .pclk   (pclk)
    );

    QQVGA_memory_controller u_QQVGA_memory_controller (
        .clk    (clk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE),
        .rclk   (),
        .d_en   (oe),
        .rAddr  (rAddr),
        .rAddr2 (rAddr2)
    );

    logic [7:0] font_bits;
    logic [6:0] char_code;
    logic [2:0] font_y;

    QQVGA_display U_QQVGA_display (
        .clk(rclk),
        .reset(reset),
        .rdata1(rData1),
        .rdata2(rData2),
        .hamming(hamming),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .rgb(rgb),
        .led(led),
        .font_rom_out(font_bits),
        .char_code(char_code),
        .font_y(font_y)
    );

    rom_command U_rom(
        .char_code(char_code),
        .row(font_y),
        .font_bits(font_bits)
    );


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
        .wData(gray_wData1),
        // read side 
        .rclk (rclk),
        .oe(oe),
        .rAddr(rAddr2),
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
        .wData(gray_wData2),
        // read side 
        .rclk (rclk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData2)
    );




    census_matcher_top u_census_matcher_top_left (
        .clk   (pclk),
        .rst   (reset),
        .rgb   (rData2),
        .de    (oe),
        .x     ((x_pixel % 320)),
        .census(census_left)
    );

    census_matcher_top u_census_matcher_top_right (
        .clk   (pclk),
        .rst   (reset),
        .rgb   (rData1),
        .de    (oe),
        .x     ((x_pixel % 320)),
        .census(census_right)
    );

    grayscale_quantizer_10step U_binary_threshold_rgb565 (
        .rgb   (wData1),      // RGB565 입력
        .valid (oe),          // 유효 신호
        .q_gray(gray_wData1)  // 이진화된 출력 (0 또는 255)
    );

    grayscale_quantizer_10step U_binary_threshold_rgb5652 (
        .rgb   (wData2),      // RGB565 입력
        .valid (oe),          // 유효 신호
        .q_gray(gray_wData2)  // 이진화된 출력 (0 또는 255)
    );



    // hamming_distance u_hamming (
    //     .census_right(census_right),
    //     .census_left(census_left),
    //     .hamming(hamming)
    // );

    disparity_generator u_disparity_generator (
        .rclk       (rclk),
        .vga_clk    (pclk),
        .reset      (reset),
        .wData1     (census_left),
        .wData2     (census_right),
        .rAddr      (rAddr),
        .oe         (oe),
        .x_pixel    (x_pixel),
        .DisplayData(hamming)
    );

endmodule

module grayscale_quantizer_10step (
    input  logic [15:0] rgb,       // RGB565 입력
    input  logic        valid,     // 유효한 데이터
    output logic [7:0]  q_gray     // 계단화된 밝기 (0~255 중 10단계)
);

    // RGB565 분리
    logic [4:0] r_raw, b_raw;
    logic [5:0] g_raw;
    logic [16:0] luma;
    logic [7:0]  luma8;

    assign r_raw = rgb[15:11];
    assign g_raw = rgb[10:5];
    assign b_raw = rgb[4:0];

    // Grayscale 변환 (가중치: R*77 + G*150 + B*29) = 총합 256
    always_comb begin
        luma = r_raw * 8'd77 + g_raw * 8'd150 + b_raw * 8'd29;
        q_gray = luma[15:8];
    end

endmodule



module QQVGA_display (
    input logic clk,
    input logic reset,
    input logic [15:0] rdata1,
    input logic [15:0] rdata2,
    input logic [5:0] hamming,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    output logic [15:0] rgb,
    output logic led,
    input logic [7:0] font_rom_out,
    output logic [6:0] char_code,
    output logic [2:0] font_y
);




    logic display_en;
    logic [15:0] w_rgb;

    assign display_en = (x_pixel < 640 && y_pixel < 480);

    assign rgb = display_en ? w_rgb : 16'b0;

    logic [15:0] black_count;
    logic led_reg;
    logic [7:0] led_hold_counter;

    logic [7:0] detect_frame_counter;

    logic detected_this_frame;

    parameter base_x = 145;
    parameter base_y = 270;

    logic is_black = (w_rgb == 16'b0);

    logic [3:0] font_x;
    //logic [2:0] font_y;
    logic [7:0] font_row_data;
    //logic [7:0] char_code;
    logic close_enable;
    logic warning_enable;
    integer i, j;

    assign led = led_reg;
    assign warning_enable = led_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            black_count  <= 0;
            led_reg         <= 0;
            led_hold_counter <= 0;
            detect_frame_counter <= 0;
        end else begin
            if ((x_pixel > 110) && (x_pixel < 210) && (y_pixel >= 320 && y_pixel < 400) && is_black)
                black_count <= black_count + 1;

            // 프레임 마지막에서 LED 판정
            if (x_pixel == 639 && y_pixel == 479) begin
                if (black_count > 150) begin
                    led_reg <= 1;
                    led_hold_counter <= 120; // 60프레임 동안 유지
                end else if (led_hold_counter > 0) begin
                    led_hold_counter <= led_hold_counter - 1;
                    led_reg <= 1;
                end else begin
                    led_reg <= 0;
                end
                black_count <= 0;
            end
        end
    end


    logic [55:0] warning_text = {
        8'd87, // 'W'
        8'd65, // 'A'
        8'd82, // 'R'
        8'd78, // 'N'
        8'd73, // 'I'
        8'd78, // 'N'
        8'd71  // 'G'
    };

    always_comb begin
        w_rgb = 16'b0;
        char_code = 0;
        font_y = 0;
        if (x_pixel < 320 && y_pixel < 240) begin
            w_rgb = {rdata1[7:3], rdata1[7:2], rdata1[7:3]};
        end else if (x_pixel >= 320 && y_pixel < 240) begin
            w_rgb = {rdata2[7:3], rdata2[7:2], rdata2[7:3]};
        end else if (x_pixel < 320 && y_pixel >= 240 && y_pixel < 480) begin
            // 거리 시각화: Hamming → RGB 색상
            case (hamming)
                // 0~7: 고정 파랑
                6'd0  : w_rgb = 16'b00000_000000_11111; // 파랑
                6'd1  : w_rgb = 16'b00000_000000_11111;
                6'd2  : w_rgb = 16'b00000_000000_11111;
                6'd3  : w_rgb = 16'b00000_000000_11111;
                6'd4  : w_rgb = 16'b00000_000000_11111;
                6'd5  : w_rgb = 16'b00000_000000_11111;
                6'd6  : w_rgb = 16'b00000_000000_11111;
                6'd7  : w_rgb = 16'b00000_000000_11111;

                // 8~14: 청록 → 초록
                6'd8  : w_rgb = 16'b00000_111000_11111; // 청록
                6'd9  : w_rgb = 16'b00000_111111_11111;
                6'd10 : w_rgb = 16'b00100_111111_10000;
                6'd11 : w_rgb = 16'b01000_111111_00000;
                6'd12 : w_rgb = 16'b01100_111111_00000;
                6'd13 : w_rgb = 16'b10000_111111_00000;
                6'd14 : w_rgb = 16'b10100_111111_00000; // 초록

                // 15~21: 초록 → 노랑
                6'd15 : w_rgb = 16'b11000_111111_00000;
                6'd16 : w_rgb = 16'b11111_111111_00000;
                6'd17 : w_rgb = 16'b11111_101000_00000;
                6'd18 : w_rgb = 16'b11111_100000_00000;
                6'd19 : w_rgb = 16'b11111_011000_00000;
                6'd20 : w_rgb = 16'b11111_010000_00000;
                6'd21 : w_rgb = 16'b11111_001000_00000; // 노랑

                // 22~28: 노랑 → 주황
                6'd22 : w_rgb = 16'b11111_000100_00000;
                6'd23 : w_rgb = 16'b11111_000010_00000;
                6'd24 : w_rgb = 16'b11111_000001_00000;
                6'd25 : w_rgb = 16'b11110_000000_00000;
                6'd26 : w_rgb = 16'b11101_000000_00000;
                6'd27 : w_rgb = 16'b11100_000000_00000;
                6'd28 : w_rgb = 16'b11000_000000_00000; // 주황

                // 29~59: 점진적 빨강
                6'd29 : w_rgb = 16'b10100_000000_00000;
                6'd30 : w_rgb = 16'b10000_000000_00000;
                6'd31 : w_rgb = 16'b10011_000000_00000;
                6'd32 : w_rgb = 16'b10110_000000_00000;
                6'd33 : w_rgb = 16'b11001_000000_00000;
                6'd34 : w_rgb = 16'b11011_000000_00000;
                6'd35 : w_rgb = 16'b11100_000000_00000;
                6'd36 : w_rgb = 16'b11101_000000_00000;
                6'd37 : w_rgb = 16'b11110_000000_00000;
                6'd38 : w_rgb = 16'b11111_000000_00000;
                6'd39 : w_rgb = 16'b11111_000000_00000;
                6'd40 : w_rgb = 16'b11111_000000_00000;
                6'd41 : w_rgb = 16'b11111_000000_00000;
                6'd42 : w_rgb = 16'b11111_000000_00000;
                6'd43 : w_rgb = 16'b11111_000000_00000;
                6'd44 : w_rgb = 16'b00000_000000_00000;
                6'd45 : w_rgb = 16'b00000_000000_00000;
                6'd46 : w_rgb = 16'b00000_000000_00000;
                6'd47 : w_rgb = 16'b00000_000000_00000;
                6'd48 : w_rgb = 16'b00000_000000_00000;
                6'd49 : w_rgb = 16'b00000_000000_00000;
                6'd50 : w_rgb = 16'b00000_000000_00000;
                6'd51 : w_rgb = 16'b00000_000000_00000;
                6'd52 : w_rgb = 16'b00000_000000_00000;
                6'd53 : w_rgb = 16'b00000_000000_00000;
                6'd54 : w_rgb = 16'b00000_000000_00000;
                6'd55 : w_rgb = 16'b00000_000000_00000;
                6'd56 : w_rgb = 16'b00000_000000_00000;
                6'd57 : w_rgb = 16'b00000_000000_00000;
                6'd58 : w_rgb = 16'b00000_000000_00000;
                6'd59 : w_rgb = 16'b00000_000000_00000;

                default: w_rgb = 16'b00000_000000_11111;
            endcase
        end
        if (warning_enable) begin
            for (i = 0; i<7; i++) begin
                if (x_pixel >= base_x + i*8 && x_pixel < base_x + (i+1)*8 &&
                    y_pixel >= base_y && y_pixel < base_y + 8) begin
                    
                    font_x = x_pixel - (base_x + i*8);
                    font_y = y_pixel - base_y;
                    char_code = warning_text[8*(7-i)-1 -: 8];
                    //char_code = warning_text[8*(6-i)+:8];
                    font_row_data = font_rom_out;

                    if (font_row_data[7 - font_x]) begin
                        w_rgb = 16'hF800;  // 빨간색 글자
                    end
                end
            end
        end
    end

endmodule

module hamming_distance (
    input  logic [43:0] census_right,
    input  logic [43:0] census_left,
    output logic [5:0]  hamming  // 0~48 범위
);

    logic [43:0] diff;
    int count;

    always_comb begin
        diff = census_right ^ census_left;

        count = 0;
        count = count +
            diff[ 0] + diff[ 1] + diff[ 2] + diff[ 3] +
            diff[ 4] + diff[ 5] + diff[ 6] + diff[ 7] +
            diff[ 8] + diff[ 9] + diff[10] + diff[11] +
            diff[12] + diff[13] + diff[14] + diff[15] +
            diff[16] + diff[17] + diff[18] + diff[19] +
            diff[20] + diff[21] + diff[22] + diff[23] +
            diff[24] + diff[25] + diff[26] + diff[27] +
            diff[28] + diff[29] + diff[30] + diff[31] +
            diff[32] + diff[33] + diff[34] + diff[35] +
            diff[36] + diff[37] + diff[38] + diff[39] +
            diff[40] + diff[41] + diff[42] + diff[43];
            //diff[44] + diff[45] + diff[46] + diff[47];

        hamming = count[5:0];  // 6비트 범위 출력 (최대 48)
    end

endmodule



