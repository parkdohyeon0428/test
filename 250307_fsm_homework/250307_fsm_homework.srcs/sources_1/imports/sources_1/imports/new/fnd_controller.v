`timescale 1ns / 1ps

module fnd_controller (
    input clk,
    input reset,
    input [13:0] bcd1, bcd2,
    output [7:0] seg,
    output [3:0] seg_comm
);
    // 10000진 카운터
    // 0~9999 -> 몇 비트로 처리해야 하는가? -> log2(9999)
    // $clog2())-1:0
    // assign seg_comm = 4'b1110;  // segment 0의 자리 on, seg는 anode type

    wire [3:0] w_digit_1;
    wire [3:0] w_digit_10;
    wire [3:0] w_digit_100;
    wire [3:0] w_digit_1000;
    wire [3:0] w_bcd;
    wire [1:0] w_seg_sel;
    wire w_clk_100hz;

    clk_divider U_Clk_Divider (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_clk_100hz)
    );

    counter_4 U_counter_4 (
        .clk  (w_clk_100hz),
        .reset(reset),
        .o_sel(w_seg_sel)
    );

    docoder_2x4 U_docoder_2x4 (
        .seg_sel (w_seg_sel),
        .seg_comm(seg_comm)
    );

    digit_splitter U_digit_splitter (
        .bcd1(bcd1),
        .bcd2(bcd2),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux_4x1 U_mux_4x1 (
        .sel(w_seg_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .bcd(w_bcd)
    );

    bcdtoseg U_bcdtoseg (
        .bcd(w_bcd),
        .seg(seg)
    );
endmodule
/*
module clk_divider (
    input  clk,
    input  reset,
    output o_clk
);

    // reg [19:0] r_counter;
    parameter FCOUNT = 10_000_000; // 100MHz -> 10Hz
    reg [$clog2(FCOUNT)-1:0] r_counter;  //$clog2 : 수의 필요한 비트수 계산
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;  // 리셋상태
            r_clk <= 1'b0;
        end else begin
            // clock divide 계산, 
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_clk <= ~r_clk;
                //r_clk <= 1'b1;  // r_clk : 0->1
            end else begin
                r_counter <= r_counter + 1;
                //r_clk <= 1'b0;  // r_clk : 1->0, 0->0 : 0으로 유지
            end
        end
    end

endmodule*/

module clk_divider (
    input  clk,
    input  reset,
    output o_clk
);

    // reg [19:0] r_counter;
    parameter FCOUNT = 200_000 ;
    reg [$clog2(FCOUNT)-1:0] r_counter;  //$clog2 : 수의 필요한 비트수 계산
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;  // 리셋상태
            r_clk <= 1'b0;
        end else begin
            // clock divide 계산, 100Mhz -> 100hz
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_clk <= 1'b1;  // r_clk : 0->1
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;  // r_clk : 1->0, 0->0 : 0으로 유지
            end
        end
    end

endmodule

module counter_4 (
    input clk,
    input reset,
    output [1:0] o_sel
);
    reg [1:0] r_counter;
    assign o_sel = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;
        end
    end

endmodule


module docoder_2x4 (
    input [1:0] seg_sel,
    output reg [3:0] seg_comm
);

    // 2x4 decoder
    always @(seg_sel) begin  // * : 모든 입력을 감시한다
        case (seg_sel)
            2'b00:   seg_comm = 4'b1110;
            2'b01:   seg_comm = 4'b1101;
            2'b10:   seg_comm = 4'b1011;
            2'b11:   seg_comm = 4'b0111;
            default: seg_comm = 4'b1110;
        endcase
    end

endmodule

module digit_splitter (
    input  [13:0] bcd1, bcd2,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
    assign digit_1 = bcd1 % 10;
    assign digit_10 = bcd1 / 10 % 10;
    assign digit_100 = bcd2 / 100 % 10;
    assign digit_1000 = bcd2 / 1000 % 10;

endmodule

module mux_4x1 (
    input  [1:0] sel,
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    output [3:0] bcd
);

    // 이러게 안하고 위에 reg 해도 됨
    reg [3:0] r_bcd;
    assign bcd = r_bcd;
    always @(sel, digit_1, digit_10, digit_100, digit_1000) begin
        case (sel)
            2'b00:   r_bcd = digit_1;
            2'b01:   r_bcd = digit_10;
            2'b10:   r_bcd = digit_100;
            2'b11:   r_bcd = digit_1000;
            default: r_bcd = 4'bx;
        endcase
    end

endmodule

module bcdtoseg (
    input [3:0] bcd,  // [3:0] sum 값
    output reg [7:0] seg  // reg type 지정 (default: wire)
);
    // always 구문은 출력으로 wire X, reg type을 가져야 한다
    always @(bcd) begin     // 항상 @(이벤트 대상) 감시. begin부터 end를 실행

        case (bcd)  // if문
            4'h0: seg = 8'hC0;
            4'h1: seg = 8'hF9;
            4'h2: seg = 8'hA4;
            4'h3: seg = 8'hB0;
            4'h4: seg = 8'h99;
            4'h5: seg = 8'h92;
            4'h6: seg = 8'h82;
            4'h7: seg = 8'hF8;
            4'h8: seg = 8'h80;
            4'h9: seg = 8'h90;
            4'hA: seg = 8'h88;
            4'hB: seg = 8'h83;
            4'hC: seg = 8'hC6;
            4'hD: seg = 8'hA1;
            4'hE: seg = 8'h86;
            4'hF: seg = 8'h8E;
            default: seg = 8'hff;
        endcase
    end
endmodule
