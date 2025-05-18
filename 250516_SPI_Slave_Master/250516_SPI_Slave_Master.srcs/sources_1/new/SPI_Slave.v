`timescale 1ns / 1ps

module Top_SPI_Slave (
    input clk,
    input reset,

    input SCLK,
    input MOSI,
    output MISO,
    input CS,

    output [3:0] fndcom,
    output [7:0] fndfont
);
    wire [7:0] w_data;
    wire w_done;
    wire [15:0] fndData;

    SPI_Slave U_spi_slave(
        .SCLK(SCLK),
        .reset(reset),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS(CS),
        .data(w_data),
        .done(w_done)
    );
    Slave_fsm U_slave_fsm(
        .clk(clk),
         .SCLK(SCLK),
        .reset(reset),
        .data(w_data),
        .done(w_done),
        .CS(CS),
        .fnd_data(fndData)
    );
    fnd_controller U_fnd(
        .clk(clk),
        .reset(reset),
        .fndData(fndData),
        .fndcom(fndcom),
        .fndfont(fndfont)
    );
endmodule

module SPI_Slave(
    input SCLK,
    input reset,
    input MOSI,
    output MISO,
    input CS,

    output reg [7:0] data,
    output reg done
);
    reg [2:0] data_count;

    always @(posedge SCLK, posedge reset) begin
        if (reset) begin
            data_count <= 0;
            data <= 0;
            done <= 0;
        end else begin
            if (CS == 0) begin
                data <= {data[6:0], MOSI};
                if (data_count == 7) begin
                    done <= 1;
                    data_count <= 0;
                end else begin
                    done <= 0;
                    data_count <= data_count + 1;
                end
            end else begin
                data_count <= 0;
                done <= 0;
            end
        end
    end

endmodule

module Slave_fsm (
    input clk,
    input reset,
    input SCLK,
    input [7:0] data,
    input done,
    input CS,
    output reg [15:0] fnd_data
);
    parameter IDLE = 0, L_BYTE = 1, H_BYTE = 2, WAIT = 3;

    reg [2:0] state , next;
    reg [15:0] fnd_data_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            fnd_data <= 0;
        end else begin
            state <= next;
            fnd_data <= fnd_data_next;
        end
    end

    always @(*) begin
        next = state;
        fnd_data_next = fnd_data;
        case (state)
            IDLE: begin
                if (CS == 0 && done == 0) begin
                fnd_data_next = 0;
                    next = L_BYTE;
                end
            end
            L_BYTE: begin
                if (CS == 0 && done == 1 && !SCLK) begin
                    fnd_data_next[7:0] = data;
                    next = H_BYTE;
                end else begin
                    next = L_BYTE;
                end
            end
            H_BYTE: begin
                if (CS == 0 && done == 1 && SCLK) begin
                    fnd_data_next[15:8] = data;
                    next = WAIT;
                end else begin
                    next = H_BYTE;
                end
            end
            WAIT: begin
                if (CS == 1) begin
                    next = IDLE;
                end
            end
        endcase
    end
endmodule

module fnd_controller (
    input clk,
    input reset,
    input [15:0] fndData,
    output [3:0] fndcom,
    output [7:0] fndfont
);
    wire [1:0] digit_sel;
    wire [3:0] digit_1, digit_10, digit_100, digit_1000, digit;
    wire tick;

    clk_div_1khz U_clk_div_1khz (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );
    counter_2bit U_counter_2bit (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .count(digit_sel)
    );
    decoder_2x4 U_decoder_2x4 (
        .x(digit_sel),
        .y(fndcom)
    );
    digitsplitter U_digitsplitter (
        .fndData(fndData),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000)
    );
    mux_4x1 U_mux_4x1 (
        .sel(digit_sel),
        .x0 (digit_1),
        .x1 (digit_10),
        .x2 (digit_100),
        .x3 (digit_1000),
        .y  (digit)
    );
    bcdtoseg U_bcdtoseg (
        .bcd(digit),
        .seg(fndfont)
    );
endmodule

module clk_div_1khz (
    input clk,
    input reset,
    output reg tick
);

    reg [$clog2(1000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (div_counter == 1000 - 1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end

endmodule

module counter_2bit (
    input clk,
    input reset,
    input tick,
    output reg [1:0] count
);

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            if (tick) begin
                count <= count + 1;
            end
        end
    end
endmodule

module decoder_2x4 (
    input [1:0] x,
    output reg [4:0] y
);
    always @(*) begin
        y = 4'b1111;
        case (x)
            2'b00: y = 4'b1110;
            2'b01: y = 4'b1101;
            2'b10: y = 4'b1011;
            2'b11: y = 4'b0111;
        endcase
    end
endmodule

module digitsplitter (
    input  [15:0] fndData,
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);
    assign digit_1 = fndData % 10;
    assign digit_10 = fndData / 10 % 10;
    assign digit_100 = fndData / 100 % 10;
    assign digit_1000 = fndData / 1000 % 10;
endmodule

module mux_4x1 (
    input [1:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    output reg [3:0] y
);

    always @(*) begin
        y = 4'b0000;  // 래치 방지?
        case (sel)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
    end
endmodule

module bcdtoseg (
    input [3:0] bcd,
    output reg [7:0] seg
);
    always @(bcd) begin
        case (bcd)
            4'h0: seg = 8'hc0;
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
            4'hE: seg = 8'h7F;
            4'hF: seg = 8'h8F;
            default: seg = 8'hff;
        endcase
    end
endmodule