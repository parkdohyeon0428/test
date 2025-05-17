`timescale 1ns / 1ps

module SPI_Master (
    input clk,
    input reset,
    input start,
    input [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg done,
    output reg ready,
    // SPI
    output reg SCLK,
    output [7:0] MOSI,
    input [7:0] MISO,
    output reg CS
);
    reg [6:0] counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            SCLK <= 0;
        end else begin
            if (counter == 99) begin
                SCLK <= 1;
                counter <= 0;
            end else begin
                counter <= counter + 1;
                SCLK <= 0;
            end
        end
    end

    parameter IDLE = 2'b00, CP0 = 2'b01, CP1 = 2'b10;

    reg [1:0] state, next;
    reg [7:0] temp_tx_data, temp_tx_data_next;
    reg [5:0] sclk_counter;
    reg [2:0] bit_counter;

    assign MOSI = temp_tx_data[7];

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            temp_tx_data <= 0;
        end else begin
            state <= next;
            temp_tx_data <= temp_tx_data_next;
        end
    end

    always @(*) begin
        next = state;
        temp_tx_data_next = temp_tx_data;
        sclk_counter = 0;
        ready = 0;
        done = 0;
        SCLK = 0;
        case (state)
            IDLE: begin
                temp_tx_data_next = 8'hz;
                done = 0;
                ready = 1;
                if (start) begin
                    temp_tx_data_next = tx_data;
                    ready = 0;
                    next = CP0;
                end
            end
            CP0: begin
                SCLK = 0;
                if (sclk_counter == 49) begin
                    rx_data = {rx_data[6:0], MISO};
                    sclk_counter = 0;
                    next = CP1;
                end else begin
                    sclk_counter = sclk_counter + 1;
                end
            end
            CP1: begin
                SCLK = 1;
                if (sclk_counter == 49) begin
                    if (bit_counter == 7) begin
                        done = 1;
                        next = IDLE;
                    end else begin
                        bit_counter = bit_counter + 1;
                        temp_tx_data_next = {temp_tx_data[6:0], 1'b0};
                        sclk_counter = 0;
                    end
                end else begin
                    sclk_counter = sclk_counter + 1;
                end
            end
        endcase
    end
endmodule
