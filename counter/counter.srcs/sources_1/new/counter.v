`timescale 1ns / 1ps
module Top_Upcounter (
    input clk,
    input reset,
    output [3:0] seg_comm,
    output [7:0] seg_data
);
    wire [13:0] w_count;
    wire w_10hz;

    clk_divider2a U_Clk_Divi (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_10hz)
    );

    counter U_Countr (
        .o_clk(w_10hz),
        .reset(reset),
        .counter_0(w_count)  // 14비트
    );


    fnd_controller U_fnd_cntl (
        .bcd(w_count),
        .clk(clk),
        .reset(reset),
        .seg(seg_data),
        .seg_comm(seg_comm)
    );

endmodule

module clk_divider2a (
    input  clk,
    input  reset,
    output o_clk
);
    parameter FCOUNT = 10_000_000;
    // $clog2 숫자를 나타내는데 필요한 비트수 계산
    reg [$clog2(FCOUNT)-1:0] r_counter;
    // clog : 수의 필요한 비트수 계산
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;  // 리셋상태
            r_clk <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1 ) begin // clock divide 계산, 100Mhz -> 100hz
                r_counter <= 0;
                r_clk <= ~r_clk;  // r_clk : 0 -> 1
            end else begin
                r_counter <= r_counter + 1;
                //r_clk <= 1'b0; // r_clk : 1 -> 0
            end
        end
    end
endmodule


module counter (
    input o_clk,
    input reset,
    output [13:0] counter_0  // 14비트
);
    reg [$clog2(10000)-1:0] r_counter;
    assign counter_0 = r_counter;

    always @(posedge o_clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            if (r_counter == 10000 - 1) begin
               r_counter <= 0;
            end else  r_counter <= r_counter + 1;
        end


    end
endmodule

