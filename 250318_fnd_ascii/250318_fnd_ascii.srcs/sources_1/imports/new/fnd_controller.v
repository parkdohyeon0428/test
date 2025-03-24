`timescale 1ns / 1ps

module fnd_controller (
    input [7:0] bcd,
    output [7:0] seg,
    output [3:0] seg_comm
);
    // 10000진 카운터
    // 0~9999 -> 몇 비트로 처리해야 하는가? -> log2(9999)
    // $clog2())-1:0
    // assign seg_comm = 4'b1110;  // segment 0의 자리 on, seg는 anode type

    
    assign seg_comm = 4'b1110;

    bcdtoseg U_bcdtoseg (
        .bcd(bcd),
        .seg(seg)
    );
endmodule

module bcdtoseg (
    input [7:0] bcd,  // [3:0] sum 값
    output reg [7:0] seg  // reg type 지정 (default: wire)
);
    // always 구문은 출력으로 wire X, reg type을 가져야 한다
    always @(bcd) begin     // 항상 @(이벤트 대상) 감시. begin부터 end를 실행

        case (bcd)  // if문
            "0": seg = 8'hC0;
            "1": seg = 8'hF9;
            "2": seg = 8'hA4;
            "3": seg = 8'hB0;
            "4": seg = 8'h99;
            "5": seg = 8'h92;
            "6": seg = 8'h82;
            "7": seg = 8'hF8;
            "8": seg = 8'h80;
            "9": seg = 8'h90;
            "A": seg = 8'h88;  // 1000 1000
            "B": seg = 8'h00;  // 1000 0010 (도트 추가)
            "C": seg = 8'hC6;  // 1100 0110
            "D": seg = 8'b01000000;  // 1010 0000 (도트 추가)
            "E": seg = 8'h86;  // 1000 0110
            "F": seg = 8'h8E;  // 1000 1110
            default: seg = 8'hFF;
        endcase
    end
endmodule


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
    input  [13:0] bcd,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
    assign digit_1 = bcd % 10;
    assign digit_10 = bcd / 10 % 10;
    assign digit_100 = bcd / 100 % 10;
    assign digit_1000 = bcd / 1000 % 10;

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


