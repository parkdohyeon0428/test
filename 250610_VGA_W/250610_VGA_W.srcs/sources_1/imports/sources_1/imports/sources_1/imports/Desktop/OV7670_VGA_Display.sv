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
    input  logic       btn_u,
    input  logic       btn_d,
    input  logic       btn_r,
    input  logic       btn_l,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic       sda1,
    output logic       scl1,
    output logic       sda2,
    output logic       scl2,
    output logic     buzz_clk,

    output logic [1:0] led,
    output logic [3:0] fnd_comm,
    output logic [7:0] fnd_font
);
    logic we1, we2, oe;  //w_rclk, DE, rclk, 
    logic [16:0] wAddr1, rAddr, rAddr2;
    logic [3:0] r_harming;
    logic [15:0] wData1, rData1;
    logic [16:0] wAddr2;
    logic [15:0] wData2, rData2;
    logic [9:0] x_pixel, y_pixel;
    logic [7:0] fnd;
    logic de_btn_u, de_btn_d, de_btn_r, de_btn_l;
    logic [43:0] census_left, census_right;
    logic [15:0] hamming;
    logic [15:0] rgb;
    logic [15:0] ww_rgb;

    logic [7:0] gray_rData1, gray_rData2;

    logic [7:0] gray_wData1, gray_wData2;

    logic [4:0] sad_disp;



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

    logic [15:0] font_bits;
    logic [6:0] char_code;
    logic [3:0] font_y;
    logic [1:0] buzz_state;

    QQVGA_display U_QQVGA_display (
        .clk(pclk),
        .reset(reset),
        .rdata1(rData2),
        .rdata2(rData1),
        .hamming(hamming),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .rgb(rgb),
        .led(led),
        .font_rom_out(font_bits),
        .char_code(char_code),
        .font_y(font_y),
        .fnd(fnd),
        .buzz_state(buzz_state),
        .sad_disp(sad_disp)
    );

    rom_command U_rom (
        .char_code(char_code),
        .row(font_y),
        .font_bits(font_bits)
    );

    fnd_controlloer U_fnd (  //control anod segments
        .clk(clk),
        .reset(reset),
        .count(fnd),
        .seg_out(fnd_font),
        .seg_comm(fnd_comm)
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

    
buzzer U_buzzer (
    .rclk(rclk),
    .reset(reset),
    .state(buzz_state),
    .buzz_clk(buzz_clk)
);




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


    btn_debounce u_Btn_Debounce_U (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_u),
        .o_btn(de_btn_u)
    );

    btn_debounce u_Btn_Debounce_D (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(de_btn_d)
    );

    btn_debounce u_Btn_Debounce_L (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(de_btn_l)
    );

    btn_debounce u_Btn_Debounce_R (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(de_btn_r)
    );


    sad_matcher_top u_sad_matcher_top (
        .clk(clk),
        .pclk(pclk),
        .rst(reset),
        .left_rgb(rData2),
        .right_rgb(rData1),
        .de(oe),
        .x(x_pixel % 320),
        .y(y_pixel % 320),
        .btn_p1_up(de_btn_u),
        .btn_p1_down(de_btn_d),
        .btn_p2_up(de_btn_r),
        .btn_p2_down(de_btn_l),
        .disparity(sad_disp)
    );


endmodule

module grayscale_quantizer_10step (
    input  logic [15:0] rgb,    // RGB565 입력
    input  logic        valid,  // 유효한 데이터
    output logic [ 7:0] q_gray  // 계단화된 밝기 (0~255 중 10단계)
);

    // RGB565 분리
    logic [4:0] r_raw, b_raw;
    logic [ 5:0] g_raw;
    logic [16:0] luma;
    logic [ 7:0] luma8;

    assign r_raw = rgb[15:11];
    assign g_raw = rgb[10:5];
    assign b_raw = rgb[4:0];

    // Grayscale 변환 (가중치: R*77 + G*150 + B*29) = 총합 256
    always_comb begin
        luma   = r_raw * 8'd77 + g_raw * 8'd150 + b_raw * 8'd29;
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
    output logic [1:0] led,
    input logic [15:0] font_rom_out,
    output logic [6:0] char_code,
    output logic [3:0] font_y,
    output logic [7:0] fnd,
    input logic [4:0] sad_disp,
    output logic [1:0] buzz_state
);
    parameter IDLE = 0, ORANGE = 1, RED = 2 ;

    logic [1:0] state, next;
    logic display_en;
    logic [15:0] w_rgb;

    assign display_en = (x_pixel < 640 && y_pixel < 480);

    assign rgb = display_en ? w_rgb : 16'b0;

    logic [15:0] black_count;
    logic [15:0] orange_count;
    logic [15:0] red_count;


    logic [15:0] black_count1;
    logic [1:0] led_reg;
    logic [7:0] led_hold_counter;
    logic [7:0] detect_frame_counter;

    logic detected_this_frame;
    logic detected_this_frame1;

    logic [15:0] black_sum;
    logic [19:0] hamming_sum;
    logic [19:0] orange_sum;
    logic [19:0] red_sum;
    logic [19:0] final_hamming_sum;

    parameter base_x = 110;
    parameter base_y = 270;

    parameter base_x1 = 430;
    //parameter base_y1 = 270;

    logic [3:0] font_x;
    logic [15:0] font_row_data;
    logic warning_enable;
    logic warning_enable1;

    integer i;
    integer j;

    assign led[0] = led_reg[0];
    assign warning_enable = led_reg[0];

    assign led[1] = led_reg[1];
    assign warning_enable1 = led_reg[1];

    logic is_black = (w_rgb == 16'b0);
    logic is_orange = (w_rgb == 16'b11111_100000_00000);
    logic is_red = (w_rgb == 16'b11111_000000_00000);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            black_count <= 0;
            black_count1 <= 0;
            detect_frame_counter <= 0;
            black_sum <= 0;
            orange_count <= 0;
            red_count <= 0;
            hamming_sum <= 0;
            final_hamming_sum <= 0;
            fnd <= 0;
        end else 
        begin
            if ( x_pixel > 40 && x_pixel < 280 && y_pixel >= 270 && y_pixel < 450) begin
                if(is_black) begin                  
                black_count <= black_count + 1;
                hamming_sum <= hamming_sum + hamming;
                end
                else if(is_orange) begin
                orange_count <= orange_count + 1;
                end
                else if(is_red) begin
                red_count <= red_count + 1;
                end
                end
          

            
            if (x_pixel > 360 && x_pixel < 600 && y_pixel >= 270 && y_pixel < 450 && is_black) begin
                black_count1 <= black_count1 + 1;
            end


            // 프레임 마지막에서 LED 판정
            if (x_pixel == 639 && y_pixel == 479) begin
                // detected_this_frame <= (black_count >= 500);
                if (black_count >= 1500) begin
                    detected_this_frame <= 1;
                    buzz_state <= 3;
                end
                else if (orange_count >= 1200) begin
                    detected_this_frame <= 1;
                    buzz_state <= 2;
                end
                else if(red_count >= 1000) begin
                    detected_this_frame <= 1;
                    buzz_state <= 2;
                end
               else begin
                    detected_this_frame <= 0;
                    buzz_state <= 0;
                end





                if (black_count1 >= 1300) begin
                    detected_this_frame1 <= 1;
                end else begin
                    detected_this_frame1 <= 0;
                end

                black_count <= 0;
                orange_count <= 0;
                red_count <= 0;
                black_count1 <= 0;
                hamming_sum <= 0;

            end
        end 

    end






    

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            led_reg          <= 0;
            //led_hold_counter <= 0;
        end else begin
            if (detected_this_frame) begin
                //if (detect_frame_counter >= 8'd120 && led_hold_counter == 0) begin
                led_reg[0] <= 1;
                //led_hold_counter <= 120; // 240프레임 동안 유지
            end else begin
                led_reg[0] <= 0;
            end
            if (detected_this_frame1) begin
                //if (detect_frame_counter >= 8'd120 && led_hold_counter == 0) begin
                led_reg[1] <= 1;
            end else begin
                led_reg[1] <= 0;
            end
        end
    end
    



    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next;
        end
    end

    always_comb begin 
        next = state;
    end

    logic [55:0] warning_text = {
        8'd87,  // 'W'
        8'd65,  // 'A'
        8'd82,  // 'R'
        8'd78,  // 'N'
        8'd73,  // 'I'
        8'd78,  // 'N'
        8'd71  // 'G'
    };

    // logic [55:0] warning_text = {
    //     8'd71,  // 'G'
    //     8'd78,  // 'N'
    //     8'd73,  // 'I'
    //     8'd78,  // 'N'
    //     8'd82,  // 'R'
    //     8'd65,  // 'A'
    //     8'd87   // 'W'
    // };
    // logic [6:0] rel_x = x_pixel - 100;  // 0~99
    // logic [5:0] rel_y = y_pixel - 280;  // 0~39
    // logic [16:0] image_addr;

    always_comb begin
        w_rgb = 16'b0;

        if (x_pixel < 320 && y_pixel < 240) begin
            w_rgb = {rdata1[7:3], rdata1[7:2], rdata1[7:3]};
        end else if (x_pixel >= 320 && y_pixel < 240) begin
            w_rgb = {rdata2[7:3], rdata2[7:2], rdata2[7:3]};
        end else if (x_pixel < 320 && y_pixel >= 240 && y_pixel < 480) begin
            // 거리 시각화: Hamming → RGB 색상
            case (hamming)
                // 파랑 (0~9)
                6'd0, 6'd1, 6'd2, 6'd3, 6'd4,
                6'd5, 6'd6, 6'd7, 6'd8, 6'd9, 6'd10, 6'd11, 6'd12:
                    w_rgb = 16'b00000_000000_11111;

                // 청록 (10~16)
                6'd13, 6'd14, 6'd15, 6'd16:
                    w_rgb = 16'b00000_111111_11111;

                // 초록 (17~24)
                6'd17, 6'd18, 6'd19, 6'd20, 6'd21, 6'd22, 6'd23, 6'd24:
                    w_rgb = 16'b00000_111111_00000;

                // 노랑 (25~32)
                6'd25, 6'd26, 6'd27, 6'd28, 6'd29, 6'd30, 6'd31:
                    w_rgb = 16'b11111_111111_00000;

                // 주황 (33~37)
                6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37:
                    w_rgb = 16'b11111_100000_00000;

                // 빨강 (38~44)
                6'd38, 6'd39, 6'd40, 6'd41, 6'd42, 6'd43, 6'd44:
                    w_rgb = 16'b11111_000000_00000;

                // 검정 (45~59)
                6'd45, 6'd46, 6'd47, 6'd48, 6'd49,
                6'd50, 6'd51, 6'd52, 6'd53, 6'd54,
                6'd55, 6'd56, 6'd57, 6'd58, 6'd59:
                    w_rgb = 16'b00000_000000_00000;

                default:
                    w_rgb = 16'b00000_000000_00000;  // fallback: 검정
            endcase


            // if (warning_enable) begin
            //     if (x_pixel >= 100 && x_pixel < 200 &&
            //         y_pixel >= 280 && y_pixel < 308) begin

            //         // 이미지 내에서의 상대 위치
               
            //         image_addr = rel_y * 100 + rel_x;

            //         w_rgb = font_rom_out;  // image_rom_data는 16비트 RGB565 출력
            //     end
            // end
            if (warning_enable) begin
                for (i = 0; i < 7; i++) begin
                    if (x_pixel >= base_x + i*16 && x_pixel < base_x + (i+1)*16 &&
                        y_pixel >= base_y && y_pixel < base_y + 16) begin

                        font_x = x_pixel - (base_x + i * 16);
                        font_y = y_pixel - base_y;

                        char_code = warning_text[8*(7-i)-1-:8];
                        //char_code = warning_text[8*(6-i) +: 8]; // warning_text[]
                        font_row_data = font_rom_out;

                        if (font_row_data[15-font_x]) begin
                            w_rgb = 16'hFFFF;  // 빨간색 글자
                        end
                    end
                end
            end
        end else if (x_pixel >= 320 && y_pixel >= 240 && y_pixel < 480) begin
            case (sad_disp)
                // 파랑 (0~3)
                5'd0, 5'd1, 5'd2, 5'd3:
                    w_rgb = 16'b00000_000000_11111;  // 파랑

                // 청록 (4~6)
                5'd4, 5'd5, 5'd6:
                    w_rgb = 16'b00000_111111_11111;  // 청록

                // 초록 (7~10)
                5'd7, 5'd8, 5'd9, 5'd10:
                    w_rgb = 16'b00000_111111_00000;  // 초록

                // 노랑 (11~15)
                5'd11, 5'd12, 5'd13, 5'd14, 5'd15:
                    w_rgb = 16'b11111_111111_00000;  // 노랑

                // 주황 (16~20)
                5'd16, 5'd17, 5'd18, 5'd19, 5'd20:
                    w_rgb = 16'b11111_100000_00000;  // 주황

                // 빨강 (21~24)
                5'd21, 5'd22, 5'd23, 5'd24:
                    w_rgb = 16'b11111_000000_00000;  // 빨강

                // 검정 (25~31)
                5'd25, 5'd26, 5'd27, 5'd28, 5'd29, 5'd30, 5'd31:
                    w_rgb = 16'b00000_000000_00000;  // 빨강

                default:
                    w_rgb = 16'b00000_000000_11111;  // 검정
            endcase


            // if (warning_enable1) begin
            //     if (x_pixel >= 420 && x_pixel < 520 &&
            //         y_pixel >= 280 && y_pixel < 308) begin

            //         // 이미지 내에서의 상대 위치
               
            //         image_addr = rel_y * 100 + rel_x;

            //         w_rgb = font_rom_out;  // image_rom_data는 16비트 RGB565 출력
            //     end
            // end
            if (warning_enable1) begin
                for (j = 0; j < 7; j++) begin
                    if (x_pixel >= base_x1 + j*16 && x_pixel < base_x1 + (j+1)*16 &&
                        y_pixel >= base_y && y_pixel < base_y + 16) begin

                        font_x = x_pixel - (base_x1 + j * 16);
                        font_y = y_pixel - base_y;
                        
                        char_code = warning_text[8*(7-j)-1-:8];
                        //char_code = warning_text[8*(6-j) +: 8];
                        font_row_data = font_rom_out;

                        if (font_row_data[15-font_x]) begin
                            w_rgb = 16'hFFFF;  // 빨간색 글자
                        end
                    end
                end
            end
        end
        // waring     
    end

endmodule

// module hamming_distance (
//     input  logic [43:0] census_right,
//     input  logic [43:0] census_left,
//     output logic [5:0]  hamming  // 0~48 범위
// );

//     logic [43:0] diff;
//     int count;

//     always_comb begin
//         diff = census_right ^ census_left;

//         count = 0;
//         count = count +
//             diff[ 0] + diff[ 1] + diff[ 2] + diff[ 3] +
//             diff[ 4] + diff[ 5] + diff[ 6] + diff[ 7] +
//             diff[ 8] + diff[ 9] + diff[10] + diff[11] +
//             diff[12] + diff[13] + diff[14] + diff[15] +
//             diff[16] + diff[17] + diff[18] + diff[19] +
//             diff[20] + diff[21] + diff[22] + diff[23] +
//             diff[24] + diff[25] + diff[26] + diff[27] +
//             diff[28] + diff[29] + diff[30] + diff[31] +
//             diff[32] + diff[33] + diff[34] + diff[35] +
//             diff[36] + diff[37] + diff[38] + diff[39] +
//             diff[40] + diff[41] + diff[42] + diff[43];
//             //diff[44] + diff[45] + diff[46] + diff[47];

//         hamming = count[5:0];  // 6비트 범위 출력 (최대 48)
//     end

// endmodule



module buzzer (
    input rclk,
    input reset,
    input [1:0] state,
    output buzz_clk
);




logic [20:0] counter; 
logic [30:0] counter2; 



logic oclk;

logic bclk1;
logic [1:0] state_buzz, state_buzz_next;

logic [30:0] buzz_count, buzz_count_next;
logic buzz_clk_reg, buzz_clk_next;



assign buzz_clk = buzz_clk_reg;

always_ff @(posedge rclk, posedge reset ) begin
    if(reset) begin
        counter <= 0;
    end
    else begin
        if(counter == 1000000 - 1) begin
            oclk <= 1;
            counter <= 0;
        end
        else if (counter == 500000 - 1) begin
            counter <= counter + 1;
            oclk <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
end



always_ff @(posedge rclk, posedge reset ) begin
    if(reset) begin
        counter2 <= 0;
    end
    else begin
        if(counter2 >= buzz_count) begin
            bclk1 <= 1;
            counter2 <= 0;
        end

        else if(counter2 == buzz_count/2 ) begin
            counter2 <= counter2 + 1;
            bclk1 <= 0;
        end
        else begin
            counter2 <= counter2 + 1;
        end
    end
end





always_ff @(posedge rclk, posedge reset) begin 
    if(reset )begin
        buzz_count <= 0;
        buzz_clk_reg <= 0;
    end
    else begin
        buzz_count <= buzz_count_next;
        buzz_clk_reg <= buzz_clk_next;
    end
end



always_comb begin
    buzz_count_next = buzz_count;
    buzz_clk_next = buzz_clk_reg;
    case (state)
      0  : begin
        buzz_clk_next = 0;
      end 

      1 : begin
        buzz_count_next = 100000000;
        if(bclk1 == 1) begin
            buzz_clk_next = oclk;
        end
        else begin
            buzz_clk_next = 0;
        end
      end

      2 : begin
        buzz_count_next = 50000000;
        if(bclk1 == 1) begin
            buzz_clk_next = oclk;
        end
        else begin
            buzz_clk_next = 0;
        end
      end

     3  : begin
        buzz_count_next = 100000;
        if(bclk1 == 1) begin
            buzz_clk_next = oclk;
        end
        else begin
            buzz_clk_next = 0;
        end
      end
    endcase
end


endmodule
    