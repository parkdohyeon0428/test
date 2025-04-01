`timescale 1ns / 1ps

module main_top (
    input clk,
    input reset,
    input sw,
    output [7:0] fnd_font,
    output [3:0] fnd_comm
);
    //wire w_tick;
    wire [13:0] w_bcd;

    // clk_div U_Clk_div (
    //     .clk  (clk),
    //     .reset(reset),
    //     .tick (w_tick)
    // );
    // updowncount U_UpDown (
    //     .clk(clk),
    //     .reset(reset),
    //     .sw(sw),
    //     .tick(w_tick),
    //     .bcd(w_bcd)
    // );
    count U_Count(
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .bcd(w_bcd)
    );
    fnd_ctrl U_FND (
        .clk(clk),
        .reset(reset),
        .bcd(w_bcd),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );
endmodule

module count (
    input clk,
    input reset,
    input sw,
    output [13:0] bcd
);
    wire w_tick;

    clk_div U_Clk_div (
        .clk  (clk),
        .reset(reset),
        .tick (w_tick)
    );
    updowncount U_UpDown (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .tick(w_tick),
        .bcd(bcd)
    );
endmodule

module clk_div (
    input  clk,
    input  reset,
    output tick
);
    reg tick_1clk;
    assign tick = tick_1clk;

    reg [$clog2(1000)-1:0] count;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            tick_1clk <= 0;
        end else begin
            //tick_1clk <= 0;
            if (count == 1000-1) begin
                count <= 0;
                tick_1clk <= 1;
            end else begin
                count <= count + 1;
            end
        end
    end
endmodule

module updowncount (
    input clk,
    input reset,
    input sw,
    input tick,
    output reg [13:0] bcd
);
    // reg [13:0] count;
    // assign bcd = count;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            bcd <= 0;
        end else begin
            if (sw == 0) begin
                if (tick == 1) begin
                    if (bcd == 9999) begin
                        bcd <= 0;
                    end else begin
                        bcd <= bcd + 1;
                    end
                end
            end else if (sw == 1) begin
                if (tick == 1) begin
                    if (bcd == 0) begin
                        bcd <= 9999;
                    end else begin
                        bcd <= bcd - 1;
                    end
                end
            end
        end
    end
endmodule

