`timescale 1ns / 1ps
module census_matcher_top (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  rgb,      // 8-bit Luma 입력
    input  logic        de,
    input  logic [9:0]  x,
    output logic [44:0] census    // 3x15 기준 중심 제외 44 + 중심 차이 1 = 45bit
);

    // === 라인 버퍼 3개 ===
    logic [5:0] linebuf0[0:319];
    logic [5:0] linebuf1[0:319];
    logic [5:0] linebuf2[0:319];

    logic [9:0] x_d;
    logic [1:0] line_index;
    logic [5:0] q_gray;

    // === 10계단화 (6비트)
    always_comb begin
        if (!de)
            q_gray = 6'd0;
        else if (rgb < 8'd17)      q_gray = 6'd1;
        else if (rgb < 8'd25)      q_gray = 6'd2;
        else if (rgb < 8'd34)      q_gray = 6'd3;
        else if (rgb < 8'd42)      q_gray = 6'd4;
        else if (rgb < 8'd51)      q_gray = 6'd5;
        else if (rgb < 8'd59)      q_gray = 6'd6;
        else if (rgb < 8'd68)      q_gray = 6'd7;
        else if (rgb < 8'd76)      q_gray = 6'd8;
        else if (rgb < 8'd85)      q_gray = 6'd9;
        else if (rgb < 8'd93)      q_gray = 6'd10;
        else if (rgb < 8'd102)     q_gray = 6'd11;
        else if (rgb < 8'd110)     q_gray = 6'd12;
        else if (rgb < 8'd119)     q_gray = 6'd13;
        else if (rgb < 8'd127)     q_gray = 6'd14;
        else if (rgb < 8'd136)     q_gray = 6'd15;
        else if (rgb < 8'd144)     q_gray = 6'd16;
        else if (rgb < 8'd153)     q_gray = 6'd17;
        else if (rgb < 8'd161)     q_gray = 6'd18;
        else if (rgb < 8'd170)     q_gray = 6'd19;
        else if (rgb < 8'd178)     q_gray = 6'd20;
        else if (rgb < 8'd187)     q_gray = 6'd21;
        else if (rgb < 8'd195)     q_gray = 6'd22;
        else if (rgb < 8'd204)     q_gray = 6'd23;
        else if (rgb < 8'd212)     q_gray = 6'd24;
        else if (rgb < 8'd221)     q_gray = 6'd25;
        else if (rgb < 8'd229)     q_gray = 6'd26;
        else if (rgb < 8'd238)     q_gray = 6'd27;
        else if (rgb < 8'd246)     q_gray = 6'd28;
        else                       q_gray = 6'd29;
    end

    // === 라인 버퍼 저장
    always_ff @(posedge clk) begin
        if (rst) begin
            x_d <= 0;
            line_index <= 0;
        end else if (de) begin
            x_d <= x;
            case (line_index)
                2'd0: linebuf0[x] <= q_gray;
                2'd1: linebuf1[x] <= q_gray;
                2'd2: linebuf2[x] <= q_gray;
            endcase
            if (x == 319)
                line_index <= line_index + 1;
        end
    end

    // === 픽셀 값 수집 (하드코딩)
    logic [5:0] c00, c01, c02, c03, c04, c05, c06, c07, c08, c09, c10, c11, c12, c13, c14;
    logic [5:0] c10_, c11_, c12_, c13_, c14_, c15, c16, c17, c18, c19, c110, c111, c112, c113, c114;
    logic [5:0] c20, c21, c22, c23, c24, c25, c26, c27, c28, c29, c210, c211, c212, c213, c214;
    logic [5:0] center;

    always_comb begin
        c00 = (x_d >= 7)  ? linebuf0[x_d - 7]  : 0;
        c01 = (x_d >= 6)  ? linebuf0[x_d - 6]  : 0;
        c02 = (x_d >= 5)  ? linebuf0[x_d - 5]  : 0;
        c03 = (x_d >= 4)  ? linebuf0[x_d - 4]  : 0;
        c04 = (x_d >= 3)  ? linebuf0[x_d - 3]  : 0;
        c05 = (x_d >= 2)  ? linebuf0[x_d - 2]  : 0;
        c06 = (x_d >= 1)  ? linebuf0[x_d - 1]  : 0;
        c07 =              linebuf0[x_d];
        c08 = (x_d <= 318)? linebuf0[x_d + 1]  : 0;
        c09 = (x_d <= 317)? linebuf0[x_d + 2]  : 0;
        c10 = (x_d <= 316)? linebuf0[x_d + 3]  : 0;
        c11 = (x_d <= 315)? linebuf0[x_d + 4]  : 0;
        c12 = (x_d <= 314)? linebuf0[x_d + 5]  : 0;
        c13 = (x_d <= 313)? linebuf0[x_d + 6]  : 0;
        c14 = (x_d <= 312)? linebuf0[x_d + 7]  : 0;

        c10_  = (x_d >= 7)  ? linebuf1[x_d - 7]  : 0;
        c11_  = (x_d >= 6)  ? linebuf1[x_d - 6]  : 0;
        c12_  = (x_d >= 5)  ? linebuf1[x_d - 5]  : 0;
        c13_  = (x_d >= 4)  ? linebuf1[x_d - 4]  : 0;
        c14_  = (x_d >= 3)  ? linebuf1[x_d - 3]  : 0;
        c15   = (x_d >= 2)  ? linebuf1[x_d - 2]  : 0;
        c16   = (x_d >= 1)  ? linebuf1[x_d - 1]  : 0;
        center=               linebuf1[x_d];
        c17   = (x_d <= 318)? linebuf1[x_d + 1]  : 0;
        c18   = (x_d <= 317)? linebuf1[x_d + 2]  : 0;
        c19   = (x_d <= 316)? linebuf1[x_d + 3]  : 0;
        c110  = (x_d <= 315)? linebuf1[x_d + 4]  : 0;
        c111  = (x_d <= 314)? linebuf1[x_d + 5]  : 0;
        c112  = (x_d <= 313)? linebuf1[x_d + 6]  : 0;
        c113  = (x_d <= 312)? linebuf1[x_d + 7]  : 0;
        c114  = (x_d <= 311)? linebuf1[x_d + 8]  : 0;

        c20 = (x_d >= 7)  ? linebuf2[x_d - 7]  : 0;
        c21 = (x_d >= 6)  ? linebuf2[x_d - 6]  : 0;
        c22 = (x_d >= 5)  ? linebuf2[x_d - 5]  : 0;
        c23 = (x_d >= 4)  ? linebuf2[x_d - 4]  : 0;
        c24 = (x_d >= 3)  ? linebuf2[x_d - 3]  : 0;
        c25 = (x_d >= 2)  ? linebuf2[x_d - 2]  : 0;
        c26 = (x_d >= 1)  ? linebuf2[x_d - 1]  : 0;
        c27 =              linebuf2[x_d];
        c28 = (x_d <= 318)? linebuf2[x_d + 1]  : 0;
        c29 = (x_d <= 317)? linebuf2[x_d + 2]  : 0;
        c210= (x_d <= 316)? linebuf2[x_d + 3]  : 0;
        c211= (x_d <= 315)? linebuf2[x_d + 4]  : 0;
        c212= (x_d <= 314)? linebuf2[x_d + 5]  : 0;
        c213= (x_d <= 313)? linebuf2[x_d + 6]  : 0;
        c214= (x_d <= 312)? linebuf2[x_d + 7]  : 0;
    end

    // === Census 생성
    always_comb begin
        census[0]  = (c00 > center); census[1]  = (c01 > center); census[2]  = (c02 > center);
        census[3]  = (c03 > center); census[4]  = (c04 > center); census[5]  = (c05 > center);
        census[6]  = (c06 > center); census[7]  = (c07 > center); census[8]  = (c08 > center);
        census[9]  = (c09 > center); census[10] = (c10 > center); census[11] = (c11 > center);
        census[12] = (c12 > center); census[13] = (c13 > center); census[14] = (c14 > center);

        census[15] = (c10_ > center); census[16] = (c11_ > center); census[17] = (c12_ > center);
        census[18] = (c13_ > center); census[19] = (c14_ > center); census[20] = (c15 > center);
        census[21] = (c16 > center); census[22] = (c17 > center); census[23] = (c18 > center);
        census[24] = (c19 > center); census[25] = (c110 > center); census[26] = (c111 > center);
        census[27] = (c112 > center); census[28] = (c113 > center); census[29] = (c114 > center);

        census[30] = (c20 > center); census[31] = (c21 > center); census[32] = (c22 > center);
        census[33] = (c23 > center); census[34] = (c24 > center); census[35] = (c25 > center);
        census[36] = (c26 > center); census[37] = (c27 > center); census[38] = (c28 > center);
        census[39] = (c29 > center); census[40] = (c210 > center); census[41] = (c211 > center);
        census[42] = (c212 > center); census[43] = (c213 > center); census[44] = (c214 > center);
    end

endmodule
