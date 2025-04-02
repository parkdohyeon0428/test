`timescale 1ns / 1ps

module fnd_ctrl (
    input clk,
    input reset,
    input [13:0] bcd,
    output [3:0] fnd_comm,
    output [7:0] fnd_font
);
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_fnd_comm;
    wire [1:0] w_seg_sel;
    wire w_clk;

    clk_divider U_Clk_Div(
        .clk(clk),
        .reset(reset),
        .o_clk(w_clk)
    );

    digit_splitter U_Digit_Spl (
        .bcd(bcd),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );
    seg_sel U_Seg_Sel (
        .clk(clk),
        .reset(reset),
        .tick(w_clk),
        .seg_sel(w_seg_sel)
    );
    seg_comm U_Seg_Comm (
        .seg_sel (w_seg_sel),
        .fnd_comm(fnd_comm)
    );
    bcd_digit U_Bcd_Digit (
        .seg_sel(w_seg_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .seg_comm(w_fnd_comm)
    );
    seg_font U_Seg_Font (
        .seg_comm(w_fnd_comm),
        .seg_font(fnd_font)
    );
endmodule

module clk_divider (
    input  clk,
    input  reset,
    output o_clk
);

    // reg [19:0] r_counter;
    parameter FCOUNT = 100_000 ;
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

module digit_splitter (
    input  [13:0] bcd,
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);

    assign digit_1 = bcd % 10;
    assign digit_10 = (bcd / 10) % 10;
    assign digit_100 = (bcd / 100) % 10;
    assign digit_1000 = (bcd / 1000) % 10;
endmodule

module seg_sel (
    input clk,
    input reset,
    input tick,
    output reg [1:0] seg_sel
);
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            seg_sel = 0;
        end else begin
            if(tick == 1) begin
                seg_sel = seg_sel + 1;
            end
        end
    end
endmodule

module seg_comm (
    input [1:0] seg_sel,
    output reg [3:0] fnd_comm
);
    always @(seg_sel) begin
        case (seg_sel)
            2'b00:   fnd_comm = 4'b1110;
            2'b01:   fnd_comm = 4'b1101;
            2'b10:   fnd_comm = 4'b1011;
            2'b11:   fnd_comm = 4'b0111;
            default: fnd_comm = 4'b0000;
        endcase
    end
endmodule

module bcd_digit (
    input [1:0] seg_sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    output reg [3:0] seg_comm
);
    always @(*) begin
        case (seg_sel)
            2'b00:   seg_comm = digit_1;
            2'b01:   seg_comm = digit_10;
            2'b10:   seg_comm = digit_100;
            2'b11:   seg_comm = digit_1000;
            default: seg_comm = 4'bx;
        endcase
    end
endmodule

module seg_font (
    input [3:0] seg_comm,
    output reg [7:0] seg_font
);
    always @(seg_comm) begin
        case (seg_comm)
            4'h0: seg_font = 8'hC0;
            4'h1: seg_font = 8'hF9;
            4'h2: seg_font = 8'hA4;
            4'h3: seg_font = 8'hB0;
            4'h4: seg_font = 8'h99;
            4'h5: seg_font = 8'h92;
            4'h6: seg_font = 8'h82;
            4'h7: seg_font = 8'hF8;
            4'h8: seg_font = 8'h80;
            4'h9: seg_font = 8'h90;
            4'hA: seg_font = 8'h88;
            4'hB: seg_font = 8'h83;
            4'hC: seg_font = 8'hC6;
            4'hD: seg_font = 8'hA1;
            4'hE: seg_font = 8'h86;
            4'hF: seg_font = 8'h8E;
            default: seg_font = 8'hff;
        endcase
    end
endmodule

